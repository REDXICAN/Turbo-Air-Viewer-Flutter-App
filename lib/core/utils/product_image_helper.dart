// lib/core/utils/product_image_helper.dart
import 'package:flutter/material.dart';

class ProductImageHelper {
  // Clean SKU for file path - handle special characters
  static String _cleanSkuForPath(String sku) {
    // Remove or replace problematic characters
    return sku
        .replaceAll('(', '')
        .replaceAll(')', '')
        .replaceAll('-L', '-L') // Keep -L suffix
        .replaceAll(' ', '%20'); // Properly encode spaces for assets
  }

  // Get image paths to try (mimics Python's fallback logic)
  static List<String> getImagePaths(String sku, String page) {
    final cleanSku = _cleanSkuForPath(sku);

    // Try multiple path variations like Python does
    return [
      'assets/screenshots/$sku/$sku $page.png', // Original SKU with space
      'assets/screenshots/$sku/$sku$page.png', // Without space
      'assets/screenshots/$cleanSku/${cleanSku}_$page.png', // Clean SKU with underscore
      'assets/screenshots/$cleanSku/$cleanSku $page.png', // Clean SKU with space
      'assets/screenshots/$sku/${sku}_P$page.png', // With P prefix format
    ];
  }

  // Build product thumbnail with fallback
  static Widget buildProductThumbnail({
    required String sku,
    String page = 'P.1',
    double width = 60,
    double height = 60,
    BoxFit fit = BoxFit.cover,
    VoidCallback? onTap,
  }) {
    final paths = getImagePaths(sku, page);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _MultiPathImage(
            paths: paths,
            fit: fit,
            errorWidget: const Icon(Icons.image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // Build screenshot thumbnail with overlay (for product details)
  static Widget buildScreenshotThumbnail({
    required String sku,
    required String page,
    required String label,
    VoidCallback? onTap,
  }) {
    final paths = getImagePaths(sku, page);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              _MultiPathImage(
                paths: paths,
                fit: BoxFit.contain,
                errorWidget: Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              // Label overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // Zoom icon
              if (onTap != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Show full screen image viewer
  static void showFullScreenImage(
    BuildContext context,
    String sku,
    String page,
    String title,
  ) {
    final paths = getImagePaths(sku, page);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background (tap to close)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),
            // Image container
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: _MultiPathImage(
                  paths: paths,
                  fit: BoxFit.contain,
                  errorWidget: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'SKU: $sku',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Title
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget that tries multiple image paths until one works
class _MultiPathImage extends StatelessWidget {
  final List<String> paths;
  final BoxFit fit;
  final Widget errorWidget;

  const _MultiPathImage({
    required this.paths,
    required this.fit,
    required this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return _ImageWithFallback(
      paths: paths,
      fit: fit,
      errorWidget: errorWidget,
      currentIndex: 0,
    );
  }
}

// Recursive widget to try each path
class _ImageWithFallback extends StatelessWidget {
  final List<String> paths;
  final BoxFit fit;
  final Widget errorWidget;
  final int currentIndex;

  const _ImageWithFallback({
    required this.paths,
    required this.fit,
    required this.errorWidget,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= paths.length) {
      return errorWidget;
    }

    return Image.asset(
      paths[currentIndex],
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Try next path
        if (currentIndex + 1 < paths.length) {
          return _ImageWithFallback(
            paths: paths,
            fit: fit,
            errorWidget: errorWidget,
            currentIndex: currentIndex + 1,
          );
        }
        return errorWidget;
      },
    );
  }
}
