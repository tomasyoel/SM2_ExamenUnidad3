import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AgregarCatProdPage extends StatefulWidget {
  final String negocioId;

  const AgregarCatProdPage({super.key, required this.negocioId});

  @override
  _AgregarCatProdPageState createState() => _AgregarCatProdPageState();
}

class _AgregarCatProdPageState extends State<AgregarCatProdPage> {
  final TextEditingController _categoriaController = TextEditingController();
  String? _categoriaId;

  Future<void> _agregarCategoria() async {
    if (_categoriaController.text.isNotEmpty) {
      var uuid = const Uuid();
      String categoriaId = _categoriaId ?? uuid.v4();

      final nuevaCategoria = {
        'id': categoriaId,
        'nombre': _categoriaController.text,
      };

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('cartasnegocio')
          .doc(widget.negocioId)
          .get();

      if (snapshot.exists) {
        await FirebaseFirestore.instance
            .collection('cartasnegocio')
            .doc(widget.negocioId)
            .update({
          'categoriasprod': FieldValue.arrayUnion([nuevaCategoria]),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('cartasnegocio')
            .doc(widget.negocioId)
            .set({
          'categoriasprod': [nuevaCategoria],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Categoría ${_categoriaId != null ? 'actualizada' : 'agregada'} exitosamente')));
      _categoriaController.clear();
      setState(() {
        _categoriaId = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, introduce un nombre de categoría.')));
    }
  }

  void _editarCategoria(String id, String nombre) {
    setState(() {
      _categoriaId = id;
      _categoriaController.text = nombre;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar/Editar Categoría de Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _categoriaController,
              decoration:
                  const InputDecoration(labelText: 'Nombre de la Categoría'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _agregarCategoria,
              child: Text(_categoriaId != null
                  ? 'Guardar Cambios'
                  : 'Agregar Categoría'),
            ),
          ],
        ),
      ),
    );
  }
}
