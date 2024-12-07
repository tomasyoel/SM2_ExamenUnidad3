// import 'package:flutter/material.dart';

// class ProductCard extends StatelessWidget {
//   final Map<String, dynamic> productData;

//   const ProductCard({Key? key, required this.productData}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black26,
//             blurRadius: 4,
//             offset: Offset(2, 2),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 120,
//               width: double.infinity,
//               color: Colors.grey[200], // Placeholder color
//               child: productData['imageurl'] != null &&
//                       productData['imageurl'].isNotEmpty
//                   ? Image.network(
//                       productData['imageurl'],
//                       fit: BoxFit.cover,
//                     )
//                   : Image.asset(
//                       'assets/images/placeholder.png',
//                       fit: BoxFit.cover,
//                     ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     productData['nombre'] ?? 'Nombre no disponible',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                   SizedBox(height: 4),
//                   Text(
//                     productData['descripcion'] ?? 'Descripción no disponible',
//                     style: TextStyle(color: Colors.grey[600]),
//                     overflow: TextOverflow.ellipsis,
//                     maxLines: 1,
//                   ),
//                   SizedBox(height: 8),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         "S/.${productData['precio']?.toStringAsFixed(2) ?? '0.00'}",
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.add_circle, color: Colors.orange),
//                         onPressed: () {
//                           // Action to add the product
//                         },
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
