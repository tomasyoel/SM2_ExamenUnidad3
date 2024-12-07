// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class CuponesPage extends StatelessWidget {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mis Cupones'),
//       ),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: _firestore
//             .collection('cupones')
//             .where('clientId', isEqualTo: _auth.currentUser?.uid)
//             .snapshots(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text('Error: ${snapshot.error}'));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text('No tienes cupones disponibles.'));
//           }
//           return ListView(
//             children: snapshot.data!.docs.map((doc) {
//               final data = doc.data() as Map<String, dynamic>;
//               return Card(
//                 child: ListTile(
//                   title: Text(data['codigo']),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(data['message'] ?? 'Sin mensaje'),
//                       SizedBox(height: 5),
//                       Text('Descuento: ${data['descuento']}%'),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }
// }
