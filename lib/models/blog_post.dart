class BlogPost {
  final String id;
  final String title;
  final String excerpt;
  final String content;
  final String imageUrl;
  final String category;
  final int readTime;
  final DateTime date;
  final String slug;

  const BlogPost({
    required this.id,
    required this.title,
    required this.excerpt,
    this.content = '',
    this.imageUrl = '',
    required this.category,
    this.readTime = 3,
    required this.date,
    required this.slug,
  });
}
