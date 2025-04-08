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

  final formkey = GlobalKey<FormState>();
  bool isvisible = false;
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Form(
            key: formkey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              
                //Register
                children: [
                  ListTile(
                    title: Text("Registrar nueva cuenta", style: TextStyle(fontSize:50, fontWeight: FontWeight.bold ),),                 
                  ),

                  // Email
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
                                  return "Por favor ingrese su correo electrónico";
                                  } else if (!value.contains("@")) {
                                  return "Correo inválido";
                                  }
                                  return null;
                                  },
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    icon: Icon(Icons.email),
                                    border: InputBorder.none,
                                    hintText: "Correo electrónico",
                                  ),
                                ),
                              ),
                  
                  Container(
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
                              color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                            child: TextFormField(
                              controller: username,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return "Por favor ingrese su nombre de usuario";
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                icon: Icon(Icons.person),
                                border: InputBorder.none,
                                hintText: "Username",
                              ),
                            ),
                          ),
                      
                          //Password
                           Container(
                             margin: const EdgeInsets.all(8),
                            padding: 
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
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
                                      isvisible = !isvisible; //boton de visibilidad contraseña
                                    });
                                  }, icon: Icon(isvisible? Icons.visibility: Icons.visibility_off))),
                            ),
                          ),

                          //Confirm Password
                           Container(
                             margin: const EdgeInsets.all(8),
                            padding: 
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              // ignore: deprecated_member_use
                              color: const Color.fromARGB(255, 97, 155, 202).withOpacity(.5)),
                            child: TextFormField(
                              controller: confirmpassword,
                               validator: (value) {
                                if (value!.isEmpty) {
                                  return "Por favor ingrese su contraseña";
                                } else if (value != password.text) {
                                  return "La contraseña no coinciden";
                                }
                                return null;
                              },
                              obscureText: !isvisible,
                              decoration: InputDecoration(
                                icon: const Icon(Icons.lock),
                                border: InputBorder.none,
                                hintText: " Confirmar contraseña",
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      isvisible = !isvisible; //boton de visibilidad contraseña
                                    });
                                  }, icon: Icon(isvisible? Icons.visibility: Icons.visibility_off))),
                            ),
                          ),

                          const SizedBox(height: 10),                       
                          //Login Button
                  Container(
                    height: 55,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color.fromARGB(255, 16, 60, 134) 
                    ),
                    child: TextButton(
                    onPressed: () async {
                      if (formkey.currentState!.validate()) {
                           print("✅ Formulario validado");
                        try {
                          // Intentar crear usuario
                          print("⏳ Creando usuario...");
                          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: email.text.trim(),
                            password: password.text.trim(),
                          );
                          print("✅ Usuario creado");
                          // Obtener UID del usuario registrado
                            String uid = credential.user!.uid;

                            // Guardar en Firestore
                            print("⏳ Guardando en Firestore...");
                            await FirebaseFirestore.instance.collection('users').doc(uid).set({
                              'email': email.text.trim(),
                              'username': username.text.trim(),
                              'createdAt': Timestamp.now(),
                            });
                            print("✅ Usuario guardado en Firestore");

                          // Si llega aquí, se creó con éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Cuenta creada exitosamente ")),
                          );

                          // Opcional: navegar a otra pantalla
                          print("Redirigiendo al login...");
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginMenu()),
                          );

                        } on FirebaseAuthException catch (e) {
                          print("❌ Error de FirebaseAuth: ${e.code}");
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
                      } else {
                        print("❌ Formulario no validado");
                      }
                    },
                    child: Text("REGISTRARSE", style: TextStyle(color: Colors.white ),
                    )),
                    ),
              
                    //sing up bottom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Ya tienes una cuenta?"),
                      TextButton(onPressed: () {
                        //navegar a la pantalla de login
                         Navigator.push(context,
                         MaterialPageRoute(
                          builder: (context) => const LoginMenu ())); 
                      },
                       child: const Text("LOGIN"))
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
