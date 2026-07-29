class Tutorial {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String category;
  final int readTime;
  final String url;

  const Tutorial({
    required this.id,
    required this.title,
    this.thumbnailUrl = '',
    required this.category,
    this.readTime = 5,
    this.url = '',
  });
}
