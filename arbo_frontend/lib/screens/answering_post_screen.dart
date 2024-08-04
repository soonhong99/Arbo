import 'package:arbo_frontend/data/user_data.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;

class AnsweringPostScreen extends StatefulWidget {
  final String postId;

  const AnsweringPostScreen({super.key, required this.postId});

  @override
  _AnsweringPostScreenState createState() => _AnsweringPostScreenState();
}

class _AnsweringPostScreenState extends State<AnsweringPostScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _content = '';
  final List<String> _imageUrls = [];
  final List<Map<String, dynamic>> _comments = [];
  final int _hearts = 0;

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
        final storageRef = FirebaseStorage.instance.ref().child(
            'answering_posts/${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putBlob(file);
        final snapshot = await uploadTask.whenComplete(() {});

        final imageUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _imageUrls.add(imageUrl);
        });
      });
    });
  }

  void _saveAnsweringPost() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('answeringPost')
            .add({
          'title': _title,
          'content': _content,
          'imageUrls': _imageUrls,
          'timestamp': DateTime.now(),
          'nickname': nickname,
          'answeredUserId': userUid,
          'greatAnswer': false,
          'comments': _comments,
          'hearts': _hearts,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Answering post uploaded successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error saving answering post: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Failed to upload answering post. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Our Answer'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.green[50],
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a title' : null,
                  onSaved: (value) => _title = value!,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.green[50],
                  ),
                  maxLines: 10,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter content' : null,
                  onSaved: (value) => _content = value!,
                ),
                const SizedBox(height: 20),
                Text(
                  'Images (${_imageUrls.length}/5)',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._imageUrls.map((url) => _buildImagePreview(url)),
                    if (_imageUrls.length < 5)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_photo_alternate,
                              color: Colors.green, size: 40),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Your Answering'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: _saveAnsweringPost,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(String url) {
    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, fit: BoxFit.cover),
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
}
