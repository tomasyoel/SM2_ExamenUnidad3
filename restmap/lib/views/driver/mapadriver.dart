// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapaDriverPage extends StatefulWidget {
  final String orderId;

  const MapaDriverPage({super.key, required this.orderId});

  @override
  _MapaDriverPageState createState() => _MapaDriverPageState();
}

class _MapaDriverPageState extends State<MapaDriverPage> {
  GoogleMapController? _mapController;
  DocumentSnapshot? _orderData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng _driverLocation = const LatLng(-12.0464, -77.0428);
  late BitmapDescriptor _driverIcon;
  late BitmapDescriptor _customerIcon;
  String? _mapStyle;
  final Set<Marker> _markers = {};
  List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _setCustomMapPins();
    _getDriverLocation();
    _loadMapStyle();
  }

  Future<void> _loadOrderData() async {
    DocumentSnapshot orderSnapshot =
        await _firestore.collection('pedidos').doc(widget.orderId).get();
    setState(() {
      _orderData = orderSnapshot;
      _updateMarkersAndPolyline();
    });
  }

  Future<void> _setCustomMapPins() async {
    _driverIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/driver.png',
    );
    _customerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(devicePixelRatio: 2.5),
      'assets/customer.png',
    );
  }

  Future<void> _getDriverLocation() async {
    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _driverLocation = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation, 15),
      );
      _updateMarkersAndPolyline();
    });
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await rootBundle.loadString('assets/map_style.json');
  }

  void _updateMarkersAndPolyline() {
    if (_orderData != null) {
      final orderData = _orderData!.data() as Map<String, dynamic>;
      final customerLocation =
          LatLng(orderData['latitud'], orderData['longitud']);

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverLocation,
            icon: _driverIcon,
          ),
        );
        _markers.add(
          Marker(
            markerId: const MarkerId('customer'),
            position: customerLocation,
            icon: _customerIcon,
          ),
        );
        _getPolyline(_driverLocation, customerLocation);
      });
    }
  }

  Future<void> _getPolyline(LatLng start, LatLng end) async {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=YOUR_GOOGLE_MAPS_API_KEY',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        final points = data['routes'][0]['overview_polyline']['points'];
        _polylineCoordinates = _decodePolyline(points);
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: _polylineCoordinates,
              width: 5,
              color: Colors.blue,
            ),
          );
        });
      } else {
        //print('No routes found');
      }
    } else {
      //print('Failed to fetch route');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates
          .add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }

    return polylineCoordinates;
  }

  void _callCustomer(String phoneNumber) {
    launch('tel:$phoneNumber');
  }

  void _messageCustomer(String phoneNumber) {
    launch('https://wa.me/$phoneNumber');
  }

  @override
  Widget build(BuildContext context) {
    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cargando...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final orderData = _orderData!.data() as Map<String, dynamic>;
    // final customerLocation = LatLng(orderData['latitud'], orderData['longitud']);
    final customerPhone = orderData['userPhone'];
    final customerName = orderData['nombresCompletos'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido en camino'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_mapStyle != null) {
                _mapController?.setMapStyle(_mapStyle);
              }
              _updateMarkersAndPolyline();
            },
            initialCameraPosition: CameraPosition(
              target: _driverLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 50,
            left: 10,
            right: 10,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text('Entrega a cargo de $customerName'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () => _callCustomer(customerPhone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () => _messageCustomer(customerPhone),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      child: const Text('Entregado'),
                      onPressed: () {
                        _firestore
                            .collection('pedidos')
                            .doc(widget.orderId)
                            .update({
                          'orderStatus': 'entregado',
                          'driverLocation': GeoPoint(_driverLocation.latitude,
                              _driverLocation.longitude),
                          'driverName':
                              FirebaseAuth.instance.currentUser!.displayName,
                          'driverPhone':
                              FirebaseAuth.instance.currentUser!.phoneNumber,
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
