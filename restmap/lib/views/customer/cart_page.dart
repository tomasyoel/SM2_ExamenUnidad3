// import 'package:restmap/models/order.dart' as app_models;
// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/views/customer/user_location_page.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';
// import 'customer_home_page.dart';

// class CartPage extends StatefulWidget {
//   final List<Map<String, dynamic>> orderProducts;

//   CartPage({required this.orderProducts});

//   @override
//   _CartPageState createState() => _CartPageState();
// }

// class _CartPageState extends State<CartPage> {
//   final FirestoreService firestoreService = FirestoreService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   double _totalPrice = 0.0;
//   double _realTotalPrice = 0.0;
//   String? _userAddress;
//   String? _userPhone;
//   String _couponCode = '';
//   double _discount = 0.0;
//   String _notes = '';
//   bool _isEditingNotes = false;
//   Map<String, dynamic>? _couponData;
//   String _modalidad = 'Delivery';
//   String _selectedCountryCode = '+51';
//   double? _latitude;
//   double? _longitude;
//   String _selectedPaymentMethod = 'ContraEntrega';
//   String _selectedSubPaymentMethod = 'Efectivo';
//   TextEditingController _phoneController = TextEditingController();
//   TextEditingController _notesController = TextEditingController();
//   TextEditingController _couponController = TextEditingController();
//   TextEditingController _montoController = TextEditingController();
//   bool _isMontoEditable = true;
//   bool _showPaymentMethods = false;

//   @override
//   void initState() {
//     super.initState();
//     _calculateTotalPrice();
//     _refreshUserDetails();
//   }

//   Future<void> _refreshUserDetails() async {
//     await _getCurrentUserAddress();
//     await _getCurrentUserPhone();
//     await _getCurrentUserLocation();
//   }

//   Future<void> _getCurrentUserAddress() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       var userData = await firestoreService.getUserById(user.uid);
//       setState(() {
//         _userAddress = userData['direccion'];
//       });

//       QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
//           .collection('usuarios')
//           .doc(user.uid)
//           .collection('direcciones')
//           .where('predeterminada', isEqualTo: true)
//           .limit(1)
//           .get();
//       if (addressSnapshot.docs.isNotEmpty) {
//         var defaultAddressDoc = addressSnapshot.docs.first;
//         setState(() {
//           _userAddress = defaultAddressDoc['direccion'];
//           _latitude = defaultAddressDoc['latitud'];
//           _longitude = defaultAddressDoc['longitud'];
//         });
//       } else {
//         setState(() {
//           _userAddress = 'Agrega una dirección...';
//           _latitude = null;
//           _longitude = null;
//         });
//       }
//     }
//   }

//   Future<void> _getCurrentUserPhone() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       var userData = await firestoreService.getUserById(user.uid);
//       setState(() {
//         _userPhone = userData['nro_celular'];
//       });
//     }
//   }

// Future<void> _getCurrentUserLocation() async {
//   User? user = _auth.currentUser;
//   if (user != null) {
//     List<Map<String, dynamic>> addresses = await firestoreService.getUserAddresses(user.uid);
//     Map<String, dynamic>? defaultAddress = addresses.firstWhere((address) => address['predeterminada'] == true, orElse: () => {});
//     if (defaultAddress.isNotEmpty) {
//       setState(() {
//         _latitude = defaultAddress['latitud'];
//         _longitude = defaultAddress['longitud'];
//       });
//     }
//   }
// }


//   void _calculateTotalPrice() {
//     _totalPrice = 0.0;
//     _realTotalPrice = 0.0;
//     for (var orderProduct in widget.orderProducts) {
//       _totalPrice += orderProduct['price'] * orderProduct['quantity'];
//       _realTotalPrice += orderProduct['price'] * orderProduct['quantity'];
//     }
//     _updateTotalPrice();
//   }

//   void _applyCoupon() async {
//     if (_couponCode.isEmpty) return;

//     var coupon = await firestoreService.getCouponByCode(_couponCode);
//     if (coupon != null && coupon['activo'] == true) {
//       setState(() {
//         _couponData = coupon;
//         _updateTotalPrice();
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('El cupón ingresado no existe o no es válido, ingrese uno válido'),
//         ),
//       );
//       _couponController.clear();
//     }
//   }

//   void _removeCoupon() {
//     setState(() {
//       _couponData = null;
//       _updateTotalPrice();
//     });
//   }

//   void _updateTotalPrice() {
//     setState(() {
//       if (_couponData != null) {
//         _discount = (_totalPrice * _couponData!['descuento']) / 100;
//         _totalPrice -= _discount;
//       } else {
//         _discount = 0.0;
//       }
//     });
//   }

//   void _incrementQuantity(int index, int stock) {
//     if (_getTotalQuantityForProduct(widget.orderProducts[index]['product'].id) < stock) {
//       setState(() {
//         widget.orderProducts[index]['quantity']++;
//         _calculateTotalPrice();
//       });
//     }
//   }

//   void _decrementQuantity(int index) {
//     if (widget.orderProducts[index]['quantity'] > 1) {
//       setState(() {
//         widget.orderProducts[index]['quantity']--;
//         _calculateTotalPrice();
//       });
//     } else {
//       setState(() {
//         widget.orderProducts.removeAt(index);
//         _calculateTotalPrice();
//       });
//     }
//   }

//   int _getTotalQuantityForProduct(String productId) {
//     return widget.orderProducts
//         .where((orderProduct) => orderProduct['product'].id == productId)
//         .fold<int>(0, (sum, orderProduct) => sum + (orderProduct['quantity'] as int));
//   }

//   Future<void> _checkAndShowPaymentMethods() async {
//     bool stockAvailable = await _checkStockAvailability();

//     if (!stockAvailable) {
//       _showOutOfStockMessage();
//       return;
//     }

//     setState(() {
//       _showPaymentMethods = true;
//     });
//   }

//   Future<bool> _checkStockAvailability() async {
//     for (var orderProduct in widget.orderProducts) {
//       var productData = await firestoreService.getProductById(orderProduct['product'].id);
//       if (productData == null || productData['stock'] < orderProduct['quantity']) {
//         return false;
//       }
//     }
//     return true;
//   }

//   void _showOutOfStockMessage() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Stock Insuficiente'),
//         content: Text(
//             'Lo siento, al parecer alguien más compró uno o más de los productos que seleccionaste y se agotó por el día de hoy.'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 widget.orderProducts.clear();
//               });
//               Navigator.pop(context);
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => CustomerHomePage()),
//               );
//             },
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _createOrder() async {
//     bool stockAvailable = await _checkStockAvailability();

//     if (!stockAvailable) {
//       _showOutOfStockMessage();
//       return;
//     }

//     User? user = _auth.currentUser;
//     if (user != null) {
//       String currentUserId = user.uid;

//       app_models.Order order = app_models.Order(
//         id: firestoreService.generateOrderId(),
//         clientId: currentUserId,
//         totalPrice: _totalPrice,
//         orderStatus: 'pendiente',
//         orderDate: DateTime.now(),
//         notas: _notes,
//         modalidad: _modalidad,
//         userAddress: _userAddress ?? '',
//         userPhone: _userPhone ?? '',
//         couponCode: _couponData != null ? _couponCode : '', // No guardar el cupón si no se aplica
//         discount: _discount,
//         latitud: _latitude,
//         longitud: _longitude,
//         orderProducts: widget.orderProducts.map((product) => {
//           'productId': product['product'].id,
//           'productName': product['productName'], // Incluir el nombre del producto
//           'size': product['size'], // Incluir el tamaño del producto
//           'quantity': product['quantity'],
//           'price': product['price'],
//           'imageUrl': product['imageUrl'],
//           'stock': product['stock'],
//         }).toList(),
//         metodoPago: _selectedPaymentMethod,
//         subMetodoPago: _selectedSubPaymentMethod == 'Efectivo'
//             ? 'Efectivo'
//             : 'Pago QR Yape/Plin',
//         monto: _selectedSubPaymentMethod == 'Efectivo'
//             ? double.parse(_montoController.text)
//             : null,
//         fotopago: _selectedPaymentMethod == 'Pago Online' ? "" : null,
//         nombresCompletos: "",
//       );

//       await firestoreService.addOrder(order);

//       for (var orderProduct in widget.orderProducts) {
//         await _updateProductStock(orderProduct['product'].id, orderProduct['quantity']);
//       }

//       // Actualizar el estado del cupón
//       if (_couponData != null) {
//         await firestoreService.updateCouponStatus(_couponData!['id'], false);
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Pedido Exitoso puede ver el estado de su pedido en Mis Pedidos')),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => CustomerHomePage()),
//       );
//     }
//   }

//   Future<void> _updateProductStock(String productId, int quantityOrdered) async {
//     var productData = await firestoreService.getProductById(productId);
//     if (productData != null) {
//       int newStock = productData['stock'] - quantityOrdered;
//       await firestoreService.updateProduct(productId, {'stock': newStock});
//       if (newStock <= 0) {
//         await firestoreService.updateProduct(productId, {'estado': 'Agotado'});
//       } else {
//         await firestoreService.updateProduct(productId, {'estado': 'Disponible'});
//       }
//     }
//   }

//   Future<void> _updateUserPhone() async {
//     User? user = _auth.currentUser;
//     if (user != null && _userPhone != null && _userPhone!.isNotEmpty) {
//       await firestoreService.updateUser(user.uid, {'nro_celular': _userPhone});
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Número de teléfono actualizado')),
//       );
//       setState(() {
//         _getCurrentUserPhone();
//         _phoneController.clear();
//       });
//     }
//   }

//   Future<void> _refreshAddress() async {
//     await _getCurrentUserAddress();
//   }

//   void _toggleMontoEdit() {
//     setState(() {
//       _isMontoEditable = !_isMontoEditable;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detalle de Pedido'),
//         centerTitle: true,
//       ),
//       body: widget.orderProducts.isEmpty
//           ? Center(child: Text('No tienes productos agregados al carrito'))
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (!_showPaymentMethods) ...[
//                     Text('Modalidad',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                     ToggleButtons(
//                       isSelected: [
//                         _modalidad == 'Delivery',
//                         _modalidad == 'Recojo en Tienda'
//                       ],
//                       onPressed: (int index) {
//                         setState(() {
//                           _modalidad = index == 0 ? 'Delivery' : 'Recojo en Tienda';
//                           if (_modalidad == 'Recojo en Tienda') {
//                             _selectedPaymentMethod = 'ContraEntrega';
//                             _selectedSubPaymentMethod = 'Efectivo';
//                           }
//                         });
//                       },
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                           child: Text('Delivery'),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                           child: Text('Recojo en Tienda'),
//                         ),
//                       ],
//                       borderRadius: BorderRadius.circular(8.0),
//                       fillColor: Colors.orange,
//                       selectedColor: Colors.white,
//                       color: Colors.black,
//                     ),
//                     SizedBox(height: 16),
//                     if (_modalidad == 'Delivery') ...[
//                       Text(
//                         'Delivery Dirección',
//                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                       ),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Text(_userAddress ?? 'Cargando dirección...'),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () async {
//                               await Navigator.push(
//                                 context,
//                                 MaterialPageRoute(
//                                   builder: (context) => UserLocationPage(
//                                     // userId: _auth.currentUser!.uid,
//                                   ),
//                                 ),
//                               );
//                               await _refreshAddress();
//                             },
//                             icon: Icon(IconlyLight.edit),
//                             label: Text('Editar Dirección'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.orange,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                     SizedBox(height: 16),
//                     Text(
//                       'Teléfono',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     Text(_userPhone ?? '-------------'),
//                     SizedBox(height: 8),
//                     Row(
//                       children: [
//                         SizedBox(
//                           width: 80,
//                           child: CountryCodePicker(
//                             onChanged: (countryCode) {
//                               _selectedCountryCode = countryCode.dialCode!;
//                             },
//                             initialSelection: 'PE',
//                             favorite: ['+51', 'PE'],
//                             showCountryOnly: false,
//                             showOnlyCountryWhenClosed: false,
//                             alignLeft: false,
//                             showFlag: false,
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: TextField(
//                             controller: _phoneController,
//                             keyboardType: TextInputType.phone,
//                             decoration: InputDecoration(
//                               hintText: 'Ingrese su teléfono',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                             onChanged: (value) {
//                               _userPhone = '$_selectedCountryCode$value';
//                             },
//                           ),
//                         ),
//                         SizedBox(width: 8),
//                         ElevatedButton(
//                           onPressed: _updateUserPhone,
//                           child: Text('Guardar'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.orange,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'Notas',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     if (_isEditingNotes)
//                       Column(
//                         children: [
//                           TextField(
//                             controller: _notesController,
//                             maxLength: 500,
//                             maxLines: 3,
//                             decoration: InputDecoration(
//                               hintText: 'Añadir Notas',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           ElevatedButton(
//                             onPressed: () {
//                               setState(() {
//                                 _notes = _notesController.text;
//                                 _isEditingNotes = false;
//                               });
//                             },
//                             child: Text('Listo'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.grey,
//                             ),
//                           ),
//                         ],
//                       )
//                     else
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Expanded(
//                             child: Text(
//                               _notes.isEmpty ? '---------' : _notes,
//                               style: TextStyle(fontSize: 16),
//                             ),
//                           ),
//                           ElevatedButton.icon(
//                             onPressed: () {
//                               setState(() {
//                                 _isEditingNotes = true;
//                                 _notesController.text = _notes;
//                               });
//                             },
//                             icon: Icon(Icons.edit),
//                             label: Text('Añadir Nota'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.orange,
//                             ),
//                           ),
//                         ],
//                       ),
//                     SizedBox(height: 16),
//                     ...widget.orderProducts.map((orderProduct) {
//                       return Column(
//                         children: [
//                           Row(
//                             children: [
//                               orderProduct['imageUrl'] != null
//                                   ? Image.network(
//                                       orderProduct['imageUrl'],
//                                       height: 50,
//                                       width: 50,
//                                       fit: BoxFit.cover,
//                                     )
//                                   : Icon(Icons.image_not_supported),
//                               SizedBox(width: 16),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       orderProduct['product'].name,
//                                       style: TextStyle(fontSize: 18),
//                                       overflow: TextOverflow.visible,
//                                     ),
//                                     Text('Belihanpiy',
//                                         style: TextStyle(color: Colors.grey)),
//                                     Text(
//                                       'S/.${orderProduct['price'].toStringAsFixed(2)}',
//                                       style: TextStyle(color: Colors.black),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               Spacer(),
//                               Row(
//                                 children: [
//                                   IconButton(
//                                     onPressed: () => _decrementQuantity(widget.orderProducts.indexOf(orderProduct)),
//                                     icon: orderProduct['quantity'] > 1 
//                                         ? Icon(Icons.remove) 
//                                         : Icon(Icons.delete, color: Colors.red),
//                                   ),
//                                   Text('${orderProduct['quantity']}'),
//                                   IconButton(
//                                     onPressed: () => _incrementQuantity(widget.orderProducts.indexOf(orderProduct), orderProduct['stock']),
//                                     icon: Icon(Icons.add),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                           Divider(),
//                         ],
//                       );
//                     }).toList(),
//                     SizedBox(height: 16),
//                     _couponData != null
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(IconlyLight.discount),
//                                   SizedBox(width: 8),
//                                   Text('Descuento aplicado'),
//                                 ],
//                               ),
//                               TextButton(
//                                 onPressed: _removeCoupon,
//                                 child: Text('Quitar Cupón'),
//                               ),
//                             ],
//                           )
//                         : Row(
//                             children: [
//                               Expanded(
//                                 child: TextField(
//                                   controller: _couponController,
//                                   onChanged: (value) {
//                                     setState(() {
//                                       _couponCode = value;
//                                     });
//                                   },
//                                   decoration: InputDecoration(
//                                     hintText: 'Código de Cupón',
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(12),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               SizedBox(width: 8),
//                               ElevatedButton(
//                                 onPressed: _applyCoupon,
//                                 child: Text('Aplicar Cupón'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.orange,
//                                 ),
//                               ),
//                             ],
//                           ),
//                     SizedBox(height: 16),
//                     Text(
//                       'Resumen de Pagos',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     ListTile(
//                       title: Text('Precios'),
//                       trailing: Text('S/.${_realTotalPrice.toStringAsFixed(2)}'),
//                     ),
//                     ListTile(
//                       title: Text('Descuento Aplicado'),
//                       trailing: Text('S/.${_discount.toStringAsFixed(2)}'),
//                     ),
//                     ListTile(
//                       title: Text('Pago Total'),
//                       trailing: Text('S/.${_totalPrice.toStringAsFixed(2)}'),
//                     ),
//                     SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _checkAndShowPaymentMethods,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(IconlyLight.wallet),
//                           SizedBox(width: 8),
//                           Text('Pagar'),
//                         ],
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         minimumSize: Size(double.infinity, 50),
//                       ),
//                     ),
//                   ] else ...[
//                     Text(
//                       'Método de Pago',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                     ToggleButtons(
//                       isSelected: [
//                         _selectedPaymentMethod == 'ContraEntrega',
//                         _selectedPaymentMethod == 'Pago Online'
//                       ],
//                       onPressed: (int index) {
//                         setState(() {
//                           _selectedPaymentMethod =
//                               index == 0 ? 'ContraEntrega' : 'Pago Online';
//                           if (_selectedPaymentMethod == 'ContraEntrega') {
//                             _selectedSubPaymentMethod = 'Efectivo';
//                           } else {
//                             _selectedSubPaymentMethod = 'Pago QR Yape/Plin';
//                           }
//                         });
//                       },
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                           child: Text('ContraEntrega'),
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                           child: Text('Pago Online'),
//                         ),
//                       ],
//                       borderRadius: BorderRadius.circular(8.0),
//                       fillColor: Colors.orange,
//                       selectedColor: Colors.white,
//                       color: Colors.black,
//                     ),
//                     SizedBox(height: 16),
//                     if (_selectedPaymentMethod == 'ContraEntrega') ...[
//                       if (_modalidad == 'Delivery') ...[
//                         ToggleButtons(
//                           isSelected: [
//                             _selectedSubPaymentMethod == 'Efectivo',
//                             _selectedSubPaymentMethod == 'Pago QR Yape/Plin'
//                           ],
//                           onPressed: (int index) {
//                             setState(() {
//                               _selectedSubPaymentMethod = index == 0
//                                   ? 'Efectivo'
//                                   : 'Pago QR Yape/Plin';
//                             });
//                           },
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                               child: Text('Efectivo'),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                               child: Text('Pago QR Yape/Plin'),
//                             ),
//                           ],
//                           borderRadius: BorderRadius.circular(8.0),
//                           fillColor: Colors.orange,
//                           selectedColor: Colors.white,
//                           color: Colors.black,
//                         ),
//                       ],
//                       if (_modalidad == 'Recojo en Tienda') ...[
//                         ToggleButtons(
//                           isSelected: [
//                             _selectedSubPaymentMethod == 'Efectivo',
//                           ],
//                           onPressed: (int index) {
//                             setState(() {
//                               _selectedSubPaymentMethod = 'Efectivo';
//                             });
//                           },
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                               child: Text('Efectivo'),
//                             ),
//                           ],
//                           borderRadius: BorderRadius.circular(8.0),
//                           fillColor: Colors.orange,
//                           selectedColor: Colors.white,
//                           color: Colors.black,
//                         ),
//                       ],
//                       if (_selectedSubPaymentMethod == 'Efectivo') ...[
//                         if (_isMontoEditable)
//                           TextField(
//                             controller: _montoController,
//                             keyboardType: TextInputType.number,
//                             decoration: InputDecoration(
//                               hintText: 'Ingrese el monto',
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                             ),
//                           )
//                         else
//                           Text(
//                             'Monto: S/.${_montoController.text}',
//                             style: TextStyle(fontSize: 16),
//                           ),
//                         SizedBox(height: 8),
//                         ElevatedButton(
//                           onPressed: _isMontoEditable
//                               ? () {
//                                   double monto = double.parse(_montoController.text);
//                                   if (monto <= _totalPrice) {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text('El monto debe ser superior al pago total'),
//                                         backgroundColor: Colors.red,
//                                       ),
//                                     );
//                                   } else {
//                                     setState(() {
//                                       _isMontoEditable = false;
//                                     });
//                                   }
//                                 }
//                               : _toggleMontoEdit,
//                           child: Text(_isMontoEditable ? 'Guardar' : 'Editar Monto'),
//                         ),
//                       ],
//                     ] else if (_selectedPaymentMethod == 'Pago Online') ...[
//                       Container(
//                         height: 600,
//                         width: double.infinity,
//                         child: Center(
//                           child: Text(
//                             'Yapear al QR una vez realizado el pedido en mis pedidos revisar su pedido y adjuntar su captura para confirmar y proceder a preparar su pedido',
//                             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                             textAlign: TextAlign.center,
//                           ),
//                         ),
//                       ),
//                     ],
//                     SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _createOrder,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(IconlyLight.wallet),
//                           SizedBox(width: 8),
//                           Text('Ordenar'),
//                         ],
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         minimumSize: Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//     );
//   }
// }
