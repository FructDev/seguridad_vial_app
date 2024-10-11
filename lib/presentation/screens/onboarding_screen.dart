// lib/presentation/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({Key? key}) : super(key: key);

  void goToLogin(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnboarding', false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definimos la lista de páginas dentro del método build para que tengan acceso a 'context' y 'goToLogin'
    final List<PageViewModel> pages = [
      PageViewModel(
        title: "Bienvenido a Seguridad Vial App",
        body:
            "Mantente seguro en las carreteras y contribuye a una conducción más segura para todos.",
        image: Center(
          child: Lottie.asset(
            'assets/animations/driving_safe.json',
            width: 250,
            height: 250,
            fit: BoxFit.fill,
          ),
        ),
        decoration: PageDecoration(
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
          bodyTextStyle:
              GoogleFonts.montserrat(fontSize: 18, color: Colors.black87),
        ),
      ),
      PageViewModel(
        title: "Reportes en Tiempo Real",
        body:
            "Recibe alertas y reporta incidentes en tiempo real para mantener informada a la comunidad.",
        image: Center(
          child: Lottie.asset(
            'assets/animations/real_time.json',
            width: 250,
            height: 250,
            fit: BoxFit.fill,
          ),
        ),
        decoration: PageDecoration(
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
          bodyTextStyle:
              GoogleFonts.montserrat(fontSize: 18, color: Colors.black87),
        ),
      ),
      PageViewModel(
        title: "Mapas Interactivos",
        body:
            "Visualiza zonas de riesgo y evita accidentes con nuestros mapas actualizados.",
        image: Center(
          child: Lottie.asset(
            'assets/animations/maps.json',
            width: 250,
            height: 250,
            fit: BoxFit.fill,
          ),
        ),
        decoration: PageDecoration(
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
          bodyTextStyle:
              GoogleFonts.montserrat(fontSize: 18, color: Colors.black87),
        ),
      ),
      PageViewModel(
        title: "Comienza Ahora",
        body:
            "Únete a nosotros y sé parte de una comunidad comprometida con la seguridad vial.",
        image: Center(
          child: Lottie.asset(
            'assets/animations/community.json',
            width: 250,
            height: 250,
            fit: BoxFit.fill,
          ),
        ),
        footer: ElevatedButton(
          onPressed: () => goToLogin(context),
          child: const Text(
            '¡Empezar!',
            style: TextStyle(fontSize: 18),
          ),
        ),
        decoration: PageDecoration(
          titleTextStyle: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
          bodyTextStyle:
              GoogleFonts.montserrat(fontSize: 18, color: Colors.black87),
        ),
      ),
    ];

    return IntroductionScreen(
      pages: pages,
      onDone: () => goToLogin(context),
      onSkip: () => goToLogin(context),
      showSkipButton: true,
      skip: const Text("Saltar",
          style:
              TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
      next: const Icon(Icons.arrow_forward, color: Colors.deepPurple),
      done: const Text("Empezar",
          style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
              fontSize: 16)),
      dotsDecorator: const DotsDecorator(
        activeColor: Colors.deepPurple,
        size: Size(10.0, 10.0),
        color: Colors.black26,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
      globalBackgroundColor: Colors.white,
      animationDuration: 500,
      curve: Curves.easeInOut,
    );
  }
}
