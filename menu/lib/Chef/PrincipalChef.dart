import 'package:flutter/material.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:menu/dashboardChef/CreacionMenu.dart';
import 'package:menu/dashboardChef/HistorialComanda.dart';
import 'package:menu/dashboardChef/Inventario.dart';
import 'package:menu/dashboardChef/MenuChef.dart';
import 'package:menu/dashboardChef/ComandaChef.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrincipalChef extends StatefulWidget {
  final int currentIndex;
  const PrincipalChef({super.key, this.currentIndex = 0});

  @override
  State<PrincipalChef> createState() => _PrincipalChefState();
}

class _PrincipalChefState extends State<PrincipalChef> {
  late int _selectedIndex;
  String _rolUsuario = "Hola, Chef";

  final List<Widget> _pages = <Widget>[
    const MenuChef(),
    const CreacionMenu(),
    const ComandaChef(),
    const HistorialComanda(),
    Inventario(),
  ];

  final List<DrawerItem> _drawerItems = [
    DrawerItem(
      icon: Icons.restaurant_menu,
      title: "Menú",
      subtitle: "Ver platos disponibles",
    ),
    DrawerItem(
      icon: Icons.add_circle_outline,
      title: "Crear Plato",
      subtitle: "Añadir nuevo elemento",
    ),
    DrawerItem(
      icon: Icons.receipt_long,
      title: "Comandas",
      subtitle: "Pedidos activos",
    ),
    DrawerItem(
      icon: Icons.history,
      title: "Historial",
      subtitle: "Comandas anteriores",
    ),
    DrawerItem(
      icon: Icons.inventory_2,
      title: "Inventario",
      subtitle: "Gestionar productos",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
    obtenerRolUsuario();
  }

  Future<void> obtenerRolUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('rol')) {
        setState(() {
          _rolUsuario = doc['rol'];
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chef"),
        backgroundColor: const Color.fromARGB(255, 67, 126, 236),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 117, 182, 219),
                    Color.fromARGB(255, 74, 84, 143),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _rolUsuario,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        "Panel de Control",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _drawerItems.length,
                itemBuilder: (context, index) {
                  final item = _drawerItems[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Colors.orange.shade50
                          : Colors.transparent,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade600,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        item.subtitle,
                        style: TextStyle(
                          color: isSelected
                              ? const Color.fromARGB(255, 117, 182, 219)
                              : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Color.fromARGB(255, 117, 182, 219),
                            )
                          : null,
                      onTap: () => _onItemTapped(index),
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () => logoutConRedireccionPorRol(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Cerrar Sesión",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class DrawerItem {
  final IconData icon;
  final String title;
  final String subtitle;

  DrawerItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// 🔐 Función mejorada para cerrar sesión con redirección según rol
Future<void> logoutConRedireccionPorRol(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey('rol')) {
      final rol = doc['rol'];
      print("🎯 Rol encontrado: $rol");

      await FirebaseAuth.instance.signOut();

      if (rol == 'Chef') {
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => const LoginMenu()));
     } else if (rol == 'Admin') {
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => const ChefWaiter()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rol no válido")),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => const ChefWaiter()));
    }
  } else {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(
        builder: (context) => const ChefWaiter()));
  }
}