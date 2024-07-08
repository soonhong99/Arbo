import 'package:flutter/material.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> postData;

  const EditPostScreen({super.key, required this.postData});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _topic;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.postData['title']);
    _contentController =
        TextEditingController(text: widget.postData['content']);
    _topic = widget.postData['topic'];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'topic': _topic,
        'title': _titleController.text,
        'content': _contentController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _topic,
                decoration: const InputDecoration(labelText: 'Topic'),
                items: <String>[
                  'Education and Development',
                  'Improving Facilities',
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
                validator: (value) =>
                    value == null ? 'Please select a topic' : null,
              ),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a title' : null,
              ),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: null,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter content' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
