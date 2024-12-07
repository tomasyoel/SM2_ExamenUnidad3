import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ListaPedidosPage extends StatefulWidget {
  const ListaPedidosPage({super.key});

  @override
  _ListaPedidosPageState createState() => _ListaPedidosPageState();
}

class _ListaPedidosPageState extends State<ListaPedidosPage> {
  late Future<List<Map<String, dynamic>>> _pedidosFuture;

  @override
  void initState() {
    super.initState();
    _pedidosFuture = _fetchPedidos();
  }

  Future<List<Map<String, dynamic>>> _fetchPedidos() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("Usuario no autenticado");
    }

    final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();
    final List<dynamic> pedidos = userDoc.data()?['pedidos'] ?? [];

    // Obtener los nombres de los negocios
    for (var pedido in pedidos) {
      if (pedido['negocioId'] != null) {
        final negocioDoc = await FirebaseFirestore.instance
            .collection('negocios')
            .doc(pedido['negocioId'])
            .get();
        pedido['nombreNegocio'] = negocioDoc.data()?['nombre'] ?? 'Sin Nombre';
      }
    }

    return List<Map<String, dynamic>>.from(pedidos);
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final whatsappUrl = "https://wa.me/+51$phoneNumber";
    final whatsappUrlScheme = "whatsapp://send?phone=+51$phoneNumber";

    try {
      bool launched = await launch(whatsappUrlScheme);
      if (!launched) {
        await launch(whatsappUrl);
      }
    } catch (e) {
      print("No se pudo lanzar WhatsApp: $e");
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mis Pedidos"),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _pedidosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar pedidos: ${snapshot.error}"));
          }

          final pedidos = snapshot.data ?? [];

          if (pedidos.isEmpty) {
            return const Center(
              child: Text("No tienes pedidos realizados."),
            );
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

              return Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    "Pedido: ${pedido['nombreNegocio'] ?? 'Negocio'} - ${pedido['codigoPedido'] ?? 'Sin Código'}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Estado: ${pedido['estadoPedido'] ?? 'Desconocido'}",
                        style: TextStyle(
                          color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}"),
                      const SizedBox(height: 4),
                      Text("Fecha: $formatoFecha"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => _mostrarDetallesPedido(context, pedido),
                        child: const Text("Detalles"),
                      ),
                      IconButton(
                        icon: Image.asset('assets/whatsapp.png', height: 24, width: 24),
                        onPressed: () async {
                          final nroCelularNegocio = pedido['nroCelularNegocio'] ?? '';
                          if (nroCelularNegocio.isNotEmpty) {
                            await _launchWhatsApp(nroCelularNegocio);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('El negocio no tiene número de WhatsApp')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'pendiente':
        return Colors.amber;
      case 'en proceso':
        return Colors.blue;
      case 'completado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _mostrarDetallesPedido(BuildContext context, Map<String, dynamic> pedido) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Detalles del Pedido: ${pedido['codigoPedido']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Image.asset('assets/whatsapp.png', height: 24, width: 24),
                    onPressed: () async {
                      final nroCelularNegocio = pedido['nroCelularNegocio'] ?? '';
                      if (nroCelularNegocio.isNotEmpty) {
                        await _launchWhatsApp(nroCelularNegocio);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('El negocio no tiene número de WhatsApp')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const Divider(),
              Text(
                "Modalidad: ${pedido['modalidad'] ?? 'Sin Modalidad'}",
                style: const TextStyle(fontSize: 16),
              ),
              if (pedido['modalidad'] == 'delivery') ...[
                const SizedBox(height: 4),
                Text(
                  "Dirección: ${pedido['direccion'] ?? 'Sin Dirección'}",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  "Costo de Delivery: S/ ${pedido['costoDelivery']?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                "Método de Pago: ${pedido['metodoPago'] ?? 'Desconocido'}",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                "Notas:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                pedido['notas'] ?? 'Sin Notas',
                textAlign: TextAlign.justify,
              ),
              const Divider(),
              const Text(
                "Productos:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ...productos.map((producto) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(producto['nombre'], style: const TextStyle(fontSize: 16)),
                  subtitle: Text(
                    "Cantidad: ${producto['cantidad']} - Total: S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }),
              const Divider(),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ListaPedidosPage extends StatefulWidget {
//   const ListaPedidosPage({Key? key}) : super(key: key);

//   @override
//   _ListaPedidosPageState createState() => _ListaPedidosPageState();
// }

// class _ListaPedidosPageState extends State<ListaPedidosPage> {
//   late Future<List<dynamic>> _pedidosFuture;

//   @override
//   void initState() {
//     super.initState();
//     _pedidosFuture = _fetchPedidos();
//   }

//   Future<List<dynamic>> _fetchPedidos() async {
//     final User? user = FirebaseAuth.instance.currentUser;

//     if (user == null) {
//       throw Exception("Usuario no autenticado");
//     }

//     final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).get();

//     return List<dynamic>.from(userDoc.data()?['pedidos'] ?? []);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mis Pedidos"),
//         backgroundColor: Colors.orange,
//       ),
//       body: FutureBuilder<List<dynamic>>(
//         future: _pedidosFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text("Error al cargar pedidos: ${snapshot.error}"));
//           }

//           final pedidos = snapshot.data ?? [];

//           if (pedidos.isEmpty) {
//             return const Center(
//               child: Text("No tienes pedidos realizados."),
//             );
//           }

//           return ListView.builder(
//             padding: const EdgeInsets.all(16.0),
//             itemCount: pedidos.length,
//             itemBuilder: (context, index) {
//               final pedido = pedidos[index];

//               return Card(
//                 elevation: 4.0,
//                 margin: const EdgeInsets.symmetric(vertical: 8.0),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.all(16.0),
//                   title: Text(
//                     "Pedido: ${pedido['codigoPedido'] ?? 'Sin Código'}",
//                     style: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const SizedBox(height: 8),
//                       Text(
//                         "Estado: ${pedido['estadoPedido'] ?? 'Desconocido'}",
//                         style: TextStyle(
//                           color: _getEstadoColor(pedido['estadoPedido'] ?? 'pendiente'),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text("Total: S/ ${pedido['total']?.toStringAsFixed(2) ?? '0.00'}"),
//                       const SizedBox(height: 4),
//                       Text("Fecha: ${pedido['fecha']?.toDate()?.toLocal() ?? 'Sin Fecha'}"),
//                     ],
//                   ),
//                   trailing: ElevatedButton(
//                     onPressed: () => _mostrarDetallesPedido(context, pedido),
//                     child: const Text("Ver Detalles"),
//                   ),
//                 ),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }

//   Color _getEstadoColor(String estado) {
//     switch (estado.toLowerCase()) {
//       case 'pendiente':
//         return Colors.amber;
//       case 'en proceso':
//         return Colors.blue;
//       case 'completado':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   void _mostrarDetallesPedido(BuildContext context, Map<String, dynamic> pedido) {
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
//               Text(
//                 "Detalles del Pedido: ${pedido['codigoPedido']}",
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const Divider(),
//               Text("Modalidad: ${pedido['modalidad'] ?? 'Sin Modalidad'}"),
//               if (pedido['modalidad'] == 'delivery') ...[
//                 Text("Dirección: ${pedido['direccion'] ?? 'Sin Dirección'}"),
//               ],
//               const SizedBox(height: 8),
//               Text("Método de Pago: ${pedido['metodoPago'] ?? 'Desconocido'}"),
//               const SizedBox(height: 8),
//               Text("Notas: ${pedido['notas'] ?? 'Sin Notas'}"),
//               const SizedBox(height: 8),
//               Text(
//                 "Productos:",
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 4),
//               ...productos.map((producto) {
//                 return ListTile(
//                   title: Text(producto['nombre']),
//                   subtitle: Text(
//                       "Cantidad: ${producto['cantidad']} - Total: S/ ${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}"),
//                 );
//               }).toList(),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
