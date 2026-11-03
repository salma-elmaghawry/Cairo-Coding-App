import 'package:flutter/material.dart';

/// A picture from a link, since images aren't uploaded on the Spark plan. A broken or missing
/// link shows [fallback] instead of an error box.
class QuizImage extends StatelessWidget {
  const QuizImage({
    super.key,
    required this.url,
    this.height,
    this.radius = 16,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String url;
  final double? height;
  final double radius;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final placeholder =
        fallback ??
        ColoredBox(
          color: colorScheme.surfaceContainerHighest,
          child: Center(child: Icon(Icons.image_not_supported_outlined, color: colorScheme.onSurfaceVariant)),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: url.trim().isEmpty
            ? placeholder
            : Image.network(
                url.trim(),
                fit: fit,
                // On the web, most image hosts don't send CORS headers, and this still shows their pictures.
                webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
              ),
      ),
    );
  }
}
