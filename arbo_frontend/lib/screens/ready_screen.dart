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
  final Random _random = Random();
  Color _currentColor = Colors.blue;
  Path _currentPath = Path();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetDrawing() {
    setState(() {
      userPaintBackGround.clear();
    });
  }

  Color _getRandomColor() {
    // 더 진한 색상을 생성하기 위해 RGB 값의 범위를 조정합니다.
    int red = _random.nextInt(200) + 56; // 56-255
    int green = _random.nextInt(200) + 56; // 56-255
    int blue = _random.nextInt(200) + 56; // 56-255

    // 노란색과 살구색 계열을 피하기 위한 조건
    if ((red > 200 && green > 200) ||
        (red > 200 && green > 150 && blue < 100)) {
      // 노란색이나 살구색에 가까운 경우, 파란색 계열로 조정
      blue = _random.nextInt(100) + 156; // 156-255
      red = _random.nextInt(100); // 0-99
      green = _random.nextInt(100); // 0-99
    }

    return Color.fromRGBO(red, green, blue, 0.8); // 투명도를 0.8로 설정
  }

  void _startNewStroke(Offset position) {
    setState(() {
      _currentColor = _getRandomColor();
      _currentPath = Path();
      _currentPath.moveTo(position.dx, position.dy);
      userPaintBackGround
          .add(PaintStroke(path: _currentPath, color: _currentColor));
    });
  }

  void _updateStroke(Offset position) {
    setState(() {
      if (userPaintBackGround.isNotEmpty) {
        _currentPath.lineTo(position.dx, position.dy);
      }
    });
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
              painter: PathPainter(userPaintBackGround),
              size: Size.infinite,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white70, Colors.yellow, Colors.blue],
                  ).createShader(bounds),
                  child: Text(
                    'CommPain\'t',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(5.0, 5.0),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _navigateToRootScreen,
                  icon: const Icon(Icons.brush, size: 24),
                  label: const Text(
                    'Paint Local Society YOURSELF!',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: IconButton(
              icon: const Icon(Icons.refresh),
              iconSize: 32,
              color: Colors.red,
              onPressed: _resetDrawing,
              tooltip: 'Reset Drawing',
            ),
          ),
        ],
      ),
    );
  }
}
