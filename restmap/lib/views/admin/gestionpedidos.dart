// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:restmap/models/order.dart' as app_models;
// import 'package:restmap/services/firestore_service.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';
// import 'package:url_launcher/url_launcher.dart';
// //import 'package:firebase_auth/firebase_auth.dart';

// class OrderManagementPage extends StatefulWidget {
//   @override
//   _OrderManagementPageState createState() => _OrderManagementPageState();
// }

// class _OrderManagementPageState extends State<OrderManagementPage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   //final FirebaseAuth _auth = FirebaseAuth.instance;
//   late Stream<List<app_models.Order>> _ordersStream;

//   @override
//   void initState() {
//     super.initState();
//     _ordersStream = _firestoreService.getOrders();
//   }

//   void _updateOrderStatus(String orderId, String status) async {
//     await _firestoreService.updateOrderStatus(orderId, status);
//   }

//   Future<void> _setDeliveryTime(app_models.Order order) async {
//     final DateTime now = DateTime.now().toUtc().subtract(Duration(hours: 5)); // Hora actual de Tacna, Perú (GMT-5)
//     final TimeOfDay? selectedTime = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.fromDateTime(now),
//     );

//     if (selectedTime != null) {
//       final DateTime endTime = DateTime(
//         now.year,
//         now.month,
//         now.day,
//         selectedTime.hour,
//         selectedTime.minute,
//       );
//       await _firestoreService.updateOrderStartTime(order.id, now);
//       await _firestoreService.updateOrderEndTime(order.id, endTime);
//       _updateOrderStatus(order.id, 'preparando');
//     }
//   }

//   void _completeOrder(app_models.Order order) async {
//     final DateTime now = DateTime.now().toUtc().subtract(Duration(hours: 5)); // Hora actual de Tacna, Perú (GMT-5)
//     await _firestoreService.updateOrderEndTime(order.id, now);
//     _updateOrderStatus(order.id, 'listo');
//   }

//   void _sendWhatsAppMessage(app_models.Order order, String driverPhone) async {
//   final message = _generateOrderDetailsMessage(order, driverPhone);
//   final url = 'https://wa.me/$driverPhone?text=${Uri.encodeComponent(message)}';

//   if (await canLaunch(url)) {
//     await launch(url);
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Datos enviados al driver')));
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir WhatsApp')));
//   }
// }

//   String _generateOrderDetailsMessage(app_models.Order order, String driverPhone) {
//   final StringBuffer message = StringBuffer();
//   final String customerName = order.nombresCompletos.isNotEmpty ? order.nombresCompletos : order.userPhone;

//   // Limpiar el número de teléfono para eliminar cualquier paréntesis, guión o espacio
//   String cleanPhoneNumber = order.userPhone.replaceAll(RegExp(r'[\(\)\-\s]'), '');
//   if (!cleanPhoneNumber.startsWith('51')) {
//     cleanPhoneNumber = '+51$cleanPhoneNumber';
//   } else {
//     cleanPhoneNumber = '+$cleanPhoneNumber';
//   }

//   message.writeln('Detalles del Pedido:');
//   message.writeln('Cliente: $customerName');
//   message.writeln('Dirección: ${order.userAddress}');
//   message.writeln('Teléfono: $cleanPhoneNumber');
//   message.writeln('Modalidad: ${order.modalidad}');
//   message.writeln('Método de Pago: ${order.metodoPago}');
//   message.writeln('Submétodo de Pago: ${order.subMetodoPago}');
//   if (order.monto != null) {
//     message.writeln('Monto a pagar: S/. ${order.monto}');
//     message.writeln('Cliente va a pagar con: S/. ${order.monto}');
//   }
//   message.writeln('Total: S/. ${order.totalPrice.toStringAsFixed(2)}');
//   message.writeln('Contacto Driver: $driverPhone');
//   if (order.latitud != null && order.longitud != null) {
//     final String mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${order.latitud},${order.longitud}';
//     message.writeln('Ubicación GPS: $mapsUrl');
//   }
//   message.writeln('Productos:');
//   for (var product in order.orderProducts) {
//     message.writeln('- ${product['productName']} (Tamaño: ${product['size']}) x${product['quantity']}');
//   }
//   if (order.notas.isNotEmpty) {
//     message.writeln('Notas: ${order.notas}');
//   }
//   return message.toString();
// }



//   Future<void> _updateDriverContact(String orderId, String driverPhone) async {
//     await _firestoreService.updateOrderDriverContact(orderId, driverPhone);
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gestión de Pedidos'),
//       ),
//       body: StreamBuilder<List<app_models.Order>>(
//         stream: _ordersStream,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text('Error al cargar los pedidos'));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No hay pedidos'));
//           }

//           final orders = snapshot.data!;
//           return ListView.builder(
//             itemCount: orders.length,
//             itemBuilder: (context, index) {
//               final order = orders[index];
//               return _buildOrderItem(order);
//             },
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildOrderItem(app_models.Order order) {
//     return FutureBuilder<Map<String, dynamic>?>(
//       future: _firestoreService.getUserInfoById(order.clientId),
//       builder: (context, userSnapshot) {
//         if (userSnapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (userSnapshot.hasError) {
//           return Center(child: Text('Error al cargar la información del usuario'));
//         } else if (!userSnapshot.hasData) {
//           return Center(child: Text('Usuario no encontrado'));
//         }

//         final userInfo = userSnapshot.data!;
//         Color itemColor;
//         switch (order.orderStatus) {
//           case 'confirmado':
//             itemColor = Colors.orange;
//             break;
//           case 'preparando':
//             itemColor = Colors.blue;
//             break;
//           case 'listo':
//             itemColor = Colors.green;
//             break;
//           case 'en camino':
//             itemColor = Colors.purple;
//             break;
//           case 'entregado':
//             itemColor = Colors.grey;
//             break;
//           default:
//             itemColor = Colors.grey[300]!;
//         }

//         return Card(
//           color: itemColor,
//           child: ExpansionTile(
//             title: Text('Pedido de ${order.nombresCompletos}'),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Correo: ${userInfo['correo']} (${userInfo['edad']} años)'),
//                 Text('Estado: ${order.orderStatus}'),
//                 if (order.startTime != null && order.endTime != null) ...[
//                   Text('Hora de inicio: ${DateFormat('HH:mm').format(order.startTime!)}'),
//                   Text('Hora final: ${DateFormat('HH:mm').format(order.endTime!)}'),
//                   StreamBuilder(
//                     stream: Stream.periodic(Duration(seconds: 1)),
//                     builder: (context, snapshot) {
//                       final remainingTime = _calculateRemainingTime(order.endTime!, order.id);
//                       return Text('Tiempo restante: $remainingTime');
//                     },
//                   ),
//                 ],
//                 if (userInfo['restricciones_nutricionales'] != null && userInfo['restricciones_nutricionales'].isNotEmpty)
//                   Text('Restricciones nutricionales: ${userInfo['restricciones_nutricionales']}'),
//               ],
//             ),
//             children: [
//               ListTile(
//                 title: Text('Dirección: ${order.userAddress}'),
//               ),
//               ListTile(
//                 title: Text('Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate)}'),
//                 subtitle: Text('Total: S/. ${order.totalPrice.toStringAsFixed(2)}'),
//               ),
//               ListTile(
//                 title: Text('Modalidad: ${order.modalidad}'),
//               ),
//               ListTile(
//                 title: Text('Teléfono de contacto: ${order.userPhone}'),
//               ),
//               ListTile(
//                 title: Text('Método de pago: ${order.metodoPago}'),
//                 subtitle: Text('Submétodo de pago: ${order.subMetodoPago}'),
//               ),
//               ListTile(
//                 title: Text('Cupón aplicado: ${order.couponCode}'),
//                 subtitle: Text('Descuento: ${order.discount}'),
//               ),
//               if (order.notas.isNotEmpty)
//                 ListTile(
//                   title: Text('Notas:'),
//                   subtitle: Text(order.notas),
//                 ),
//               if (order.latitud != null && order.longitud != null)
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ListTile(
//                       title: Text('Ubicación'),
//                     ),
//                     Container(
//                       height: 150,
//                       width: double.infinity,
//                       child: GoogleMap(
//                         initialCameraPosition: CameraPosition(
//                           target: LatLng(order.latitud!, order.longitud!),
//                           zoom: 15,
//                         ),
//                         markers: {
//                           Marker(
//                             markerId: MarkerId(order.id),
//                             position: LatLng(order.latitud!, order.longitud!),
//                           ),
//                         },
//                         liteModeEnabled: true,
//                       ),
//                     ),
//                   ],
//                 ),
//               ListTile(
//                 title: Text('Productos:'),
//                 subtitle: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: order.orderProducts.map((product) {
//                     var productName = product['productName'] ?? 'Producto desconocido';
//                     var size = product['size'] ?? 'Tamaño desconocido';
//                     var cantidad = product['quantity']?.toString() ?? 'Cantidad desconocida';
//                     var precio = product['price'] != null ? (product['price'] as double).toStringAsFixed(2) : '0.00';
//                     return ListTile(
//                       title: Text('$productName (Tamaño: $size)'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('Cantidad: $cantidad'),
//                           Text('Precio: S/. $precio'),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               if (order.fotopago != null)
//                 ListTile(
//                   title: Text('Comprobante de pago:'),
//                   subtitle: Image.network(order.fotopago!),
//                 ),
//               if (order.modalidad == 'Delivery') ...[
//                 ListTile(
//                   title: Row(
//                     children: [
//                       IconButton(
//                         icon: Icon(IconlyBold.send),
//                         onPressed: () {
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               String phoneNumber = '+51';
//                               return AlertDialog(
//                                 title: Text('Enviar detalles por WhatsApp'),
//                                 content: TextField(
//                                   onChanged: (value) {
//                                     phoneNumber = value;
//                                   },
//                                   keyboardType: TextInputType.phone,
//                                   decoration: InputDecoration(
//                                     hintText: 'Número de teléfono (+51...)',
//                                   ),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     child: Text('Cancelar'),
//                                     onPressed: () {
//                                       Navigator.of(context).pop();
//                                     },
//                                   ),
//                                   TextButton(
//                                     child: Text('Enviar'),
//                                     onPressed: () {
//                                       _sendWhatsAppMessage(order, phoneNumber);
//                                       _updateDriverContact(order.id, phoneNumber);
//                                       Navigator.of(context).pop();
//                                     },
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(IconlyBold.call),
//                         onPressed: () {
//                           launch('tel:${order.userPhone}');
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   if (order.orderStatus == 'pendiente') ...[
//                     IconButton(
//                       icon: Icon(Icons.check),
//                       onPressed: () async {
//                         _updateOrderStatus(order.id, 'confirmado');
//                         await _setDeliveryTime(order);
//                       },
//                     ),
//                     IconButton(
//                       icon: Icon(Icons.close),
//                       onPressed: () => _updateOrderStatus(order.id, 'cancelado'),
//                     ),
//                   ],
//                   if (order.orderStatus == 'preparando') ...[
//                     IconButton(
//                       icon: Icon(Icons.check),
//                       onPressed: () async {
//                         _completeOrder(order);
//                       },
//                     ),
//                   ],
//                   if (order.orderStatus == 'listo') ...[
//                     if (order.modalidad == 'Delivery')
//                       IconButton(
//                         icon: Icon(IconlyBold.profile),
//                         onPressed: () => _updateOrderStatus(order.id, 'en camino'),
//                       )
//                     else
//                       IconButton(
//                         icon: Icon(Icons.check_circle),
//                         onPressed: () => _updateOrderStatus(order.id, 'entregado'),
//                       ),
//                   ],
//                 ],
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   String _calculateRemainingTime(DateTime endTime, String orderId) {
//     final DateTime now = DateTime.now().toUtc().subtract(Duration(hours: 5)); // Hora actual de Tacna, Perú (GMT-5)
//     final Duration difference = endTime.difference(now);
//     if (difference.isNegative) {
//       _updateOrderStatus(orderId, 'listo');
//       return '0:00';
//     }
//     final String hours = difference.inHours.toString().padLeft(2, '0');
//     final String minutes = (difference.inMinutes % 60).toString().padLeft(2, '0');
//     final String seconds = (difference.inSeconds % 60).toString().padLeft(2, '0');
//     return '$hours:$minutes:$seconds';
//   }
// }
