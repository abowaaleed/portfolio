import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SiteText extends StatelessWidget {
  final String field;
  final String fallback;
  final TextStyle? style;
  final TextAlign? textAlign;

  const SiteText(this.field, {required this.fallback, this.style, this.textAlign, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('settings').doc('site_texts').snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final value = data?[field];
        final text = (value is String && value.trim().isNotEmpty) ? value : fallback;
        return Text(text, style: style, textAlign: textAlign);
      },
    );
  }
}

class SiteTextFieldDef {
  final String key;
  final String label;
  final String fallback;
  final bool multiline;

  const SiteTextFieldDef(this.key, this.label, this.fallback, {this.multiline = false});
}

const List<SiteTextFieldDef> siteTextFieldDefs = [
  SiteTextFieldDef('heroName', 'الاسم في الواجهة الرئيسية', 'صالح الحودي'),
  SiteTextFieldDef('heroSubtitle', 'اللقب في الواجهة الرئيسية', 'Saleh Alhoodi — موقع صالح الحودي'),
  SiteTextFieldDef('heroDescription', 'نبذة الواجهة الرئيسية', 'مطوّر تطبيقات وأنظمة • شغوف بالتقنية والتراث السعودي', multiline: true),
  SiteTextFieldDef('heroAppsButton', 'زر "تطبيقاتي"', 'تطبيقاتي'),
  SiteTextFieldDef('heroContactButton', 'زر "تواصل"', 'تواصل'),
  SiteTextFieldDef('navSiteName', 'اسم الموقع (شريط التنقل)', 'صالح الحودي'),
  SiteTextFieldDef('navTagline', 'وصف الموقع (شريط التنقل)', 'موقع صالح الحودي'),
  SiteTextFieldDef('navHome', 'عنصر القائمة: الرئيسية', 'الرئيسية'),
  SiteTextFieldDef('navApps', 'عنصر القائمة: تطبيقاتي', 'تطبيقاتي'),
  SiteTextFieldDef('navTutorials', 'عنصر القائمة: الشروحات', 'الشروحات'),
  SiteTextFieldDef('navNews', 'عنصر القائمة: أخبار', 'أخبار'),
  SiteTextFieldDef('navBlog', 'عنصر القائمة: المدونة', 'المدونة'),
  SiteTextFieldDef('navContact', 'عنصر القائمة: تواصل', 'تواصل'),
  SiteTextFieldDef('suggestionsLabel', 'عنوان "مقترحة لك"', 'مقترحة لك'),
  SiteTextFieldDef('appsTitle', 'عنوان قسم التطبيقات', 'تطبيقاتي'),
  SiteTextFieldDef('appsSubtitle', 'وصف قسم التطبيقات', 'تطبيقات وأدوات طورتها'),
  SiteTextFieldDef('tutorialsTitle', 'عنوان قسم الشروحات', 'الشروحات'),
  SiteTextFieldDef('tutorialsSubtitle', 'وصف قسم الشروحات', 'دروس تقنية'),
  SiteTextFieldDef('newsTitle', 'عنوان قسم الأخبار', 'الأخبار والترندات'),
  SiteTextFieldDef('newsSubtitle', 'وصف قسم الأخبار', 'تقنية • محلية • ترندات • عالمي'),
  SiteTextFieldDef('blogTitle', 'عنوان قسم المدونة', 'المدونة'),
  SiteTextFieldDef('blogSubtitle', 'وصف قسم المدونة', 'تدوينات البرمجة والتقنية'),
  SiteTextFieldDef('socialTitle', 'عنوان قسم التواصل', 'تواصل معي'),
  SiteTextFieldDef('socialSubtitle', 'وصف قسم التواصل', 'على منصات التواصل'),
  SiteTextFieldDef('feedbackTitle', 'عنوان قسم التعليقات', 'رأيك يهمني'),
  SiteTextFieldDef('feedbackSubtitle', 'وصف قسم التعليقات', 'شاركني باقتراح أو تعليق'),
  SiteTextFieldDef('feedbackCardTitle', 'عنوان بطاقة التعليقات', 'ما رأيك في الموقع؟'),
  SiteTextFieldDef('footerName', 'الاسم في التذييل', 'صالح الحودي'),
  SiteTextFieldDef('footerCopyright', 'نص الحقوق في التذييل', '© 2026 Saleh Alhoodi. جميع الحقوق محفوظة.'),
];
