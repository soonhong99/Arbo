import 'package:flutter/material.dart';

class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';

  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _topic = '자유';
  String _scale = '대자보';
  String _content = '';

  void _savePost() {
    final isValid = _formKey.currentState!.validate();
    if (isValid) {
      _formKey.currentState!.save();
      // 로직을 추가하여 서버에 게시물을 저장하거나, 로컬 데이터베이스에 저장합니다.
      // 예: uploadPost(_title, _topic, _content);
      Navigator.pop(context); // 포스트 저장 후 화면을 닫습니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePost,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) {
                  return value!.isEmpty ? 'Please enter a title' : null;
                },
                onSaved: (value) => _title = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Scale'),
                value: _scale,
                items: <String>['대자보', '소자보']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _scale = newValue!;
                  });
                },
                validator: (value) {
                  return value == null || value.isEmpty
                      ? 'Please select a scale'
                      : null;
                },
                onSaved: (value) => _scale = value!,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Topic'),
                value: _topic,
                items: <String>['정치', '경제', '사회', '정보', '호소', '자유']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _topic = newValue!;
                  });
                },
                validator: (value) {
                  return value == null || value.isEmpty
                      ? 'Please select a topic'
                      : null;
                },
                onSaved: (value) => _topic = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 8,
                validator: (value) {
                  return value!.isEmpty ? 'Please enter some content' : null;
                },
                onSaved: (value) => _content = value!,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
