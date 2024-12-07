import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidoEnCaminoPage extends StatefulWidget {
  final String orderId;

  const PedidoEnCaminoPage({super.key, required this.orderId});

  @override
  _PedidoEnCaminoPageState createState() => _PedidoEnCaminoPageState();
}

class _PedidoEnCaminoPageState extends State<PedidoEnCaminoPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  GoogleMapController? _mapController;
  Map<String, dynamic>? orderData;
  Map<String, dynamic>? clientData;
  LatLng? driverLocation;
  LatLng? clientLocation;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> _polylines = {};
  StreamSubscription<Position>? _positionStream;
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    _getDriverLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    final orderSnapshot =
        await _firestore.collection('pedidos').doc(widget.orderId).get();
    final order = orderSnapshot.data();
    if (order != null) {
      final clientId = order['clientId'];
      final clientSnapshot =
          await _firestore.collection('usuarios').doc(clientId).get();
      setState(() {
        orderData = order;
        clientData = clientSnapshot.data();
        clientLocation = LatLng(order['latitud'], order['longitud']);
        _updatePolylines();
      });
    }
  }

  Future<void> _getDriverLocation() async {
    _positionStream =
        Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        driverLocation = LatLng(position.latitude, position.longitude);
        _currentSpeed = position.speed * 3.6; // Convert from m/s to km/h
        _updatePolylines();
      });
    });
  }

  Future<void> _updatePolylines() async {
    if (driverLocation == null || clientLocation == null) return;

    const String apiKey = 'TU_API_KEY';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${driverLocation!.latitude},${driverLocation!.longitude}&destination=${clientLocation!.latitude},${clientLocation!.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'].isEmpty) {
          print('No routes found');
          return;
        }

        final points = data['routes'][0]['overview_polyline']['points'];
        polylineCoordinates = _decodePolyline(points);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 6,
            ),
          };
        });

        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                (driverLocation!.latitude < clientLocation!.latitude)
                    ? driverLocation!.latitude
                    : clientLocation!.latitude,
                (driverLocation!.longitude < clientLocation!.longitude)
                    ? driverLocation!.longitude
                    : clientLocation!.longitude,
              ),
              northeast: LatLng(
                (driverLocation!.latitude > clientLocation!.latitude)
                    ? driverLocation!.latitude
                    : clientLocation!.latitude,
                (driverLocation!.longitude > clientLocation!.longitude)
                    ? driverLocation!.longitude
                    : clientLocation!.longitude,
              ),
            ),
            50,
          ),
        );
      } else {
        print('Failed to load directions: ${response.body}');
      }
    } catch (e) {
      print('Error fetching directions: $e');
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    var list = poly.codeUnits;
    var lList = [];
    int index = 0;
    int len = poly.length;
    int c = 0;
    // repeating until all attributes are decoded
    do {
      var shift = 0;
      int result = 0;

      // for each attribute, decoding unsigned value
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      /* if value is negative then bitwise not the value */
      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    /*adding to previous value as done in encoding */
    for (var i = 2; i < lList.length; i++) {
      lList[i] += lList[i - 2];
    }

    List<LatLng> points = [];
    for (var i = 0; i < lList.length; i += 2) {
      points.add(LatLng(lList[i], lList[i + 1]));
    }
    return points;
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _markAsDelivered() async {
    await _firestore.collection('pedidos').doc(widget.orderId).update({
      'orderStatus': 'entregado',
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido En Camino'),
      ),
      body: orderData == null || clientData == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updatePolylines();
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(0, 0),
                      zoom: 10,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: orderData == null
                        ? {}
                        : {
                            Marker(
                              markerId: const MarkerId('driverLocation'),
                              position: driverLocation!,
                              infoWindow:
                                  const InfoWindow(title: 'Tu ubicación'),
                            ),
                            Marker(
                              markerId: const MarkerId('clientLocation'),
                              position: clientLocation!,
                              infoWindow: const InfoWindow(
                                  title: 'Ubicación del cliente'),
                            ),
                          },
                    polylines: _polylines,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('El cliente es: ${clientData!['nombres']}'),
                      Text(
                          'Velocidad actual: ${_currentSpeed.toStringAsFixed(2)} km/h'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.call),
                            label: const Text('Llamar'),
                            onPressed: () {
                              _launchURL('tel:${orderData!['userPhone']}');
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.message),
                            label: const Text('Escribir'),
                            onPressed: () {
                              _launchURL(
                                  'https://wa.me/${orderData!['userPhone']}');
                            },
                          ),
                        ],
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: _markAsDelivered,
                          child: const Text('Entregado'),
                        ),
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: _updatePolylines,
                          child: const Text('Como llegar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
