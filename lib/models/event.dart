enum EventSourceType { youtube, web, localFile, m3u, mp4, hls, rtmp }

enum EventStatus { upcoming, live, ended }

class LiveEvent {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String? thumbnailUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final int priceFc;
  final EventSourceType sourceType;
  final String sourceUrl;
  final String? localFilePath;
  final EventStatus status;
  final String category;
  final String? location;
  final String? organizer;
  final bool isFeatured;
  final int? viewersCount;

  const LiveEvent({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    this.thumbnailUrl,
    required this.startTime,
    this.endTime,
    required this.priceFc,
    required this.sourceType,
    required this.sourceUrl,
    this.localFilePath,
    this.status = EventStatus.upcoming,
    required this.category,
    this.location,
    this.organizer,
    this.isFeatured = false,
    this.viewersCount,
  });

  bool get isLive => status == EventStatus.live;
  bool get isUpcoming => status == EventStatus.upcoming;
  bool get hasEnded => status == EventStatus.ended;

  String get priceDisplay => priceFc == 0 ? 'GRATUIT' : '$priceFc FC';

  String get sourceBadge {
    switch (sourceType) {
      case EventSourceType.youtube:
        return 'YouTube';
      case EventSourceType.web:
        return 'Web';
      case EventSourceType.localFile:
        return 'Local';
      case EventSourceType.m3u:
        return 'M3U';
      case EventSourceType.mp4:
        return 'MP4';
      case EventSourceType.hls:
        return 'HLS';
      case EventSourceType.rtmp:
        return 'RTMP';
    }
  }

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    return LiveEvent(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      priceFc: json['price_fc'] ?? 0,
      sourceType: EventSourceType.values.firstWhere(
        (e) => e.name == json['source_type'],
        orElse: () => EventSourceType.web,
      ),
      sourceUrl: json['source_url'],
      status: EventStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EventStatus.upcoming,
      ),
      category: json['category'] ?? 'sport',
      location: json['location'],
      organizer: json['organizer'],
      isFeatured: json['is_featured'] ?? false,
      viewersCount: json['viewers_count'],
    );
  }
}

// Sample local events for the DRC market
class SampleEvents {
  static List<LiveEvent> get events => [
        LiveEvent(
          id: 'evt_001',
          title: 'FINALE LINAFOOT 2025',
          subtitle: 'AS Vita Club vs TP Mazembe',
          description:
              'La grande finale du championnat national de football de la RDC. Un match historique entre les deux géants du football congolais.',
          thumbnailUrl: 'https://picsum.photos/seed/football1/800/450',
          startTime: DateTime.now().add(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 6)),
          priceFc: 2000,
          sourceType: EventSourceType.youtube,
          sourceUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          status: EventStatus.upcoming,
          category: 'sport',
          location: 'Stade des Martyrs, Kinshasa',
          organizer: 'FECOFA',
          isFeatured: true,
        ),
        LiveEvent(
          id: 'evt_002',
          title: 'GALA DE BOXE - KINSHASA FIGHT NIGHT',
          subtitle: 'Championnat d\'Afrique Centrale',
          description:
              'Soirée de boxe professionnelle avec 6 combats au programme. Le clou du spectacle : le match pour le titre de Champion d\'Afrique Centrale.',
          thumbnailUrl: 'https://picsum.photos/seed/boxing1/800/450',
          startTime: DateTime.now().add(const Duration(hours: 1)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          priceFc: 3000,
          sourceType: EventSourceType.hls,
          sourceUrl: 'https://stream.example.com/kinshasa-fight/live.m3u8',
          status: EventStatus.live,
          category: 'sport',
          location: 'Palais du Peuple, Kinshasa',
          organizer: 'Kinshasa Boxing Promotions',
          isFeatured: true,
          viewersCount: 4523,
        ),
        LiveEvent(
          id: 'evt_003',
          title: 'CONCERT FALLY IPUPA LIVE',
          subtitle: 'Tournée "Formule Noire"',
          description:
              'Le roi de la rumba congolaise en concert exceptionnel. Une nuit magique avec Fally Ipupa et ses danseurs dans la capitale.',
          thumbnailUrl: 'https://picsum.photos/seed/concert1/800/450',
          startTime: DateTime.now().add(const Duration(days: 2)),
          priceFc: 5000,
          sourceType: EventSourceType.web,
          sourceUrl: 'https://live.fally-ipupa.com/concert-kinshasa',
          status: EventStatus.upcoming,
          category: 'musique',
          location: 'Zénith, Kinshasa',
          organizer: 'Maison Mère Records',
          isFeatured: true,
        ),
        LiveEvent(
          id: 'evt_004',
          title: 'MMA AFRICA CHAMPIONSHIP',
          subtitle: 'Arts Martiaux Mixtes - Edition Kinshasa',
          description:
              'Le meilleur du MMA africain en direct de Kinshasa. 8 combats au programme avec les meilleurs combattants du continent.',
          thumbnailUrl: 'https://picsum.photos/seed/mma1/800/450',
          startTime: DateTime.now().add(const Duration(days: 5)),
          endTime: DateTime.now().add(const Duration(days: 5, hours: 4)),
          priceFc: 4000,
          sourceType: EventSourceType.rtmp,
          sourceUrl: 'rtmp://stream.africamma.com/live/kinshasa2025',
          status: EventStatus.upcoming,
          category: 'sport',
          location: 'Salle Omnisports, Kinshasa',
          organizer: 'Africa MMA Organization',
          isFeatured: false,
        ),
        LiveEvent(
          id: 'evt_005',
          title: 'MESSE DE NOEL - CATHÉDRALE KINSHASA',
          subtitle: 'Retransmission en Direct',
          description:
              'Retransmission en direct de la grande messe de Noël célébrée à la Cathédrale Notre-Dame du Congo.',
          thumbnailUrl: 'https://picsum.photos/seed/church1/800/450',
          startTime: DateTime.now().add(const Duration(days: 10)),
          priceFc: 0,
          sourceType: EventSourceType.youtube,
          sourceUrl: 'https://www.youtube.com/watch?v=LIVE_CHURCH_STREAM',
          status: EventStatus.upcoming,
          category: 'culture',
          location: 'Cathédrale Notre-Dame, Kinshasa',
          organizer: 'Archidiocèse de Kinshasa',
          isFeatured: false,
        ),
        LiveEvent(
          id: 'evt_006',
          title: 'LUTTE TRADITIONNELLE CONGO',
          subtitle: 'Championnat National de Lutte',
          description:
              'Le sport ancestral à l\'honneur ! Championnats nationaux de lutte traditionnelle congolaise avec les meilleurs lutteurs des 26 provinces.',
          thumbnailUrl: 'https://picsum.photos/seed/wrestling1/800/450',
          startTime: DateTime.now().add(const Duration(days: 7)),
          priceFc: 1500,
          sourceType: EventSourceType.m3u,
          sourceUrl: 'https://stream.kin-sports.cd/lutte2025/playlist.m3u',
          status: EventStatus.upcoming,
          category: 'sport',
          location: 'Stade Tata Raphaël, Kinshasa',
          organizer: 'Fédération Congolaise de Lutte',
          isFeatured: false,
        ),
      ];
}
