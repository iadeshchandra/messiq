import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final ocrScannerProvider = Provider((ref) => OcrScannerService());

class OcrScannerService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<double?> scanReceiptForTotal() async {
    try {
      // 1. Open the camera to snap the receipt
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      
      if (image == null) return null; // User canceled the camera

      // 2. Feed the image to Google ML Kit
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      double maxFoundAmount = 0.0;
      
      // 3. Regex to hunt down any numbers (e.g., 150, 1200.50)
      RegExp regExp = RegExp(r'\d+(\.\d+)?');

      // 4. Scan line by line to find the highest number (usually the Total)
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final matches = regExp.allMatches(line.text);
          for (final match in matches) {
            final numValue = double.tryParse(match.group(0) ?? '0');
            if (numValue != null && numValue > maxFoundAmount) {
              maxFoundAmount = numValue;
            }
          }
        }
      }
      
      return maxFoundAmount > 0 ? maxFoundAmount : null;
    } catch (e) {
      print("OCR Error: $e");
      return null;
    }
  }

  // Always dispose of the recognizer when done to free up RAM
  void dispose() {
    _textRecognizer.close();
  }
}
