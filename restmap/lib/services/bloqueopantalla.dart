import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateBlockScreen extends StatelessWidget {
  const UpdateBlockScreen({Key? key}) : super(key: key);

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+51900205498';
    final whatsappUrl = "https://wa.me/$phoneNumber";
    final whatsappUrlScheme = "whatsapp://send?phone=$phoneNumber";

    try {
      bool launched = await launch(whatsappUrlScheme);
      if (!launched) {
        await launch(whatsappUrl);
      }
    } on Exception catch (e) {
      print("No se pudo lanzar WhatsApp: ${e.toString()}");
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        print("No se pudo abrir WhatsApp ni en el navegador.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.orange,
              ),
              SizedBox(height: 20),
              Text(
                // 'Período de prueba finalizado',
                'Lanzamos la Actualización',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Para seguir usando esta aplicación, debe actualizar a la última versión.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _launchWhatsApp,
                icon: Icon(Icons.chat),
                label: Text('Contactar por WhatsApp'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

