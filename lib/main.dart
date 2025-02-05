import 'dart:io';

import 'package:block_ui/block_ui.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const size = Size(600, 850);

  await windowManager.show();
  await windowManager.focus();
  await windowManager.setSize(size);
  await windowManager.setMaximumSize(size);
  await windowManager.setMinimumSize(size);
  await windowManager.setMaximizable(false);
  await windowManager.setResizable(false);
  await windowManager.setTitle("MPYDL");

  runApp(const MyApp());

  await windowManager.setAlignment(Alignment.center, animate: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MPYDL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
        ),
        useMaterial3: true,
        // fontFamily: 'Raleway',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            fontSize: 14.0,
            fontFamily: 'Hind',
            color: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const MyHomePage(title: 'GUI per YDL'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _output = "";
  final _urlController = TextEditingController();

  Future<void> _aggiornaYdl() async {
    try {
      Dio dio = Dio();
      String url =
          "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe";
      String filePath = "ydl.exe";

      await dio.download(url, filePath, onReceiveProgress: (received, total) {
        if (total != -1) {
          setState(() {
            _output =
                "Download progress: ${(received / total * 100).toStringAsFixed(0)}%";
          });
        }
      });

      setState(() {
        _output += "\n✅ File scaricato";
      });
    } catch (e) {
      setState(() {
        _output += "n❌ Errore nel download: $e";
      });
    }
  }

  Future<void> _scaricaMp3(String dir) async {
    String ydlUrl = _urlController.text;

    if (ydlUrl.isEmpty) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Attenzione!'),
          content: const Text('Inserire un url'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'OK'),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _output = "Download in corso...";
      });

      try {
        Process process = await Process.start(
          "ydl.exe",
          [
            "-x",
            "--audio-format",
            "mp3",
            "-o",
            "$dir\\%(title)s.%(ext)s\" ",
            // "C:\\Personal\\Musica\\%(title)s.%(ext)s\" ",
            _urlController.text
          ],
          runInShell: true,
        );

        process.stdout.transform(SystemEncoding().decoder).listen((data) {
          setState(() {
            _output += "\n$data";
          });
        });

        process.stderr.transform(SystemEncoding().decoder).listen((data) {
          setState(() {
            _output += "\nErrore: $data";
          });
        });

        int exitCode = await process.exitCode;
        setState(() {
          _output += exitCode == 0
              ? "\n✅ Download completato con successo!"
              : "\n❌ Errore nel download. Codice: $exitCode";
        });
      } catch (e) {
        setState(() {
          _output = "Errore nell'esecuzione: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // _urlController.text = "https://www.youtube.com/watch?v=g6t8g6ka4W0";

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   title: Text("MYDL"),
      // ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    BlockUi.show(
                      context,
                      child: SpinKitChasingDots(
                        color: Color(0xff388e3c),
                      ),
                    );
                    await _aggiornaYdl();
                    BlockUi.hide(context);
                  },
                  child: Text("Aggiorna YDL"),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
                    String? selectedDirectory =
                        await FilePicker.platform.getDirectoryPath();

                    if (selectedDirectory != null) {
                      BlockUi.show(
                        context,
                        child: SpinKitChasingDots(
                          color: Color(0xff388e3c),
                        ),
                      );
                      await _scaricaMp3(selectedDirectory);
                      BlockUi.hide(context);
                    }
                  },
                  child: Text("Scarica Canzone"),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: "Inserisci url",
                hintText: "Inserisci url",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(5),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _output,
                      style: TextStyle(
                        color: Colors.green,
                        // fontFamily: "monospace",
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
