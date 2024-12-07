// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:restmap/services/firestore_service.dart';
import 'package:restmap/services/upload_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PerfilAdminPage extends StatefulWidget {
  const PerfilAdminPage({super.key});

  @override
  _PerfilAdminPageState createState() => _PerfilAdminPageState();
}

class _PerfilAdminPageState extends State<PerfilAdminPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _nroCelularController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  String? _photoUrl;
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await _firestoreService.getUserById(user!.uid);
      var userData = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _nombreController.text = userData['nombre'] ?? '';
        _apellidoController.text = userData['apellido'] ?? '';
        _dniController.text = userData['dni'] ?? '';
        _nroCelularController.text = userData['nro_celular'] ?? '';
        _direccionController.text = userData['direccion'] ?? '';
        _photoUrl = userData['photoUrl'];
      });
    }
  }

  Future<void> _updateUserData() async {
    if (user != null) {
      Map<String, dynamic> updatedData = {
        'nombre': _nombreController.text,
        'apellido': _apellidoController.text,
        'dni': _dniController.text,
        'nro_celular': _nroCelularController.text,
        'direccion': _direccionController.text,
        'photoUrl': _photoUrl,
      };
      await _firestoreService.updateUser(user!.uid, updatedData);
      _showInfoDialog('Perfil actualizado exitosamente.');
    }
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        setState(() {
          _image = File(result.files.single.path!);
        });
        await _uploadImage();
      } else {
        // El usuario canceló la selección
        //print('No se seleccionó ninguna imagen.');
      }
    } catch (e) {
      //print('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _takePicture() async {
    //print('Tomar foto no implementado.');
  }

  Future<void> _uploadImage() async {
    if (_image != null && user != null) {
      try {
        String? downloadUrl = await uploadProfileImage(_image!);
        if (downloadUrl != null) {
          setState(() {
            _photoUrl = downloadUrl;
          });
          await _updateUserData();
        }
      } catch (e) {
        //print('Error al subir la imagen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateUserData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showImageSourceActionSheet(context),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _photoUrl != null
                    ? NetworkImage(_photoUrl!)
                    : const AssetImage('assets/placeholder.png')
                        as ImageProvider,
                child: _photoUrl == null
                    ? const Icon(Icons.camera_alt,
                        size: 50, color: Colors.white70)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Nombre', _nombreController),
            _buildTextField('Apellido', _apellidoController),
            _buildTextField('DNI', _dniController),
            _buildTextField('Número de Celular', _nroCelularController),
            _buildTextField('Dirección', _direccionController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (user != null && user!.email != null) {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: user!.email!);
                  _showInfoDialog(
                      'Correo para restablecer contraseña enviado.');
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Cambiar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir desde galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePicture();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Información'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
