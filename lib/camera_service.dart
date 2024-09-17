import 'dart:js' as js;

class CameraService {
  static Future<void> startCamera() async {
    try {
      await js.context.callMethod('startCamera', ['video-container']);
    } catch (e) {
      print('Error starting camera: $e');
    }
  }

  static void stopCamera() {
    try {
      js.context.callMethod('stopCamera', ['video-container']);
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  static void startRecording() {
    try {
      js.context.callMethod('startRecording');
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  static void stopRecording() {
    try {
      js.context.callMethod('stopRecording');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  static void uploadRecording(String apiUrl) {
    try {
      js.context.callMethod('uploadRecording', [apiUrl]);
    } catch (e) {
      print('Error uploading recording: $e');
    }
  }
}
