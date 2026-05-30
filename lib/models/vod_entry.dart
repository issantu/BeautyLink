class VodEntry {
  final String id;
  final String title;
  final String? logo;
  final String streamUrl;
  final String group;
  final bool isSeries;

  const VodEntry({
    required this.id,
    required this.title,
    this.logo,
    required this.streamUrl,
    required this.group,
    this.isSeries = false,
  });

  // Strip quality markers and normalize for display / matching
  String get displayTitle => title
      .replaceAll(RegExp(r'\s*[\(\[][^\)\]]*[\)\]]\s*'), ' ')
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();

  String get searchKey => displayTitle.toLowerCase().trim();
}
