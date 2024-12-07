import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:iconly/iconly.dart';
import 'package:uuid/uuid.dart';

class CuponesPage extends StatelessWidget {
  final CollectionReference cuponesNegocios =
      FirebaseFirestore.instance.collection('cuponesnegocios');

  CuponesPage({super.key}) {
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Cupones"),
        actions: [
          IconButton(
            icon: const Icon(IconlyBold.add_user), 
            onPressed: () {
              _crearNuevoCupon(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: cuponesNegocios
            .where('negocioId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No tienes cupones disponibles.'));
          }
          var negocioDoc = snapshot.data!.docs.first;
          List cupones = negocioDoc['cupones'];

          return ListView.builder(
            itemCount: cupones.length,
            itemBuilder: (context, index) {
              var cupon = cupones[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.red,
                      child: Row(
                        children: [
                          const Icon(IconlyLight.ticket, color: Colors.white),
                          const SizedBox(width: 8.0),
                          Text(
                            'Cupón: ${cupon['codigo']} - ${cupon['porcentaje']}%',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.orange.shade50,
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descuento: ${cupon['porcentaje']}%',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown.shade900,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'Válido hasta: ${_formatDate(cupon['fecha_vencimiento'].toDate())}',
                            style: const TextStyle(
                              fontSize: 16.0,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Código: ${cupon['codigo']}',
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                cupon['estado'] ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold,
                                  color: cupon['estado']
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }


  String _formatDate(DateTime date) {
    var formatter = DateFormat('d MMMM yyyy, hh:mm a', 'es_ES');
    return formatter.format(date);
  }


  void _crearNuevoCupon(BuildContext context) {
    final TextEditingController codigoController = TextEditingController();
    final TextEditingController porcentajeController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    DateTime fechaVencimiento = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Crear nuevo cupón'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codigoController,
                  decoration: const InputDecoration(labelText: 'Código del Cupón'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El código es obligatorio';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: porcentajeController,
                  decoration: const InputDecoration(labelText: 'Porcentaje de Descuento'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El porcentaje es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _guardarCupon(
                        codigoController.text,
                        int.parse(porcentajeController.text),
                        fechaVencimiento,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Crear Cupón'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  void _guardarCupon(String codigo, int porcentaje, DateTime fechaVencimiento) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final CollectionReference cuponesNegocios =
        FirebaseFirestore.instance.collection('cuponesnegocios');

    DocumentReference negocioRef = cuponesNegocios.doc(currentUser?.uid);

  
    Map<String, dynamic> nuevoCupon = {
      'id': const Uuid().v4(),
      'codigo': codigo,
      'porcentaje': porcentaje,
      'estado': true,
      'fecha_vencimiento': fechaVencimiento,
    };

    await negocioRef.set({
      'negocioId': currentUser?.uid,
      'cupones': FieldValue.arrayUnion([nuevoCupon]),
    }, SetOptions(merge: true));
  }
}




// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
// import 'package:intl/date_symbol_data_local.dart';

// class CuponesPage extends StatelessWidget {
//   final CollectionReference cupones = FirebaseFirestore.instance.collection('cupones');

//   CuponesPage() {
//     initializeDateFormatting(); // Asegúrate de inicializar el formateo de fechas
//   }

//   @override
//   Widget build(BuildContext context) {
//     final User? currentUser = FirebaseAuth.instance.currentUser;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Mis Cupones"),
//       ),
//       body: FutureBuilder<void>(
//         future: initializeDateFormatting('es_ES', null), // Inicializa la localización
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             return StreamBuilder<QuerySnapshot>(
//               stream: cupones.where('clientId', isEqualTo: currentUser?.uid).snapshots(),
//               builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//                 if (snapshot.hasError) {
//                   return const Center(child: Text('Algo salió mal'));
//                 }
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return const Center(child: Text('No tienes cupones disponibles.'));
//                 }
//                 return ListView(
//                   children: snapshot.data!.docs.map((DocumentSnapshot document) {
//                     Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
//                     Timestamp? createdAtTimestamp = data['createdAt'];
//                     DateTime? createdAtDate = createdAtTimestamp != null ? createdAtTimestamp.toDate() : null;
//                     DateTime? expirationDate = createdAtDate?.add(Duration(days: 7));

//                     return Card(
//                       margin: EdgeInsets.all(10.0),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10.0),
//                       ),
//                       color: Colors.orange.shade100,
//                       child: Padding(
//                         padding: const EdgeInsets.all(10.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             if (createdAtDate != null && expirationDate != null)
//                               Text(
//                                 'Válido del ${DateFormat('d MMMM', 'es_ES').format(createdAtDate)} al ${DateFormat('d MMMM', 'es_ES').format(expirationDate)}',
//                                 style: TextStyle(
//                                   fontSize: 16.0,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.orange,
//                                 ),
//                               ),
//                             SizedBox(height: 10.0),
//                             Text(
//                               '${data['descuento']}% en Belihanpiy💚🌱',
//                               style: TextStyle(
//                                 fontSize: 20.0,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.green.shade900,
//                               ),
//                             ),
//                             SizedBox(height: 10.0),
//                             Text(
//                               data['message'],
//                               style: TextStyle(
//                                 fontSize: 16.0,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             SizedBox(height: 10.0),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   'Código: ${data['codigo']}',
//                                   style: TextStyle(
//                                     fontSize: 16.0,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black,
//                                   ),
//                                 ),
//                                 Text(
//                                   data['activo'] ? 'Activo' : 'Inactivo',
//                                   style: TextStyle(
//                                     fontSize: 16.0,
//                                     fontWeight: FontWeight.bold,
//                                     color: data['activo'] ? Colors.green : Colors.red,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 );
//               },
//             );
//           } else {
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//     );
//   }
// }
