// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:restmap/views/admin/gestionarnegocio.dart';
import 'package:restmap/views/admin/perfiladmin.dart';
import 'package:restmap/views/admin/agregarnegocio.dart';
import 'package:restmap/views/admin/agregartipococina.dart';
// import 'package:restmap/views/admin/gestionartipococina.dart';
import 'package:restmap/views/admin/agregarusuarionegocio.dart';
import 'package:restmap/views/admin/gestionarusuarionegocio.dart';
import 'package:restmap/services/firebase_auth_service.dart';

class PaginaPrincipalAdmin extends StatefulWidget {
  const PaginaPrincipalAdmin({super.key});

  @override
  _PaginaPrincipalAdminState createState() => _PaginaPrincipalAdminState();
}

class _PaginaPrincipalAdminState extends State<PaginaPrincipalAdmin> {
  String _selectedPage = 'gestion_negocios';
  final FirebaseAuthService _authService = FirebaseAuthService();

  void _onSelectPage(String page) {
    setState(() {
      _selectedPage = page;
    });
    Navigator.pop(context);
  }

  void _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signIn');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Panel de Administración"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Administrador',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Gestionar Negocios'),
              selected: _selectedPage == 'gestion_negocios',
              onTap: () => _onSelectPage('gestion_negocios'),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Agregar Usuario Negocio'),
              selected: _selectedPage == 'agregar_usuario_negocio',
              onTap: () => _onSelectPage('agregar_usuario_negocio'),
            ),
            ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('Gestionar Usuarios Negocio'),
              selected: _selectedPage == 'gestionar_usuario_negocio',
              onTap: () => _onSelectPage('gestionar_usuario_negocio'),
            ),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text('Agregar Negocio'),
              selected: _selectedPage == 'agregar_negocio',
              onTap: () => _onSelectPage('agregar_negocio'),
            ),
            ListTile(
              leading: const Icon(Icons.kitchen),
              title: const Text('Agregar Tipo de Cocina'),
              selected: _selectedPage == 'agregar_tipococina',
              onTap: () => _onSelectPage('agregar_tipococina'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Gestionar Tipo de Cocina'),
              selected: _selectedPage == 'gestionar_tipococina',
              onTap: () => _onSelectPage('gestionar_tipococina'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              selected: _selectedPage == 'perfil',
              onTap: () => _onSelectPage('perfil'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Salir'),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_selectedPage) {
      case 'gestion_negocios':
        return const GestionarNegociosPage();
      case 'agregar_negocio':
        return const AgregarNegocioPage();
      case 'agregar_usuario_negocio':
        return const CreateUserNegocioPage();
      case 'gestionar_usuario_negocio':
        return ManageNegocioPage();
      case 'agregar_tipococina':
        return const AgregarTipoCocinaPage();
      // case 'gestionar_tipococina':
      //   return const GestionarTipoCocinaPage();
      case 'perfil':
        return const PerfilAdminPage();
      default:
        return const Center(
            child: Text("Bienvenido al panel de administración"));
    }
  }
}
