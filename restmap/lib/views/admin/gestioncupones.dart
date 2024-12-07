import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CouponManagementPage extends StatelessWidget {
  final CollectionReference coupons = FirebaseFirestore.instance.collection('cupones');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Cupones"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: coupons.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text('${data['codigo']} - ${data['descuento']}%'),
                subtitle: Text((data['activo'] ?? false) ? 'Activo' : 'Consumido'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.toggle_on),
                      onPressed: () => _toggleCouponStatus(document),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCoupon(context, document.id),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _toggleCouponStatus(DocumentSnapshot document) async {
    bool currentStatus = document['activo'] ?? false;
    await document.reference.update({'activo': !currentStatus});
  }

  void _deleteCoupon(BuildContext context, String couponId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Está seguro de que desea eliminar este cupón?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm) {
      try {
        await coupons.doc(couponId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cupón eliminado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar el cupón')),
        );
      }
    }
  }
}
