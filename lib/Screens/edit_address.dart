import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class EditAddressScreen extends StatefulWidget {
  final String initialAddress;
  final Function(String, double, double) onSave;
  final double initialLongitude;
  final double initialLatitude;

  const EditAddressScreen({
    super.key,
    required this.initialAddress,
    required this.initialLongitude,
    required this.initialLatitude,
    required this.onSave,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  late TextEditingController _addressController;
  GoogleMapController? _mapController;
  late LatLng _selectedLocation; // Default location
  bool _isMapReady = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialAddress);
    _selectedLocation = LatLng(widget.initialLatitude, widget.initialLongitude);
    print("Initial Location: $_selectedLocation");
    if (widget.initialLatitude == 0.0 && widget.initialLongitude == 0.0) {
      _getCurrentLocation();
    } else {
      _isMapReady = true;
      _updateMarker();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final location = Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    // Check if location service is enabled
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    // Check if permission is granted
    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Get current location
    locationData = await location.getLocation();
    setState(() {
      _selectedLocation = LatLng(
        locationData.latitude ?? 0,
        locationData.longitude ?? 0,
      );
      _updateMarker();
      _isMapReady = true;
    });
  }

  void _updateMarker() {
    _markers = {
      Marker(
        markerId: MarkerId('selected_location'),
        position: _selectedLocation,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
          });
        },
      ),
    };
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_isMapReady) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 15),
      );
      _updateMarker();
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
      _updateMarker();
      print(
        'Selected Location: ${_selectedLocation.latitude}, ${_selectedLocation.longitude}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Address"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: "Address",
                hintText: "Enter your full address",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Or select location on map:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                  _isMapReady
                      ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation,
                              zoom: 15,
                            ),
                            markers: _markers,
                            onTap: _onMapTap,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                          ),
                        ),
                      )
                      : Center(child: CircularProgressIndicator()),
            ),
          ),
          if (_isMapReady)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Selected coordinates: ${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}",
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Save both the text address and coordinates
                widget.onSave(
                  _addressController.text,
                  _selectedLocation.longitude,
                  _selectedLocation.latitude,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "Save Address",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
