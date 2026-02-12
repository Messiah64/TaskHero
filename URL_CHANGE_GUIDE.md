# 🌐 URL & Hosting Guide

> **Last Updated**: February 12, 2026

---

## Current Setup

| Item | Value |
|------|-------|
| **Live URL** | [taskhero-sutd.web.app](https://taskhero-sutd.web.app) |
| **Firebase Project** | `health-is-wealth-b91b2` |
| **Hosting Site Name** | `taskhero-sutd` |
| **Build Directory** | `build/web` |

### Current `firebase.json` Hosting Config

```json
{
  "hosting": {
    "site": "taskhero-sutd",
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "**",
        "headers": [
          { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
          { "key": "Cross-Origin-Embedder-Policy", "value": "credentialless" }
        ]
      },
      {
        "source": "**/*.@(js|css|wasm)",
        "headers": [
          { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
        ]
      }
    ],
    "rewrites": [
      { "source": "**", "destination": "/index.html" }
    ]
  }
}
```

**Key headers explained:**
- `Cross-Origin-Opener-Policy: same-origin` — Required for `SharedArrayBuffer` (used by some Flutter web features)
- `Cross-Origin-Embedder-Policy: credentialless` — Enables cross-origin isolation without breaking Google Sign-In
- Cache-Control on JS/CSS/WASM — Immutable caching for build artifacts (they have hashed filenames)
- SPA rewrite — All routes serve `index.html` (Flutter handles routing client-side)

---

## Option 1: Create a New Firebase Hosting Site

Firebase allows multiple hosting sites within one project. This is how `taskhero-sutd` was created.

### Steps

1. **Create the new site:**
   ```bash
   firebase hosting:sites:create your-new-site-name
   ```

2. **Update `firebase.json`:**
   ```json
   {
     "hosting": {
       "site": "your-new-site-name",
       ...
     }
   }
   ```

3. **Update `.firebaserc`** (add the new target):
   ```json
   {
     "projects": {
       "default": "health-is-wealth-b91b2"
     },
     "targets": {
       "health-is-wealth-b91b2": {
         "hosting": {
           "your-new-site-name": ["your-new-site-name"]
         }
       }
     }
   }
   ```

4. **Build and deploy:**
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

5. **Authorize the new domain** in Firebase Console:
   - Go to Authentication → Settings → Authorized domains
   - Add `your-new-site-name.web.app`

6. **Your new URL:** `https://your-new-site-name.web.app`

---

## Option 2: Add a Custom Domain

For a fully branded URL like `taskhero.app` or `taskhero.sutd.edu.sg`:

### Steps

1. **Purchase/obtain a domain:**
   - Commercial: Namecheap, Cloudflare Domains, Google Domains
   - University: Request a subdomain from SUTD IT (e.g., `taskhero.sutd.edu.sg`)

2. **Add custom domain in Firebase Console:**
   - Go to [Firebase Hosting](https://console.firebase.google.com/project/health-is-wealth-b91b2/hosting)
   - Click your site (`taskhero-sutd`)
   - Click **"Add custom domain"**
   - Enter your domain name

3. **Configure DNS records:**
   Firebase will provide DNS records to add at your domain registrar:
   - **TXT record** — For domain ownership verification
   - **A records** — Point to Firebase Hosting IP addresses

4. **Wait for SSL certificate** — Firebase auto-provisions a free SSL certificate. Takes up to 24 hours.

5. **Authorize the domain** in Firebase Auth:
   - Authentication → Settings → Authorized domains
   - Add your custom domain

6. **Done!** Your custom domain now serves the same app.

---

## Option 3: Keep Current URL

The app is already deployed at `taskhero-sutd.web.app`. If you just want to update branding:

### Files to Update

| File | What to Change |
|------|---------------|
| `web/index.html` | `<title>` tag |
| `web/manifest.json` | `name` and `short_name` fields |
| `web/index.html` | `<meta name="description">` tag |

These changes only affect the browser tab title and PWA install name — the URL stays the same.

---

## After Changing URLs — Checklist

When you move to a new URL, make sure to update:

- [ ] `firebase.json` → `"site"` field
- [ ] `.firebaserc` → hosting targets
- [ ] Firebase Console → Authentication → Authorized domains
- [ ] Any hardcoded URLs in code (search for the old URL)
- [ ] Browser bookmarks and shared links
- [ ] Any external integrations that reference the URL

---

## Troubleshooting

### "This domain is not authorized" error on Google Sign-In
→ Add the new domain to Firebase Console → Authentication → Settings → Authorized domains

### Deploy goes to wrong site
→ Check `firebase.json` has the correct `"site"` value
→ Run `firebase hosting:sites:list` to see all available sites

### CORS errors after URL change
→ The `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers in `firebase.json` handle this. Make sure they're still present after editing.

### Google Sign-In popup blocked
→ Ensure `Cross-Origin-Embedder-Policy` is set to `credentialless` (not `require-corp`), which allows the Google OAuth popup to work correctly.

---

## Related Documentation

- [SETUP_COMPLETE.md](SETUP_COMPLETE.md) — Full setup verification checklist
- [FIREBASE_AUTH_SETUP.md](FIREBASE_AUTH_SETUP.md) — Auth configuration details
- [Knowledge_Base.md](Knowledge_Base.md) — Complete project knowledge base
