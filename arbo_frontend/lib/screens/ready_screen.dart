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
                const Text(
                  'CommPain\'t',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _navigateToRootScreen,
                  child: const Text(
                    'Click and Paint Local Society YOURSELF!',
                    style: TextStyle(fontSize: 18),
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
