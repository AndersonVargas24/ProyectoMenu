import 'package:flutter/material.dart';
import 'package:menu/WaiterDashboard/CrearComanda.dart';

class ViewComanda extends StatefulWidget {
  const ViewComanda({super.key});

  @override
  State<ViewComanda> createState() => _ViewComandaState();
}

class _ViewComandaState extends State<ViewComanda> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sección Comandas"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Navegar a crear comanda
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SeccionCreateComanda()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('comandas existentes'),
      ),
    );
  }
}