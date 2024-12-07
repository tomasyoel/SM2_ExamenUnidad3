import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ListaPedidosNegocioPage extends StatefulWidget {
  final String negocioId;

  const ListaPedidosNegocioPage({super.key, required this.negocioId});

  @override
  _ListaPedidosNegocioPageState createState() =>
      _ListaPedidosNegocioPageState();
}

class _ListaPedidosNegocioPageState extends State<ListaPedidosNegocioPage> {
  late Stream<DocumentSnapshot> _negocioStream;
  final Map<String, Timer> _timers = {};
  final Map<String, int> _tiempoRestante = {};

  @override
  void initState() {
    super.initState();
    _negocioStream = FirebaseFirestore.instance
        .collection('negocios')
        .doc(widget.negocioId)
        .snapshots();
  }

  @override
  void dispose() {
    for (var timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.amber.shade100;
      case 'confirmado':
        return Colors.blue.shade100;
      case 'preparacion':
        return Colors.orange.shade100;
      case 'listo':
        return Colors.green.shade100;
      case 'enviado':
        return Colors.purple.shade100;
      case 'rechazado':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Future<void> _actualizarPedido(
      String codigoPedido, Map<String, dynamic> updatedFields) async {
    DocumentReference negocioRef =
        FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId);

    await negocioRef.get().then((doc) {
      if (doc.exists) {
        List<dynamic> pedidos = doc['pedidos'] ?? [];
        int index =
            pedidos.indexWhere((p) => p['codigoPedido'] == codigoPedido);
        if (index != -1) {
          pedidos[index].addAll(updatedFields);
          negocioRef.update({'pedidos': pedidos});
        }
      }
    });
  }

  Future<void> _mostrarDetallesPedido(Map<String, dynamic> pedido) async {
    final productos =
        List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
    final ubicacion = pedido['ubicacion'] as GeoPoint?;
    final direccion = pedido['direccion'] ?? 'No disponible';
    final modalidad = pedido['modalidad'] ?? 'No especificada';
    final notas = pedido['notas'] ?? 'Sin notas';
    final metodoPago = pedido['metodoPago'] ?? 'No especificado';
    final costoDelivery = pedido['costoDelivery'] ?? 'No definido';
    final fechaPedido = (pedido['fecha'] as Timestamp?)?.toDate();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Detalles del Pedido: ${pedido['codigoPedido']}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const Divider(),
                Text(
                    "Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format((pedido['fecha'] as Timestamp).toDate().toUtc().add(const Duration(hours: -5)))}"),
                Text(
                    "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}"),
                Text(
                    "Estado de Pago: ${pedido['estadoPago'] ?? 'No definido'}"),
                const SizedBox(height: 8),
                Text(
                  "Dirección: $direccion",
                  style: const TextStyle(fontSize: 16),
                ),
                if (ubicacion != null)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(ubicacion.latitude, ubicacion.longitude),
                        zoom: 15,
                      ),
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      markers: {
                        Marker(
                          markerId: const MarkerId('ubicacion'),
                          position:
                              LatLng(ubicacion.latitude, ubicacion.longitude),
                        ),
                      },
                    ),
                  ),
                Text("Modalidad: $modalidad"),
                if (modalidad == "delivery")
                  Text("Costo de Delivery: S/ $costoDelivery"),
                Text("Método de Pago: $metodoPago"),
                Text("Notas: $notas"),
                const Divider(),
                const Text(
                  "Productos:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...productos.map((producto) {
                  return ListTile(
                    title: Text(producto['nombre']),
                    subtitle: Text("Cantidad: ${producto['cantidad']}"),
                    trailing: Text(
                        "S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}"),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _iniciarTemporizador(
      Map<String, dynamic> pedido, int minutos) async {
    String codigoPedido = pedido['codigoPedido'];
    int tiempoPreparacion = minutos * 60; // Convertir minutos a segundos
    int tiempoInicio = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    int tiempoFin = tiempoInicio + tiempoPreparacion;

    await _actualizarPedido(codigoPedido, {
      'estadoPedido': 'preparacion',
      'tiempoFin': tiempoFin,
    });

    _timers[codigoPedido] =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      int tiempoActual = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      int segundosRestantes = tiempoFin - tiempoActual;

      if (segundosRestantes <= 0) {
        timer.cancel();
        await _actualizarPedido(codigoPedido, {'estadoPedido': 'listo'});
        setState(() {});
      } else {
        setState(() {
          _tiempoRestante[codigoPedido] = segundosRestantes;
        });
      }
    });
  }

  String _formatTiempo(int segundos) {
    int minutos = segundos ~/ 60;
    int segundosRestantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos del Negocio"),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _negocioStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null || !data.containsKey('pedidos')) {
            return const Center(child: Text("No hay pedidos nuevos"));
          }

          final pedidos = List<Map<String, dynamic>>.from(data['pedidos']);

          if (pedidos.isEmpty) {
            return const Center(child: Text("No hay pedidos nuevos"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: pedidos.length,
            itemBuilder: (context, index) {
              final pedido = pedidos[index];
              final fechaPedido = (pedido['fecha'] as Timestamp?)?.toDate();
              final formatoFecha = fechaPedido != null
                  ? DateFormat('dd/MM/yyyy hh:mm a').format(fechaPedido)
                  : 'Sin Fecha';
              String codigoPedido = pedido['codigoPedido'];
              int? segundosRestantes = _tiempoRestante[codigoPedido];

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  onTap: () => _mostrarDetallesPedido(pedido),
                  title: Text(
                    "Pedido: ${pedido['codigoPedido']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format((pedido['fecha'] as Timestamp).toDate().toUtc().add(const Duration(hours: -5)))}"),
                      Text(
                          "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}"),
                      if (pedido['estadoPedido'] == 'preparacion' &&
                          segundosRestantes != null)
                        Text(
                            "Tiempo restante: ${_formatTiempo(segundosRestantes)}"),
                    ],
                  ),
                  trailing: pedido['estadoPedido'] == 'pendiente'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _iniciarTemporizador(
                                  pedido, 10), // Predeterminado 10 min
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _actualizarPedido(
                                  codigoPedido, {'estadoPedido': 'rechazado'}),
                            ),
                          ],
                        )
                      : pedido['estadoPedido'] == 'preparacion'
                          ? const Icon(Icons.access_time, color: Colors.orange)
                          : pedido['estadoPedido'] == 'listo' &&
                                  pedido['modalidad'] == 'delivery'
                              ? IconButton(
                                  icon: const Icon(Icons.motorcycle,
                                      color: Colors.purple),
                                  onPressed: () => _actualizarPedido(
                                    codigoPedido,
                                    {
                                      'estadoPedido': 'enviado',
                                      'fechaEnvio': DateTime.now(),
                                    },
                                  ),
                                )
                              : const Icon(Icons.check, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';

// class ListaPedidosNegocioPage extends StatefulWidget {
//   final String negocioId;

//   const ListaPedidosNegocioPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _ListaPedidosNegocioPageState createState() => _ListaPedidosNegocioPageState();
// }

// class _ListaPedidosNegocioPageState extends State<ListaPedidosNegocioPage> {
//   late Stream<DocumentSnapshot> _negocioStream;
//   Map<String, Timer> _timers = {};
//   Map<String, int> _tiempoRestante = {};

//   @override
//   void initState() {
//     super.initState();
//     _negocioStream = FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(widget.negocioId)
//         .snapshots();
//   }

//   @override
//   void dispose() {
//     _timers.values.forEach((timer) => timer.cancel());
//     super.dispose();
//   }

//   Future<void> _launchWhatsApp(String phoneNumber) async {
//     final whatsappUrl = "https://wa.me/+51$phoneNumber";
//     try {
//       await launch(whatsappUrl);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
//       );
//     }
//   }

//   Color _getEstadoColor(String estado) {
//     switch (estado.toLowerCase()) {
//       case 'pendiente':
//         return Colors.amber.shade100;
//       case 'confirmado':
//         return Colors.blue.shade100;
//       case 'preparacion':
//         return Colors.orange.shade100;
//       case 'listo':
//         return Colors.green.shade100;
//       case 'enviado':
//         return Colors.purple.shade100;
//       case 'rechazado':
//         return Colors.red.shade100;
//       default:
//         return Colors.grey.shade200;
//     }
//   }

//   Future<void> _actualizarPedido(String codigoPedido, Map<String, dynamic> updatedFields) async {
//     DocumentReference negocioRef = FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId);

//     await negocioRef.get().then((doc) {
//       if (doc.exists) {
//         List<dynamic> pedidos = doc['pedidos'] ?? [];
//         int index = pedidos.indexWhere((p) => p['codigoPedido'] == codigoPedido);
//         if (index != -1) {
//           pedidos[index].addAll(updatedFields);
//           negocioRef.update({'pedidos': pedidos});
//         }
//       }
//     });
//   }

//   Future<void> _aceptarPedido(Map<String, dynamic> pedido) async {
//     String codigoPedido = pedido['codigoPedido'];
//     await _actualizarPedido(codigoPedido, {'estadoPedido': 'confirmado'});

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         int tiempoPreparacion = 10; // Por defecto, 10 minutos
//         return AlertDialog(
//           title: Text('Configurar Tiempo de Preparación'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Indica el tiempo estimado de preparación (en minutos):'),
//               TextFormField(
//                 keyboardType: TextInputType.number,
//                 initialValue: '10',
//                 onChanged: (value) {
//                   tiempoPreparacion = int.tryParse(value) ?? 10;
//                 },
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 _iniciarTemporizador(pedido, tiempoPreparacion);
//               },
//               child: Text('Aceptar'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _iniciarTemporizador(Map<String, dynamic> pedido, int minutos) async {
//     String codigoPedido = pedido['codigoPedido'];
//     int tiempoPreparacion = minutos * 60; // Convertir minutos a segundos
//     int tiempoInicio = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//     int tiempoFin = tiempoInicio + tiempoPreparacion;

//     await _actualizarPedido(codigoPedido, {
//       'estadoPedido': 'preparacion',
//       'tiempoFin': tiempoFin,
//     });

//     _timers[codigoPedido] = Timer.periodic(const Duration(seconds: 1), (timer) async {
//       int tiempoActual = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//       int segundosRestantes = tiempoFin - tiempoActual;

//       if (segundosRestantes <= 0) {
//         timer.cancel();
//         await _actualizarPedido(codigoPedido, {'estadoPedido': 'listo'});
//         setState(() {});
//       } else {
//         setState(() {
//           _tiempoRestante[codigoPedido] = segundosRestantes;
//         });
//       }
//     });
//   }

//   String _formatTiempo(int segundos) {
//     int minutos = segundos ~/ 60;
//     int segundosRestantes = segundos % 60;
//     return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
//   }

//   Future<void> _mostrarDetallesPedido(Map<String, dynamic> pedido) async {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//       ),
//       builder: (context) {
//         final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     "Pedido: ${pedido['codigoPedido']}",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                     ),
//                   ),
//                   IconButton(
//                     icon: Image.asset('assets/whatsapp.png', height: 24, width: 24),
//                     onPressed: () async {
//                       final phoneNumber = pedido['nroCelularCliente'] ?? '';
//                       if (phoneNumber.isNotEmpty) {
//                         await _launchWhatsApp(phoneNumber);
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('Número no disponible')),
//                         );
//                       }
//                     },
//                   ),
//                 ],
//               ),
//               const Divider(),
//               Text("Estado de Pago:"),
//               DropdownButton<String>(
//                 value: pedido['estadoPago'] ?? 'Contraentrega',
//                 items: ['Contraentrega', 'Pagado Todo', 'Solo delivery']
//                     .map((estado) => DropdownMenuItem<String>(
//                           value: estado,
//                           child: Text(estado),
//                         ))
//                     .toList(),
//                 onChanged: (nuevoEstado) {
//                   if (nuevoEstado != null) {
//                     _actualizarPedido(pedido['codigoPedido'], {'estadoPago': nuevoEstado});
//                   }
//                 },
//               ),
//               const Divider(),
//               Text(
//                 "Productos:",
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               ...productos.map((producto) {
//                 return ListTile(
//                   title: Text(producto['nombre']),
//                   subtitle: Text("Cantidad: ${producto['cantidad']}"),
//                   trailing: Text("S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}"),
//                 );
//               }).toList(),
//               Align(
//                 alignment: Alignment.centerRight,
//                 child: Text(
//                   "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}",
//                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Pedidos del Negocio"),
//         backgroundColor: Colors.orange,
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: _negocioStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }

//           final data = snapshot.data?.data() as Map<String, dynamic>?;

//           if (data == null || !data.containsKey('pedidos')) {
//             return const Center(child: Text("No hay pedidos nuevos"));
//           }

//           final pedidos = List<Map<String, dynamic>>.from(data['pedidos']);

//           if (pedidos.isEmpty) {
//             return const Center(child: Text("No hay pedidos nuevos"));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16.0),
//             itemCount: pedidos.length,
//             itemBuilder: (context, index) {
//               final pedido = pedidos[index];
//               final fechaPedido = (pedido['fecha'] as Timestamp?)?.toDate();
//               final formatoFecha = fechaPedido != null
//                   ? DateFormat('dd/MM/yyyy hh:mm a').format(fechaPedido)
//                   : 'Sin Fecha';
//               String codigoPedido = pedido['codigoPedido'];
//               int? segundosRestantes = _tiempoRestante[codigoPedido];

//               return Card(
//                 elevation: 4.0,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16.0),
//                   onTap: () => _mostrarDetallesPedido(pedido),
//                   title: Text(
//                     "Pedido: ${pedido['codigoPedido']}",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Fecha: $formatoFecha"),
//                       Text("Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}"),
//                       if (pedido['estadoPedido'] == 'preparacion' && segundosRestantes != null)
//                         Text("Tiempo restante: ${_formatTiempo(segundosRestantes)}"),
//                     ],
//                   ),
//                   trailing: pedido['estadoPedido'] == 'pendiente'
//                       ? Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.check, color: Colors.green),
//                               onPressed: () => _aceptarPedido(pedido),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.cancel, color: Colors.red),
//                               onPressed: () => _actualizarPedido(codigoPedido, {'estadoPedido': 'rechazado'}),
//                             ),
//                           ],
//                         )
//                       : pedido['estadoPedido'] == 'preparacion'
//                           ? const Icon(Icons.access_time, color: Colors.orange)
//                           : pedido['estadoPedido'] == 'listo' && pedido['modalidad'] == 'delivery'
//                               ? IconButton(
//                                   icon: const Icon(Icons.motorcycle, color: Colors.purple),
//                                   onPressed: () => _actualizarPedido(
//                                     codigoPedido,
//                                     {
//                                       'estadoPedido': 'enviado',
//                                       'fechaEnvio': DateTime.now(),
//                                     },
//                                   ),
//                                 )
//                               : const Icon(Icons.check, color: Colors.green),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';

// class ListaPedidosNegocioPage extends StatefulWidget {
//   final String negocioId; // Recibe el ID del negocio como argumento

//   const ListaPedidosNegocioPage({Key? key, required this.negocioId}) : super(key: key);

//   @override
//   _ListaPedidosNegocioPageState createState() => _ListaPedidosNegocioPageState();
// }

// class _ListaPedidosNegocioPageState extends State<ListaPedidosNegocioPage> {
//   late Stream<DocumentSnapshot> _negocioStream;
//   Map<String, Timer> _timers = {};
//   Map<String, int> _tiempoRestante = {};

//   @override
//   void initState() {
//     super.initState();

//     // Usar el negocioId proporcionado para obtener los pedidos
//     _negocioStream = FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(widget.negocioId)
//         .snapshots();
//   }

//   @override
//   void dispose() {
//     _timers.values.forEach((timer) => timer.cancel());
//     super.dispose();
//   }

//   Future<void> _launchWhatsApp(String phoneNumber) async {
//     final whatsappUrl = "https://wa.me/+51$phoneNumber";
//     try {
//       await launch(whatsappUrl);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
//       );
//     }
//   }

//   Color _getEstadoColor(String estado) {
//     switch (estado.toLowerCase()) {
//       case 'pendiente':
//         return Colors.amber.shade100;
//       case 'confirmado':
//         return Colors.blue.shade100;
//       case 'preparacion':
//         return Colors.orange.shade100;
//       case 'listo':
//         return Colors.green.shade100;
//       case 'enviado':
//         return Colors.purple.shade100;
//       case 'rechazado':
//         return Colors.red.shade100;
//       default:
//         return Colors.grey.shade200;
//     }
//   }

//   Future<void> _actualizarPedido(String codigoPedido, Map<String, dynamic> updatedFields) async {
//     DocumentReference negocioRef = FirebaseFirestore.instance.collection('negocios').doc(widget.negocioId);

//     // Actualizar en el negocio
//     await negocioRef.get().then((doc) {
//       if (doc.exists) {
//         List<dynamic> pedidos = doc['pedidos'] ?? [];
//         int index = pedidos.indexWhere((p) => p['codigoPedido'] == codigoPedido);
//         if (index != -1) {
//           pedidos[index].addAll(updatedFields);
//           negocioRef.update({'pedidos': pedidos});
//         }
//       }
//     });
//   }

//   Future<void> _aceptarPedido(Map<String, dynamic> pedido) async {
//     String codigoPedido = pedido['codigoPedido'];

//     // Actualizar estado a 'confirmado'
//     await _actualizarPedido(codigoPedido, {
//       'estadoPedido': 'confirmado',
//     });

//     // Después de 5 segundos, cambiar a 'preparacion' y iniciar temporizador
//     Future.delayed(const Duration(seconds: 5), () async {
//       await _actualizarPedido(codigoPedido, {
//         'estadoPedido': 'preparacion',
//       });

//       // Iniciar temporizador (ejemplo: 15 minutos)
//       int tiempoPreparacion = 15 * 60; // 15 minutos en segundos
//       int tiempoInicio = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//       int tiempoFin = tiempoInicio + tiempoPreparacion;

//       await _actualizarPedido(codigoPedido, {
//         'tiempoFin': tiempoFin,
//       });

//       // Actualizar estado a 'listo' cuando el temporizador termine
//       _timers[codigoPedido] = Timer.periodic(const Duration(seconds: 1), (timer) async {
//         int tiempoActual = DateTime.now().millisecondsSinceEpoch ~/ 1000;
//         int segundosRestantes = tiempoFin - tiempoActual;

//         if (segundosRestantes <= 0) {
//           timer.cancel();
//           await _actualizarPedido(codigoPedido, {
//             'estadoPedido': 'listo',
//           });
//           setState(() {});
//         } else {
//           setState(() {
//             _tiempoRestante[codigoPedido] = segundosRestantes;
//           });
//         }
//       });
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Pedidos del Negocio"),
//         backgroundColor: Colors.orange,
//       ),
//       body: StreamBuilder<DocumentSnapshot>(
//         stream: _negocioStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }

//           final data = snapshot.data?.data() as Map<String, dynamic>?;

//           if (data == null || !data.containsKey('pedidos')) {
//             return const Center(child: Text("No hay pedidos nuevos"));
//           }

//           final pedidos = List<Map<String, dynamic>>.from(data['pedidos']);

//           if (pedidos.isEmpty) {
//             return const Center(child: Text("No hay pedidos nuevos"));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16.0),
//             itemCount: pedidos.length,
//             itemBuilder: (context, index) {
//               final pedido = pedidos[index];
//               final fechaPedido = (pedido['fecha'] as Timestamp?)?.toDate();
//               final formatoFecha = fechaPedido != null
//                   ? DateFormat('dd/MM/yyyy hh:mm a').format(fechaPedido)
//                   : 'Sin Fecha';

//               String codigoPedido = pedido['codigoPedido'];
//               int? segundosRestantes = _tiempoRestante[codigoPedido];

//               return Card(
//                 elevation: 4.0,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16.0),
//                   leading: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.check_circle, color: Colors.green),
//                         onPressed: () async {
//                           await _aceptarPedido(pedido);
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel, color: Colors.red),
//                         onPressed: () => _actualizarPedido(codigoPedido, {'estadoPedido': 'rechazado'}),
//                       ),
//                     ],
//                   ),
//                   title: Text(
//                     "Pedido: ${pedido['codigoPedido'] ?? 'Sin Código'}",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Fecha: $formatoFecha",
//                       ),
//                       Text(
//                         "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}",
//                       ),
//                       if (pedido['estadoPedido'] == 'preparacion' && segundosRestantes != null)
//                         Text(
//                           "Tiempo restante: ${_formatTiempo(segundosRestantes)}",
//                           style: const TextStyle(color: Colors.red),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   String _formatTiempo(int segundos) {
//     int minutos = segundos ~/ 60;
//     int segundosRestantes = segundos % 60;
//     return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';

// class ListaPedidosNegocioPage extends StatefulWidget {
//   const ListaPedidosNegocioPage({Key? key}) : super(key: key);

//   @override
//   _ListaPedidosNegocioPageState createState() => _ListaPedidosNegocioPageState();
// }

// class _ListaPedidosNegocioPageState extends State<ListaPedidosNegocioPage> {
//   late Stream<QuerySnapshot> _pedidosStream;
//   Map<String, Timer> _timers = {};

//   @override
//   void initState() {
//     super.initState();
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       _pedidosStream = FirebaseFirestore.instance
//           .collection('negocios')
//           .doc(user.uid)
//           .collection('pedidos')
//           .orderBy('fecha', descending: true)
//           .snapshots();
//     }
//   }

//   @override
//   void dispose() {
//     _timers.values.forEach((timer) => timer.cancel());
//     super.dispose();
//   }

//   Future<void> _launchWhatsApp(String phoneNumber) async {
//     final whatsappUrl = "https://wa.me/+51$phoneNumber";
//     try {
//       await launch(whatsappUrl);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
//       );
//     }
//   }

//   Color _getEstadoColor(String estado) {
//     switch (estado.toLowerCase()) {
//       case 'pendiente': return Colors.amber;
//       case 'confirmado': return Colors.blue;
//       case 'preparacion': return Colors.orange;
//       case 'listo': return Colors.green;
//       case 'enviado': return Colors.purple;
//       case 'rechazado': return Colors.red;
//       default: return Colors.grey;
//     }
//   }

//   void _mostrarDetallesPedido(BuildContext context, DocumentSnapshot pedido) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//       ),
//       builder: (context) {
//         final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
//         return DraggableScrollableSheet(
//           initialChildSize: 0.9,
//           minChildSize: 0.5,
//           maxChildSize: 0.95,
//           builder: (_, controller) => Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
//             ),
//             child: ListView(
//               controller: controller,
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             "Detalles del Pedido: ${pedido['codigoPedido']}",
//                             style: const TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           IconButton(
//                             icon: Image.asset('assets/whatsapp.png', height: 24, width: 24),
//                             onPressed: () => _launchWhatsApp(pedido['nroCelularCliente'] ?? ''),
//                           ),
//                         ],
//                       ),
//                       const Divider(),
//                       Text(
//                         "Modalidad: ${pedido['modalidad'] ?? 'Sin Modalidad'}",
//                         style: const TextStyle(fontSize: 16),
//                       ),
//                       if (pedido['modalidad'] == 'delivery') ...[
//                         const SizedBox(height: 4),
//                         Text(
//                           "Dirección: ${pedido['direccion'] ?? 'Sin Dirección'}",
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "Costo de Delivery: S/ ${pedido['costoDelivery']?.toStringAsFixed(2) ?? '0.00'}",
//                           style: const TextStyle(fontSize: 16),
//                         ),
//                       ],
//                       const SizedBox(height: 8),
//                       const Divider(),
//                       Text(
//                         "Productos:",
//                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                       ...productos.map((producto) {
//                         return ListTile(
//                           contentPadding: EdgeInsets.zero,
//                           title: Text(producto['nombre'], style: const TextStyle(fontSize: 16)),
//                           subtitle: Text(
//                             "Cantidad: ${producto['cantidad']} - Total: S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}",
//                             style: const TextStyle(fontSize: 14),
//                           ),
//                         );
//                       }).toList(),
//                       const Divider(),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: Text(
//                           "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}",
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 18,
//                             color: Colors.green,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _iniciarTemporizador(DocumentSnapshot pedido) {
//     final tiempoPreparacion = 15 * 60; // 15 minutos en segundos
//     _timers[pedido.id] = Timer.periodic(const Duration(seconds: 1), (timer) async {
//       if (mounted) {
//         final tiempoRestante = timer.tick;
//         if (tiempoRestante >= tiempoPreparacion) {
//           timer.cancel();
//           // Actualizar estado a listo automáticamente
//           await _actualizarEstadoPedido(pedido, 'listo', null);
//         }
//       }
//     });
//   }

//   Future<void> _actualizarEstadoPedido(
//     DocumentSnapshot pedido,
//     String nuevoEstado,
//     String? nuevoPedPago
//   ) async {
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final batch = FirebaseFirestore.instance.batch();

//     // Actualizar pedido en colección de negocios
//     final pedidoNegocioRef = FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(user.uid)
//         .collection('pedidos')
//         .doc(pedido.id);

//     // Actualizar pedido en colección de usuarios
//     final pedidoUsuarioRef = FirebaseFirestore.instance
//         .collection('usuarios')
//         .doc(pedido['usuarioId'])
//         .collection('pedidos')
//         .doc(pedido.id);

//     // Preparar datos de actualización
//     final updateData = {
//       'estadoPedido': nuevoEstado,
//       if (nuevoPedPago != null) 'pedPago': nuevoPedPago,
//     };

//     batch.update(pedidoNegocioRef, updateData);
//     batch.update(pedidoUsuarioRef, updateData);

//     await batch.commit();
//   }

//   Future<void> _rechazarPedido(DocumentSnapshot pedido) async {
//     final User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;

//     final batch = FirebaseFirestore.instance.batch();

//     // Restaurar stock en carta de negocio
//     final cartaRef = FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(user.uid)
//         .collection('cartas')
//         .doc(pedido['cartaId']);

//     final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);

//     // Restaurar stock para cada producto
//     for (var producto in productos) {
//       batch.update(cartaRef, {
//         'productos.${producto['id']}.stock':
//           FieldValue.increment(producto['cantidad'])
//       });
//     }

//     // Actualizar estado del pedido a rechazado
//     final pedidoNegocioRef = FirebaseFirestore.instance
//         .collection('negocios')
//         .doc(user.uid)
//         .collection('pedidos')
//         .doc(pedido.id);

//     final pedidoUsuarioRef = FirebaseFirestore.instance
//         .collection('usuarios')
//         .doc(pedido['usuarioId'])
//         .collection('pedidos')
//         .doc(pedido.id);

//     batch.update(pedidoNegocioRef, {'estadoPedido': 'rechazado'});
//     batch.update(pedidoUsuarioRef, {'estadoPedido': 'rechazado'});

//     await batch.commit();
//   }

//   List<String> _getEstadosPosibles(String modalidad) {
//     return modalidad == 'delivery'
//         ? ['Confirmado', 'Preparación', 'Listo', 'Enviado']
//         : ['Confirmado', 'Preparación', 'Listo'];
//   }

//   List<String> _getPedPagoPosibles(String modalidad) {
//     return modalidad == 'delivery'
//         ? ['No Pagado', 'Contra Entrega', 'Pagado - Cobrar solo delivery', 'Todo Pagado']
//         : ['No Pagado', 'Pagado'];
//   }

//   Widget _buildEstadoPedidoDropdown(DocumentSnapshot pedido) {
//     return DropdownButton<String>(
//       value: pedido['estadoPedido'] ?? 'Pendiente',
//       items: _getEstadosPosibles(pedido['modalidad']).map((estado) {
//         return DropdownMenuItem(
//           value: estado,
//           child: Text(estado),
//         );
//       }).toList(),
//       onChanged: (nuevoEstado) {
//         if (nuevoEstado != null) {
//           _actualizarEstadoPedido(pedido, nuevoEstado.toLowerCase(), null);
//         }
//       },
//     );
//   }

//   Widget _buildPedPagoDropdown(DocumentSnapshot pedido) {
//     return DropdownButton<String>(
//       value: pedido['pedPago'] ?? 'No Pagado',
//       items: _getPedPagoPosibles(pedido['modalidad']).map((pedPago) {
//         return DropdownMenuItem(
//           value: pedPago,
//           child: Text(pedPago),
//         );
//       }).toList(),
//       onChanged: (nuevoPedPago) {
//         if (nuevoPedPago != null) {
//           _actualizarEstadoPedido(pedido, pedido['estadoPedido'], nuevoPedPago);
//         }
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mis Pedidos"),
//         backgroundColor: Colors.orange,
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _pedidosStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }

//           final pedidos = snapshot.data?.docs ?? [];

//           if (pedidos.isEmpty) {
//             return const Center(child: Text("No hay pedidos nuevos"));
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16.0),
//             itemCount: pedidos.length,
//             itemBuilder: (context, index) {
//               final pedido = pedidos[index];
//               final fechaPedido = (pedido['fecha'] as Timestamp?)?.toDate();
//               final formatoFecha = fechaPedido != null
//                   ? DateFormat('dd/MM/yyyy hh:mm a').format(fechaPedido)
//                   : 'Sin Fecha';

//               return Card(
//                 elevation: 4.0,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16.0),
//                   leading: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: const Icon(Icons.check_circle, color: Colors.white),
//                         onPressed: () async {
//                           await _actualizarEstadoPedido(pedido, 'confirmado', null);
//                           Future.delayed(const Duration(seconds: 5), () {
//                             _actualizarEstadoPedido(pedido, 'preparacion', null);
//                             _iniciarTemporizador(pedido);
//                           });
//                         },
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.cancel, color: Colors.white),
//                         onPressed: () => _rechazarPedido(pedido),
//                       ),
//                     ],
//                   ),
//                   title: Text(
//                     "Código: ${pedido['codigoPedido'] ?? 'Sin Código'}",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Fecha: $formatoFecha",
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                       Text(
//                         "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}",
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                       _buildEstadoPedidoDropdown(pedido),
//                       _buildPedPagoDropdown(pedido),
//                     ],
//                   ),
//                   trailing: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Image.asset('assets/whatsapp.png', height: 24, width: 24),
//                         onPressed: () => _mostrarDetallesPedido(context, pedido),
//                       ),
//                       if (pedido['estadoPedido'] == 'listo' && pedido['modalidad'] == 'delivery')
//                         IconButton(
//                           icon: const Icon(Icons.motorcycle, color: Colors.white),
//                           onPressed: () => _actualizarEstadoPedido(pedido, 'enviado', null),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
