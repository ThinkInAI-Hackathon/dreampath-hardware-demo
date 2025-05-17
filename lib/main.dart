import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

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

  @override
  void initState() {
    super.initState();
    _checkTorchAvailability();
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

  Future<void> _toggleTorch() async {
    if (!_hasTorch) return;

    try {
      if (_isTorchOn) {
        await TorchLight.disableTorch();
      } else {
        await TorchLight.enableTorch();
      }
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法控制手电筒: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台灯'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
          ],
        ),
      ),
    );
  }
}
