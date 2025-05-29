import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditarPlatoPage extends StatefulWidget {
  final String itemId;

  const EditarPlatoPage({super.key, required this.itemId});

  @override
  _EditarPlatoPageState createState() => _EditarPlatoPageState();
}

class _EditarPlatoPageState extends State<EditarPlatoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _precioController;
  late TextEditingController _descripcionController;
  String _tipo = 'Plato';
  String _imagen = '';
  bool _cargando = true;
  File? _nuevaImagen;

  @override
  void initState() {
    super.initState();
    _cargarPlato();
  }

  Future<void> _cargarPlato() async {
    final doc = await FirebaseFirestore.instance.collection('menu').doc(widget.itemId).get();
    final data = doc.data() as Map<String, dynamic>;

    _nombreController = TextEditingController(text: data['nombre']);
    _precioController = TextEditingController(text: data['precio'].toString());
    _descripcionController = TextEditingController(text: data['descripcion']);
    _tipo = data['tipo'];
    _imagen = data['imagen'];

    setState(() {
      _cargando = false;
    });
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

  Future<String?> _subirImagen(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('platos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _guardarEdicion() async {
    if (_formKey.currentState!.validate()) {
      String urlFinal = _imagen;

      if (_nuevaImagen != null) {
        final subida = await _subirImagen(_nuevaImagen!);
        if (subida != null) {
          urlFinal = subida;
        }
      }

      final updatedPlato = {
        'nombre': _nombreController.text,
        'precio': double.tryParse(_precioController.text) ?? 0,
        'descripcion': _descripcionController.text,
        'tipo': _tipo,
        'imagen': urlFinal,
      };

      try {
        await FirebaseFirestore.instance.collection('menu').doc(widget.itemId).update(updatedPlato);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plato actualizado exitosamente')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Plato'),
        backgroundColor: const Color.fromARGB(255, 33, 150, 243),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarEdicion,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nombre del Plato', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  decoration: _inputDecoration('Ej. Arroz con Pollo'),
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese el nombre del plato' : null,
                ),
                const SizedBox(height: 16),
                const Text('Precio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _precioController,
                  decoration: _inputDecoration('Ej. 12000'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese el precio' : null,
                ),
                const SizedBox(height: 16),
                const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descripcionController,
                  decoration: _inputDecoration('Ej. Plato típico con pollo, arroz y verduras.'),
                  maxLines: 3,
                  validator: (value) => value == null || value.isEmpty ? 'Ingrese la descripción' : null,
                ),
                const SizedBox(height: 16),
                const Text('Tipo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: [
                    ChoiceChip(
                      label: const Text('Plato'),
                      selected: _tipo == 'Plato',
                      selectedColor: const Color.fromARGB(255, 33, 150, 243),
                      onSelected: (selected) => setState(() => _tipo = 'Plato'),
                    ),
                    ChoiceChip(
                      label: const Text('Bebida'),
                      selected: _tipo == 'Bebida',
                      selectedColor: const Color.fromARGB(255, 33, 150, 243),
                      onSelected: (selected) => setState(() => _tipo = 'Bebida'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Imagen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: _seleccionarImagen,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _nuevaImagen != null
                          ? Image.file(_nuevaImagen!, height: 200, width: double.infinity, fit: BoxFit.cover)
                          : (_imagen.isNotEmpty
                              ? Image.network(_imagen, height: 200, width: double.infinity, fit: BoxFit.cover)
                              : Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.add_a_photo, size: 50),
                                )),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _guardarEdicion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 33, 150, 243),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}