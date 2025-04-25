import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            ListTile(
              leading: const Icon(Icons.collections),
              title: const Text('Elegir de galería de app'),
              onTap: () {
                Navigator.pop(context);
                _mostrarSelectorImagen();
              },
            ),
          ],
        );
      },
    );
  }

  void _mostrarSelectorImagen() {
    List<String> imagenes = [];

    if (dropdownValue == 'Bebida') {
      imagenes = [
        'assets/bebidas/limonadas/limonada.png',
      ];
    } else {
      imagenes = [
        'assets/platos/bandeja_paisa/bandeja1.png',
      ];
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: GridView.builder(
            itemCount: imagenes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    imagenSeleccionada = imagenes[index];
                    imagenDesdeDispositivo = null;
                  });
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(imagenes[index], fit: BoxFit.cover),
                ),
              );
            },
          ),
        );
      },
    );
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
      await FirebaseFirestore.instance.collection('menu').add({
        'nombre': nombre,
        'precio': double.tryParse(precio) ?? 0,
        'descripcion': descripcion,
        'tipo': tipo,
        'imagen': imagenSeleccionada ?? '', // Guardamos solo si es asset
        'fechaCreacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plato subido exitosamente')),
      );
      Navigator.pop(context);
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
        leading: const BackButton(),
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
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 51, 50, 115),
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('CANCELAR'),
                ),
                ElevatedButton(
                  onPressed: _subirPlato,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 51, 50, 115),
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('SUBIR'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}