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
- Preview fonctionnelle : splash, onboarding, home (TMDb+IPTV+events),
  films, séries, paiement RDC avec 46 000 FC / 3 000 FC affichés correctement

### Session 3 — Remplacement PayPal → Stripe (done)
- **Côté RDC (inchangé)** : composeur USSD en FC conservé intact
  - `*150*1*{montant}*839495208#` (M-Pesa)
  - `*185*2*1*839495208*{montant}#` (Airtel)
  - `#144*1*839495208*{montant}#` (Orange)
  - `*210*2*839495208*{montant}#` (Africell)
- **Backend FastAPI** créé à `/app/backend/server.py` :
  - `POST /api/stripe/checkout` : crée session Stripe pour abonnement
    (daily_sub $1.99 / monthly_sub $14.99) ou PPV event (prix fixes côté
    serveur pour éviter la manipulation frontend)
  - `GET /api/stripe/status/{session_id}` : polling pour vérifier le paiement
  - `POST /api/webhook/stripe` : webhook officiel Stripe
  - Pages HTML `/payment-success.html` et `/payment-cancel.html`
  - MongoDB collection `payment_transactions` créée avec tracking complet
- **Flutter** mis à jour :
  - `PaymentMethod.paypal` → `PaymentMethod.stripe`
  - `PaymentService.openPayPal()` + `confirmPayPalPayment()` → remplacé par
    `createStripeCheckout()` + `openStripeCheckout()` + `confirmStripePayment()`
    (poll jusqu'à 5× le backend)
  - `ApiConstants.backendBaseUrl` configurable via `--dart-define=BACKEND_URL=...`
  - Carte UI "PayPal" → "Stripe Checkout" (logo carte, PCI-DSS, 135+ devises,
    3D Secure)
  - Onglet "International — PayPal" → "International — Stripe"
- **Sécurité** : montants définis côté backend uniquement (PACKAGES +
  PPV_PRICES), jamais reçus du frontend → anti-manipulation

## Validation end-to-end (testée en web preview)
- ✅ Onglet RDC affiche **3 000 FC / 46 000 FC** + 4 Mobile Money providers
- ✅ Onglet Stripe affiche **$1.99 / $14.99 USD** + carte Stripe Checkout
- ✅ Clic sur "Payer avec Stripe" → backend crée session →
  `cs_test_a1hpc2nv3VCR0Ix8slwmgOnfzH94CTlQ6Ysddh1PLHRVSxmdhwJxuR3WgF` →
  ouverture de `checkout.stripe.com` dans nouvel onglet
- ✅ MongoDB `payment_transactions` contient l'entrée avec `payment_status:
  initiated`, `amount: 14.99`, `metadata: {kind: subscription, plan: monthly}`
- ✅ Backend `/api/health` retourne `{ok: true}`
- ⚠️ **Android/iOS réel non testé** (environnement Emergent n'a pas
  d'émulateur). La validation finale passe par les GitHub Actions.

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
