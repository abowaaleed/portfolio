enum AppStatus { published, beta, dev }

class AppItem {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String url;
  final AppStatus status;
  final int clickCount;
  final bool isPinned;

  const AppItem({
    required this.id,
    required this.name,
    required this.description,
    this.iconUrl = '',
    required this.url,
    this.status = AppStatus.published,
    this.clickCount = 0,
    this.isPinned = false,
  });

  factory AppItem.fromMap(Map<String, dynamic> map) => AppItem(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String,
        iconUrl: map['iconUrl'] as String? ?? '',
        url: map['url'] as String,
        status: AppStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => AppStatus.published,
        ),
        clickCount: map['clickCount'] as int? ?? 0,
        isPinned: map['isPinned'] as bool? ?? false,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'iconUrl': iconUrl,
        'url': url,
        'status': status.name,
        'clickCount': clickCount,
        'isPinned': isPinned,
      };

  AppItem copyWith({int? clickCount}) => AppItem(
        id: id,
        name: name,
        description: description,
        iconUrl: iconUrl,
        url: url,
        status: status,
        clickCount: clickCount ?? this.clickCount,
        isPinned: isPinned,
      );
}
