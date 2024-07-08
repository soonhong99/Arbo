import 'package:arbo_frontend/data/user_data.dart';
import 'package:arbo_frontend/data/user_data_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;

Future<String> createNewPost(String title, String content, String topic) async {
  try {
    DocumentReference docRef =
        await firestore_instance.collection('posts').add({
      'title': title,
      'topic': topic,
      'scale': '대자보', // 기본값 설정
      'content': content,
      'userId': currentLoginUser?.uid ?? 'anonymous',
      'timestamp': DateTime.now(),
      'nickname': loginUserData!['닉네임'] ?? 'Anonymous',
      'comments': [],
      'hearts': 0,
      'designedPicture': [],
      'visitedUser': 0,
    });
    print('Post created successfully');
    return docRef.id;
  } catch (e) {
    print('Error creating post: $e');
    rethrow;
  }
}

class CreatePostScreen extends StatefulWidget {
  static const routeName = '/create-post';

  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = 'null';
  String _topic = 'Education and Development';
  String _scale = '대자보';
  String _content = 'null';
  String _nickName = 'null';
  final int _hearts = 0;
  final List<Map<String, dynamic>> _comments = [];
  final List<String> _imageUrls = [];
  final int _visitedUsers = 0;
  final UserDataProvider userDataProvider = UserDataProvider();
  bool _isPostSaved = false;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _pickImage() async {
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();

      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((e) async {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putBlob(file);
        final snapshot = await uploadTask.whenComplete(() {});

        final imageUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _imageUrls.add(imageUrl);
        });
      });
    });
  }

  void _deleteImages() async {
    for (var imageUrl in _imageUrls) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }

  void _savePost() async {
    final isValid = _formKey.currentState!.validate();

    if (isValid) {
      _formKey.currentState!.save();
      if (currentLoginUser != null) {
        try {
          _nickName = nickname;
          // Save post to Firestore
          await firestore_instance.collection('posts').add({
            'title': _title,
            'topic': _topic,
            'scale': _scale,
            'content': _content,
            'userId': userUid,
            'timestamp': DateTime.now(),
            'nickname': _nickName,
            'comments': _comments,
            'hearts': _hearts,
            'designedPicture': _imageUrls,
            'visitedUser': _visitedUsers, // 방문한 사용자 닉네임 리스트 초기화
          });

          setState(() {
            _isPostSaved = true;
          });

          if (mounted) {
            Future.delayed(const Duration(seconds: 1)).then((_) {
              Navigator.of(context).pop(true);
            });
          }
        } catch (e) {
          print(e);
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isPostSaved && _imageUrls.isNotEmpty) {
      () {
        _deleteImages();
      };
    }
    return true;
  }

  @override
  void dispose() {
    if (!_isPostSaved && _imageUrls.isNotEmpty) {
      _deleteImages();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Post'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop) {
                Navigator.of(context).pop();
              }
            },
          ),
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
                  items: <String>[
                    'Education and Development',
                    'Improving Facilites',
                    'Recycling Management',
                    'Crime Prevention',
                    'Local Commercial',
                    'Local Events'
                  ].map<DropdownMenuItem<String>>((String value) {
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _imageUrls.length < 3 ? _pickImage : null,
                  child: const Text('Upload Image'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _imageUrls
                      .map((url) => Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(),
                            ),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print(error);
                                return const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                );
                              },
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
