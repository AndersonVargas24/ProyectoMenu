import 'package:flutter/material.dart';

class Principalwaiter extends StatefulWidget {
  const Principalwaiter({super.key});

  @override
  State<Principalwaiter> createState() => _PrincipalwaiterState();
}

class _PrincipalwaiterState extends State<Principalwaiter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pantalla Principal Mesero"),),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("¡Bienvenido Mesero!", style: TextStyle(fontSize: 20)),
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