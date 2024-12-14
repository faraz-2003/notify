// lib/models/shop_item.dart

/// A model class representing a shopping item with its associated shop location.
class ShopItem {
  /// Unique identifier for the item
  final String id;

  /// Name of the item to be purchased
  final String itemName;

  /// Name of the shop where the item can be purchased
  final String shopName;

  /// Latitude of the shop location
  final double latitude;

  /// Longitude of the shop location
  final double longitude;

  /// Flag indicating whether the item has been purchased
  final bool isPurchased;

  /// Creates a new [ShopItem] instance.
  ShopItem({
    required this.id,
    required this.itemName,
    required this.shopName,
    required this.latitude,
    required this.longitude,
    this.isPurchased = false,
  });

  /// Creates a copy of this [ShopItem] with the given fields replaced with new values.
  ShopItem copyWith({
    String? id,
    String? itemName,
    String? shopName,
    double? latitude,
    double? longitude,
    bool? isPurchased,
  }) {
    return ShopItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      shopName: shopName ?? this.shopName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  /// Converts the [ShopItem] instance to a Map.
  /// Useful for storing the item in a database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemName': itemName,
      'shopName': shopName,
      'latitude': latitude,
      'longitude': longitude,
      'isPurchased': isPurchased ? 1 : 0, // SQLite doesn't support boolean
    };
  }

  /// Creates a [ShopItem] instance from a Map.
  /// Useful for retrieving the item from a database.
  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'],
      itemName: map['itemName'],
      shopName: map['shopName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isPurchased: map['isPurchased'] == 1, // Convert SQLite integer to boolean
    );
  }

  /// Returns a string representation of the [ShopItem].
  @override
  String toString() {
    return 'ShopItem(id: $id, itemName: $itemName, shopName: $shopName, '
        'latitude: $latitude, longitude: $longitude, isPurchased: $isPurchased)';
  }

  /// Compares this [ShopItem] with another for equality.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShopItem &&
        other.id == id &&
        other.itemName == itemName &&
        other.shopName == shopName &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isPurchased == isPurchased;
  }

  /// Generates a hash code for this [ShopItem].
  @override
  int get hashCode {
    return id.hashCode ^
    itemName.hashCode ^
    shopName.hashCode ^
    latitude.hashCode ^
    longitude.hashCode ^
    isPurchased.hashCode;
  }
}