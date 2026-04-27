# OmniFlix - Setup Guide

## Prérequis

- Flutter SDK >= 3.1.0
- Dart SDK >= 3.1.0
- Android Studio / VS Code
- Un compte développeur TMDb (gratuit)
- Un compte RAWG (gratuit)

## Installation

```bash
cd BeautyLink
flutter pub get
flutter run
```

## Configuration des APIs

### 1. TMDb (Films & Séries)
1. Créez un compte sur https://developer.themoviedb.org
2. Obtenez une clé API gratuite
3. Ouvrez `lib/core/constants/api_constants.dart`
4. Remplacez `YOUR_TMDB_API_KEY` par votre clé

### 2. RAWG (Jeux Vidéo)
1. Créez un compte sur https://rawg.io/apidocs
2. Obtenez une clé API gratuite
3. Ouvrez `lib/core/constants/api_constants.dart`
4. Remplacez `YOUR_RAWG_API_KEY` par votre clé

## Paiement Mobile Money (Production)

Pour intégrer les vrais APIs de paiement, modifiez `lib/services/payment_service.dart` :

- **Airtel Money (Congo)**: Intégration API Airtel
- **M-Pesa (Vodacom Congo)**: Intégration Safaricom Daraja API
- **Orange Money**: Intégration Orange Developer
- **Africell Money**: Intégration Africell API

## Structure du projet

```
lib/
├── core/
│   ├── theme/          # Thème sombre premium
│   ├── constants/      # API keys, tarifs FC
│   └── utils/          # Formateurs (prix FC, dates)
├── models/             # Channel, Movie, Game, Event, Subscription
├── services/           # TMDb, RAWG, IPTV, Payment
├── providers/          # Riverpod state management
├── screens/
│   ├── home_screen.dart
│   ├── live_tv/        # TV en Direct + Player
│   ├── movies/         # Films & Séries
│   ├── games/          # Jeux Vidéo
│   ├── events/         # Événements PPV
│   └── payment/        # Abonnement & PPV
└── widgets/            # Composants réutilisables
```

## Tarifs (Franc Congolais)

| Formule | Prix |
|---------|------|
| Pass Journée | 3 000 FC |
| Abonnement Mensuel | 46 000 FC |
| Événements PPV | Variable (par événement) |

## Casting TV / Projecteur

L'app supporte le casting via Chromecast (Android & iOS).
Assurez-vous que votre Chromecast est sur le même réseau Wi-Fi.

## Événements PPV Locaux

Les événements peuvent venir de plusieurs sources :
- **YouTube**: Liens YouTube Live
- **Web**: Liens de streaming web
- **HLS**: Flux `.m3u8`
- **RTMP**: Flux RTMP
- **MP4**: Fichiers vidéo directs
- **M3U**: Playlists IPTV

Ajoutez vos événements dans `lib/models/event.dart` > `SampleEvents.events`
ou connectez-les à votre propre backend API.
