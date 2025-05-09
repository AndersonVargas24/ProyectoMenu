import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/dashboardChef/BebidaChef.dart';
import 'package:menu/dashboardChef/MenuChef.dart';

class CreacionMenu extends StatefulWidget {
  const CreacionMenu({super.key});

  @override
  State<CreacionMenu> createState() => _CreacionMenuState();
}

class _CreacionMenuState extends State<CreacionMenu> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  String dropdownValue = 'Bebida';
  String? imagenSeleccionada;
  File? imagenDesdeDispositivo;

  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarDesdeGaleria() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        imagenDesdeDispositivo = File(imagen.path);
        imagenSeleccionada = null;
      });
    }
  }

  Future<void> _tomarFoto() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        imagenDesdeDispositivo = File(foto.path);
        imagenSeleccionada = null;
      });
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Seleccionar de galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarDesdeGaleria();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _tomarFoto();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String?> _subirImagenAStorage(File imagen) async {
    try {
      final nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('menu/$nombreArchivo');
      final uploadTask = await storageRef.putFile(imagen);
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Error al subir imagen: $e');
      return null;
    }
  }

  Future<void> _subirPlato() async {
    String nombre = nombreController.text.trim();
    String precio = precioController.text.trim();
    String descripcion = descripcionController.text.trim();
    String tipo = dropdownValue;

    if (nombre.isEmpty || precio.isEmpty || descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    try {
      String? urlImagen;

      if (imagenDesdeDispositivo != null) {
        urlImagen = await _subirImagenAStorage(imagenDesdeDispositivo!);
      } else {
        urlImagen = imagenSeleccionada;
      }

      await FirebaseFirestore.instance.collection('menu').add({
        'nombre': nombre,
        'precio': double.tryParse(precio) ?? 0,
        'descripcion': descripcion,
        'tipo': tipo,
        'imagen': urlImagen ?? '',
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato subido exitosamente')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PrincipalChef(
            currentIndex: tipo == 'Bebida' ? 1 : 0, // Ajusta el índice según tu orden
          ),
        ),
      );
    } catch (e) {
      print('Error al subir: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir el plato')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 247, 254),
      appBar: AppBar(
        title: const Text("Nuevo plato"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PrincipalChef(currentIndex: 0),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _mostrarOpcionesImagen,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: imagenDesdeDispositivo != null
                      ? Image.file(imagenDesdeDispositivo!, fit: BoxFit.cover)
                      : imagenSeleccionada != null
                          ? Image.asset(imagenSeleccionada!, fit: BoxFit.cover)
                          : const Icon(Icons.download, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre:',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio:',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción:',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo:',
                  border: InputBorder.none,
                ),
                value: dropdownValue,
                items: ['Bebida', 'Plato']
                    .map((tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    dropdownValue = value!;
                    if (imagenDesdeDispositivo == null) {
                      imagenSeleccionada = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PrincipalChef(currentIndex: 0),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 208, 208, 233),
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('  CANCELAR  '),
                ),
                ElevatedButton(
                  onPressed: _subirPlato,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 208, 208, 233),
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('SUBIR PLATO'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
