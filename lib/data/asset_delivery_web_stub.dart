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
