// import 'package:restmap/models/order.dart' as app_models;
// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/views/customer/adjuntarcomprobante.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class ListOrderPage extends StatefulWidget {
//   @override
//   _ListOrderPageState createState() => _ListOrderPageState();
// }

// class _ListOrderPageState extends State<ListOrderPage> {
//   final FirestoreService firestoreService = FirestoreService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mis Pedidos'),
//         centerTitle: true,
//       ),
//       body: StreamBuilder<List<app_models.Order>>(
//         stream: firestoreService.getUserOrders(_auth.currentUser!.uid),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             print('No hay datos o snapshot está vacío');
//             return Center(child: Text('No has realizado ningún pedido'));
//           }

//           List<app_models.Order> orders = snapshot.data!;
//           print('Número de pedidos: ${orders.length}');
//           for (var order in orders) {
//             print('Pedido ID: ${order.id}, Estado: ${order.orderStatus}');
//           }

//           orders.sort((a, b) => b.orderDate.compareTo(a.orderDate)); // Ordenar por fecha más reciente primero

//           return ListView.builder(
//             itemCount: orders.length,
//             itemBuilder: (context, index) {
//               app_models.Order order = orders[index];
//               return Card(
//                 margin: EdgeInsets.all(10),
//                 child: ExpansionTile(
//                   leading: Icon(IconlyLight.bag),
//                   title: Text('Fecha de Pedido: ${order.orderDate}'),
//                   subtitle: Text('Estado: ${order.orderStatus}'),
//                   children: [
//                     ListTile(
//                       title: Text('Fecha de Pedido'),
//                       subtitle: Text(order.orderDate.toString()),
//                     ),
//                     ListTile(
//                       title: Text('Total'),
//                       subtitle: Text('S/.${order.totalPrice.toStringAsFixed(2)}'),
//                     ),
//                     ListTile(
//                       title: Text('Modalidad'),
//                       subtitle: Text(order.modalidad),
//                     ),
//                     ListTile(
//                       title: Text('Dirección de Envío'),
//                       subtitle: Text(order.userAddress),
//                     ),
//                     if (order.latitud != null && order.longitud != null)
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ListTile(
//                             title: Text('Ubicación'),
//                           ),
//                           Container(
//                             height: 150,
//                             width: double.infinity,
//                             child: GoogleMap(
//                               initialCameraPosition: CameraPosition(
//                                 target: LatLng(order.latitud!, order.longitud!),
//                                 zoom: 15,
//                               ),
//                               markers: {
//                                 Marker(
//                                   markerId: MarkerId(order.id),
//                                   position: LatLng(order.latitud!, order.longitud!),
//                                 ),
//                               },
//                               liteModeEnabled: true,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ListTile(
//                       title: Text('Teléfono de Contacto'),
//                       subtitle: Text(order.userPhone),
//                     ),
//                     ListTile(
//                       title: Text('Método de Pago'),
//                       subtitle: Text(order.metodoPago),
//                     ),
//                     if (order.subMetodoPago.isNotEmpty)
//                       ListTile(
//                         title: Text('Submétodo de Pago'),
//                         subtitle: Text(order.subMetodoPago),
//                       ),
//                     if (order.metodoPago == 'ContraEntrega' && order.subMetodoPago == 'Efectivo' && order.monto != null)
//                       ListTile(
//                         title: Text('Monto'),
//                         subtitle: Text('S/.${order.monto!.toStringAsFixed(2)}'),
//                       ),
//                     if (order.fotopago != null)
//                       ListTile(
//                         title: Text('Comprobante de Pago'),
//                         subtitle: Image.network(order.fotopago!),
//                       ),
//                     if (order.metodoPago == 'Pago Online' && (order.fotopago == null || order.nombresCompletos == ""))
//                       ListTile(
//                         title: ElevatedButton(
//                           onPressed: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => AdjuntarComprobantePage(orderId: order.id, totalPrice: order.totalPrice),
//                             ),
//                           ),
//                           child: Text('Adjuntar Comprobante de Pago'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.orange,
//                           ),
//                         ),
//                       ),
//                     if (order.notas.isNotEmpty)
//                       ListTile(
//                         title: Text('Notas'),
//                         subtitle: Text(order.notas),
//                       ),
//                     if (order.couponCode != null)
//                       ListTile(
//                         title: Text('Cupón Aplicado'),
//                         subtitle: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(order.couponCode!),
//                             if (order.discount != null)
//                               Text('Descuento: S/.${order.discount!.toStringAsFixed(2)}'),
//                           ],
//                         ),
//                       ),
//                     ExpansionTile(
//                       title: Text('Productos'),
//                       children: order.orderProducts.map((product) {
//                         var productName = product['productName'];
//                         var size = product['size'];
//                         return ListTile(
//                           title: Text('$productName ($size)'),
//                           subtitle: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text('Cantidad: ${product['quantity']}'),
//                               Text('Precio: S/.${product['price'].toStringAsFixed(2)}'),
//                             ],
//                           ),
//                         );
//                       }).toList(),
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
