import 'package:flutter/material.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _diagonalAnimation;
  late Animation<double> _doorAnimation;
  late Animation<double> _logoOpacityAnimation;
  bool _showLogo = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _diagonalAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    _doorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showLogo = true;
        });
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de presentación animada (SplashScreen) con logo y fondo dividido
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Fondo dividido
              CustomPaint(
                size: Size(MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height),
                painter: SplashPainter(
                  diagonalProgress: _diagonalAnimation.value,
                  doorProgress: _doorAnimation.value,
                ),
              ),
              // Logo con animación de opacidad
              Center(
                child: Opacity(
                  opacity: _logoOpacityAnimation.value,
                  child: Image.asset(
                    'assets/logo-principal.png',
                    width: 200,
                    height: 200,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SplashPainter extends CustomPainter {
  final double diagonalProgress;
  final double doorProgress;

  SplashPainter({required this.diagonalProgress, required this.doorProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Color izquierdo (azul oscuro)
    paint.color = const Color(0xFF1E1E1E);
    var leftPath = Path();
    if (diagonalProgress == 0) {
      // División vertical inicial
      leftPath.addRect(Rect.fromLTWH(0, 0, size.width / 2, size.height));
    } else {
      // Transformación diagonal
      leftPath.moveTo(0, 0);
      leftPath.lineTo(size.width * (0.5 - doorProgress * 0.5), 0);
      leftPath.lineTo(size.width * (0.3 - doorProgress * 0.3), size.height);
      leftPath.lineTo(0, size.height);
      leftPath.close();
    }
    canvas.drawPath(leftPath, paint);

    // Color derecho (morado)
    paint.color = Colors.deepPurple.withOpacity(diagonalProgress);
    var rightPath = Path();
    if (diagonalProgress == 0) {
      // División vertical inicial
      rightPath.addRect(
          Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height));
    } else {
      // Transformación diagonal
      rightPath.moveTo(size.width, 0);
      rightPath.lineTo(size.width * (0.5 + doorProgress * 0.5), 0);
      rightPath.lineTo(size.width * (0.7 + doorProgress * 0.3), size.height);
      rightPath.lineTo(size.width, size.height);
      rightPath.close();
    }
    canvas.drawPath(rightPath, paint);
  }

  @override
  bool shouldRepaint(covariant SplashPainter oldDelegate) {
    return oldDelegate.diagonalProgress != diagonalProgress ||
        oldDelegate.doorProgress != doorProgress;
  }
}