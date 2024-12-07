import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restmap/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageNegocioPage extends StatelessWidget {
  final CollectionReference usuarios =
      FirebaseFirestore.instance.collection('usuarios');
  final FirebaseAuthService authService = FirebaseAuthService();

  ManageNegocioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestionar Usuarios de Negocio"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usuarios.where('rol', isEqualTo: 'negocio').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Algo salió mal'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final negocios = snapshot.data?.docs ?? [];

          if (negocios.isEmpty) {
            return const Center(
              child: Text(
                "Aún no tienes usuarios de negocio registrados.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: negocios.length,
            itemBuilder: (context, index) {
              var data = negocios[index].data()! as Map<String, dynamic>;
              final bool isCurrentUser = currentUser?.uid == negocios[index].id;

              String nombre = data['nombre'] ?? data['correo'] ?? 'Sin nombre';

              return ListTile(
                leading: data['logo'] != null
                    ? Image.network(data['logo'], width: 50, height: 50)
                    : const Icon(Icons.business),
                title: Text(nombre),
                subtitle: Text('Correo: ${data['correo']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () => _viewNegocio(context, data),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: isCurrentUser
                          ? null
                          : () => _deleteNegocio(
                              context, negocios[index].id, data['correo']),
                      color: isCurrentUser ? Colors.grey : Colors.red,
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

  void _viewNegocio(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Información del Negocio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nombre: ${data['nombre'] ?? data['correo']}'),
              Text('Correo: ${data['correo']}'),
              Text('Rol: ${data['rol']}'),
              if (data['propietario'] != null)
                Text('Propietario: ${data['propietario']}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cerrar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteNegocio(BuildContext context, String userId, String email) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content:
              const Text('¿Está seguro de que desea eliminar este negocio?'),
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
        await authService.deleteUserByEmail(email);
        await usuarios.doc(userId).delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Negocio eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar el negocio: $e')),
          );
        }
      }
    }
  }
}
