import 'package:flutter/material.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';

class SeccionCreateComanda extends StatefulWidget {
  const SeccionCreateComanda({super.key});

  @override
  State<SeccionCreateComanda> createState() => _SeccionCreateComandaState();
}

class _SeccionCreateComandaState extends State<SeccionCreateComanda> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, 
      child: Scaffold(
        appBar: AppBar(
          title: Text("Crear Comanda"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // navegar a la pantalla anterior
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const Principalwaiter()),
              );
            },
          ),
        ),
        body: Center(child: Text("crear una comanda")),
      ),
    );
  }
}