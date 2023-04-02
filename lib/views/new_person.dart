import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:gift_app/models/ModelProvider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';

class NewPersonView extends StatefulWidget {
  const NewPersonView({super.key});

  @override
  State<NewPersonView> createState() => _NewPersonViewState();
}

class _NewPersonViewState extends State<NewPersonView> {
  late TextEditingController _nameController;
  final picker = ImagePicker();
  String _key = "";

  Future<void> saveNewPerson(String name) async {
    final newPerson = Person(
      name: name,
      pictureKey: _key,
    );
    try {
      await Amplify.DataStore.save(newPerson);
    } on DataStoreException catch (e) {
      safePrint(e);
    }
  }

  Future<void> uploadImage() async {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) {
      safePrint('Kein Bild ausgewählt');
      return;
    }
    final uniqueKey = const Uuid().v1();
    final key = pickedFile.name + uniqueKey;
    final file = File(pickedFile.path);
    try {
      final UploadFileResult result = await Amplify.Storage.uploadFile(
        local: file,
        key: key,
        onProgress: (progress) {
          safePrint('Abschnitt fertig: ${progress.getFractionCompleted()}');
        },
      );
      _key = key;
      safePrint('Bild wurde hochgeladen: ${result.key}');
    } on StorageException catch (e) {
      safePrint(e);
    }
  }

  @override
  void initState() {
    _nameController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Person Hinzufügen'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 40,
          ),
          _description(),
          const SizedBox(
            height: 40,
          ),
          _textField(),
          const SizedBox(
            height: 40,
          ),
          _imageButton(),
          _button(),
        ],
      ),
    );
  }

  Widget _description() {
    return const Center(
      child: Text(
        "Trage eine neue Person ein, die du beschenken möchtest!",
        style: TextStyle(fontSize: 20),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _textField() {
    return Container(
      margin: const EdgeInsetsDirectional.all(8),
      child: TextField(
        controller: _nameController,
        decoration: const InputDecoration(
          hintText: 'Name',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _button() {
    return ElevatedButton(
      onPressed: () async {
        if (_nameController.text.isNotEmpty) {
          await saveNewPerson(_nameController.text);
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: const Text('Person speichern'),
    );
  }

  Widget _imageButton() {
    return ElevatedButton(
      onPressed: () {
        uploadImage();
      },
      child: const Text('Bild hinzufügen'),
    );
  }
}
