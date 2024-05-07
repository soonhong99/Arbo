import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:arbo_frontend/widgets/main_widgets/key_board_trigger_widget.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KeyBoardTrigger(
                labelText: '검색할 나무를 입력하세요',
                screenWidth: screenWidth,
              ),
              const SizedBox(
                width: 10,
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
        Expanded(
          child: hotPost(screenWidth),
        ),
      ],
    );
  }

  ListView hotPost(double screenWidth) {
    return ListView.separated(
      scrollDirection: Axis.vertical,
      separatorBuilder: (context, index) => const SizedBox(
        height: 5,
      ),
      itemCount: 5, // hardcoding
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              Container(
                height: 500,
                color: Colors.green[500],
                child: const Center(child: Text('Entry A')),
              ),
              Container(
                height: 500,
                color: Colors.green[300],
                child: const Center(child: Text('Entry B')),
              ),
              Container(
                height: 500,
                color: Colors.green[100],
                child: const Center(child: Text('Entry C')),
              ),
            ],
          ),
        );
      },
    );
  }
}
