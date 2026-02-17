import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformSupport {
  static bool get isDesktopUnsupportedForGoogleMaps {
    if (kIsWeb) return false; // web should be supported
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }
}
