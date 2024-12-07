// import 'package:restmap/models/order.dart' as app_models;
// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Future<void> addProduct(Map<String, dynamic> productData) async {
  //   try {
  //     await _db.collection('productos').add(productData);
  //     print("Producto agregado exitosamente");
  //   } catch (e) {
  //     print("Error al agregar el producto: $e");
  //     throw e;
  //   }
  // }

  Future<void> updateUser(String id, Map<String, dynamic> userData) async {
    try {
      await _db.collection('usuarios').doc(id).update(userData);
      //print("Perfil actualizado exitosamente");
    } catch (e) {
      //print("Error al actualizar el perfil: $e");
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserById(String id) async {
    return await _db.collection('usuarios').doc(id).get();
  }

  Future<String?> obtenerVersionMinima() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('version')
          .doc('n4gJAQPr09uWNTFKaMOP')
          .get();
      if (doc.exists) {
        return doc['versionmin'];
      }
      return null;
    } catch (e) {
      //print('Error al obtener la versión mínima: $e');
      return null;
    }
  }

  // Future<void> updateProduct(String id, Map<String, dynamic> productData) async {
  //   await _db.collection('productos').doc(id).update(productData);
  // }

  // Future<void> deleteProduct(String id) async {
  //   await _db.collection('productos').doc(id).delete();
  // }

  // Future<void> deleteProductWithImage(String id, String imageUrl) async {
  //   try {
  //     await deleteProduct(id);
  //     await _storage.refFromURL(imageUrl).delete();
  //     print("Producto y su imagen eliminados exitosamente");
  //   } catch (e) {
  //     print("Error al eliminar el producto y su imagen: $e");
  //     throw e;
  //   }
  // }

  // Stream<List<Map<String, dynamic>>> getProducts() {
  //   return _db.collection('productos').snapshots().map((snapshot) => snapshot
  //       .docs
  //       .map((doc) => {...doc.data(), 'id': doc.id} as Map<String, dynamic>)
  //       .toList());
  // }

  // Future<DocumentSnapshot> getProductTypeById(String id) async {
  //   return await _db.collection('tipoproducto').doc(id).get();
  // }

  // Future<void> addUser(Map<String, dynamic> userData) async {
  //   try {
  //     await _db.collection('usuarios').doc(userData['uid']).set(userData);
  //     print("Usuario agregado exitosamente");
  //   } catch (e) {
  //     print("Error al agregar el usuario: $e");
  //     throw e;
  //   }
  // }

  // Future<void> deleteAdmin(String userId) async {
  //   try {
  //     await _db.collection('usuarios').doc(userId).delete();
  //     await FirebaseAuth.instance.currentUser!.delete();
  //     print("Administrador eliminado exitosamente");
  //   } catch (e) {
  //     print("Error al eliminar el supervisor: $e");
  //     throw e;
  //   }
  // }

  // Future<void> updateOrder(String id, Map<String, dynamic> orderData) async {
  //   await _db.collection('pedidos').doc(id).update(orderData);
  // }

  // Future<bool> checkAdminExists() async {
  //   final querySnapshot = await _db
  //       .collection('usuarios')
  //       .where('rol', isEqualTo: 'administrador')
  //       .limit(1)
  //       .get();
  //   return querySnapshot.docs.isNotEmpty;
  // }

  // Future<void> updateApprovalStatus(String userId, bool isApproved) async {
  //   try {
  //     await _db
  //         .collection('usuarios')
  //         .doc(userId)
  //         .update({'approved': isApproved});
  //     print("Estado de aprobación actualizado exitosamente");
  //   } catch (e) {
  //     print("Error al actualizar el estado de aprobación: $e");
  //     throw e;
  //   }
  // }

  // Future<void> addCoupon(String code, int discount) {
  //   return _db.collection('cupones').add({
  //     'codigo': code,
  //     'descuento': discount,
  //     'activo': true,
  //   });
  // }

  // Future<void> updateCoupon(String id, String code, int discount, bool isActive) {
  //   return _db.collection('cupones').doc(id).update({
  //     'codigo': code,
  //     'descuento': discount,
  //     'activo': isActive,
  //   });
  // }

  // Future<void> deleteCoupon(String id) {
  //   return _db.collection('cupones').doc(id).delete();
  // }

  // Future<List<Map<String, dynamic>>> getAssignedOrders(String driverId) async {
  //   try {
  //     QuerySnapshot snapshot = await _db
  //         .collection('pedidos')
  //         .where('driverId', isEqualTo: driverId)
  //         .get();
  //     return snapshot.docs
  //         .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
  //         .toList();
  //   } catch (e) {
  //     print("Error al obtener los pedidos asignados: $e");
  //     throw e;
  //   }
  // }

  // Future<void> addPublicity(Map<String, dynamic> publicityData) async {
  //   try {
  //     await _db.collection('publicidad').add(publicityData);
  //   } catch (e) {
  //     print('Error adding publicity: $e');
  //     rethrow;
  //   }
  // }

  // Future<void> updatePublicity(String id, Map<String, dynamic> data) async {
  //   try {
  //     await _db.collection('publicidad').doc(id).update(data);
  //   } catch (e) {
  //     print('Error updating publicity: $e');
  //     rethrow;
  //   }
  // }

  // Future<void> deletePublicity(String id) async {
  //   try {
  //     await _db.collection('publicidad').doc(id).delete();
  //   } catch (e) {
  //     print('Error deleting publicity: $e');
  //     rethrow;
  //   }
  // }

  // Stream<List<Map<String, dynamic>>> getPublicities() {
  //   return _db.collection('publicidad').snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       var data = doc.data() as Map<String, dynamic>;
  //       data['id'] = doc.id;
  //       return data;
  //     }).toList();
  //   });
  // }

  // Future<void> addYapePlinImage(Map<String, dynamic> yapePlinData) async {
  //   await _db.collection('yapeplin').add(yapePlinData);
  // }

  // Future<void> updateYapePlinImage(String id, Map<String, dynamic> yapePlinData) async {
  //   await _db.collection('yapeplin').doc(id).update(yapePlinData);
  // }

  // Future<void> deleteYapePlinImage(String id) async {
  //   await _db.collection('yapeplin').doc(id).delete();
  // }

  // Stream<List<Map<String, dynamic>>> getYapePlinImages() {
  //   return _db.collection('yapeplin').snapshots().map((snapshot) {
  //     return snapshot.docs.map((doc) {
  //       var data = doc.data() as Map<String, dynamic>;
  //       data['id'] = doc.id;
  //       return data;
  //     }).toList();
  //   });
  // }

// Future<Map<String, dynamic>?> getActiveYapePlinImage() async {
//   QuerySnapshot snapshot = await _db
//       .collection('yapeplin')
//       .where('isActive', isEqualTo: true)
//       .limit(1)
//       .get();

//   if (snapshot.docs.isNotEmpty) {
//     var data = snapshot.docs.first.data() as Map<String, dynamic>;

//     String imageUrl = await _storage.ref('yapeplinimage/${data['imageUrl']}').getDownloadURL();
//     data['imageUrl'] = imageUrl;
//     return data;
//   } else {
//     return null;
//   }
// }

  // Future<void> addOrder(app_models.Order order) async {
  //   try {
  //     await _db.collection('pedidos').doc(order.id).set(order.toMap());
  //     print("Pedido agregado exitosamente");
  //   } catch (e) {
  //     print("Error al agregar el pedido: $e");
  //     throw e;
  //   }
  // }

  // String generateOrderId() {
  //   return _db.collection('pedidos').doc().id;
  // }

  // Stream<List<app_models.Order>> getUserOrders(String userId) {
  //   return _db
  //       .collection('pedidos')
  //       .where('clientId', isEqualTo: userId)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //           .map((doc) =>
  //               app_models.Order.fromMap(doc.data() as Map<String, dynamic>))
  //           .toList());
  // }

  // Future<Map<String, dynamic>?> getCouponByCode(String code) async {
  //   var snapshot = await FirebaseFirestore.instance
  //       .collection('cupones')
  //       .where('codigo', isEqualTo: code)
  //       .limit(1)
  //       .get();
  //   if (snapshot.docs.isNotEmpty) {
  //     return {
  //       'id': snapshot.docs.first.id,
  //       'descuento': snapshot.docs.first['descuento'],
  //       'activo': snapshot.docs.first['activo']
  //     };
  //   }
  //   return null;
  // }

  // Future<void> updateCouponStatus(String couponId, bool isActive) async {
  //   await FirebaseFirestore.instance
  //       .collection('cupones')
  //       .doc(couponId)
  //       .update({'activo': isActive});
  // }

  // Future<Map<String, dynamic>?> getProductById(String id) async {
  //   var doc = await _db.collection('productos').doc(id).get();
  //   return doc.exists ? doc.data() as Map<String, dynamic>? : null;
  // }

  // Stream<DocumentSnapshot> streamProductById(String id) {
  //   return _db.collection('productos').doc(id).snapshots();
  // }

  //   Future<String> getProductNameById(String id) async {
  //   var doc = await _db.collection('productos').doc(id).get();
  //   return doc.exists ? (doc.data()?['nombre'] ?? '0001') : '0001';
  // }

  // Future<List<Map<String, dynamic>>> getUserAddresses(String userId) async {
  //   var snapshot = await _db
  //       .collection('usuarios')
  //       .doc(userId)
  //       .collection('direcciones')
  //       .get();
  //   return snapshot.docs
  //       .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
  //       .toList();
  // }

  // void updateMiPagoYapePlin(mipago, Map<String, bool> map) {}

  // Stream<List<app_models.Order>> getOrders() {
  //   return _db
  //       .collection('pedidos')
  //       .orderBy('orderDate', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs
  //           .map((doc) => app_models.Order.fromMap(doc.data()))
  //           .toList());
  // }

  // Future<void> updateOrderStatus(String orderId, String status) async {
  //   await _db.collection('pedidos').doc(orderId).update({
  //     'orderStatus': status,
  //   });
  // }

  // Future<void> updateOrderStartTime(String orderId, DateTime startTime) async {
  //   await _db.collection('pedidos').doc(orderId).update({'startTime': startTime});
  // }

  //   Future<void> updateOrderEndTime(String orderId, DateTime endTime) async {
  //   await _db.collection('pedidos').doc(orderId).update({'endTime': endTime});
  // }

  //   Future<void> updateDriverApproval(String userId, bool isApproved) async {
  //   await _db.collection('usuarios').doc(userId).update({'approved': isApproved});
  // }

  // Future<Map<String, dynamic>?> getUserInfoById(String userId) async {
  // DocumentSnapshot userDoc = await _db.collection('usuarios').doc(userId).get();
  // return userDoc.exists ? userDoc.data() as Map<String, dynamic>? : null;
  // }

  // Método para obtener la información del usuario
  // Future<Map<String, dynamic>?> getUserInfoById(String userId) async {
  //   try {
  //     DocumentSnapshot userDoc = await _db.collection('usuarios').doc(userId).get();
  //     if (userDoc.exists) {
  //       return userDoc.data() as Map<String, dynamic>?;
  //     }
  //     return null;
  //   } catch (e) {
  //     print(e);
  //     return null;
  //   }
  // }

  // Future<void> saveCoupon(String userId, String couponMessage) async {
  //   await _db.collection('usuarios').doc(userId).collection('cupones').add({
  //     'mensaje': couponMessage,
  //     'timestamp': FieldValue.serverTimestamp(),
  //   });
  // }

  //   Future<void> updateOrderDriverContact(String orderId, String driverPhone) {
  //   return _db.collection('pedidos').doc(orderId).update({'driverContact': driverPhone});
  // }
}
