import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';

// ─── OPENAI GPT-4o-mini SERVICE ─────────────────────────────────
class AIService {
  static Future<Map<String, dynamic>?> formatTask(String input) async {
    if (input.trim().isEmpty) return null;

    const systemPrompt = '''
You are TaskHero AI, helping SUTD students format task requests.

SUTD Context:
- Compact campus, 5-10 min between buildings
- Canteen: Building 2, Level 2
- Buildings have 5-8 levels, Hostel separate
- Nearby: Changi City Point (10min walk), Expo MRT
- Meal prices: \$3-6 SGD

Compensation (SGD):
- Food pickup 15min: \$2-4
- Off-campus 30min: \$5-8
- Tutoring 60min: \$10-20
- Tech help 30min: \$5-10
- Urgent: +\$2

Categories: "Food & Supplies", "Academic Help", "Campus Errands", "Tech & Making", "Social & Events", "Marketplace"

Return ONLY valid JSON with this exact schema:
{
  "title": "emoji + short title (max 50 chars)",
  "description": "clear instructions",
  "category": "one of 6 categories",
  "estimated_minutes": number,
  "suggested_compensation": number,
  "urgency": "normal" or "urgent",
  "pickup": {"building": "...", "level": "...", "landmark": "..."},
  "delivery": {"building": "...", "level": "...", "landmark": "..."}
}''';

    try {
      print('[OpenAI] Starting task formatting...');
      print('[OpenAI] Input length: ${input.length} chars');

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      print('[OpenAI] Sending request to GPT-4o-mini...');

      final resp = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiKeys.openaiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': 'Student request: "$input"'},
          ],
          'temperature': 0.3,
          'max_tokens': 1024,
          'response_format': {'type': 'json_object'},
        }),
      );

      print('[OpenAI] Response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('[OpenAI] Response received successfully');

        final text = data['choices'][0]['message']['content'] as String;
        print('[OpenAI] SUCCESS: Received formatted task');
        return jsonDecode(text) as Map<String, dynamic>;
      }

      print('[OpenAI] ERROR: Status ${resp.statusCode}');
      print('[OpenAI] Response body: ${resp.body}');
      return null;
    } catch (e, stackTrace) {
      print('[OpenAI] EXCEPTION: $e');
      print('[OpenAI] Stack trace: $stackTrace');
      return null;
    }
  }
}

// ─── DEEPGRAM STT SERVICE ───────────────────────────────────────
class DeepgramService {
  static Future<String?> transcribe(Uint8List audio, {String mime = 'audio/webm'}) async {
    try {
      // Log audio details for debugging
      print('[Deepgram] Starting transcription...');
      print('[Deepgram] Audio size: ${audio.length} bytes');
      print('[Deepgram] MIME type: $mime');
      
      if (audio.isEmpty) {
        print('[Deepgram] ERROR: Audio is empty!');
        return null;
      }

      final resp = await http.post(
        Uri.parse('https://api.deepgram.com/v1/listen?model=nova-2-general&smart_format=true'),
        headers: {
          'Authorization': 'Token ${ApiKeys.deepgramKey}',
          'Content-Type': mime,
        },
        body: audio,
      );

      print('[Deepgram] Response status: ${resp.statusCode}');

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        print('[Deepgram] Response body: ${resp.body.substring(0, resp.body.length > 200 ? 200 : resp.body.length)}...');
        
        final transcript = data['results']?['channels']?[0]?['alternatives']?[0]?['transcript'] as String?;
        
        if (transcript == null || transcript.isEmpty) {
          print('[Deepgram] WARNING: Transcript is empty or null');
        } else {
          print('[Deepgram] SUCCESS: Transcript length ${transcript.length} chars');
        }
        
        return transcript;
      }
      
      // Log detailed error information
      print('[Deepgram] ERROR: Status ${resp.statusCode}');
      print('[Deepgram] Response body: ${resp.body}');
      print('[Deepgram] Response headers: ${resp.headers}');
      return null;
    } catch (e, stackTrace) {
      print('[Deepgram] EXCEPTION: $e');
      print('[Deepgram] Stack trace: $stackTrace');
      return null;
    }
  }
}

// ─── FIREBASE STORAGE SERVICE ───────────────────────────────────
class StorageService {
  static Future<String?> upload({
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final resp = await http.post(
        Uri.parse('https://firebasestorage.googleapis.com/v0/b/${ApiKeys.storageBucket}/o?name=$path'),
        headers: {'Content-Type': contentType},
        body: bytes,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['downloadTokens'];
        return 'https://firebasestorage.googleapis.com/v0/b/${ApiKeys.storageBucket}/o/${Uri.encodeComponent(path)}?alt=media&token=$token';
      }
      print('Storage ${resp.statusCode}: ${resp.body}');
      return null;
    } catch (e) {
      print('Storage error: $e');
      return null;
    }
  }
}
