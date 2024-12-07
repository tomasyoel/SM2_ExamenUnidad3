import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NegociosDetallePage extends StatelessWidget {
  final String negocioId;
  final LatLng userLocation;

  NegociosDetallePage({required this.negocioId, required this.userLocation});

  Future<Map<String, dynamic>?> _getNegocioData() async {
    DocumentSnapshot negocioSnapshot =
        await FirebaseFirestore.instance.collection('negocios').doc(negocioId).get();
    return negocioSnapshot.data() as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> _getProductoMasBarato() async {
    QuerySnapshot cartaSnapshot = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .where('negocioId', isEqualTo: negocioId)
        .get();

    if (cartaSnapshot.docs.isNotEmpty) {
      var carta = cartaSnapshot.docs.first.data() as Map<String, dynamic>;
      var productos = carta['carta'] as List<dynamic>;

      if (productos.isNotEmpty) {
        var productoMasBarato = productos.reduce((curr, next) =>
            curr['precio'] < next['precio'] ? curr : next);
        return productoMasBarato;
      }
    }

    return null;
  }

  Future<void> _iniciarRuta(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'No se pudo abrir la ruta en Google Maps';
    }
  }

  // Método para calcular la distancia entre dos puntos geográficos
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radio de la Tierra en Km
    var dLat = _deg2rad(lat2 - lat1);
    var dLon = _deg2rad(lon2 - lon1);
    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) {
    return deg * (math.pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Negocio'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getNegocioData(),
        builder: (context, negocioSnapshot) {
          if (!negocioSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var negocioData = negocioSnapshot.data;
          var ubicacion = negocioData?['ubicacion'] as GeoPoint?;
          double distancia = ubicacion != null
              ? _calculateDistance(
                  userLocation.latitude,
                  userLocation.longitude,
                  ubicacion.latitude,
                  ubicacion.longitude,
                )
              : 0.0; // Si no hay ubicación, la distancia será 0.0 km

          return FutureBuilder<Map<String, dynamic>?>(
            future: _getProductoMasBarato(),
            builder: (context, productoSnapshot) {
              if (!productoSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var productoMasBarato = productoSnapshot.data;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Logo y nombre del negocio
                    negocioData?['logo'] != null
                        ? Image.network(
                            negocioData!['logo'],
                            width: 100,
                            height: 100,
                          )
                        : const Icon(Icons.store, size: 100),
                    const SizedBox(height: 20),
                    Text(
                      negocioData?['nombre'] ?? 'Sin nombre',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Dirección: ${negocioData?['direccion'] ?? 'Sin dirección'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    // Distancia calculada y mostrada correctamente
                    Text(
                      'Distancia: ${distancia.toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    if (productoMasBarato != null)
                      Column(
                        children: [
                          Text(
                            'Producto más barato:',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          productoMasBarato['urlImagen'] != null
                              ? Image.network(
                                  productoMasBarato['urlImagen'],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.fastfood, size: 100),
                          const SizedBox(height: 10),
                          Text(
                            productoMasBarato['nombre'],
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            'S/ ${productoMasBarato['precio'].toString()}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Botón para iniciar ruta
                    ElevatedButton.icon(
                      onPressed: () {
                        if (ubicacion != null) {
                          _iniciarRuta(ubicacion.latitude, ubicacion.longitude);
                        }
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Iniciar Ruta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}






// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:math' as math;
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class NegociosDetallePage extends StatelessWidget {
//   final String negocioId;
//   final LatLng userLocation;

//   NegociosDetallePage({required this.negocioId, required this.userLocation});

//   Future<Map<String, dynamic>?> _getNegocioData() async {
//     DocumentSnapshot negocioSnapshot =
//         await FirebaseFirestore.instance.collection('negocios').doc(negocioId).get();
//     return negocioSnapshot.data() as Map<String, dynamic>?;
//   }

//   Future<Map<String, dynamic>?> _getProductoMasBarato() async {
//     QuerySnapshot cartaSnapshot = await FirebaseFirestore.instance
//         .collection('cartasnegocio')
//         .where('negocioId', isEqualTo: negocioId)
//         .get();

//     if (cartaSnapshot.docs.isNotEmpty) {
//       var carta = cartaSnapshot.docs.first.data() as Map<String, dynamic>;
//       var productos = carta['carta'] as List<dynamic>;

//       if (productos.isNotEmpty) {
//         var productoMasBarato = productos.reduce((curr, next) =>
//             curr['precio'] < next['precio'] ? curr : next);
//         return productoMasBarato;
//       }
//     }

//     return null;
//   }

//   Future<void> _iniciarRuta(double lat, double lng) async {
//     final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'No se pudo abrir la ruta en Google Maps';
//     }
//   }

//   // Método para calcular la distancia entre dos puntos geográficos
//   double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const R = 6371; // Radio de la Tierra en Km
//     var dLat = _deg2rad(lat2 - lat1);
//     var dLon = _deg2rad(lon2 - lon1);
//     var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
//         math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) *
//         math.sin(dLon / 2) * math.sin(dLon / 2);
//     var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
//     return R * c;
//   }

//   double _deg2rad(double deg) {
//     return deg * (math.pi / 180);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Información del Negocio'),
//         backgroundColor: Colors.blue.shade900,
//       ),
//       body: FutureBuilder<Map<String, dynamic>?>(
//         future: _getNegocioData(),
//         builder: (context, negocioSnapshot) {
//           if (!negocioSnapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           var negocioData = negocioSnapshot.data;
//           var ubicacion = negocioData?['ubicacion'] as GeoPoint?;
//           double distancia = ubicacion != null
//               ? _calculateDistance(
//                   userLocation.latitude,
//                   userLocation.longitude,
//                   ubicacion.latitude,
//                   ubicacion.longitude,
//                 )
//               : 0.0;

//           return FutureBuilder<Map<String, dynamic>?>(
//             future: _getProductoMasBarato(),
//             builder: (context, productoSnapshot) {
//               if (!productoSnapshot.hasData) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               var productoMasBarato = productoSnapshot.data;

//               return Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: [
//                     // Logo y nombre del negocio
//                     negocioData?['logo'] != null
//                         ? Image.network(
//                             negocioData!['logo'],
//                             width: 100,
//                             height: 100,
//                           )
//                         : const Icon(Icons.store, size: 100),
//                     const SizedBox(height: 20),
//                     Text(
//                       negocioData?['nombre'] ?? 'Sin nombre',
//                       style: const TextStyle(
//                           fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Dirección: ${negocioData?['direccion'] ?? 'Sin dirección'}',
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       'Distancia: ${distancia.toStringAsFixed(2)} km',
//                       style: const TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                     const SizedBox(height: 10),
//                     if (productoMasBarato != null)
//                       Column(
//                         children: [
//                           Text(
//                             'Producto más barato:',
//                             style: const TextStyle(
//                                 fontSize: 18, fontWeight: FontWeight.bold),
//                           ),
//                           const SizedBox(height: 10),
//                           productoMasBarato['urlImagen'] != null
//                               ? Image.network(
//                                   productoMasBarato['urlImagen'],
//                                   width: 100,
//                                   height: 100,
//                                   fit: BoxFit.cover,
//                                 )
//                               : const Icon(Icons.fastfood, size: 100),
//                           const SizedBox(height: 10),
//                           Text(
//                             productoMasBarato['nombre'],
//                             style: const TextStyle(fontSize: 18),
//                           ),
//                           Text(
//                             'S/ ${productoMasBarato['precio'].toString()}',
//                             style: const TextStyle(
//                                 fontSize: 16, color: Colors.green),
//                           ),
//                         ],
//                       ),
//                     const Spacer(),
//                     // Botón para iniciar ruta
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         if (ubicacion != null) {
//                           _iniciarRuta(ubicacion.latitude, ubicacion.longitude);
//                         }
//                       },
//                       icon: const Icon(Icons.directions),
//                       label: const Text('Iniciar Ruta'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue.shade900,
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }