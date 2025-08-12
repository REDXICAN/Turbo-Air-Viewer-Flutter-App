// lib/core/utils/product_image_helper.dart
import 'package:flutter/material.dart';

class ProductImageHelper {
  // Map of SKUs to image paths
  static const Map<String, String> _productImages = {
    // Add your product images here
    // Example:
    // 'PRO-26R-N(-L)': 'assets/screenshots/PRO-26R-N(-L).png',
    // 'TSR-23SD-N6(-L)': 'assets/screenshots/TSR-23SD-N6(-L).png',
  };

  static bool hasImage(String sku) {
    return _productImages.containsKey(sku);
  }

  static String getImagePath(String sku) {
    return _productImages[sku] ?? 'assets/images/placeholder.png';
  }

  static Widget getProductImage(String sku, {double? width, double? height}) {
    if (hasImage(sku)) {
      return Image.asset(
        getImagePath(sku),
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(width: width, height: height);
        },
      );
    }
    return _buildPlaceholder(width: width, height: height);
  }

  static Widget _buildPlaceholder({double? width, double? height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.inventory_2,
        color: Colors.grey[400],
        size: (width != null && height != null)
            ? (width < height ? width * 0.5 : height * 0.5)
            : 40,
      ),
    );
  }

  static DecorationImage? getDecorationImage(String sku) {
    if (hasImage(sku)) {
      return DecorationImage(
        image: AssetImage(getImagePath(sku)),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}
