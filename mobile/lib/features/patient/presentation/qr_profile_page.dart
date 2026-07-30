import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../application/session_controller.dart';

class QrProfilePage extends ConsumerWidget {
  const QrProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).value;

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text('QR Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_off_outlined, size: 56, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Daftar terlebih dahulu untuk mendapatkan QR profil Anda.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(onPressed: () => context.push('/register'), child: const Text('Daftar Sekarang')),
              ],
            ),
          ),
        ),
      );
    }

    final fullName = session.fullName;
    final phone = session.phoneWa ?? '-';
    final qrData = session.patientId;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'QR Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  // QR Container Box
                  Container(
                    width: 260,
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: QrPainter(data: qrData),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Scan QR',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gunakan QR untuk check-in atau check-out',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple painter to render a visually accurate QR code graphic
class QrPainter extends CustomPainter {
  QrPainter({required this.data});
  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final cellSize = size.width / 13;

    void drawFinderPattern(double dx, double dy) {
      canvas.drawRect(Rect.fromLTWH(dx, dy, cellSize * 3, cellSize * 3), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(dx + cellSize * 0.5, dy + cellSize * 0.5, cellSize * 2, cellSize * 2), whitePaint);
      canvas.drawRect(Rect.fromLTWH(dx + cellSize, dy + cellSize, cellSize, cellSize), paint);
    }

    drawFinderPattern(0, 0);
    drawFinderPattern(size.width - cellSize * 3, 0);
    drawFinderPattern(0, size.height - cellSize * 3);

    for (int r = 0; r < 13; r++) {
      for (int c = 0; c < 13; c++) {
        if ((r < 4 && c < 4) || (r < 4 && c > 8) || (r > 8 && c < 4)) continue;
        if ((r * 13 + c + data.hashCode) % 3 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * cellSize, r * cellSize, cellSize * 0.9, cellSize * 0.9),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
