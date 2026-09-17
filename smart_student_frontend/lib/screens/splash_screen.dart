import 'package:flutter/material.dart';
import 'login_screen.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bgController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_mainController);

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [Color(0xFF0A1E0A), Color(0xFF020A02)],
              ),
            ),
          ),

          // Tech Nodes (Background Icons)
          Positioned(
            top: 100,
            left: -20,
            child: RotationTransition(
              turns: _bgController,
              child: Icon(
                Icons.hexagon_outlined,
                size: 150,
                color: Colors.greenAccent.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            top: 250,
            right: -30,
            child: RotationTransition(
              turns: ReverseAnimation(_bgController),
              child: Icon(
                Icons.device_hub,
                size: 120,
                color: Colors.greenAccent.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 30,
            child: RotationTransition(
              turns: ReverseAnimation(_bgController),
              child: Icon(
                Icons.code,
                size: 100,
                color: Colors.greenAccent.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 50,
            child: RotationTransition(
              turns: _bgController,
              child: Icon(
                Icons.code,
                size: 120,
                color: Colors.greenAccent.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: RotationTransition(
              turns: _bgController,
              child: Icon(
                Icons.track_changes,
                size: 150,
                color: Colors.greenAccent.withValues(alpha: 0.04),
              ),
            ),
          ),

          // Glowing Text and Progress Bar
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                String fullText = "All You Need\nin Your Journey...";
                int textLength = (fullText.length * _mainController.value)
                    .floor();
                String visibleText = fullText.substring(0, textLength);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 100, // Increased to prevent descender clipping
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          visibleText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.4, // Extra line-height for 'j' & 'y' descenders
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 250,
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 8,
                        width: 250 * _animation.value,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.greenAccent,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
