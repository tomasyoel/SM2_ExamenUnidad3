import 'dart:io';

import 'package:restmap/services/firestore_service.dart';
import 'package:restmap/services/upload_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  _DriverProfilePageState createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _placaController = TextEditingController();
  final TextEditingController _vehiculoController = TextEditingController();
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
        _placaController.text = userData['placa'] ?? '';
        _vehiculoController.text = userData['vehiculo'] ?? '';
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
        'placa': _placaController.text,
        'vehiculo': _vehiculoController.text,
        'nro_celular': _nroCelularController.text,
        'direccion': _direccionController.text,
        'photoUrl': _photoUrl,
      };
      await _firestoreService.updateUser(user!.uid, updatedData);
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
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _takePicture() async {
    // Aquí podrías implementar la funcionalidad de tomar una foto si usas una biblioteca diferente.
    // Por ejemplo, puedes usar Camera para capturar imágenes desde la cámara.
    print('Take picture not implemented.');
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
        print('Error uploading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Conductor'),
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
                    ? const Icon(Icons.camera_alt, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField('Nombre', _nombreController),
            _buildTextField('Apellido', _apellidoController),
            _buildTextField('DNI', _dniController),
            _buildTextField('Placa', _placaController),
            _buildTextField('Vehículo', _vehiculoController),
            _buildTextField('Número de Celular', _nroCelularController),
            _buildTextField('Dirección', _direccionController),
            ElevatedButton(
              onPressed: () async {
                if (user != null && user!.email != null) {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: user!.email!);
                  _showInfoDialog(
                      'Correo para restablecer contraseña enviado.');
                }
              },
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
