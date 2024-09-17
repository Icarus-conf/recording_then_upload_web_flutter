import 'dart:html' as html;
import 'dart:js' as js;
// import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;

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
  String _statusMessage = 'Ready'; // To store the status message

  @override
  void initState() {
    super.initState();
    _preview = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..style.width = '100%' // Set explicit style for width
      ..style.height = '100%'; // Set explicit style for height

    _result = html.VideoElement()
      ..autoplay = false
      ..muted = false
      ..style.width = '100%' // Set explicit style for width
      ..style.height = '100%' // Set explicit style for height
      ..controls = true;

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('preview', (int _) => _preview);

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory('result', (int _) => _result);
  }

  Future<html.MediaStream?> _openCamera() async {
    setState(() {
      _statusMessage = 'Accessing camera...';
    });

    final html.MediaStream? stream = await html.window.navigator.mediaDevices
        ?.getUserMedia({'video': true, 'audio': true});
    _preview.srcObject = stream;

    if (stream == null) {
      setState(() {
        _statusMessage = 'Failed to access camera.';
      });
    } else {
      setState(() {
        _statusMessage = 'Camera accessed successfully.';
      });
    }

    return stream;
  }

  void startRecording(html.MediaStream stream) {
    setState(() {
      _statusMessage = 'Starting recording...';
    });

    _recorder = html.MediaRecorder(stream);
    _recorder.start();

    _recorder.addEventListener('dataavailable', (event) {
      _blob = js.JsObject.fromBrowserObject(event)['data'];
    }, true);

    _recorder.addEventListener('stop', (event) {
      final url = html.Url.createObjectUrl(_blob);
      _result.src = url;
      setState(() {
        _statusMessage = 'Recording stopped. Ready to upload.';
      });

      stream.getTracks().forEach((track) {
        if (track.readyState == 'live') {
          track.stop();
        }
      });
    });
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
          'https://hr.computerengine.net/EmpMobile/Jobs/SmartUpload/uploadexmple.asp',
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
        } else {
          setState(() {
            _statusMessage = 'Unexpected request state.';
          });
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
        _statusMessage = 'Failed to upload.';
      });
    }
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
                Text(
                  'Recording Preview',
                ),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10.0),
                  width: 300,
                  height: 200,
                  color: Colors.blue,
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
                          final html.MediaStream? stream = await _openCamera();
                          if (stream != null) {
                            startRecording(stream);
                          }
                        },
                        child: Text('Start Recording'),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      ElevatedButton(
                        onPressed: () => stopRecording(),
                        child: Text('Stop Recording'),
                      ),
                      SizedBox(
                        width: 20.0,
                      ),
                      ElevatedButton(
                        onPressed: () => uploadVideo(),
                        child: Text('Upload Video'),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Recording Result',
                ),
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
