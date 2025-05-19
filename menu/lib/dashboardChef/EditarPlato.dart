import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  }

  Future<void> _guardarEdicion() async {
    if (_formKey.currentState!.validate()) {
      final updatedPlato = {
        'nombre': _nombreController.text,
        'precio': double.tryParse(_precioController.text) ?? 0,
        'descripcion': _descripcionController.text,
        'tipo': _tipo,
        'imagen': _imagen,
      };

      try {
        await FirebaseFirestore.instance.collection('menu').doc(widget.itemId).update(updatedPlato);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plato actualizado exitosamente')));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Plato'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _guardarEdicion,
          ),
        ],
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance.collection('menu').doc(widget.itemId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No se encontró el plato"));
          }

          final data = snapshot.data as DocumentSnapshot;
          final item = data.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nombre del Plato',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe el nombre del plato',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el nombre del plato';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Precio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: _precioController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe el precio',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa el precio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe una breve descripción',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa la descripción';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tipo de Plato',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Plato'),
                          selected: _tipo == 'Plato',
                          onSelected: (selected) {
                            setState(() {
                              _tipo = 'Plato';
                            });
                          },
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Bebida'),
                          selected: _tipo == 'Bebida',
                          onSelected: (selected) {
                            setState(() {
                              _tipo = 'Bebida';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Imagen del Plato (URL o asset)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextFormField(
                      initialValue: _imagen,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'URL de la imagen o nombre del asset',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _imagen = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _guardarEdicion,
                      child: const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
