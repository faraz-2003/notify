import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../models/shop_item.dart';
import '../services/database_service.dart';
import 'map_selection_screen.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _shopNameController = TextEditingController();

  LatLng? _selectedLocation;
  bool _isManualLocation = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _itemNameController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  Future<void> _selectLocationManually() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapSelectionScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _isManualLocation = true;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a location')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final newItem = ShopItem(
        id: const Uuid().v4(),
        itemName: _itemNameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );

      await context.read<DatabaseService>().insertShopItem(newItem);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Shopping Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _shopNameController,
              decoration: const InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a shop name';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _selectLocationManually,
              icon: const Icon(Icons.map),
              label: const Text('Select Location from Map'),
            ),
            if (_selectedLocation != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Location',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      ),
                      if (_isManualLocation)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Manually selected location',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveItem,
            child: _isSaving
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Save Item'),
          ),
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_places_flutter/google_places_flutter.dart';
// import 'package:google_places_flutter/model/prediction.dart';
// import 'package:uuid/uuid.dart';
// import 'package:provider/provider.dart';
// import '../models/shop_item.dart';
// import '../services/database_service.dart';
// import 'map_selection_screen.dart';
//
// class AddItemScreen extends StatefulWidget {
//   const AddItemScreen({super.key});
//
//   @override
//   State<AddItemScreen> createState() => _AddItemScreenState();
// }
//
// class _AddItemScreenState extends State<AddItemScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _itemNameController = TextEditingController();
//   final _shopNameController = TextEditingController();
//
//   LatLng? _selectedLocation;
//   bool _isManualLocation = false;
//   bool _isSaving = false;
//
//   @override
//   void dispose() {
//     _itemNameController.dispose();
//     _shopNameController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _selectLocationManually() async {
//     final LatLng? result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MapSelectionScreen(
//           initialLocation: _selectedLocation,
//         ),
//       ),
//     );
//
//     if (result != null) {
//       setState(() {
//         _selectedLocation = result;
//         _isManualLocation = true;
//       });
//     }
//   }
//
//   Future<void> _saveItem() async {
//     if (!_formKey.currentState!.validate() || _selectedLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please fill all fields and select a location')),
//       );
//       return;
//     }
//
//     setState(() => _isSaving = true);
//
//     try {
//       final newItem = ShopItem(
//         id: const Uuid().v4(),
//         itemName: _itemNameController.text.trim(),
//         shopName: _shopNameController.text.trim(),
//         latitude: _selectedLocation!.latitude,
//         longitude: _selectedLocation!.longitude,
//       );
//
//       await context.read<DatabaseService>().insertShopItem(newItem);
//
//       if (mounted) {
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error saving item: $e')),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSaving = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Add Shopping Item'),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _itemNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Item Name',
//                 border: OutlineInputBorder(),
//               ),
//               validator: (value) {
//                 if (value == null || value.trim().isEmpty) {
//                   return 'Please enter an item name';
//                 }
//                 return null;
//               },
//             ),
//             const SizedBox(height: 16),
//             // Using GooglePlaceAutoCompleteTextField for place search
//             GooglePlaceAutoCompleteTextField(
//               textEditingController: _shopNameController,
//               googleAPIKey: 'YOUR_GOOGLE_PLACES_API_KEY',
//               inputDecoration: const InputDecoration(
//                 labelText: 'Search Shop',
//                 border: OutlineInputBorder(),
//               ),
//               debounceTime: 800, // Milliseconds to wait before searching
//               countries: const ['us', 'in'], // Restrict to these countries
//               isLatLngRequired: true,
//               getPlaceDetailWithLatLng: (Prediction prediction) {
//                 // This callback provides the selected place's lat/lng
//                 setState(() {
//                   _selectedLocation = LatLng(
//                     double.parse(prediction.lat ?? "0"),
//                     double.parse(prediction.lng ?? "0"),
//                   );
//                   _isManualLocation = false;
//                 });
//               },
//               itemClick: (Prediction prediction) {
//                 _shopNameController.text = prediction.description ?? '';
//                 _shopNameController.selection = TextSelection.fromPosition(
//                   TextPosition(offset: _shopNameController.text.length),
//                 );
//               },
//               // Optional: Customize the way predictions are displayed
//               itemBuilder: (context, index, Prediction prediction) {
//                 return ListTile(
//                   title: Text(prediction.description ?? ''),
//                   onTap: () {
//                     _shopNameController.text = prediction.description ?? '';
//                     _shopNameController.selection = TextSelection.fromPosition(
//                       TextPosition(offset: _shopNameController.text.length),
//                     );
//                     Navigator.pop(context);
//                   },
//                 );
//               },
//               isCrossBtnShown: true, // Show clear button
//             ),
//             const SizedBox(height: 8),
//             TextButton.icon(
//               onPressed: _selectLocationManually,
//               icon: const Icon(Icons.map),
//               label: const Text('Select Location Manually'),
//             ),
//             if (_selectedLocation != null) ...[
//               const SizedBox(height: 16),
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Selected Location',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
//                             'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
//                       ),
//                       if (_isManualLocation)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 8),
//                           child: Text(
//                             'Manually selected location',
//                             style: TextStyle(
//                               fontStyle: FontStyle.italic,
//                               color: Colors.grey,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: ElevatedButton(
//             onPressed: _isSaving ? null : _saveItem,
//             child: _isSaving
//                 ? const SizedBox(
//               height: 20,
//               width: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             )
//                 : const Text('Save Item'),
//           ),
//         ),
//       ),
//     );
//   }
// }