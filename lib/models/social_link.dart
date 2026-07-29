class SocialLink {
  final String id;
  final String name;
  final String iconName;
  final String url;
  final int clickCount;

  const SocialLink({
    required this.id,
    required this.name,
    required this.iconName,
    required this.url,
    this.clickCount = 0,
  });
}
