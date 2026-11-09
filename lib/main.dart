import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

void main() => runApp(const KlonFlowApp());

class KlonFlowApp extends StatelessWidget {
  const KlonFlowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Klon Flow',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _server = TextEditingController();
  final _prompt = TextEditingController();
  VideoPlayerController? _video;
  bool _loading = false;
  String? _error;

  Future<void> _generate() async {
    if (_server.text.trim().isEmpty || _prompt.text.trim().isEmpty) {
      setState(() => _error = 'Isi alamat server dan prompt dulu.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http
          .post(
            Uri.parse(_server.text.trim()),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': _prompt.text.trim()}),
          )
          .timeout(const Duration(minutes: 10));
      if (res.statusCode != 200) {
        throw Exception('Server membalas ${res.statusCode}');
      }
      final url = jsonDecode(res.body)['video_url'] as String;
      final old = _video;
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      await c.initialize();
      await c.setLooping(true);
      await c.play();
      setState(() => _video = c);
      await old?.dispose();
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _server.dispose();
    _prompt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klon Flow')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _server,
            decoration: const InputDecoration(
              labelText: 'Alamat server (https://...)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _prompt,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Deskripsi video',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _loading ? null : _generate,
            child: Text(_loading ? 'Memproses...' : 'Buat Video'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_video != null && _video!.value.isInitialized)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AspectRatio(
                aspectRatio: _video!.value.aspectRatio,
                child: VideoPlayer(_video!),
              ),
            ),
        ],
      ),
    );
  }
}
