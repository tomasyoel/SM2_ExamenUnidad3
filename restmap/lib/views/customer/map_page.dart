import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';
import 'package:location/location.dart' as loc;

// import 'user_location_page.dart';

class MapPage extends StatefulWidget {
  final String userId;

  MapPage({required this.userId});

  @override
  _MapPageState createState() => _MapPageState();
}

  class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  loc.Location location = loc.Location();
  LatLng _currentPosition = LatLng(-12.0464, -77.0428); 
  LatLng? _selectedPosition;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  final String _googleApiKey = 'API_KEY';
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

  Future<void> _updateAddressField() async {
    if (_selectedPosition != null) {
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          _selectedPosition!.latitude,
          _selectedPosition!.longitude,
        );
        if (placemarks.isNotEmpty) {
          setState(() {
            _addressController.text = placemarks.first.street ?? '';
          });
        } else {
          setState(() {
            _addressController.text =
                'Lat: ${_selectedPosition!.latitude}, Lng: ${_selectedPosition!.longitude}';
          });
        }
      } catch (e) {
        setState(() {
          _addressController.text =
              'Lat: ${_selectedPosition!.latitude}, Lng: ${_selectedPosition!.longitude}';
        });
      }
    }
  }

  void _saveAddress() async {
  if (_selectedPosition == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selecciona una ubicación en el mapa')),
    );
    return;
  }

  print('Guardando dirección para el usuario: ${widget.userId}');

  Map<String, dynamic> newAddress = {
    'nombre': _nameController.text,
    'direccion': _addressController.text,
    'latitud': _selectedPosition!.latitude,
    'longitud': _selectedPosition!.longitude,
    'predeterminada': false,
  };

  DocumentReference userRef =
      FirebaseFirestore.instance.collection('usuarios').doc(widget.userId);

  DocumentSnapshot userSnapshot = await userRef.get();
  print('Datos del usuario encontrados: ${userSnapshot.exists}'); 

  if (userSnapshot.exists) {
    List<dynamic> existingAddresses =
        (userSnapshot.data() as Map<String, dynamic>)['direcciones'] ?? [];

    existingAddresses.add(newAddress);

    await userRef.update({
      'direcciones': existingAddresses,
    }).then((_) {
      print('Dirección guardada correctamente para el usuario: ${widget.userId}');
      Navigator.pop(context, true);
    }).catchError((error) {
      print('Error al guardar la dirección: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la dirección: $error')),
      );
    });
  } else {
    await userRef.set({
      'direcciones': [newAddress],
    }, SetOptions(merge: true)).then((_) {
      print('Dirección guardada correctamente para el usuario: ${widget.userId}');
      Navigator.pop(context, true);
    }).catchError((error) {
      print('Error al guardar la dirección: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar la dirección: $error')),
      );
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Añadir Dirección'),
        backgroundColor: Color(0xFF6BBE92),
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
                            markerId: MarkerId('selected-location'),
                            position: _selectedPosition!,
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (LatLng position) {
                    setState(() {
                      _selectedPosition = position;
                      _updateAddressField();
                    });
                  },
                ),
                Positioned(
                  top: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFE3B0),
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: _addressController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _saveAddress,
                          child: Text('Guardar Dirección'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6BBE92),
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
