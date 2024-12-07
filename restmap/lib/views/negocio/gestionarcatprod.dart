import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GestionarCatProdPage extends StatelessWidget {
  final String negocioId;

  GestionarCatProdPage({required this.negocioId});

  Future<void> _confirmarEliminacionCategoria(String categoriaId, String categoriaNombre, BuildContext context) async {
    bool confirmacion = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar la categoría "$categoriaNombre"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmacion == true) {
      await _eliminarCategoria(categoriaId, context);
    }
  }

  Future<void> _eliminarCategoria(String categoriaId, BuildContext context) async {
    QuerySnapshot productos = await FirebaseFirestore.instance
        .collection('cartasnegocio')
        .where('negocioId', isEqualTo: negocioId)
        .where('productos', arrayContainsAny: [
          {'categoriaId': categoriaId}
        ])
        .get();

    if (productos.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('No se puede eliminar la categoría porque está en uso por algún producto.')));
    } else {

      DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioId).get();
      var negocio = snapshot.data() as Map<String, dynamic>;
      List categorias = negocio['categoriasprod'] ?? [];

  
      categorias.removeWhere((cat) => cat['id'] == categoriaId);

      await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioId).update({
        'categoriasprod': categorias,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Categoría eliminada exitosamente.')));
    }
  }

  Future<void> _editarCategoria(Map<String, dynamic> categoria, BuildContext context) async {
    TextEditingController _categoriaController = TextEditingController(text: categoria['nombre']);


    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Editar Categoría'),
          content: TextField(
            controller: _categoriaController,
            decoration: InputDecoration(labelText: 'Nuevo nombre de la categoría'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Guardar'),
              onPressed: () async {
                String nuevoNombre = _categoriaController.text;

                if (nuevoNombre.isNotEmpty) {
                
                  DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioId).get();
                  var negocio = snapshot.data() as Map<String, dynamic>;
                  List categorias = negocio['categoriasprod'] ?? [];

         
                  int categoriaIndex = categorias.indexWhere((cat) => cat['id'] == categoria['id']);
                  if (categoriaIndex != -1) {
                    categorias[categoriaIndex]['nombre'] = nuevoNombre;
                  }

         
                  await FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioId).update({
                    'categoriasprod': categorias,
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Categoría actualizada exitosamente.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestionar Categorías de Producto'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('cartasnegocio').doc(negocioId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var negocio = snapshot.data!.data() as Map<String, dynamic>;
          List categorias = negocio['categoriasprod'] ?? [];

          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              var categoria = categorias[index];

              return ListTile(
                title: Text(categoria['nombre']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        _editarCategoria(categoria, context);
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _confirmarEliminacionCategoria(categoria['id'], categoria['nombre'], context);
                      },
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
}
