import 'package:flutter/material.dart';
import 'package:menu/dashboardChef/CreacionMenu.dart';
import 'package:menu/dashboardChef/HistorialComanda.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/MenuChef.dart';
import 'package:menu/dashboardChef/ComandaChef.dart';
import 'package:menu/dashboardChef/BebidaChef.dart';

class PrincipalChef extends StatefulWidget {
  final int currentIndex;
  const PrincipalChef({super.key, this.currentIndex = 0});

  @override
  State<PrincipalChef> createState() => _PrincipalChefState();
}

class _PrincipalChefState extends State<PrincipalChef> {
  late int _selectedIndex;

  final List<Widget> _pages = <Widget>[
    const MenuChef(),
    const BebidaChef(),
    const CreacionMenu(),
    const ComandaChef(),
    const HistorialComanda(),
    Inventario(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context); // Cierra el Drawer después de seleccionar una opción
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chef")),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: const Text(
                "Menú de Opciones",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text("Menú"),
              selected: _selectedIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            ListTile(
              title: const Text("Bebidas"),
              selected: _selectedIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            ListTile(
              title: const Text("Crear Plato o Bebida"),
              selected: _selectedIndex == 2,
              onTap: () => _onItemTapped(2),
            ),
            ListTile(
              title: const Text("Comandas"),
              selected: _selectedIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            ListTile(
              title: const Text("Historial de Comandas"),
              selected: _selectedIndex == 4,
              onTap: () => _onItemTapped(4),
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text("Inventario"),
              selected: _selectedIndex == 5,
              onTap: () => _onItemTapped(5),
            ),  
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
