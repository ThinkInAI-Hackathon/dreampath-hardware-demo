import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const TorchApp());
}

class TorchApp extends StatelessWidget {
  const TorchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台灯',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const TorchHomePage(),
    );
  }
}

class TorchHomePage extends StatefulWidget {
  const TorchHomePage({super.key});

  @override
  State<TorchHomePage> createState() => _TorchHomePageState();
}

class _TorchHomePageState extends State<TorchHomePage> {
  bool _isTorchOn = false;
  bool _hasTorch = false;
  Timer? _apiCheckTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkTorchAvailability();
    _startApiCheck();
  }

  @override
  void dispose() {
    _apiCheckTimer?.cancel();
    super.dispose();
  }

  void _startApiCheck() {
    // Initial check
    _checkApiStatus();

    // Set up periodic check every 30 seconds
    _apiCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkApiStatus();
    });
  }

  Future<void> _checkApiStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await http.get(Uri.parse('https://deeppath.cc/api/devices/lamp'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'on' && !_isTorchOn) {
          _turnOnTorch();
        } else if (status == 'off' && _isTorchOn) {
          _turnOffTorch();
        }
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API请求失败: HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法连接到API: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkTorchAvailability() async {
    try {
      _hasTorch = await TorchLight.isTorchAvailable();
      setState(() {});
    } catch (e) {
      setState(() {
        _hasTorch = false;
      });
    }
  }

  Future<void> _turnOnTorch() async {
    if (!_hasTorch) return;

    try {
      await TorchLight.enableTorch();
      setState(() {
        _isTorchOn = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法开启手电筒: ${e.toString()}')),
      );
    }
  }

  Future<void> _turnOffTorch() async {
    if (!_hasTorch) return;

    try {
      await TorchLight.disableTorch();
      setState(() {
        _isTorchOn = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法关闭手电筒: ${e.toString()}')),
      );
    }
  }

  Future<void> _toggleTorch() async {
    if (!_hasTorch) return;

    if (_isTorchOn) {
      await _turnOffTorch();
    } else {
      await _turnOnTorch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灯'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkApiStatus,
            tooltip: '立即检查API状态',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_hasTorch)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  '设备没有手电筒功能',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
              ),
            GestureDetector(
              onTap: _toggleTorch,
              child: Icon(
                _isTorchOn ? Icons.flashlight_on : Icons.flashlight_off,
                size: 150,
                color: _isTorchOn ? Colors.amber : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              _isTorchOn ? '点击关闭手电筒' : '点击打开手电筒',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              '每30秒自动同步API状态',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
