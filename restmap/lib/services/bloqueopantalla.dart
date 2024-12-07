import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateBlockScreen extends StatelessWidget {
  const UpdateBlockScreen({super.key});

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+51900205498';
    const whatsappUrl = "https://wa.me/$phoneNumber";
    const whatsappUrlScheme = "whatsapp://send?phone=$phoneNumber";

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
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              const Text(
                // 'Período de prueba finalizado',
                'Lanzamos la Actualización',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Para seguir usando esta aplicación, debe actualizar a la última versión.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat),
                label: const Text('Contactar por WhatsApp'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

