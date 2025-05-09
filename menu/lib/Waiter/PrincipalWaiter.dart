import 'package:flutter/material.dart';
import 'package:menu/WaiterDashboard/SeccionMenu.dart';

class Principalwaiter extends StatefulWidget {
  const Principalwaiter({super.key});

  @override
  State<Principalwaiter> createState() => _PrincipalwaiterState();
}

class _PrincipalwaiterState extends State<Principalwaiter> {
  int _selectedIndex = 0;
  final List<Widget> _pages = <Widget>[
    const SeccionMenu(),
  ];

  void _onItemTapped (int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop (context); // Cierra el Drawer después de seleccionar una opción
    });
  }
  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mesero")),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              // ignore: sort_child_properties_last
              child: Text("Menú de Opciones"),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: Text("Menú"),
              onTap: () => _onItemTapped(0),
            ),

            ListTile(
              leading: const Icon(Icons.receipt),
              title: Text("Comandas"),
              onTap: () => _onItemTapped(2),
            ),
           
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}