import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:menu/Autehtentication/ChefWaiter.dart';
import 'package:menu/Waiter/PrincipalWaiter.dart';
import 'package:menu/Chef/PrincipalChef.dart';
import 'package:menu/Autehtentication/signup.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginMenu extends StatefulWidget {
  const LoginMenu({super.key});

  @override
  State<LoginMenu> createState() => _LoginMenuState();
}

class _LoginMenuState extends State<LoginMenu> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool isvisible = false;
  final formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Form(
              key: formkey,
              child: Column(
                children: [
                  SizedBox(
                    width: 400,
                    height: 290,
                    child: Image.asset(
                      'lib/assets/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                    child: TextFormField(
                      controller: email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Por favor ingrese su correo";
                        } else if (!value.contains('@')) {
                          return "Correo inválido";
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        icon: Icon(Icons.email),
                        border: InputBorder.none,
                        hintText: "Correo electrónico",
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                    child: TextFormField(
                      controller: password,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Por favor ingrese su contraseña";
                        }
                        return null;
                      },
                      obscureText: !isvisible,
                      decoration: InputDecoration(
                          icon: const Icon(Icons.lock),
                          border: InputBorder.none,
                          hintText: "Contraseña",
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  isvisible = !isvisible;
                                });
                              },
                              icon: Icon(isvisible ? Icons.visibility : Icons.visibility_off))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color.fromARGB(255, 16, 60, 134)),
                    child: TextButton(
                        onPressed: () async {
                          if (formkey.currentState!.validate()) {
                            try {
                              print("🔐 Iniciando sesión...");
                              final credential = await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                      email: email.text.trim(),
                                      password: password.text.trim());

                              final uid = credential.user!.uid;
                              print("✅ Sesión iniciada, buscando rol...");

                              final doc = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .get();

                              if (doc.exists && doc.data()!.containsKey('rol')) {
                                final rol = doc['rol'];
                                print("🎯 Rol encontrado: $rol");

                                if (rol == 'Chef') {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const PrincipalChef()));
                                } else if (rol == 'Mesero') {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const Principalwaiter()));
                                } else if (rol == 'Admin') {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => const ChefWaiter()));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Rol no válido")),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No se encontró el rol del usuario")),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              String errorMsg = "Error al iniciar sesión";
                              if (e.code == 'user-not-found') {
                                errorMsg = 'No existe un usuario con este correo';
                              } else if (e.code == 'wrong-password') {
                                errorMsg = 'Contraseña incorrecta';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("❌ $errorMsg")),
                              );
                            }
                          }
                        },
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(color: Colors.white),
                        )),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No tienes cuenta?"),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RegisterMenu()));
                          },
                          child: const Text("REGISTRATE"))
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}