class Game {
  final int id;
  final String name;
  final String? backgroundImage;
  final String? description;
  final double? rating;
  final int? ratingsCount;
  final String? released;
  final List<String> platforms;
  final List<String> genres;
  final List<String> tags;
  final String? website;
  final bool? tba;
  final List<String> screenshots;

  const Game({
    required this.id,
    required this.name,
    this.backgroundImage,
    this.description,
    this.rating,
    this.ratingsCount,
    this.released,
    this.platforms = const [],
    this.genres = const [],
    this.tags = const [],
    this.website,
    this.tba,
    this.screenshots = const [],
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      backgroundImage: json['background_image'],
      description: json['description_raw'] ?? json['description'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingsCount: json['ratings_count'],
      released: json['released'],
      platforms: (json['platforms'] as List?)
              ?.map((p) => p['platform']['name'] as String)
              .toList() ??
          [],
      genres: (json['genres'] as List?)
              ?.map((g) => g['name'] as String)
              .toList() ??
          [],
      tags: (json['tags'] as List?)
              ?.take(5)
              .map((t) => t['name'] as String)
              .toList() ??
          [],
      website: json['website'],
      tba: json['tba'],
      screenshots: (json['short_screenshots'] as List?)
              ?.map((s) => s['image'] as String)
              .toList() ??
          [],
    );
  }

  String get coverImage =>
      backgroundImage ?? 'https://via.placeholder.com/320x180/141928/7C4DFF?text=${Uri.encodeComponent(name)}';

  String get year => released?.isNotEmpty == true ? released!.substring(0, 4) : '';

  String get ratingDisplay => rating != null ? rating!.toStringAsFixed(1) : 'N/A';

  String get platformsDisplay {
    if (platforms.isEmpty) return 'Multi-plateforme';
    return platforms.take(3).join(' • ');
  }
}
