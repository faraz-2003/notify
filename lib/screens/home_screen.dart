import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop_item.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import 'add_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ShopItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final databaseService = context.read<DatabaseService>();
    setState(() => _isLoading = true);
    final items = await databaseService.getAllShopItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Future<void> _markAsPurchased(ShopItem item) async {
    final databaseService = context.read<DatabaseService>();
    await databaseService.markAsPurchased(item.id, true);
    await _loadItems();
  }

  String _getDistanceText(ShopItem item, double? currentLat, double? currentLng) {
    if (currentLat == null || currentLng == null) return '';

    final locationService = context.read<LocationService>();
    final distance = locationService.calculateDistance(
      currentLat,
      currentLng,
      item.latitude,
      item.longitude,
    );

    return locationService.formatDistance(distance);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shopping_basket_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No shopping items yet!',
              style: TextStyle(fontSize: 18),
            ),
            TextButton(
              onPressed: () => _navigateToAddItem(context),
              child: const Text('Add your first item'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadItems,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            return Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
              onDismissed: (_) async {
                final databaseService =
                context.read<DatabaseService>();
                await databaseService.deleteShopItem(item.id);
                setState(() => _items.removeAt(index));
              },
              child: ListTile(
                title: Text(item.itemName),
                subtitle: Text(item.shopName),
                trailing: item.isPurchased
                    ? const Icon(Icons.check_circle,
                    color: Colors.green)
                    : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () => _markAsPurchased(item),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddItem(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddItem(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddItemScreen()),
    );
    if (result == true) {
      await _loadItems();
    }
  }
}