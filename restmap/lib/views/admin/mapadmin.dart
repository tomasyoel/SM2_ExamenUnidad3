// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;

class MapaAdminPage extends StatefulWidget {
  const MapaAdminPage({super.key});

  @override
  _MapaAdminPageState createState() => _MapaAdminPageState();
}

class _MapaAdminPageState extends State<MapaAdminPage> {
  GoogleMapController? mapController;
  loc.Location location = loc.Location();
  LatLng _currentPosition = const LatLng(-12.0464, -77.0428);
  LatLng? _selectedPosition;
  bool _isLocationReady = false;
  bool _initialPositionSet = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();

    location.onLocationChanged.listen((loc.LocationData currentLocation) {
      if (!_initialPositionSet) {
        setState(() {
          _currentPosition =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _isLocationReady = true;
          _initialPositionSet = true;
          if (mapController != null) {
            _updateCameraPosition();
          }
        });
      }
    });
  }

  void _initializeLocation() async {
    var userLocation = await location.getLocation();
    setState(() {
      _currentPosition =
          LatLng(userLocation.latitude!, userLocation.longitude!);
      _isLocationReady = true;
      _initialPositionSet = true;
      if (mapController != null) {
        _updateCameraPosition();
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController!.setMapStyle('''
    [
      {
        "featureType": "poi.business",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.medical",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.place_of_worship",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      }
    ]
    ''');
    if (_isLocationReady && !_initialPositionSet) {
      _updateCameraPosition();
    }
  }

  void _updateCameraPosition() {
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  void _saveLocation() {
    if (_selectedPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una ubicación en el mapa')),
      );
      return;
    }

    Navigator.pop(context, _selectedPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        backgroundColor: const Color(0xFF6BBE92),
      ),
      body: _isLocationReady
          ? Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15.0,
                  ),
                  markers: _selectedPosition != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected-location'),
                            position: _selectedPosition!,
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (LatLng position) {
                    setState(() {
                      _selectedPosition = position;
                    });
                  },
                ),
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: ElevatedButton(
                    onPressed: _saveLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6BBE92),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Guardar Ubicación'),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
