import 'dart:math';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:flutter/material.dart';

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  _ReadyScreenState createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _locationMessage;
  final bool _isLoading = false;

  final Random _random = Random();
  Color _currentColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  Color _getRandomColor() {
    return Color.fromRGBO(
      _random.nextInt(256),
      _random.nextInt(256),
      _random.nextInt(256),
      0.5,
    );
  }

  void _startNewStroke(Offset position) {
    setState(() {
      _currentColor = _getRandomColor();
      userPaintBackGround
          .add(PaintStroke(points: [position], color: _currentColor));
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      if (userPaintBackGround.isNotEmpty) {
        userPaintBackGround.last.points.add(position);
        _currentColor = _getRandomColor();
        userPaintBackGround.last.color = _currentColor;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToRootScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RootScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) => _startNewStroke(details.localPosition),
            onPanUpdate: (details) => _updateStroke(details.localPosition),
            child: CustomPaint(
              painter: StrokePainter(userPaintBackGround),
              size: Size.infinite,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'CommPain\'t',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                if (!_isLoading)
                  ElevatedButton(
                    onPressed: _navigateToRootScreen,
                    child: const Text(
                      'Click and Paint Local Society YOURSELF!',
                      style: TextStyle(
                        fontSize: 18, // 'CommPain't 텍스트 크기와 동일하게 설정
                      ),
                    ),
                  ),
                if (_isLoading) const CircularProgressIndicator(),
                if (_locationMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _locationMessage!,
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
