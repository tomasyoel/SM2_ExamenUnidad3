// import 'package:cloud_firestore/cloud_firestore.dart';

// class Order {
//   final String id;
//   final String clientId;
//   final List<Map<String, dynamic>> orderProducts;
//   final double totalPrice;
//   final String orderStatus;
//   final DateTime orderDate;
//   final String notas;
//   final String modalidad;
//   final String userAddress;
//   final String userPhone;
//   final String? couponCode;
//   final double? discount;
//   final double? latitud;
//   final double? longitud;
//   final String metodoPago;
//   final String subMetodoPago;
//   final double? monto;
//   final String nombresCompletos;
//   final String? fotopago;
//   final DateTime? deliveryTime;
//   final DateTime? startTime;
//   final DateTime? endTime;

//   Order({
//     required this.id,
//     required this.clientId,
//     required this.orderProducts,
//     required this.totalPrice,
//     required this.orderStatus,
//     required this.orderDate,
//     required this.notas,
//     required this.modalidad,
//     required this.userAddress,
//     required this.userPhone,
//     this.couponCode,
//     this.discount,
//     this.latitud,
//     this.longitud,
//     required this.metodoPago,
//     required this.subMetodoPago,
//     this.monto,
//     required this.nombresCompletos,
//     this.fotopago,
//     this.deliveryTime,
//     this.startTime,
//     this.endTime,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'clientId': clientId,
//       'orderProducts': orderProducts,
//       'totalPrice': totalPrice,
//       'orderStatus': orderStatus,
//       'orderDate': orderDate,
//       'notas': notas,
//       'modalidad': modalidad,
//       'userAddress': userAddress,
//       'userPhone': userPhone,
//       'couponCode': couponCode,
//       'discount': discount,
//       'latitud': latitud,
//       'longitud': longitud,
//       'metodoPago': metodoPago,
//       'subMetodoPago': subMetodoPago,
//       'monto': monto,
//       'nombresCompletos': nombresCompletos,
//       'fotopago': fotopago,
//       'deliveryTime': deliveryTime,
//       'startTime': startTime,
//       'endTime': endTime,
//     };
//   }

//   factory Order.fromMap(Map<String, dynamic> map) {
//     return Order(
//       id: map['id'],
//       clientId: map['clientId'],
//       orderProducts: List<Map<String, dynamic>>.from(map['orderProducts']),
//       totalPrice: (map['totalPrice'] is int) ? (map['totalPrice'] as int).toDouble() : map['totalPrice'],
//       orderStatus: map['orderStatus'],
//       orderDate: (map['orderDate'] as Timestamp).toDate(),
//       notas: map['notas'] ?? '',
//       modalidad: map['modalidad'],
//       userAddress: map['userAddress'] ?? '',
//       userPhone: map['userPhone'] ?? '',
//       couponCode: map['couponCode'],
//       discount: (map['discount'] is int) ? (map['discount'] as int).toDouble() : map['discount'],
//       latitud: (map['latitud'] is int) ? (map['latitud'] as int).toDouble() : map['latitud'],
//       longitud: (map['longitud'] is int) ? (map['longitud'] as int).toDouble() : map['longitud'],
//       metodoPago: map['metodoPago'],
//       subMetodoPago: map['subMetodoPago'],
//       monto: (map['monto'] is int) ? (map['monto'] as int).toDouble() : map['monto'],
//       nombresCompletos: map['nombresCompletos'] ?? '',
//       fotopago: map['fotopago'],
//       deliveryTime: (map['deliveryTime'] as Timestamp?)?.toDate(),
//       startTime: (map['startTime'] as Timestamp?)?.toDate(),
//       endTime: (map['endTime'] as Timestamp?)?.toDate(),
//     );
//   }
// }