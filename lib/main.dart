import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late html.VideoElement _preview;
  late html.MediaRecorder _recorder;
  late html.VideoElement _result;
  late html.Blob _blob;
  String _statusMessage = 'Initializing...';
  bool _isLoading = true;
  Timer? _recordingTimer; // Timer to automatically stop recording

  @override
  void initState() {
    super.initState();
    _preview = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    _result = html.VideoElement()
      ..autoplay = false
      ..muted = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..controls = true;

    ui.platformViewRegistry.registerViewFactory('preview', (int _) => _preview);
    ui.platformViewRegistry.registerViewFactory('result', (int _) => _result);

    Future.delayed(Duration(milliseconds: 100), () {
      _initializeCamera();
    });
  }

  void _log(String message) {
    print(message);
    setState(() {
      _statusMessage = message;
    });
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
    });

    _log('Initializing camera...');

    final html.MediaStream? stream = await html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': true});

    if (stream != null) {
      _preview.srcObject = stream;
      _log('Camera accessed successfully and stream assigned to preview.');
      startRecording(stream);

      // Automatically stop recording after 10 seconds
      _recordingTimer = Timer(Duration(seconds: 10), () {
        stopRecording();
        // Added delay before upload to ensure data is ready
        Future.delayed(Duration(milliseconds: 500), () {
          uploadVideo();
        });
      });
    } else {
      _log('Failed to access camera.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void startRecording(html.MediaStream stream) {
    setState(() {
      _statusMessage = 'Starting recording...';
    });

    _recorder = html.MediaRecorder(stream);
    _recorder.start();

    _recorder.addEventListener('dataavailable', (event) {
      _blob = js.JsObject.fromBrowserObject(event)['data'];
      _log('Data available for upload');
    }, true);

    _recorder.addEventListener('stop', (event) async {
      final url = html.Url.createObjectUrl(_blob);
      _result.src = url;
      setState(() {
        _statusMessage = 'Recording stopped. Compressing and ready to upload.';
      });

      final compressedBlob = await compressVideo(_result);
      setState(() {
        _blob = compressedBlob;
      });

      // Cleanup
      html.Url.revokeObjectUrl(url);

      stream.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    });
  }

  Future<html.Blob> compressVideo(html.VideoElement videoElement) async {
    final canvas = html.CanvasElement(width: 640, height: 480);
    final context = canvas.context2D;

    context.drawImageScaled(videoElement, 0, 0, 640, 480);

    final compressedBlob = await canvas.toBlob('video/mp4');
    return compressedBlob;
  }

  void stopRecording() {
    _recorder.stop();
    setState(() {
      _statusMessage = 'Stopping recording...';
    });
  }

  Future<void> uploadVideo() async {
    setState(() {
      _statusMessage = 'Uploading video...';
    });

    try {
      if (_blob == null) {
        setState(() {
          _statusMessage = 'No video to upload.';
        });
        return;
      }

      var formData = html.FormData();
      var blob = html.Blob([_blob]);
      formData.appendBlob('FILE1', blob, 'video.mp4');

      final request = html.HttpRequest();
      request.open('POST',
          '####URRLL',
          async: true);

      request.onLoadEnd.listen((_) {
        if (request.readyState == html.HttpRequest.DONE) {
          if (request.status == 200) {
            setState(() {
              _statusMessage = 'Upload successful!';
            });
          } else {
            setState(() {
              _statusMessage = 'Upload failed with status: ${request.status}';
            });
          }
        }
      });

      request.onError.listen((event) {
        setState(() {
          _statusMessage = 'Upload failed due to network error.';
        });
      });

      request.send(formData);
    } catch (error) {
      setState(() {
        _statusMessage = 'Failed to upload: $error';
      });
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Recording Preview'),
                if (_isLoading) CircularProgressIndicator(),
                if (!_isLoading)
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10.0),
                    width: 300,
                    height: 200,
                    child: HtmlElementView(
                      key: UniqueKey(),
                      viewType: 'preview',
                    ),
                  ),
                Container(
                  margin: EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () async {
                          final html.MediaStream? stream = await html
                              .window.navigator.mediaDevices
                              ?.getUserMedia({'video': true, 'audio': true});
                          if (stream != null) {
                            startRecording(stream);
                            // Automatically stop recording after 10 seconds
                            _recordingTimer = Timer(Duration(seconds: 10), () {
                              stopRecording();
                              // Added delay before upload to ensure data is ready
                              Future.delayed(Duration(milliseconds: 500), () {
                                uploadVideo();
                              });
                            });
                          }
                        },
                        child: Text('Start Recording'),
                      ),
                      SizedBox(width: 20.0),
                      ElevatedButton(
                        onPressed: () => stopRecording(),
                        child: Text('Stop Recording'),
                      ),
                      SizedBox(width: 20.0),
                      ElevatedButton(
                        onPressed: () => uploadVideo(),
                        child: Text('Upload Video'),
                      ),
                    ],
                  ),
                ),
                Text('Recording Result'),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  width: 300,
                  height: 200,
                  color: Colors.blue,
                  child: HtmlElementView(
                    key: UniqueKey(),
                    viewType: 'result',
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _statusMessage,
                  style: TextStyle(fontSize: 18, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
