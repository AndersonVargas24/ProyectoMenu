import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class EditarProductoScreen extends StatefulWidget {
  final String productoId;
  final Map<String, dynamic> productoData;

  const EditarProductoScreen({
    super.key,
    required this.productoId,
    required this.productoData,
  });

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  late TextEditingController nombreController;
  late TextEditingController categoriaController;
  File? _nuevaImagen;
  bool _subiendo = false;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.productoData['nombre']);
    categoriaController = TextEditingController(text: widget.productoData['categoria']);
  
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _nuevaImagen = File(pickedFile.path);
      });
    }
  }

  Future<void> _guardarCambios() async {
    setState(() {
      _subiendo = true;
    });

    String? urlImagen = widget.productoData['imagenUrl'];

    if (_nuevaImagen != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('productos')
          .child('${widget.productoId}.jpg');
      await storageRef.putFile(_nuevaImagen!);
      urlImagen = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance
        .collection('productos')
        .doc(widget.productoId)
        .update({
      'nombre': nombreController.text,
      'Categoría': categoriaController.text,
      'imagenUrl': urlImagen,
    });

    setState(() {
      _subiendo = false;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: categoriaController,
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 10),
            _nuevaImagen != null
                ? Image.file(_nuevaImagen!, height: 150)
                : widget.productoData['imagenUrl'] != null
                    ? Image.network(widget.productoData['imagenUrl'], height: 150)
                    : const Placeholder(fallbackHeight: 150),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _seleccionarImagen,
              icon: const Icon(Icons.image),
              label: const Text('Cambiar imagen'),
            ),
            const SizedBox(height: 20),
            _subiendo
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _guardarCambios,
                    child: const Text('Guardar cambios'),
                  )
          ],
        ),
      ),
    );
  }
}
