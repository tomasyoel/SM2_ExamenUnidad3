import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<File?> getImage() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
  );

  if (result != null) {
    File imageFile = File(result.files.single.path!);
    return imageFile;
  } else {
    // El usuario canceló la selección
    return null;
  }
}
