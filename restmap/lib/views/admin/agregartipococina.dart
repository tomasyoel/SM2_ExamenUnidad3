// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AgregarTipoCocinaPage extends StatefulWidget {
  const AgregarTipoCocinaPage({super.key});

  @override
  _AgregarTipoCocinaPageState createState() => _AgregarTipoCocinaPageState();
}

class _AgregarTipoCocinaPageState extends State<AgregarTipoCocinaPage> {
  final TextEditingController _nameController = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  bool _isAdding = false;

  Future<void> _addTipoCocina() async {
    if (_nameController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Por favor, ingrese un nombre y seleccione una imagen.'),
        ),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      _imageUrl = await _uploadImage();

      CollectionReference tiposCocina =
          FirebaseFirestore.instance.collection('tipococina');

      await tiposCocina.add({
        'nombre': _nameController.text,
        'imagen': _imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo de cocina agregado exitosamente')),
      );

      _nameController.clear();
      _imageFile = null;
      setState(() {
        _isAdding = false;
      });
    } catch (e) {
      setState(() {
        _isAdding = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al agregar el tipo de cocina: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
          'tipococinaimagen/${_nameController.text}_${DateTime.now().millisecondsSinceEpoch}.png');
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      //print('Error al subir la imagen: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null) {
        setState(() {
          _imageFile = File(result.files.single.path!);
        });
      } else {
        //print('No se seleccionó ninguna imagen.');
      }
    } catch (e) {
      //print('Error al seleccionar la imagen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Tipo de Cocina'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Nombre del Tipo de Cocina'),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null
                    ? const Icon(Icons.camera_alt,
                        size: 50, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAdding ? null : _addTipoCocina,
              child: const Text('Agregar Tipo de Cocina'),
            ),
          ],
        ),
      ),
    );
  }
}
