// import 'package:belihanpiyapp2/models/order.dart' as app_models;
// import 'package:belihanpiyapp2/services/firestore_service.dart';
// import 'package:belihanpiyapp2/views/customer/user_location_page.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';

// import 'customer_home_page.dart'; // Importa CustomerHomePage

// class CreateOrderPage extends StatefulWidget {
//   final List<Map<String, dynamic>> orderProducts;

//   CreateOrderPage({
//     required this.orderProducts,
//   });

//   @override
//   _CreateOrderPageState createState() => _CreateOrderPageState();
// }

// class _CreateOrderPageState extends State<CreateOrderPage> {
//   final FirestoreService firestoreService = FirestoreService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   double _totalPrice = 0.0;
//   String? _userAddress;
//   String? _userPhone;
//   String _couponCode = '';
//   double _discount = 0.0;
//   String _notes = '';
//   bool _isEditingNotes = false;
//   Map<String, dynamic>? _couponData;
//   String _modalidad = 'Delivery';
//   String _selectedCountryCode = '+51'; // Default country code for Peru
//   double? _latitude; // Nuevo campo
//   double? _longitude; // Nuevo campo

//   TextEditingController _phoneController = TextEditingController();
//   TextEditingController _notesController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _calculateTotalPrice();
//     _getCurrentUserAddress();
//     _getCurrentUserPhone();
//     _getCurrentUserLocation(); // Obtener la ubicación del usuario
//   }

//   Future<void> _getCurrentUserAddress() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       var userData = await firestoreService.getUserById(user.uid);
//       setState(() {
//         _userAddress = userData['direccion'];
//       });

//       // Obtener la dirección predeterminada
//       QuerySnapshot addressSnapshot = await FirebaseFirestore.instance
//           .collection('usuarios')
//           .doc(user.uid)
//           .collection('direcciones')
//           .where('predeterminada', isEqualTo: true)
//           .limit(1)
//           .get();
//       String defaultAddress = addressSnapshot.docs.isNotEmpty
//           ? addressSnapshot.docs.first['direccion']
//           : '----------';

//       setState(() {
//         _userAddress = defaultAddress;
//       });
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

//   Future<void> _getCurrentUserLocation() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       var userData = await firestoreService.getUserById(user.uid);
//       setState(() {
//         _latitude = userData['latitud'];
//         _longitude = userData['longitud'];
//       });
//     }
//   }

//   void _calculateTotalPrice() {
//     _totalPrice = 0.0;
//     for (var orderProduct in widget.orderProducts) {
//       _totalPrice += orderProduct['price'] * orderProduct['quantity'];
//     }
//     _updateTotalPrice();
//   }

//   void _applyCoupon() async {
//     if (_couponCode.isEmpty) return;

//     var coupon = await firestoreService.getCouponByCode(_couponCode);
//     if (coupon != null) {
//       setState(() {
//         _couponData = coupon;
//         _updateTotalPrice();
//       });
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
//     if (widget.orderProducts[index]['quantity'] < stock) {
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
//     }
//   }

//   Future<void> _createOrder() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       String currentUserId = user.uid;

//       // Crear el pedido principal
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
//         couponCode: _couponCode,
//         discount: _discount,
//         latitud: _latitude,
//         longitud: _longitude,
//         orderProducts: widget.orderProducts,
//       );

//       await firestoreService.addOrder(order);

//       // Agregar los productos como subcolección
//       for (var orderProduct in widget.orderProducts) {
//         await firestoreService.addProductToOrder(
//           order.id,
//           orderProduct['product'].id!,
//           orderProduct['quantity'],
//           orderProduct['price'],
//           orderProduct['imageUrl'],
//           orderProduct['stock'],
//         );
//         await _updateProductStock(orderProduct['product'].id!, orderProduct['quantity']);
//       }

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

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detalle de Pedido'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Modalidad',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             ToggleButtons(
//               isSelected: [
//                 _modalidad == 'Delivery',
//                 _modalidad == 'Recojo en Tienda'
//               ],
//               onPressed: (int index) {
//                 setState(() {
//                   _modalidad = index == 0 ? 'Delivery' : 'Recojo en Tienda';
//                 });
//               },
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                   child: Text('Delivery'),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20.0),
//                   child: Text('Recojo en Tienda'),
//                 ),
//               ],
//               borderRadius: BorderRadius.circular(8.0),
//               fillColor: Colors.orange,
//               selectedColor: Colors.white,
//               color: Colors.black,
//             ),
//             SizedBox(height: 16),
//             if (_modalidad == 'Delivery') ...[
//               Text(
//                 'Delivery Dirección',
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(_userAddress ?? 'Cargando dirección...'),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () async {
//                       await Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => UserLocationPage(
//                             userId: _auth.currentUser!.uid,
//                           ),
//                         ),
//                       );
//                       await _refreshAddress();
//                     },
//                     icon: Icon(IconlyLight.edit),
//                     label: Text('Editar Dirección'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//             SizedBox(height: 16),
//             Text(
//               'Teléfono',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             Text(_userPhone ?? '-------------'),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 SizedBox(
//                   width: 80,
//                   child: CountryCodePicker(
//                     onChanged: (countryCode) {
//                       _selectedCountryCode = countryCode.dialCode!;
//                     },
//                     initialSelection: 'PE',
//                     favorite: ['+51', 'PE'],
//                     showCountryOnly: false,
//                     showOnlyCountryWhenClosed: false,
//                     alignLeft: false,
//                     showFlag: false,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: TextField(
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     decoration: InputDecoration(
//                       hintText: 'Ingrese su teléfono',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onChanged: (value) {
//                       _userPhone = '$_selectedCountryCode$value';
//                     },
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: _updateUserPhone,
//                   child: Text('Guardar'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.orange,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Notas',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             if (_isEditingNotes)
//               Column(
//                 children: [
//                   TextField(
//                     controller: _notesController,
//                     maxLength: 500,
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       hintText: 'Añadir Notas',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   ElevatedButton(
//                     onPressed: () {
//                       setState(() {
//                         _notes = _notesController.text;
//                         _isEditingNotes = false;
//                       });
//                     },
//                     child: Text('Listo'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey,
//                     ),
//                   ),
//                 ],
//               )
//             else
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Expanded(
//                     child: Text(
//                       _notes.isEmpty ? '---------' : _notes,
//                       style: TextStyle(fontSize: 16),
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       setState(() {
//                         _isEditingNotes = true;
//                         _notesController.text = _notes;
//                       });
//                     },
//                     icon: Icon(Icons.edit),
//                     label: Text('Añadir Nota'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                   ),
//                 ],
//               ),
//             SizedBox(height: 16),
//             ...widget.orderProducts.map((orderProduct) {
//               return Column(
//                 children: [
//                   Row(
//                     children: [
//                       orderProduct['imageUrl'] != null
//                           ? Image.network(
//                               orderProduct['imageUrl'],
//                               height: 50,
//                               width: 50,
//                               fit: BoxFit.cover,
//                             )
//                           : CircularProgressIndicator(),
//                       SizedBox(width: 16),
//                       Expanded(
//                         // Updated to use Expanded to wrap text
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               orderProduct['product'].name,
//                               style: TextStyle(fontSize: 18),
//                               overflow: TextOverflow.visible,
//                             ),
//                             Text('Belihanpiy',
//                                 style: TextStyle(color: Colors.grey)),
//                             Text(
//                               'S/.${orderProduct['price'].toStringAsFixed(2)}',
//                               style: TextStyle(color: Colors.black),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Spacer(),
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: () => _decrementQuantity(widget.orderProducts.indexOf(orderProduct)),
//                             icon: Icon(Icons.remove),
//                           ),
//                           Text('${orderProduct['quantity']}'),
//                           IconButton(
//                             onPressed: () => _incrementQuantity(widget.orderProducts.indexOf(orderProduct), orderProduct['stock']),
//                             icon: Icon(Icons.add),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   Divider(),
//                 ],
//               );
//             }).toList(),
//             SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => CustomerHomePage()),
//                 ).then((newProduct) {
//                   if (newProduct != null) {
//                     setState(() {
//                       widget.orderProducts.add(newProduct);
//                       _calculateTotalPrice();
//                     });
//                   }
//                 });
//               },
//               icon: Icon(Icons.add),
//               label: Text('Seguir Comprando'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//               ),
//             ),
//             SizedBox(height: 16),
//             _couponData != null
//               ? Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(IconlyLight.discount),
//                         SizedBox(width: 8),
//                         Text('Descuento aplicado'),
//                       ],
//                     ),
//                     TextButton(
//                       onPressed: _removeCoupon,
//                       child: Text('Quitar Cupón'),
//                     ),
//                   ],
//                 )
//               : Row(
//                   children: [
//                     Expanded(
//                       child: TextField(
//                         onChanged: (value) {
//                           setState(() {
//                             _couponCode = value;
//                           });
//                         },
//                         decoration: InputDecoration(
//                           hintText: 'Código de Cupón',
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: 8),
//                     ElevatedButton(
//                       onPressed: _applyCoupon,
//                       child: Text('Aplicar Cupón'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                       ),
//                     ),
//                   ],
//                 ),
//             SizedBox(height: 16),
//             Text(
//               'Resumen de Pagos',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             ListTile(
//               title: Text('Precios'),
//               trailing: Text('S/.${_totalPrice.toStringAsFixed(2)}'),
//             ),
//             ListTile(
//               title: Text('Descuento Aplicado'),
//               trailing: Text('S/.${_discount.toStringAsFixed(2)}'),
//             ),
//             ListTile(
//               title: Text('Pago Total'),
//               trailing: Text('S/.${_totalPrice.toStringAsFixed(2)}'),
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {},
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(IconlyLight.wallet),
//                         SizedBox(width: 8),
//                         Text('Efectivo'),
//                       ],
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.orange,
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {},
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(IconlyLight.wallet),
//                         SizedBox(width: 8),
//                         Text('Tarjeta'),
//                       ],
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _createOrder,
//               child: Text('Ordenar'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 minimumSize: Size(double.infinity, 50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }










// import 'package:belihanpiyapp2/models/order.dart' as app_models;
// import 'package:belihanpiyapp2/models/product.dart';
// import 'package:belihanpiyapp2/services/firestore_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';

// class CreateOrderPage extends StatefulWidget {
//   final Product product;

//   CreateOrderPage({required this.product});

//   @override
//   _CreateOrderPageState createState() => _CreateOrderPageState();
// }

// class _CreateOrderPageState extends State<CreateOrderPage> {
//   final FirestoreService firestoreService = FirestoreService();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   int _quantity = 1;
//   double _totalPrice = 0.0;
//   double _price = 0.0;
//   String _selectedSize = 'Normal';
//   String? _userAddress;
//   String _couponCode = '';
//   double _discount = 0.0;
//   String _notes = '';
//   String _paymentMethod = 'Efectivo';

//   @override
//   void initState() {
//     super.initState();
//     _price = widget.product.price;
//     _totalPrice = _price * _quantity;
//     _getCurrentUserAddress();
//   }

//   Future<void> _getCurrentUserAddress() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       var userData = await firestoreService.getUserById(user.uid);
//       setState(() {
//         _userAddress = userData['direccion'];
//       });
//     }
//   }

//   void _updatePrice(String size) {
//     setState(() {
//       _selectedSize = size;
//       if (size == 'Mega') {
//         _price = widget.product.price + 6.0;
//       } else {
//         _price = widget.product.price;
//       }
//       _updateTotalPrice();
//     });
//   }

//   void _updateTotalPrice() {
//     setState(() {
//       _totalPrice = (_price * _quantity) - _discount;
//     });
//   }

//   Future<void> _applyCoupon() async {
//     if (_couponCode.isNotEmpty) {
//       var couponData = await firestoreService.getCouponByCode(_couponCode);
//       if (couponData != null) {
//         setState(() {
//           _discount = (_price * _quantity) * (couponData['descuento'] / 100);
//           _updateTotalPrice();
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Cupón aplicado correctamente')),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Cupón inválido')),
//         );
//       }
//     }
//   }

//   void _incrementQuantity() {
//     setState(() {
//       _quantity++;
//       _updateTotalPrice();
//     });
//   }

//   void _decrementQuantity() {
//     if (_quantity > 1) {
//       setState(() {
//         _quantity--;
//         _updateTotalPrice();
//       });
//     }
//   }

//   Future<void> _createOrder() async {
//     User? user = _auth.currentUser;
//     if (user != null) {
//       String currentUserId = user.uid;

//       app_models.Order order = app_models.Order(
//         id: firestoreService.generateOrderId(),
//         clientId: currentUserId,
//         productId: widget.product.id!,
//         quantity: _quantity,
//         totalPrice: _totalPrice,
//         orderStatus: 'pendiente',
//         orderDate: DateTime.now(),
//         notas: _notes,
//       );

//       await firestoreService.addOrder(order);
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detalle de Pedido',
//             style: TextStyle(fontWeight: FontWeight.bold)),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 ElevatedButton(
//                   onPressed: () => _updatePrice('Normal'),
//                   child: Text('Normal'),
//                   style: ElevatedButton.styleFrom(
//                     primary:
//                         _selectedSize == 'Normal' ? Colors.orange : Colors.grey,
//                   ),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton(
//                   onPressed: () => _updatePrice('Mega'),
//                   child: Text('Mega'),
//                   style: ElevatedButton.styleFrom(
//                     primary:
//                         _selectedSize == 'Mega' ? Colors.orange : Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Delivery Dirección',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             Text(_userAddress ?? 'Cargando dirección...'),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     // Navegar a la página de edición de dirección
//                   },
//                   icon: Icon(IconlyLight.editSquare),
//                   label: Text('Editar Dirección'),
//                   style: ElevatedButton.styleFrom(primary: Colors.orange),
//                 ),
//                 SizedBox(width: 8),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     // Agregar notas
//                   },
//                   icon: Icon(IconlyLight.paper),
//                   label: Text('Añadir Notas'),
//                   style: ElevatedButton.styleFrom(primary: Colors.grey),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             Row(
//               children: [
//                 Image.network(
//                   widget.product.imageUrl,
//                   width: 80,
//                   height: 80,
//                   fit: BoxFit.cover,
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(widget.product.name,
//                           style: TextStyle(
//                               fontSize: 18, fontWeight: FontWeight.bold)),
//                       Text('Belihanpiy', style: TextStyle(color: Colors.grey)),
//                       Row(
//                         children: [
//                           IconButton(
//                             onPressed: _decrementQuantity,
//                             icon: Icon(IconlyLight.arrowLeftCircle,
//                                 color: Colors.orange),
//                           ),
//                           Text('$_quantity', style: TextStyle(fontSize: 18)),
//                           IconButton(
//                             onPressed: _incrementQuantity,
//                             icon: Icon(IconlyLight.arrowRightCircle,
//                                 color: Colors.orange),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             TextField(
//               onChanged: (value) {
//                 setState(() {
//                   _couponCode = value;
//                 });
//               },
//               decoration: InputDecoration(
//                 hintText: 'Código de Cupón',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),
//             SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: _applyCoupon,
//               child: Text('Aplicar Cupón'),
//               style: ElevatedButton.styleFrom(primary: Colors.orange),
//             ),
//             SizedBox(height: 16),
//             Text(
//               'Resumen de Pagos',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             ListTile(
//               title: Text('Precios'),
//               trailing: Text('S/.${_price.toStringAsFixed(2)}'),
//             ),
//             ListTile(
//               title: Text('Descuento Aplicado'),
//               trailing: Text('S/.${_discount.toStringAsFixed(2)}'),
//             ),
//             ListTile(
//               title: Text('Pago Total'),
//               trailing: Text('S/.${_totalPrice.toStringAsFixed(2)}'),
//             ),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     setState(() {
//                       _paymentMethod = 'Efectivo';
//                     });
//                   },
//                   icon: Icon(IconlyLight.wallet),
//                   label: Text('Efectivo'),
//                   style: ElevatedButton.styleFrom(
//                     primary: _paymentMethod == 'Efectivo'
//                         ? Colors.orange
//                         : Colors.grey,
//                   ),
//                 ),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     setState(() {
//                       _paymentMethod = 'Tarjeta';
//                     });
//                   },
//                   icon: Icon(IconlyLight.folder), //cambiar el icono a tarjeta
//                   label: Text('Tarjeta'),
//                   style: ElevatedButton.styleFrom(
//                     primary: _paymentMethod == 'Tarjeta'
//                         ? Colors.orange
//                         : Colors.grey,
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: _createOrder,
//               child: Text('Ordenar'),
//               style: ElevatedButton.styleFrom(
//                 primary: Colors.orange,
//                 minimumSize: Size(double.infinity, 50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
