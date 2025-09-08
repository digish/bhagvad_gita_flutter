/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/


// This file acts as a silent placeholder for the asset_delivery package on the web.
// It prevents compile-time errors.

class AssetDelivery {
  static Future<void> fetch(String assetPackName) async {}
  static Future<String> getAssetPackPath({
    required String assetPackName,
    int? count,
    String? namingPattern,
    String? fileExtension,
  }) async {
    // On web, the path is just the relative path from the project root.
    return 'assets/audio/$assetPackName';
  }
  static void getAssetPackStatus(Function(Map<dynamic, dynamic>) onUpdate) {}
}
