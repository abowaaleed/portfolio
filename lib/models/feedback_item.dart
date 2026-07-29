class FeedbackItem {
  final String id;
  final String name;
  final String comment;
  final double rating;
  final DateTime date;
  final bool approved;

  const FeedbackItem({
    required this.id,
    this.name = '',
    required this.comment,
    this.rating = 0,
    required this.date,
    this.approved = false,
  });
}
