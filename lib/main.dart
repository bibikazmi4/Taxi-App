import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'providers/chat_provider.dart';
import 'providers/location_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/ride_provider.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/map_service.dart';
import 'utils/app_theme.dart';
import 'screens/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Web-specific error handling for Google Maps
  if (kIsWeb) {
    // Add error handler for Google Maps
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);

      // Log Google Maps specific errors
      if (details.exception.toString().contains('maps') ||
          details.exception.toString().contains('google')) {
        print('⚠️ Google Maps error detected');
        print('Error details: ${details.exception}');
      }
    };
  }

  runApp(const SwiftRideApp());
}

class SwiftRideApp extends StatelessWidget {
  const SwiftRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final map = MapService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) =>
                LocationProvider(LocationService())..loadCurrentLocation()),
        ChangeNotifierProvider(
            create: (_) => RideProvider(map, db)..loadHistory()),
        ChangeNotifierProvider(create: (_) => ProfileProvider(db)..load()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SwiftRide',
        theme: AppTheme.theme(),
        home: const AppShell(),
      ),
    );
  }
}
