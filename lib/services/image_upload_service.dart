import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ImageUploadService {
  final String cloudName = 'qrdj9mco';
  final String uploadPreset = 'farmerconnect_unsigned';

  Future<String?> uploadImage(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        ),
      );

      request.fields['upload_preset'] = uploadPreset;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'] as String?;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}

final imageUploadService = ImageUploadService();



