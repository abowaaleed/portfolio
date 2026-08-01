import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class NewsDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;
  const NewsDetailSheet({super.key, required this.data, required this.isDark});

  Future<void> _openSource(BuildContext context) async {
    final url = (data['url'] as String? ?? data['link'] as String? ?? '').trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('لا يوجد رابط للمصدر')));
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgBase64 = data['imageBase64'] as String?;
    final imgUrl = data['imageUrl'] as String?;
    final content = (data['summary'] as String? ?? data['content'] as String? ?? data['description'] as String? ?? '').trim();
    final sourceUrl = (data['url'] as String? ?? data['link'] as String? ?? '').trim();
    final category = (data['category'] as String? ?? '').trim();
    final traffic = (data['approxTraffic'] as String? ?? '').trim();
    final reason = (data['reason'] as String? ?? '').trim();
    final hasImage = (imgBase64 != null && imgBase64.isNotEmpty) || (imgUrl != null && imgUrl.isNotEmpty);

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (hasImage) ...[
              NewsThumb(base64: imgBase64, url: imgUrl, height: 190, borderRadius: BorderRadius.circular(12)),
              const SizedBox(height: 16),
            ],
            Row(children: [
              Icon(Icons.newspaper, size: 18, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  category.isNotEmpty ? category : 'خبر',
                  style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (traffic.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 12, color: AppColors.accentPurple),
                      const SizedBox(width: 4),
                      Text(traffic, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentPurple)),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            Text(
              data['title'] as String? ?? '',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.4,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            if ((data['source'] as String? ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(data['source'] as String? ?? '', style: TextStyle(fontSize: 12, color: AppColors.accent)),
            ],
            if (content.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                content,
                style: TextStyle(fontSize: 14, height: 1.8, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
            ],
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.trending_up, size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(fontSize: 12, height: 1.6, color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (sourceUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openSource(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: const Color(0xFF03222B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text(
                    'اقرأ الخبر كاملاً من المصدر الأصلي',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class NewsThumb extends StatelessWidget {
  final String? base64;
  final String? url;
  final double height;
  final BorderRadius borderRadius;
  const NewsThumb({super.key, required this.base64, required this.url, required this.height, required this.borderRadius});

  bool get _hasBase64 => base64 != null && base64!.isNotEmpty;
  bool get _hasUrl => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasBase64) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(base64Decode(base64!.split(',').last), width: double.infinity, height: height, fit: BoxFit.cover),
      );
    }
    if (_hasUrl) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          url!,
          width: double.infinity,
          height: height,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(context);
          },
          errorBuilder: (_, _, _) => _placeholder(context),
        ),
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: _placeholder(context));
  }

  Widget _placeholder(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      width: double.infinity,
      color: dark ? const Color(0xFF1A1A2E) : const Color(0xFFF1F5F9),
      child: Icon(
        Icons.image_outlined,
        size: 32,
        color: (dark ? AppColors.textSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
      ),
    );
  }
}
