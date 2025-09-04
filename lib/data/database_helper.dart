// This file acts as a "switch" to provide the correct database helper
// depending on whether the app is running on mobile or web.
// The rest of your app will ONLY import this file.

export 'database_helper_unsupported.dart'
    if (dart.library.html) 'database_helper_web.dart'
    if (dart.library.io) 'database_helper_mobile.dart';

