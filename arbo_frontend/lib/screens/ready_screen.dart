import 'dart:math';
import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/design/paint_stroke.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:arbo_frontend/roots/root_screen.dart';
import 'package:google_geocoding/google_geocoding.dart';

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  _ReadyScreenState createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _locationMessage;
  bool _isLoading = false;

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

  Future<void> _getLocationPermission() async {
    setState(() {
      _isLoading = true;
      _locationMessage = '위치 정보를 가져오는 중...';
    });

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      setState(() {
        _isLoading = false;
        _locationMessage = '위치 권한이 거부되었습니다.';
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _locationMessage = '위치 권한이 영구적으로 거부되었습니다.';
      });
      return;
    }

    _getLocation();
  }

  Future<void> _getLocation() async {
    // 현재 위치를 가져옴
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    var response = await googleGeocoding.geocoding
        .getReverse(LatLon(position.latitude, position.longitude));

    if (response != null && response.results != null) {
      final geocodingResponse = response.results;
      if (geocodingResponse != null) {
        address = geocodingResponse[0].formattedAddress!;
        print(address);
        setState(() {
          _isLoading = false;
          _locationMessage = address;
        });

        // 2초 후에 RootScreen으로 이동
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) =>
                    RootScreen(locationMessage: _locationMessage!)),
          );
        });
      } else {
        // 플라크마크가 비어있는 경우
        setState(() {
          _isLoading = false;
          _locationMessage = '지명 정보를 가져오지 못했습니다.';
        });
      }
    }

    // 디버그 정보: 플라크마크 리스트 출력
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
                const SizedBox(height: 20),
                if (!_isLoading)
                  ElevatedButton(
                    onPressed: _getLocationPermission,
                    child: const Text('Paint Local Society YOURSELF!'),
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
