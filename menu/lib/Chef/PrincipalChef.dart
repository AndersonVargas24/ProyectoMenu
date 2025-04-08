import 'package:flutter/material.dart';

class Principalchef extends StatefulWidget {
  const Principalchef({super.key});

  @override
  State<Principalchef> createState() => _PrincipalchefState();
}

class _PrincipalchefState extends State<Principalchef> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantalla Principal Chef")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("¡Bienvenido Chef!", style: TextStyle(fontSize: 20)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Acción al presionar el botón
                },
                child: const Text("Acción del Chef"),
              ),
            ],
          ),

      ),
    );
  }
}