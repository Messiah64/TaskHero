import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

late AutoRefreshingAuthClient _authClient;
late String _projectId;
late String _bucketName;

Future<void> main() async {
  // Load service account credentials
  final credFile = _findCredentialsFile();
  if (credFile == null) {
    print('ERROR: No Firebase service account JSON found in project root.');
    print('Place your *-firebase-adminsdk-*.json file in the project root.');
    exit(1);
  }

  print('Using credentials: ${credFile.path}');
  final credJson = jsonDecode(await credFile.readAsString()) as Map<String, dynamic>;
  _projectId = credJson['project_id'] as String;
  _bucketName = '$_projectId.firebasestorage.app';

  // Authenticate with Google Cloud
  final credentials = ServiceAccountCredentials.fromJson(credJson);
  _authClient = await clientViaServiceAccount(credentials, [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase.storage',
    'https://www.googleapis.com/auth/generative-language',
  ]);

  print('Authenticated as: ${credJson['client_email']}');
  print('Project: $_projectId');

  // Set up routes
  final router = Router();

  router.get('/api/health', _healthCheck);
  router.post('/api/ai/format-task', _formatTask);
  router.post('/api/storage/upload', _uploadFile);
  router.get('/api/storage/list', _listFiles);
  router.get('/api/storage/buckets', _listBuckets);

  // Add CORS middleware for Flutter web
  final handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8080);
  print('');
  print('TaskHero Server running at http://localhost:${server.port}');
  print('');
  print('Endpoints:');
  print('  GET  /api/health           - Health check');
  print('  POST /api/ai/format-task   - AI task formatting (Gemini)');
  print('  POST /api/storage/upload   - Upload file to Firebase Storage');
  print('  GET  /api/storage/list     - List files in Firebase Storage');
  print('');
}

File? _findCredentialsFile() {
  // Look in project root (one level up from server/)
  final projectRoot = Directory.current.parent;
  final candidates = [
    ...projectRoot.listSync().whereType<File>(),
    ...Directory.current.listSync().whereType<File>(),
  ];
  for (final file in candidates) {
    if (file.path.endsWith('.json') &&
        file.path.contains('firebase-adminsdk')) {
      return file;
    }
  }
  // Also check current directory
  return null;
}

// ─── Health Check ───────────────────────────────────────────────
Response _healthCheck(Request request) {
  return Response.ok(
    jsonEncode({
      'status': 'ok',
      'project': _projectId,
      'services': ['gemini-ai', 'firebase-storage'],
    }),
    headers: {'content-type': 'application/json'},
  );
}

// ─── Gemini AI: Format Task ─────────────────────────────────────
Future<Response> _formatTask(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final userInput = body['input'] as String? ?? '';

    if (userInput.trim().isEmpty) {
      return Response(400,
          body: jsonEncode({'error': 'Missing "input" field'}),
          headers: {'content-type': 'application/json'});
    }

    final prompt = '''
You are TaskHero AI, helping SUTD students format task requests into structured JSON.

Given this task description from a student, extract and format it into a structured task.

SUTD Campus Context:
- Campus is compact, walking between buildings takes 5-10 min
- Canteen is in Building 2, Level 2
- Most buildings have 5-8 levels
- Hostel is a separate building on campus
- Nearby: Changi City Point mall (10min walk), Expo MRT
- Standard meal prices: \$3-6 SGD
- Students value time highly during exam periods

Compensation Guidelines (in SGD):
- Base rate: \$5/hour
- Simple food pickup (15min): \$2-4
- Off-campus errand (30min): \$5-8
- Tutoring (60min): \$10-20
- Tech help (30min): \$5-10
- Urgent premium: +\$2

Categories (pick one): "Food & Supplies", "Academic Help", "Campus Errands", "Tech & Making", "Social & Events", "Marketplace"

Student's request: "$userInput"

Return ONLY valid JSON with this exact structure, no markdown, no explanation:
{
  "title": "emoji + short title (max 50 chars)",
  "description": "clear instructions with locations",
  "category": "one of the 6 categories above",
  "estimated_minutes": number,
  "suggested_compensation": number (in SGD, with 2 decimals),
  "urgency": "normal" or "urgent" or "emergency",
  "pickup": {"building": "...", "level": "...", "landmark": "..."},
  "delivery": {"building": "...", "level": "...", "landmark": "..."}
}
''';

    // Call Gemini API via Vertex AI
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
    );

    final geminiResponse = await _authClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 1024,
          'responseMimeType': 'application/json',
        }
      }),
    );

    if (geminiResponse.statusCode != 200) {
      print('Gemini API error: ${geminiResponse.statusCode}');
      print('Body: ${geminiResponse.body}');
      return Response(502,
          body: jsonEncode({
            'error': 'Gemini API error',
            'status': geminiResponse.statusCode,
            'details': geminiResponse.body,
          }),
          headers: {'content-type': 'application/json'});
    }

    final geminiData = jsonDecode(geminiResponse.body) as Map<String, dynamic>;
    final candidates = geminiData['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      return Response(502,
          body: jsonEncode({'error': 'No response from Gemini'}),
          headers: {'content-type': 'application/json'});
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;

    // Parse the JSON from Gemini's response
    final taskJson = jsonDecode(text);

    return Response.ok(
      jsonEncode({
        'success': true,
        'task': taskJson,
        'raw_input': userInput,
      }),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, stack) {
    print('Error in format-task: $e\n$stack');
    return Response(500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'});
  }
}

// ─── Firebase Storage: Upload ───────────────────────────────────
Future<Response> _uploadFile(Request request) async {
  try {
    final contentType = request.headers['content-type'] ?? '';

    if (contentType.contains('application/json')) {
      // JSON body with base64-encoded file
      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final fileName = body['fileName'] as String? ?? 'upload_${DateTime.now().millisecondsSinceEpoch}';
      final base64Data = body['data'] as String? ?? '';
      final mimeType = body['mimeType'] as String? ?? 'application/octet-stream';

      if (base64Data.isEmpty) {
        return Response(400,
            body: jsonEncode({'error': 'Missing "data" field (base64)'}),
            headers: {'content-type': 'application/json'});
      }

      final bytes = base64Decode(base64Data);
      final storagePath = 'taskhero/$fileName';

      // Upload to Firebase Storage via GCS JSON API
      final uploadUrl = Uri.parse(
        'https://storage.googleapis.com/upload/storage/v1/b/$_bucketName/o'
        '?uploadType=media&name=$storagePath',
      );

      final uploadResponse = await _authClient.post(
        uploadUrl,
        headers: {'Content-Type': mimeType},
        body: bytes,
      );

      if (uploadResponse.statusCode != 200) {
        print('Storage upload error: ${uploadResponse.statusCode}');
        print('Body: ${uploadResponse.body}');
        return Response(502,
            body: jsonEncode({
              'error': 'Firebase Storage upload failed',
              'status': uploadResponse.statusCode,
              'details': uploadResponse.body,
            }),
            headers: {'content-type': 'application/json'});
      }

      final uploadData = jsonDecode(uploadResponse.body);
      final publicUrl =
          'https://storage.googleapis.com/$_bucketName/$storagePath';

      return Response.ok(
        jsonEncode({
          'success': true,
          'path': storagePath,
          'url': publicUrl,
          'size': uploadData['size'],
          'contentType': uploadData['contentType'],
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response(400,
        body: jsonEncode({'error': 'Send JSON with fileName, data (base64), mimeType'}),
        headers: {'content-type': 'application/json'});
  } catch (e, stack) {
    print('Error in upload: $e\n$stack');
    return Response(500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'});
  }
}

// ─── Firebase Storage: List Files ───────────────────────────────
Future<Response> _listFiles(Request request) async {
  try {
    final prefix = request.url.queryParameters['prefix'] ?? 'taskhero/';
    final listUrl = Uri.parse(
      'https://storage.googleapis.com/storage/v1/b/$_bucketName/o?prefix=$prefix',
    );

    final listResponse = await _authClient.get(listUrl);

    if (listResponse.statusCode != 200) {
      return Response(502,
          body: jsonEncode({
            'error': 'Firebase Storage list failed',
            'status': listResponse.statusCode,
            'details': listResponse.body,
          }),
          headers: {'content-type': 'application/json'});
    }

    final data = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? []).map((item) {
      return {
        'name': item['name'],
        'size': item['size'],
        'contentType': item['contentType'],
        'updated': item['updated'],
      };
    }).toList();

    return Response.ok(
      jsonEncode({'files': items, 'count': items.length}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, stack) {
    print('Error in list: $e\n$stack');
    return Response(500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'});
  }
}

// ─── Firebase Storage: List Buckets ─────────────────────────────
Future<Response> _listBuckets(Request request) async {
  try {
    final bucketsUrl = Uri.parse(
      'https://storage.googleapis.com/storage/v1/b?project=$_projectId',
    );
    final bucketsResponse = await _authClient.get(bucketsUrl);

    if (bucketsResponse.statusCode != 200) {
      return Response(502,
          body: jsonEncode({
            'error': 'Failed to list buckets',
            'status': bucketsResponse.statusCode,
            'details': bucketsResponse.body,
          }),
          headers: {'content-type': 'application/json'});
    }

    final data = jsonDecode(bucketsResponse.body) as Map<String, dynamic>;
    final buckets = (data['items'] as List? ?? [])
        .map((b) => {'name': b['name'], 'location': b['location']})
        .toList();

    return Response.ok(
      jsonEncode({'buckets': buckets, 'count': buckets.length}),
      headers: {'content-type': 'application/json'},
    );
  } catch (e, stack) {
    print('Error in listBuckets: $e\n$stack');
    return Response(500,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'});
  }
}
