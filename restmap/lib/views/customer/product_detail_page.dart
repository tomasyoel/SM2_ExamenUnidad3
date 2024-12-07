// import 'package:restmap/models/product.dart';
// import 'package:restmap/services/firestore_service.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_iconly/flutter_iconly.dart';

// class ProductDetailPage extends StatefulWidget {
//   final Map<String, dynamic> productData;
//   final Product product;
//   final List<Map<String, dynamic>> orderProducts; // Lista de productos en el pedido

//   const ProductDetailPage({
//     Key? key,
//     required this.productData,
//     required this.product,
//     required this.orderProducts,
//   }) : super(key: key);

//   @override
//   _ProductDetailPageState createState() => _ProductDetailPageState();
// }

// class _ProductDetailPageState extends State<ProductDetailPage> {
//   String _selectedSize = 'Normal';
//   double _price = 0.0;
//   String? _imageUrl;
//   bool _isFavorite = false;
//   int _currentStock = 0;

//   @override
//   void initState() {
//     super.initState();
//     _price = widget.product.price;
//     _currentStock = widget.product.stock;
//     _fetchImageUrl(widget.product.imageUrl);
//     _refreshProductData();
//   }

//   Future<void> _refreshProductData() async {
//     var productData = await FirestoreService().getProductById(widget.product.id!);
//     if (productData != null) {
//       setState(() {
//         _currentStock = productData['stock'];
//       });
//     }
//   }

//   Future<void> _fetchImageUrl(String imageName) async {
//     try {
//       var ref = FirebaseStorage.instance.ref('images/$imageName');
//       var url = await ref.getDownloadURL();
//       setState(() {
//         _imageUrl = url;
//       });
//     } catch (e) {
//       print('Error al cargar la imagen: $e');
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
//     });
//   }

//   void _toggleFavorite() {
//     setState(() {
//       _isFavorite = !_isFavorite;
//     });
//   }

// void _addToCart() {
//   List<Map<String, dynamic>> updatedOrderProducts = List.from(widget.orderProducts);
//   bool productExists = false;
//   int totalQuantityInCart = 0;

//   for (var product in updatedOrderProducts) {
//     if (product['product'].id == widget.product.id) {
//       totalQuantityInCart += product['quantity'] as int; // Casting explícito a int
//     }
//   }

//   if (totalQuantityInCart >= _currentStock) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Todo el stock disponible ya se encuentra en el carrito y no se puede agregar más, para cambiar de tamaño reduzca su producto y escoja nuevamente el tamaño deseado'),
//         duration: Duration(seconds: 2),
//       ),
//     );
//     return;
//   }

//   for (var product in updatedOrderProducts) {
//     if (product['product'].id == widget.product.id && product['price'] == _price) {
//       if (totalQuantityInCart < _currentStock) {
//         product['quantity']++;
//         productExists = true;
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Todo el stock disponible ya se encuentra en el carrito y no se puede agregar más, para cambiar de tamaño reduzca su producto y escoja nuevamente el tamaño deseado'),
//             duration: Duration(seconds: 2),
//           ),
//         );
//         return;
//       }
//     }
//   }

//   if (!productExists) {
//     if (totalQuantityInCart < _currentStock) {
//       updatedOrderProducts.add({
//         'product': widget.product,
//         'productName': widget.product.name, // Agregar el nombre del producto
//         'size': _selectedSize, // Agregar el tamaño del producto
//         'quantity': 1,
//         'price': _selectedSize == 'Mega'
//             ? widget.product.price + 6.0
//             : widget.product.price,
//         'imageUrl': _imageUrl,
//         'stock': _currentStock,
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Todo el stock disponible ya se encuentra en el carrito y no se puede agregar más, para cambiar de tamaño reduzca su producto y escoja nuevamente el tamaño deseado'),
//           duration: Duration(seconds: 2),
//         ),
//       );
//       return;
//     }
//   }

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: Text('Producto agregado correctamente al carrito'),
//       duration: Duration(seconds: 2),
//     ),
//   );

//   Navigator.pop(context, updatedOrderProducts);
// }



//   @override
//   Widget build(BuildContext context) {
//     bool isOutOfStock = _currentStock <= 0;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Detalle', style: TextStyle(fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(
//               _isFavorite ? IconlyBold.heart : IconlyLight.heart,
//               color: _isFavorite ? Colors.red : Colors.black,
//             ),
//             onPressed: _toggleFavorite,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 height: 200,
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                   color: Colors.grey[200],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: _imageUrl == null
//                     ? Center(
//                         child: Image.asset(
//                           'assets/loadingbeli.gif',
//                           width: 100,
//                           height: 100,
//                         ),
//                       )
//                     : ClipRRect(
//                         borderRadius: BorderRadius.circular(12),
//                         child: Image.network(
//                           _imageUrl!,
//                           height: 200,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//               ),
//               SizedBox(height: 16),
//               Text(
//                 widget.product.name,
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text('Belihanpiy'),
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(Icons.star, color: Colors.yellow),
//                   SizedBox(width: 4),
//                   Text('4.8 (230)'),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(16.0),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[100],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Descripción',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       widget.product.description,
//                       textAlign: TextAlign.justify,
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'Tamaño',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _buildSizeOption('Normal'),
//                         SizedBox(width: 8),
//                         _buildSizeOption('Mega'),
//                       ],
//                     ),
//                     SizedBox(height: 16),
//                     Text(
//                       'Precio',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     SizedBox(height: 8),
//                     Text(
//                       'S/.${_price.toStringAsFixed(2)}',
//                       style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: isOutOfStock
//                     ? null
//                     : () {
//                         _addToCart();
//                       },
//                 child: Text(isOutOfStock ? 'Agotado' : 'Comprar Ahora'),
//                 style: ElevatedButton.styleFrom(
//                   foregroundColor: Colors.white,
//                   backgroundColor: isOutOfStock ? Colors.grey : Colors.orange,
//                   minimumSize: Size(double.infinity, 50),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSizeOption(String size) {
//     bool isSelected = _selectedSize == size;
//     return GestureDetector(
//       onTap: () => _updatePrice(size),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.orange : Colors.grey[200],
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Text(
//           size,
//           style: TextStyle(
//             color: isSelected ? Colors.white : Colors.black,
//           ),
//         ),
//       ),
//     );
//   }
// }