import 'package:flutter/material.dart';
import 'package:menu/Autehtentication/login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterMenu extends StatefulWidget {
  const RegisterMenu({super.key});

  @override
  State<RegisterMenu> createState() => _RegisterMenuState();
}

class _RegisterMenuState extends State<RegisterMenu> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmpassword = TextEditingController();
  String? selectedRole;

  final formkey = GlobalKey<FormState>();
  bool isvisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formkey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ListTile(
                    title: Text(
                      "Registrar nueva cuenta",
                      style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Email
                  _buildTextInput(
                    controller: email,
                    icon: Icons.email,
                    hintText: "Correo electrónico",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Por favor ingrese su correo electrónico";
                      } else if (!value.contains("@")) {
                        return "Correo inválido";
                      }
                      return null;
                    },
                  ),

                  // Username
                  _buildTextInput(
                    controller: username,
                    icon: Icons.person,
                    hintText: "Username",
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Por favor ingrese su nombre de usuario";
                      }
                      return null;
                    },
                  ),

                  // Password
                  _buildTextInput(
                    controller: password,
                    icon: Icons.lock,
                    hintText: "Contraseña",
                    obscureText: !isvisible,
                    suffixIcon: IconButton(
                      icon: Icon(isvisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isvisible = !isvisible),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Por favor ingrese su contraseña";
                      }
                      return null;
                    },
                  ),

                  // Confirm Password
                  _buildTextInput(
                    controller: confirmpassword,
                    icon: Icons.lock,
                    hintText: "Confirmar contraseña",
                    obscureText: !isvisible,
                    suffixIcon: IconButton(
                      icon: Icon(isvisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => isvisible = !isvisible),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Por favor confirme su contraseña";
                      } else if (value != password.text) {
                        return "Las contraseñas no coinciden";
                      }
                      return null;
                    },
                  ),

                  // Rol Dropdown
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 19),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      hint: const Text("Selecciona un rol"),
                      decoration: const InputDecoration.collapsed(hintText: ""),
                      items: ['Chef', 'Mesero', 'Admin', 'Usuario'].map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedRole = value),
                      validator: (value) => value == null ? "Por favor selecciona un rol" : null,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Botón Registrarse
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color.fromARGB(255, 16, 60, 134),
                    ),
                    child: TextButton(
                      onPressed: () async {
                        if (formkey.currentState!.validate()) {
                          try {
                            final credential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: email.text.trim(),
                              password: password.text.trim(),
                            );
                            String uid = credential.user!.uid;

                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'email': email.text.trim(),
                              'username': username.text.trim(),
                              'rol': selectedRole,
                              'createdAt': Timestamp.now(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Cuenta creada exitosamente")),
                            );

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginMenu()),
                            );
                          } on FirebaseAuthException catch (e) {
                            String errorMsg = "Ocurrió un error";
                            if (e.code == 'email-already-in-use') {
                              errorMsg = 'Este correo ya está registrado';
                            } else if (e.code == 'invalid-email') {
                              errorMsg = 'Correo inválido';
                            } else if (e.code == 'weak-password') {
                              errorMsg = 'La contraseña es muy débil';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          } catch (e) {
                            print("❌ Otro error: $e");
                          }
                        }
                      },
                      child: const Text("REGISTRARSE", style: TextStyle(color: Colors.white)),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Ya tienes una cuenta?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginMenu()),
                          );
                        },
                        child: const Text("LOGIN"),
                      )
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

  Widget _buildTextInput({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          icon: Icon(icon),
          border: InputBorder.none,
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}