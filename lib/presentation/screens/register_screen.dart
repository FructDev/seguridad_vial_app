// lib/presentation/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seguridad_vial_app/data/providers/auth_provider.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lottie/lottie.dart';

class RegisterScreen extends StatefulWidget {
  RegisterScreen({Key? key}) : super(key: key);

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormBuilderState>();
  String? errorMessage;
  bool isLoading = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: FadeTransition(
        opacity: _animation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
          child: Column(
            children: [
              Lottie.asset(
                'assets/animations/register.json',
                width: 200,
                height: 200,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 16),
              Text(
                'Crear Cuenta',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Regístrate para continuar',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    FormBuilderTextField(
                      name: 'email',
                      decoration: const InputDecoration(
                          labelText: 'Correo Electrónico'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Este campo es obligatorio'),
                        FormBuilderValidators.email(
                            errorText: 'Ingrese un correo válido'),
                      ]),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    FormBuilderTextField(
                      name: 'password',
                      decoration:
                          const InputDecoration(labelText: 'Contraseña'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Este campo es obligatorio'),
                        FormBuilderValidators.minLength(6,
                            errorText: 'Mínimo 6 caracteres'),
                      ]),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    FormBuilderTextField(
                      name: 'confirm_password',
                      decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña'),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(
                            errorText: 'Este campo es obligatorio'),
                        (val) {
                          if (_formKey
                                  .currentState?.fields['password']?.value !=
                              val) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ]),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              if (errorMessage != null)
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState?.saveAndValidate() ?? false) {
                      setState(() {
                        isLoading = true;
                        errorMessage = null;
                      });
                      try {
                        await authProvider.signUp(
                          email: _formKey.currentState!.value['email'],
                          password: _formKey.currentState!.value['password'],
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          errorMessage =
                              'Error al registrarse. Inténtalo de nuevo.';
                          isLoading = false;
                        });
                      }
                    }
                  },
                  child: const Text('Registrarse'),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
