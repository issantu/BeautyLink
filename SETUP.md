# OmniFlix - Setup Guide

OmniFlix est une application Flutter de divertissement (Films, TV en direct,
Jeux vidéo + ROMs, Événements PPV) avec paiement Mobile Money (RDC) et PayPal
(international).

---

## 1. Compilation rapide via GitHub Actions (recommandé)

Aucun outil local nécessaire — tout se passe sur GitHub.

### Build Android (APK debug)
1. Pousser sur la branche `main` ou `claude/**`, ou bien lancer manuellement
   le workflow **Build OmniFlix APK (Android)** depuis l'onglet *Actions*.
2. Une fois terminé, télécharger l'artifact `omniflix-debug-<run>.apk`
   et l'installer directement sur un téléphone Android.

### Build iOS (.app + IPA non signé)
1. Lancer le workflow **Build OmniFlix iOS** (s'exécute sur `macos-14`).
2. Télécharger l'artifact `omniflix-ios-unsigned-<run>.ipa`.
3. Pour installer sur un iPhone réel, utilisez **AltStore**, **Sideloadly**
   ou **TrollStore** (pas de compte développeur Apple requis pour les
   builds non signés).

> Les workflows régénèrent automatiquement les fichiers natifs manquants
> (xcodeproj, gradle wrapper, AppDelegate, MainActivity, mipmap launcher,
> Podfile, storyboards…) via `flutter create .` sans toucher aux fichiers
> personnalisés (AndroidManifest.xml, Info.plist, lib/).

---

## 2. Compilation locale

### Prérequis
- Flutter SDK >= 3.16 (testé avec **3.24.5**)
- Android Studio + Android SDK (pour Android)
- Xcode 15+ + CocoaPods (pour iOS, sur macOS uniquement)

### Démarrage
```bash
cd OmniFlix
flutter create . --org com.omniflix --project-name omniflix \
                 --platforms=android,ios
flutter pub get
flutter run
```

### Build Android
```bash
flutter build apk --debug --no-tree-shake-icons
# Sortie : build/app/outputs/flutter-apk/app-debug.apk
```

### Build iOS (macOS uniquement)
```bash
cd ios && pod install && cd ..
flutter build ios --debug --no-codesign --no-tree-shake-icons
# Pour signer/déployer, ouvrez ios/Runner.xcworkspace dans Xcode.
```

---

## 3. Configuration des APIs

Toutes les clés API sont déjà préconfigurées dans
`lib/core/constants/api_constants.dart` :

- **TMDb** (Films & Séries) — `tmdbApiKey`
- **RAWG** (Jeux vidéo) — `rawgApiKey`
- **IPTV-org** (TV en direct) — playlists publiques
- **M3U Abonné** — playlist privée premium

> Pour utiliser vos propres clés, remplacez simplement les valeurs.

---

## 4. Paiement Mobile Money (RDC)

Le paiement utilise le composeur USSD natif (`tel:*150*…#`) ce qui ne
nécessite aucune intégration backend. Le numéro marchand M-Pesa est
configurable dans `lib/core/constants/app_constants.dart` :

```dart
static const String mpesaMerchantNumber = '839495208';
```

Pour passer en production réelle (API daraja, Airtel API, etc.), modifier
`lib/services/payment_service.dart`.

---

## 5. Tarifs

| Formule              | RDC (FC)       | International (USD) |
|----------------------|----------------|---------------------|
| Pass Journée         | 3 000 FC       | $1.99               |
| Abonnement Mensuel   | 46 000 FC      | $14.99              |
| Événements PPV       | Variable       | Variable            |

---

## 6. Structure du projet

```
lib/
├── core/
│   ├── theme/          # Thème sombre premium
│   ├── constants/      # Clés API, tarifs FC/USD/EUR
│   └── utils/          # Formateurs (prix, dates)
├── models/             # Channel, Movie, Game, Event, Subscription
├── services/           # TMDb, RAWG, IPTV, Payment, Cast, VPN
├── providers/          # State management Riverpod
├── screens/
│   ├── home_screen.dart
│   ├── live_tv/        # TV en Direct + Player + VPN gate + Vavoo
│   ├── movies/         # Films & Séries
│   ├── games/          # Jeux Vidéo + ROMs Fun
│   ├── events/         # Événements PPV
│   └── payment/        # Abonnement & PPV (Mobile Money + PayPal)
└── widgets/            # Composants réutilisables
```

---

## 7. Casting TV / Projecteur

L'app supporte Chromecast / Google TV (`cast` package) sur Android et iOS.
Le casting nécessite que l'appareil soit sur le **même réseau Wi-Fi**.

---

## 8. Événements PPV

Sources supportées via `lib/models/event.dart > SampleEvents.events` :
- **YouTube** : Liens YouTube Live
- **Web** : Streaming web (WebView)
- **HLS** (`.m3u8`), **MP4**, **RTMP**, **M3U**, **Local file**

Pour connecter un backend, remplacez `SampleEvents.events` par un appel API.
