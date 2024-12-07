import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final FirebaseStorage storage = FirebaseStorage.instance;

Future<String?> uploadImage(File image) async {
  try {
    final String namefile = image.path.split("/").last;
    final mimeType = _getMimeType(namefile);
    final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

    Reference ref = storage.ref().child("images").child(namefile);
    UploadTask uploadTask = ref.putFile(image, metadata);

    TaskSnapshot snapshot = await uploadTask;
    if (snapshot.state == TaskState.success) {
      return namefile;
    }
  } catch (e) {
    debugPrint('Error uploading image: $e');
  }
  return null;
}

Future<String?> uploadProfileImage(File image) async {
  try {
    final String namefile = image.path.split("/").last;
    final mimeType = _getMimeType(namefile);
    final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

    Reference ref = storage.ref().child("perfiles").child(namefile);
    UploadTask uploadTask = ref.putFile(image, metadata);

    TaskSnapshot snapshot = await uploadTask;
    if (snapshot.state == TaskState.success) {
      return await snapshot.ref.getDownloadURL();
    }
  } catch (e) {
    debugPrint('Error uploading profile image: $e');
  }
  return null;
}

// Future<String?> uploadPublicityImage(File image) async {
//   try {
//     final String namefile = image.path.split("/").last;
//     final mimeType = _getMimeType(namefile);
//     final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

//     Reference ref = storage.ref().child("publicidad").child(namefile);
//     UploadTask uploadTask = ref.putFile(image, metadata);

//     TaskSnapshot snapshot = await uploadTask;
//     if (snapshot.state == TaskState.success) {
//       return namefile;
//     }
//   } catch (e) {
//     debugPrint('Error uploading publicity image: $e');
//   }
//   return null;
// }

// Future<String?> uploadMiyapeImage(File image) async {
//   try {
//     final String namefile = image.path.split("/").last;
//     final mimeType = _getMimeType(namefile);
//     final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

//     Reference ref = storage.ref().child("yapeplinimage").child(namefile);
//     UploadTask uploadTask = ref.putFile(image, metadata);

//     TaskSnapshot snapshot = await uploadTask;
//     if (snapshot.state == TaskState.success) {
//       return namefile;
//     }
//   } catch (e) {
//     debugPrint('Error uploading mi yape plin image: $e');
//   }
//   return null;
// }

// Future<String?> uploadPaymentImage(File image) async {
//   try {
//     final String namefile = image.path.split("/").last;
//     final mimeType = _getMimeType(namefile);
//     final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

//     Reference ref = storage.ref().child("pagos").child(namefile);
//     UploadTask uploadTask = ref.putFile(image, metadata);

//     TaskSnapshot snapshot = await uploadTask;
//     if (snapshot.state == TaskState.success) {
//       return await snapshot.ref.getDownloadURL();
//     }
//   } catch (e) {
//     debugPrint('Error uploading payment image: $e');
//   }
//   return null;
// }

// Future<String?> uploadComprobanteImage(File image) async {
//   try {
//     final String namefile = image.path.split("/").last;
//     final mimeType = _getMimeType(namefile);
//     final SettableMetadata metadata = SettableMetadata(contentType: mimeType);

//     Reference ref = storage.ref().child("pagos").child(namefile);
//     UploadTask uploadTask = ref.putFile(image, metadata);

//     TaskSnapshot snapshot = await uploadTask;
//     if (snapshot.state == TaskState.success) {
//       return await snapshot.ref.getDownloadURL();
//     }
//   } catch (e) {
//     debugPrint('Error uploading comprobante image: $e');
//   }
//   return null;
// }

String _getMimeType(String fileName) {
  final extension = fileName.split('.').last.toLowerCase();
  switch (extension) {
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'png':
      return 'image/png';
    case 'gif':
      return 'image/gif';
    default:
      return 'application/octet-stream';
  }
}
