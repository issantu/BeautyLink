class Movie {
  final int id;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final String? backdropPath;
  final String? overview;
  final String? releaseDate;
  final double? voteAverage;
  final int? voteCount;
  final List<int> genreIds;
  final String mediaType; // 'movie' or 'tv'
  final bool adult;
  final String? originalLanguage;
  final int? runtime;
  final List<String>? genres;

  const Movie({
    required this.id,
    required this.title,
    required this.originalTitle,
    this.posterPath,
    this.backdropPath,
    this.overview,
    this.releaseDate,
    this.voteAverage,
    this.voteCount,
    this.genreIds = const [],
    this.mediaType = 'movie',
    this.adult = false,
    this.originalLanguage,
    this.runtime,
    this.genres,
  });

  factory Movie.fromJson(Map<String, dynamic> json, {String mediaType = 'movie'}) {
    final isTV = json.containsKey('name') || mediaType == 'tv';
    return Movie(
      id: json['id'] ?? 0,
      title: isTV ? (json['name'] ?? '') : (json['title'] ?? ''),
      originalTitle: isTV
          ? (json['original_name'] ?? '')
          : (json['original_title'] ?? ''),
      posterPath: json['poster_path'],
      backdropPath: json['backdrop_path'],
      overview: json['overview'],
      releaseDate: isTV ? json['first_air_date'] : json['release_date'],
      voteAverage: (json['vote_average'] as num?)?.toDouble(),
      voteCount: json['vote_count'],
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      mediaType: isTV ? 'tv' : 'movie',
      adult: json['adult'] ?? false,
      originalLanguage: json['original_language'],
      runtime: json['runtime'],
    );
  }

  String get posterUrl => posterPath != null
      ? 'https://image.tmdb.org/t/p/w342$posterPath'
      : 'https://via.placeholder.com/342x513/141928/7C4DFF?text=${Uri.encodeComponent(title)}';

  String get backdropUrl => backdropPath != null
      ? 'https://image.tmdb.org/t/p/w780$backdropPath'
      : posterUrl;

  String get year => releaseDate?.isNotEmpty == true
      ? releaseDate!.substring(0, 4)
      : '';

  bool get isTV => mediaType == 'tv';
}

class TvShow extends Movie {
  final int? numberOfSeasons;
  final int? numberOfEpisodes;

  TvShow({
    required super.id,
    required super.title,
    required super.originalTitle,
    super.posterPath,
    super.backdropPath,
    super.overview,
    super.releaseDate,
    super.voteAverage,
    super.voteCount,
    super.genreIds,
    super.originalLanguage,
    this.numberOfSeasons,
    this.numberOfEpisodes,
  }) : super(mediaType: 'tv');

  factory TvShow.fromJson(Map<String, dynamic> json) {
    final movie = Movie.fromJson(json, mediaType: 'tv');
    return TvShow(
      id: movie.id,
      title: movie.title,
      originalTitle: movie.originalTitle,
      posterPath: movie.posterPath,
      backdropPath: movie.backdropPath,
      overview: movie.overview,
      releaseDate: movie.releaseDate,
      voteAverage: movie.voteAverage,
      voteCount: movie.voteCount,
      genreIds: movie.genreIds,
      originalLanguage: movie.originalLanguage,
      numberOfSeasons: json['number_of_seasons'],
      numberOfEpisodes: json['number_of_episodes'],
    );
  }
}
