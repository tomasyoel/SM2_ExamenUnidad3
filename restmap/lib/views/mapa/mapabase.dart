import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:url_launcher/url_launcher.dart';
// import 'negociosdetalle.dart';
import 'dart:math' show min, max;
import 'dart:math' as math;

class MapaBasePage extends StatefulWidget {
  const MapaBasePage({super.key});

  @override
  _MapaBasePageState createState() => _MapaBasePageState();
}

class _MapaBasePageState extends State<MapaBasePage> {
  GoogleMapController? mapController;
  loc.Location location = loc.Location();
  LatLng _currentPosition = const LatLng(-12.0464, -77.0428);
  bool _isLocationReady = false;
  bool _initialPositionSet = false;
  String? selectedNegocioId;
  LatLng? selectedNegocioLocation;
  String? selectedTipoCocinaId;
  String searchQuery = "";
  Set<Marker> markers = {};

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

  // void _initializeLocation() async {
  //   var userLocation = await location.getLocation();
  //   setState(() {
  //     _currentPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
  //     _isLocationReady = true;
  //     _initialPositionSet = true;
  //     if (mapController != null) {
  //       _updateCameraPosition();
  //     }
  //   });
  // }

  void _initializeLocation() async {
    try {
      var userLocation = await location.getLocation();

      if (mounted) {
        // Verifica si el widget está montado
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
    } catch (e) {
      print('Error al obtener la ubicación: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

  void _applyFilter(String? tipoCocinaId) {
    setState(() {
      selectedTipoCocinaId = tipoCocinaId;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en kilómetros
    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (math.pi / 180);
  }

  // Stream<List<QueryDocumentSnapshot>> _getNegociosStream() {
  //   return FirebaseFirestore.instance.collection('negocios').snapshots().map((snapshot) {
  //     var negocios = snapshot.docs;

  //     if (selectedTipoCocinaId != null) {
  //       negocios = negocios.where((negocio) {
  //         var tipoCocinaId = negocio['tipoCocinaId'];
  //         return tipoCocinaId == selectedTipoCocinaId;
  //       }).toList();
  //     }

  //     return negocios;
  //   });
  // }

  Stream<List<QueryDocumentSnapshot>> _getNegociosStream() {
    Query query = FirebaseFirestore.instance.collection('negocios');

    if (selectedTipoCocinaId != null) {
      query = query.where('tipo_cocina', isEqualTo: selectedTipoCocinaId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Future<bool> _checkSearchMatch(QueryDocumentSnapshot negocio) async {
    if (searchQuery.isEmpty) return true;

    // Verifica si el nombre del negocio coincide
    if (negocio['nombre']
        .toString()
        .toLowerCase()
        .contains(searchQuery.toLowerCase())) {
      return true;
    }

    // Verifica en la carta
    try {
      var cartaRef = await FirebaseFirestore.instance
          .collection('cartasnegocio')
          .where('negocioId', isEqualTo: negocio.id)
          .get();

      if (cartaRef.docs.isEmpty ||
          !(cartaRef.docs.first.data()).containsKey('carta')) {
        return false;
      }

      var productos = cartaRef.docs.first['carta'] as List<dynamic>;
      if (productos.isEmpty) return false;

      return productos.any((producto) => producto['nombre']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase()));
    } catch (e) {
      return false;
    }
  }

  Future<Set<Marker>> _createMarkers(
      List<QueryDocumentSnapshot> negocios) async {
    Set<Marker> newMarkers = {};

    for (var negocio in negocios) {
      if (await _checkSearchMatch(negocio)) {
        var geoPoint = negocio['ubicacion'] as GeoPoint;

        if (searchQuery.isNotEmpty) {
          try {
            var cartaRef = await FirebaseFirestore.instance
                .collection('cartasnegocio')
                .where('negocioId', isEqualTo: negocio.id)
                .get();

            if (cartaRef.docs.isNotEmpty &&
                (cartaRef.docs.first.data()).containsKey('carta')) {
              var carta = cartaRef.docs.first['carta'] as List<dynamic>;
              var productosFiltrados = carta
                  .where((producto) => producto['nombre']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

              if (productosFiltrados.isNotEmpty) {
                var precios = productosFiltrados
                    .map((e) => (e['precio'] as num).toDouble())
                    .toList();
                var minPrice = precios.reduce(min);
                var maxPrice = precios.reduce(max);

                for (var producto in productosFiltrados) {
                  var price = (producto['precio'] as num).toDouble();

                  // Determinar el color del marcador
                  double markerHue;
                  if (productosFiltrados.length == 1) {
                    markerHue = BitmapDescriptor.hueYellow;
                  } else {
                    markerHue = price == minPrice
                        ? BitmapDescriptor.hueGreen
                        : price == maxPrice
                            ? BitmapDescriptor.hueRed
                            : BitmapDescriptor.hueYellow;
                  }

                  newMarkers.add(
                    Marker(
                      markerId: MarkerId('${negocio.id}-${producto['nombre']}'),
                      position: LatLng(geoPoint.latitude, geoPoint.longitude),
                      onTap: () {
                        setState(() {
                          if (selectedNegocioId == negocio.id) {
                            selectedNegocioId = null;
                            selectedNegocioLocation = null;
                          } else {
                            selectedNegocioId = negocio.id;
                            selectedNegocioLocation =
                                LatLng(geoPoint.latitude, geoPoint.longitude);
                          }
                        });
                      },
                      icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
                      infoWindow: InfoWindow(
                        title: producto['nombre'],
                        snippet: 'Precio: S/ ${producto['precio']}',
                      ),
                    ),
                  );
                }
              }
            }
          } catch (e) {
            // Si hay un error al acceder a la carta, continuar con el siguiente negocio
            continue;
          }

          // Si el nombre del negocio coincide con la búsqueda pero no tiene productos coincidentes
          if (negocio['nombre']
                  .toString()
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) &&
              !newMarkers.any(
                  (marker) => marker.markerId.value.startsWith(negocio.id))) {
            newMarkers.add(
              Marker(
                markerId: MarkerId(negocio.id),
                position: LatLng(geoPoint.latitude, geoPoint.longitude),
                onTap: () {
                  setState(() {
                    if (selectedNegocioId == negocio.id) {
                      selectedNegocioId = null;
                      selectedNegocioLocation = null;
                    } else {
                      selectedNegocioId = negocio.id;
                      selectedNegocioLocation =
                          LatLng(geoPoint.latitude, geoPoint.longitude);
                    }
                  });
                },
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow),
                infoWindow: InfoWindow(
                  title: negocio['nombre'],
                ),
              ),
            );
          }
        } else {
          // Si no hay búsqueda activa, mostrar todos los negocios
          newMarkers.add(
            Marker(
              markerId: MarkerId(negocio.id),
              position: LatLng(geoPoint.latitude, geoPoint.longitude),
              onTap: () {
                setState(() {
                  if (selectedNegocioId == negocio.id) {
                    selectedNegocioId = null;
                    selectedNegocioLocation = null;
                  } else {
                    selectedNegocioId = negocio.id;
                    selectedNegocioLocation =
                        LatLng(geoPoint.latitude, geoPoint.longitude);
                  }
                });
              },
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
              infoWindow: InfoWindow(
                title: negocio['nombre'],
              ),
            ),
          );
        }
      }
    }
    return newMarkers;
  }

  Stream<List<String>> _getTiposCocinaConNegocios() {
    return FirebaseFirestore.instance
        .collection('negocios')
        .snapshots()
        .map((snapshot) {
      // Obtener todos los tipos de cocina únicos de los negocios
      Set<String> tiposCocinaIds = {};
      for (var doc in snapshot.docs) {
        String? tipoCocinaId = doc['tipoCocinaId'];
        if (tipoCocinaId != null) {
          tiposCocinaIds.add(tipoCocinaId);
        }
      }
      return tiposCocinaIds.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/belv1.png', width: 60),
            const SizedBox(width: 40),
            const Text('BocattoMap'),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
      ),
      body: Stack(
        children: [
          _isLocationReady
              ? StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: _getNegociosStream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FutureBuilder<Set<Marker>>(
                      future: _createMarkers(snapshot.data!),
                      builder: (context, markersSnapshot) {
                        if (!markersSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _currentPosition,
                            zoom: 15.0,
                          ),
                          markers: markersSnapshot.data!,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        );
                      },
                    );
                  },
                )
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 20.0,
            left: 10.0,
            right: 10.0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: TextField(
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar restaurante o platos',
                      prefixIcon: Icon(Icons.search),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tipococina')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var tiposCocina = snapshot.data!.docs;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Opción "Todos"
                          GestureDetector(
                            onTap: () => _applyFilter(null),
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: selectedTipoCocinaId == null
                                    ? Colors.blue.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 4.0)
                                ],
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.restaurant_menu, size: 40),
                                  SizedBox(height: 4.0),
                                  Text('Todos'),
                                ],
                              ),
                            ),
                          ),
                          // Resto de tipos de cocina
                          ...tiposCocina.map((tipoCocina) {
                            return GestureDetector(
                              onTap: () {
                                if (selectedTipoCocinaId == tipoCocina.id) {
                                  _applyFilter(null);
                                } else {
                                  _applyFilter(tipoCocina.id);
                                }
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: selectedTipoCocinaId == tipoCocina.id
                                      ? Colors.blue.shade100
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 4.0)
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Image.network(
                                      (tipoCocina.data() as Map<String,
                                              dynamic>)['imagen'] ??
                                          '',
                                      width: 40,
                                      height: 40,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.error);
                                      },
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text((tipoCocina.data() as Map<String,
                                            dynamic>)['nombre'] ??
                                        ''),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (selectedNegocioId != null && selectedNegocioLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: _buildBusinessInfoCard(
                  selectedNegocioId!, selectedNegocioLocation!),
            ),
        ],
      ),
    );
  }

  // Tarjeta de información del negocio
  Widget _buildBusinessInfoCard(String negocioId, LatLng negocioLocation) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('negocios')
          .doc(negocioId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var negocioData = snapshot.data!.data() as Map<String, dynamic>;
        var geoPoint = negocioData['ubicacion'] as GeoPoint;
        double distancia = _calculateDistance(
          _currentPosition.latitude,
          _currentPosition.longitude,
          geoPoint.latitude,
          geoPoint.longitude,
        );

        return Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    negocioData['logo'] != null
                        ? Image.network(negocioData['logo'],
                            width: 50, height: 50)
                        : const Icon(Icons.store, size: 50),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          negocioData['nombre'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'A ${distancia.toStringAsFixed(2)} km', // Distancia calculada
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _iniciarRuta(geoPoint.latitude, geoPoint.longitude);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Iniciar Ruta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade100,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget _buildBusinessInfoCard(String negocioId, LatLng negocioLocation) {
  //   return FutureBuilder<DocumentSnapshot>(
  //     future: FirebaseFirestore.instance.collection('negocios').doc(negocioId).get(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       var negocioData = snapshot.data!.data() as Map<String, dynamic>;
  //       var geoPoint = negocioData['ubicacion'] as GeoPoint;

  //       return Card(
  //         elevation: 8,
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
  //         child: Padding(
  //           padding: const EdgeInsets.all(16.0),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Row(
  //                 children: [
  //                   negocioData['logo'] != null
  //                       ? Image.network(negocioData['logo'], width: 50, height: 50)
  //                       : const Icon(Icons.store, size: 50),
  //                   const SizedBox(width: 10),
  //                   Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         negocioData['nombre'],
  //                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  //                       ),
  //                       Text(
  //                         'A 0.5 km', // Puedes implementar la lógica para calcular la distancia
  //                         style: const TextStyle(color: Colors.grey),
  //                       ),
  //                       Row(
  //                         children: List.generate(5, (index) => const Icon(Icons.star, size: 16, color: Colors.yellow)),
  //                       ),
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 10),
  //               ElevatedButton.icon(
  //                 onPressed: () {
  //                   _iniciarRuta(geoPoint.latitude, geoPoint.longitude);
  //                 },
  //                 icon: const Icon(Icons.directions),
  //                 label: const Text('Iniciar Ruta'),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: Colors.purple.shade100,
  //                   minimumSize: const Size(double.infinity, 40),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> _iniciarRuta(double lat, double lng) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir la ruta en Google Maps';
    }
  }
}

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       title: Row(
//         children: [
//           Image.asset('assets/belv1.png', width: 60),
//           const SizedBox(width: 40),
//           const Text('BocattoMap'),
//         ],
//       ),
//       backgroundColor: Colors.orange.shade700,
//     ),
//     body: Stack(
//       children: [
//         _isLocationReady
//             ? StreamBuilder<List<QueryDocumentSnapshot>>(
//                 stream: _getNegociosStream(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   return FutureBuilder<Set<Marker>>(
//                     future: _createMarkers(snapshot.data!),
//                     builder: (context, markersSnapshot) {
//                       if (!markersSnapshot.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       return GoogleMap(
//                         onMapCreated: _onMapCreated,
//                         initialCameraPosition: CameraPosition(
//                           target: _currentPosition,
//                           zoom: 15.0,
//                         ),
//                         markers: markersSnapshot.data!,
//                         myLocationEnabled: true,
//                         myLocationButtonEnabled: true,
//                       );
//                     },
//                   );
//                 },
//               )
//             : const Center(child: CircularProgressIndicator()),
//         Positioned(
//           top: 20.0,
//           left: 10.0,
//           right: 10.0,
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8.0),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//                 child: TextField(
//                   onChanged: _onSearchChanged,
//                   decoration: const InputDecoration(
//                     hintText: 'Buscar restaurante o platos',
//                     prefixIcon: Icon(Icons.search),
//                     border: InputBorder.none,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               StreamBuilder<QuerySnapshot>(
//                 stream: FirebaseFirestore.instance.collection('tipococina').snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return const Center(child: CircularProgressIndicator());
//                   }

//                   var tiposCocina = snapshot.data!.docs;

//                   return SingleChildScrollView(
//                     scrollDirection: Axis.horizontal,
//                     child: Row(
//                       children: tiposCocina.map((tipoCocina) {
//                         return GestureDetector(
//                           onTap: () {
//                             if (selectedTipoCocinaId == tipoCocina.id) {
//                               _applyFilter(null);
//                             } else {
//                               _applyFilter(tipoCocina.id);
//                             }
//                           },
//                           child: Container(
//                             margin: const EdgeInsets.symmetric(horizontal: 4.0),
//                             padding: const EdgeInsets.all(8.0),
//                             decoration: BoxDecoration(
//                               color: selectedTipoCocinaId == tipoCocina.id
//                                   ? Colors.blue.shade100
//                                   : Colors.white,
//                               borderRadius: BorderRadius.circular(12.0),
//                               boxShadow: const [
//                                 BoxShadow(color: Colors.black26, blurRadius: 4.0)
//                               ],
//                             ),
//                             child: Column(
//                               children: [
//                                 Image.network(
//                                   tipoCocina['imagen'],
//                                   width: 40,
//                                   height: 40,
//                                   errorBuilder: (context, error, stackTrace) {
//                                     return const Icon(Icons.error);
//                                   },
//                                 ),
//                                 const SizedBox(height: 4.0),
//                                 Text(tipoCocina['nombre']),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//         if (selectedNegocioId != null && selectedNegocioLocation != null)
//           Positioned(
//             bottom: 20,
//             left: 20,
//             right: 20,
//             child: _buildBusinessInfoCard(selectedNegocioId!, selectedNegocioLocation!),
//           ),
//       ],
//     ),
//   );
// }
