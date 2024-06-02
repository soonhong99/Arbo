import 'package:arbo_frontend/resources/user_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';

  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = 'null';
  String _topic = '자유';
  String _scale = '대자보';
  String _content = 'null';
  String _nickName = 'null';
  final int _hearts = 0;
  final List<dynamic> _comments = [];
  Future<void> _savePost() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          _nickName = loginUserData!['닉네임'];
          // firebase에 post라는 이름으로 저장하고 싶을 떄
          await FirebaseFirestore.instance.collection('posts').add({
            'title': _title,
            'topic': _topic,
            'scale': _scale,
            'content': _content,
            'userId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
            'nickname': _nickName,
            'comments': _comments,
            'hearts': _hearts,
          });
          Navigator.pop(context);
        } catch (e) {
          print(e);
        }
      }
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
