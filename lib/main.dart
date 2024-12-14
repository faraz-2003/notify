import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final databaseService = DatabaseService();
  final locationService = LocationService();
  final notificationService = NotificationService();

  // Initialize notifications
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<LocationService>.value(value: locationService),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const ShoppingReminderApp(),
    ),
  );
}

class ShoppingReminderApp extends StatelessWidget {
  const ShoppingReminderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 2,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class LocationTrackingService extends StatefulWidget {
  final Widget child;

  const LocationTrackingService({super.key, required this.child});

  @override
  State<LocationTrackingService> createState() => _LocationTrackingServiceState();
}

class _LocationTrackingServiceState extends State<LocationTrackingService> {
  static const double _proximityThreshold = 500; // meters

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    final locationService = context.read<LocationService>();
    final databaseService = context.read<DatabaseService>();
    final notificationService = context.read<NotificationService>();

    locationService.getLocationStream().listen((position) async {
      // Get nearby unpurchased items
      final nearbyItems = await databaseService.getNearbyItems(
        position.latitude,
        position.longitude,
        _proximityThreshold / 1000, // Convert to kilometers
      );

      if (nearbyItems.isNotEmpty) {
        // Show batch notification for multiple items
        if (nearbyItems.length > 1) {
          await notificationService.showBatchNearbyNotification(nearbyItems);
        } else {
          // Show single item notification
          await notificationService.showNearbyShopNotification(nearbyItems.first);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}