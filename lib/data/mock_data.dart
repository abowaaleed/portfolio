import '../models/app_item.dart';
import '../models/blog_post.dart';
import '../models/news_item.dart';
import '../models/social_link.dart';
import '../models/tutorial.dart';

List<AppItem> mockApps = [
  AppItem(
    id: 'pdfapp',
    name: 'دامج الصور وإنشاء PDF',
    description: 'تطبيق ويب لتحويل الصور إلى PDF، ضغط الملفات، تحرير النصوص، واستخراج النص من PDF.',
    iconUrl: 'picture_as_pdf',
    url: 'https://abowaaleed.github.io/PDFapp/',
    status: AppStatus.published,
    isPinned: true,
  ),
  AppItem(
    id: 'quran_memo',
    name: 'محفظ القرآن',
    description: 'تطبيق مساعد لحفظ القرآن الكريم مع التكرار والتقييم',
    iconUrl: 'menu_book',
    url: '',
    status: AppStatus.dev,
  ),
];

List<Tutorial> mockTutorials = [
  Tutorial(
    id: 't1',
    title: 'كيف تبني تطبيق Flutter Web كامل',
    category: 'Flutter',
    readTime: 10,
  ),
  Tutorial(
    id: 't2',
    title: 'شرح ربط Firebase مع Flutter',
    category: 'Flutter',
    readTime: 8,
  ),
  Tutorial(
    id: 't3',
    title: 'أساسيات Linux للمبتدئين',
    category: 'Linux',
    readTime: 6,
  ),
];

List<NewsItem> mockNews = [
  NewsItem(
    id: 'n1',
    title: 'Flutter 4.0 قادم مع تحسينات كبيرة في الأداء',
    source: 'Flutter Blog',
    date: DateTime.now(),
    url: '',
  ),
  NewsItem(
    id: 'n2',
    title: 'Dart 4.x: أسرع وأسهل من أي وقت مضى',
    source: 'Dart Dev',
    date: DateTime.now(),
    url: '',
  ),
  NewsItem(
    id: 'n3',
    title: 'إصدار Dart 3.12 مع دعم محسّن لـ Web Assembly',
    source: 'Dart Dev',
    date: DateTime.now(),
    url: '',
  ),
];

List<BlogPost> mockBlogPosts = [
  BlogPost(
    id: 'b1',
    title: 'رحلة تعلم Flutter: من الصفر إلى أول تطبيق',
    excerpt: 'في هذه التدوينة أشارك تجربتي مع Flutter وكيف بدأت وكيف يمكنك أن تبدأ أنت أيضًا.',
    category: 'Flutter',
    readTime: 5,
    date: DateTime.now().subtract(const Duration(days: 2)),
    slug: 'flutter-journey',
  ),
  BlogPost(
    id: 'b2',
    title: 'لماذا اخترت Dart كلغة برمجة أساسية؟',
    excerpt: 'Dart لغة رائعة تجمع بين سهولة التعلم وقوة الأداء. هذه هي أبرز الأسباب التي جعلتني أختارها.',
    category: 'Dart',
    readTime: 4,
    date: DateTime.now().subtract(const Duration(days: 7)),
    slug: 'why-dart',
  ),
];

List<SocialLink> mockSocialLinks = [
  SocialLink(
    id: 'x',
    name: 'X / Twitter',
    iconName: 'x-twitter',
    url: 'https://x.com/abowaaleed',
  ),
  SocialLink(
    id: 'github',
    name: 'GitHub',
    iconName: 'github',
    url: 'https://github.com/abowaaleed',
  ),
  SocialLink(
    id: 'telegram',
    name: 'تيليجرام',
    iconName: 'telegram',
    url: 'https://t.me/abowaaleed',
  ),
  SocialLink(
    id: 'instagram',
    name: 'انستقرام',
    iconName: 'instagram',
    url: 'https://instagram.com/abowaaleed',
  ),
  SocialLink(
    id: 'snapchat',
    name: 'سناب شات',
    iconName: 'snapchat',
    url: 'https://snapchat.com/add/abowaaleed',
  ),
  SocialLink(
    id: 'youtube',
    name: 'يوتيوب',
    iconName: 'youtube',
    url: 'https://youtube.com/@abowaaleed',
  ),
];
