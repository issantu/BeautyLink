# OmniFlix — Product Requirements Document

## Problem statement (original)
> check the github project in the repo
> finalise l'app pour android and ios, check it and make it run

## Project overview
- **Type** : Application **mobile native Flutter** (Android + iOS)
- **Domaine** : Hub de divertissement (Films via TMDb, TV en direct IPTV,
  Jeux vidéo via RAWG, événements PPV) — marché RDC + international
- **Stack** : Flutter 3.24.5 / Dart, Riverpod, video_player+chewie,
  flutter_inappwebview, cast (Chromecast), google_fonts
- **Paiement** : Mobile Money RDC via composeur USSD (M-Pesa/Airtel/Orange/
  Africell) + PayPal pour l'international
- **Pas de backend custom** : tout est client-side, APIs publiques/clés
  intégrées, données persistées via `shared_preferences`

## Architecture
```
lib/
├── core/            theme, constants, formatters
├── models/          Channel, Movie, Game, Event, Subscription
├── services/        TmdbService, RawgService, IptvService, PaymentService,
│                    CastService, VpnService
├── providers/       Riverpod (movies/tv/games/events providers)
├── screens/         home, splash, onboarding, live_tv, movies, games,
│                    events, payment
└── widgets/         Cards, headers, app_logo, cast_button…
```

## Personas
- **Utilisateur RDC** : paie en FC via Mobile Money, consomme TV en direct +
  films francophones + sport local (PPV)
- **Utilisateur international** : paie en USD/EUR via PayPal, accède au
  même catalogue

## What's been implemented (Jan 2026)
### Session 1 — Finalisation Android+iOS (completed)
- **Bug fix** : suppression du provider `paymentServiceProvider` dupliqué
  dans `lib/providers/events_provider.dart` (était aussi défini dans
  `lib/services/payment_service.dart` → conflit d'import)
- **pubspec.yaml nettoyé** : retiré les dépendances qui bloquaient la
  compilation native :
  - `firebase_core`, `firebase_analytics` (jamais initialisé, pas de
    `google-services.json` / `GoogleService-Info.plist`)
  - `openvpn_flutter` (non utilisé dans le code, dépendances natives lourdes)
  - `riverpod_annotation`, `riverpod_generator`, `build_runner`,
    `hive_generator` (aucun fichier `.g.dart` n'est utilisé)
  - `dio`, `youtube_player_flutter`, `shimmer`, `flutter_staggered_grid_view`,
    `lottie`, `flutter_svg`, `hive`, `hive_flutter`, `timeago`, `go_router`
    (importés nulle part dans `lib/`)
  - Références à `assets/images/`, `assets/icons/`, `assets/lottie/` et
    polices Poppins TTF (dossiers/fichiers absents — `google_fonts` charge
    Poppins via le réseau à la place)
- **Workflow GitHub Actions Android amélioré** (`build-apk.yml`) : ajout
  d'un step `flutter create .` qui régénère automatiquement tous les
  fichiers natifs manquants (gradle wrapper, mipmap launcher, AppDelegate,
  MainActivity, etc.) sans toucher aux fichiers personnalisés
- **Nouveau workflow iOS** (`build-ios.yml`) : tourne sur `macos-14`,
  régénère le scaffold iOS, lance `pod install`, build `.app` + `.ipa`
  non signé en artifacts téléchargeables
- **SETUP.md** réécrit avec guide complet (CI + local)

## Validation
- ✅ Tous les 43 fichiers Dart ont des accolades/parenthèses équilibrées
  (script Python custom)
- ✅ `pubspec.yaml` : YAML valide
- ✅ Workflows GitHub Actions : YAML valide
- ⚠️ **Compilation Flutter non vérifiée localement** (Flutter SDK non
  installé dans l'environnement Emergent) — la validation finale se fera
  via les workflows GitHub Actions au prochain push

## Next Action Items
- **P0** : Pousser sur GitHub et vérifier que `build-apk.yml` produit un
  APK exploitable (artifact téléchargeable)
- **P0** : Lancer `build-ios.yml` (manuel via *Actions* tab) et vérifier
  que l'IPA non signé est bien produit
- **P1** : Si la compilation passe, tester l'APK sur un Android réel pour
  valider :
  - Splash + onboarding (Lokke VPN)
  - TV en direct (chargement playlist M3U abonnée)
  - Lecture de stream HLS via chewie
  - Recherche TMDb (films/séries)
  - Catalogue jeux RAWG
  - Composeur USSD M-Pesa déclenché depuis l'écran paiement
- **P2** : Signer iOS pour distribution AltStore/TestFlight
- **P2** : Remplacer les sample events par un vrai backend PPV

## Backlog / Future
- Intégration API réelles Mobile Money (Daraja M-Pesa, Airtel API,
  Orange Developer) à la place du composeur USSD
- Hive/SQLite pour cache offline films/jeux
- Notifications push pour rappels événements PPV
- Téléchargement hors-ligne de films (DRM-free)
- Comptes utilisateur + sync multi-device
