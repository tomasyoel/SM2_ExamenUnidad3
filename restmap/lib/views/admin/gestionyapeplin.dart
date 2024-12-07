// import 'package:restmap/services/firestore_service.dart';
// import 'package:restmap/views/admin/addyapeplinpage.dart';
// import 'package:flutter/material.dart';

// class YapePlinManagePage extends StatefulWidget {
//   @override
//   _YapePlinManagePageState createState() => _YapePlinManagePageState();
// }

// class _YapePlinManagePageState extends State<YapePlinManagePage> {
//   final FirestoreService firestoreService = FirestoreService();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Gestionar Yape/Plin'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => AddYapePlinPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder<List<Map<String, dynamic>>>(
//         stream: firestoreService.getYapePlinImages(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return Center(child: Text('No hay imágenes'));
//           } else {
//             return ListView.builder(
//               itemCount: snapshot.data!.length,
//               itemBuilder: (context, index) {
//                 var yapePlinImage = snapshot.data![index];
//                 return ListTile(
//                   leading: yapePlinImage['imageUrl'] != null
//                       ? Image.network(
//                           yapePlinImage['imageUrl'],
//                           width: 50,
//                           height: 50,
//                           fit: BoxFit.cover,
//                         )
//                       : Icon(Icons.image_not_supported),
//                   title: Text('Imagen ${index + 1}'),
//                   subtitle: Text(yapePlinImage['isActive'] ? 'Activo' : 'Inactivo'),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       IconButton(
//                         icon: Icon(Icons.edit),
//                         onPressed: () {
//                           _editYapePlinImage(yapePlinImage);
//                         },
//                       ),
//                       IconButton(
//                         icon: Icon(Icons.delete),
//                         onPressed: () {
//                           firestoreService.deleteYapePlinImage(yapePlinImage['id']);
//                         },
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             );
//           }
//         },
//       ),
//     );
//   }

//   void _editYapePlinImage(Map<String, dynamic> yapePlinImage) {
//     bool _isActive = yapePlinImage['isActive'];

//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           title: Text('Editar Estado de Imagen Yape/Plin'),
//           content: SwitchListTile(
//             title: Text('Activo'),
//             value: _isActive,
//             onChanged: (bool value) {
//               setState(() {
//                 _isActive = value;
//               });
//             },
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 firestoreService.updateYapePlinImage(yapePlinImage['id'], {
//                   'isActive': _isActive,
//                 });
//                 Navigator.pop(context);
//               },
//               child: Text('Guardar'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Cancelar'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
