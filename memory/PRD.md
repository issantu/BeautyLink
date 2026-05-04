# OmniFlix — Product Requirements Document

## Problem statement (original)
> check the github project in the repo
> finalise l'app pour android and ios, check it and make it run
> pour le systeme de paiement, avant d'inserer stripe je te signale que je
> privilege un paiement en franc congolais a partir des mobile money, c'est
> important. pour les autres utilisateurs, stripe reste mieux indiqué

## Project overview
- **Type** : Application **mobile native Flutter** (Android + iOS) +
  backend FastAPI léger pour Stripe Checkout
- **Domaine** : Hub de divertissement (Films via TMDb, TV en direct IPTV,
  Jeux vidéo via RAWG, événements PPV) — marché RDC + international
- **Stack Flutter** : 3.24.5 / Dart, Riverpod, video_player+chewie,
  flutter_inappwebview, cast (Chromecast), google_fonts
- **Stack Backend** : FastAPI + Motor (MongoDB) + emergentintegrations
  pour Stripe
- **Paiement** :
  - **RDC** : Mobile Money en **Franc Congolais (FC)** via composeur
    USSD natif (M-Pesa/Airtel/Orange/Africell) — 100 % client, pas de backend
  - **International** : **Stripe Checkout** (USD) — backend FastAPI crée la
    session, user paie, app poll le status pour activer l'abonnement

## Architecture
```
/app/
├── lib/                 # Flutter app
│   ├── core/            theme, constants (backendBaseUrl, prix FC/USD)
│   ├── models/          Channel, Movie, Game, Event, Subscription
│   ├── services/        tmdb, rawg, iptv, payment (FC+Stripe), cast, vpn
│   ├── providers/       Riverpod
│   ├── screens/         home, live_tv, movies, games, events, payment
│   └── widgets/         cards, carousel, cast button
├── backend/             # FastAPI Stripe backend
│   ├── server.py        /api/stripe/checkout, /api/stripe/status/{id},
│   │                    /api/webhook/stripe, /api/health
│   ├── requirements.txt
│   └── .env             MONGO_URL, DB_NAME, STRIPE_API_KEY
├── android/, ios/       Natif mobile (auto-regen par flutter create)
├── .github/workflows/   build-apk.yml (Ubuntu), build-ios.yml (macOS)
└── build/web/           Flutter web preview (servi localement via python3)
```

## Personas
- **Utilisateur RDC** : paie en **FC** via Mobile Money (3 000 FC/jour ou
  46 000 FC/mois) — jamais redirigé hors de l'app, composeur USSD
- **Utilisateur international** : paie en **USD** ($1.99/jour ou $14.99/
  mois) via Stripe Checkout (Visa, MC, Amex, Apple/Google Pay, 3D Secure)

## What's been implemented (Jan 2026)

### Session 1 — Finalisation Android+iOS (done)
- Bug fix : `paymentServiceProvider` dupliqué → résolu
- `pubspec.yaml` nettoyé (retiré 12 deps bloquantes)
- Workflows GitHub Actions : `build-apk.yml` (Android) + `build-ios.yml` (macOS)

### Session 2 — Flutter Web preview (done)
- Installation Flutter SDK 3.24.5 dans `/opt/flutter`
- Upgrade `carousel_slider` 4.2.1 → 5.0.0 (conflit Flutter 3.24 `CarouselController`)
- `flutter build web --release` → 26 MB bundle servi via `python3 -m http.server 3000`

### Session 3 — Remplacement PayPal → Stripe International (done)
- Backend FastAPI créé : Stripe Checkout avec polling status
- Flutter `PaymentService` mis à jour : `PaymentMethod.stripe` remplace `paypal`
- UI : onglet "International — Stripe" avec carte Stripe Checkout

### Session 4 — API Mobile Money RDC avec STK Push auto-confirm (done)
**Backend** :
- Nouveau fichier `/app/backend/mobile_money.py` avec 4 adaptateurs :
  - `VodacomMpesaAdapter` (M-Pesa DRC via openapi.m-pesa.com)
  - `AirtelMoneyAdapter` (Airtel Africa API, country=CD, currency=CDF)
  - `OrangeMoneyAdapter` (Orange Developer Web Payment)
  - `AfricellMoneyAdapter` (API publique sur demande)
- Mode **sandbox par défaut** (`MOBILE_MONEY_MODE=sandbox`) : simule STK Push
  avec auto-confirm en 3s, 90 % de réussite
- Mode **live** : credentials à brancher dans `/app/backend/.env`, TODO
  marqués dans le code pour l'implémentation réelle de chaque opérateur
- Nouveaux endpoints :
  - `POST /api/mobile_money/initiate` — déclenche un STK Push
  - `GET /api/mobile_money/status/{reference}` — poll le status
  - `POST /api/mobile_money/webhook/{operator}` — callback opérateur
- MongoDB collection `mobile_money_transactions` avec tracking complet
- Prix FC définis côté serveur (anti-manipulation client)

**Flutter** :
- `PaymentService.initiateStkPush()` / `initiateStkPushPpv()`
- `PaymentService.pollMobileMoneyPayment()` — Stream poll 2s/60s max
- `_StkPendingBox` widget : spinner + badge SANDBOX dynamique
- UI payment_screen :
  - CTA principal : "Payer X FC" → STK Push auto
  - Pendant l'attente : spinner "En attente de votre PIN sur le téléphone…"
  - Auto-success → Navigator.pop
  - **Fallback USSD** : bouton "Ça ne marche pas ? Composer manuellement (USSD)"
    → garde l'ancien composeur USSD intact
- Normalisation téléphone automatique côté backend
  (`812345678` → `243812345678`)

## Validation end-to-end (testée en web preview)
- ✅ Les 2 onglets RDC/Stripe affichent les bons montants (FC / USD)
- ✅ **STK Push en sandbox** : transaction `OMX-042DCB6EA368` créée →
  auto-confirm en 4s (3s sandbox + 2s polling) → subscription `monthly`
  activée localement → Navigator.pop
- ✅ **Stripe Checkout** : clic → session `cs_test_...` créée →
  redirection `checkout.stripe.com`
- ✅ MongoDB trace les 2 types de transactions avec metadata
- ✅ Backend `/api/health` OK
- ⚠️ Android/iOS réel non testé (env Emergent sans émulateur)

## Next Action Items
- **P0** : Pousser sur GitHub et lancer **Build OmniFlix APK (Android)** +
  **Build OmniFlix iOS** depuis l'onglet *Actions* → télécharger les
  artifacts APK+IPA
- **P0** : Déployer le backend FastAPI (`/app/backend/`) sur un hôte public
  (Emergent deploy, Railway, Fly.io, Render...) et mettre à jour
  `ApiConstants.backendBaseUrl` OU utiliser `--dart-define=BACKEND_URL=...`
  lors du build APK/IPA
- **P0** : Remplacer `STRIPE_API_KEY=sk_test_emergent` par la vraie clé
  Stripe Live du compte marchand OmniFlix avant la prod
- **P1** : Tester l'APK sur Android réel pour valider composeur USSD
  M-Pesa avec un vrai compte test
- **P2** : Configurer le webhook Stripe dans le dashboard
  (pointant vers `https://api.omniflix.cd/api/webhook/stripe`)
- **P2** : Intégration API Mobile Money réelles (Daraja M-Pesa, Airtel API)
  à la place du composeur USSD pour confirmation automatique

## Backlog / Future
- Hive/SQLite pour cache offline films/jeux
- Notifications push pour rappels événements PPV
- Téléchargement hors-ligne (DRM-free)
- Comptes utilisateur + sync multi-device
- Remplacement du composeur USSD par API directe Daraja/Airtel quand
  les comptes marchands seront opérationnels
