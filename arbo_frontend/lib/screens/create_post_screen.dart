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
      'status': 'pending',
      'country': myCountry,
      'city': myCity,
      //'district': myDistrict,
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
            'country': loginUserData!['country'],
            'city': loginUserData!['city'],
            //'district': loginUserData!['district'],
            'status': 'pending'
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

  Widget _buildTextField({
    required IconData icon,
    required String label,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdown({
    required IconData icon,
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String? Function(String?) validator,
    required Function(String?) onSaved,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: value,
      items: items.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Images (${_imageUrls.length}/3)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _imageUrls.length < 3 ? _pickImage : null,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Upload Image'),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _imageUrls.map((url) => _buildImagePreview(url)).toList(),
        ),
      ],
    );
  }

  Widget _buildImagePreview(String url) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
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
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _imageUrls.remove(url);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
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
            TextButton.icon(
              icon: const Icon(Icons.save),
              label: const Text(
                "Upload your painting!",
                style: TextStyle(
                  color: Colors.green, // 연두색 텍스트 색상
                  fontWeight: FontWeight.bold, // 굵은 텍스트
                ),
              ),
              onPressed: _savePost,
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildTextField(
                    icon: Icons.title,
                    label: 'Title',
                    onSaved: (value) => _title = value!,
                    validator: (value) {
                      return value!.isEmpty ? 'Please enter a title' : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    icon: Icons.scale,
                    label: 'Scale',
                    value: _scale,
                    items: ['대자보', '소자보'],
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
                  const SizedBox(height: 16),
                  _buildDropdown(
                    icon: Icons.category,
                    label: 'Topic',
                    value: _topic,
                    items: [
                      'Education and Development',
                      'Improving Facilites',
                      'Recycling Management',
                      'Crime Prevention',
                      'Local Commercial',
                      'Local Events'
                    ],
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
                  const SizedBox(height: 16),
                  _buildTextField(
                    icon: Icons.article,
                    label: 'Content',
                    maxLines: 8,
                    onSaved: (value) => _content = value!,
                    validator: (value) {
                      return value!.isEmpty
                          ? 'Please enter some content'
                          : null;
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildImageUploadSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
