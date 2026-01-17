import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Deep Slate
              Color(0xFF1E1B4B), // Indigo-950
              Color(0xFF312E81), // Indigo-900
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Glowing Logo
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.15),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                          blurRadius: 50,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 84,
                      color: AppTheme.primaryLight, // Brighter icon
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title & Tagline
                const Text(
                  'Campus OS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your AI-Powered Academic Companion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary.withOpacity(0.8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 60),

                // Feature Grid (Glassmorphism)
                _buildFeatureCard(
                  icon: Icons.chat_bubble_rounded,
                  title: 'AI Assistant',
                  subtitle: '24/7 Academic Support',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.calendar_today_rounded,
                  title: 'Smart Schedule',
                  subtitle: 'Auto-organized Timetable',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  icon: Icons.book_rounded,
                  title: 'Knowledge Base',
                  subtitle: 'Instant Access to Resources',
                ),

                const Spacer(),

                // CTA Button
                ElevatedButton(
                  onPressed: () => context.push('/auth'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: AppTheme.primaryColor,
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryLight, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Removed Spacer and Arrow Icon
        ],
      ),
    );
  }
}
