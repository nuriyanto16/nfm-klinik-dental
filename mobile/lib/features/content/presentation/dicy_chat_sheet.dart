import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class DicyChatMessage {
  DicyChatMessage({required this.text, required this.isUser, DateTime? time})
      : time = time ?? DateTime.now();
  final String text;
  final bool isUser;
  final DateTime time;
}

class DicyChatSheet extends StatefulWidget {
  const DicyChatSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DicyChatSheet(),
    );
  }

  @override
  State<DicyChatSheet> createState() => _DicyChatSheetState();
}

class _DicyChatSheetState extends State<DicyChatSheet> {
  final List<DicyChatMessage> _messages = [
    DicyChatMessage(
      text: 'Halo! Saya Dicy 🤖, asisten virtual Nina Dental Care. Ada yang bisa Dicy bantu untuk kesehatan gigimu hari ini?',
      isUser: false,
    ),
  ];

  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(DicyChatMessage(text: text, isUser: true));
    });

    _textController.clear();

    // Generate smart bot response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      String reply = 'Terima kasih telah bertanya! ';
      final query = text.toLowerCase();

      if (query.contains('behel') || query.contains('kawat')) {
        reply += 'Pemasangan Behel Gigi di Nina Dental Care mulai dari Rp 6.500.000 (Metal) hingga Rp 12.500.000 (Keramik Sapphire). Mau reservasi konsultasi dokter spesialis ortodonti?';
      } else if (query.contains('harga') || query.contains('biaya') || query.contains('pricelist')) {
        reply += 'Kamu bisa mengecek daftar lengkap harga perawatan di menu Pricelist aplikasi ini!';
      } else if (query.contains('jam') || query.contains('buka') || query.contains('lokasi')) {
        reply += 'Klinik Nina Dental Care buka setiap hari pukul 08:00 – 21:00 di cabang Kab. Bandung (Soreang & Baleendah).';
      } else if (query.contains('reservasi') || query.contains('janji') || query.contains('daftar')) {
        reply += 'Kamu bisa langsung membuat reservasi dengan dokter pilihanmu melalui menu "+ Reservasi".';
      } else {
        reply += 'Tim kami siap membantu perawatan gigimu. Apakah kamu ingin langsung membuat reservasi dengan dokter gigi?';
      }

      setState(() {
        _messages.add(DicyChatMessage(text: reply, isUser: false));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.pink,
                  child: Icon(Icons.support_agent, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asisten Dicy',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Online · Siap Membantu 24/7',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.pink : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        color: msg.isUser ? Colors.white : AppColors.textDark,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Quick Chips Prompt Suggestions
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip('Berapa biaya Behel Gigi?'),
                const SizedBox(width: 8),
                _buildQuickChip('Lihat Pricelist lengkap'),
                const SizedBox(width: 8),
                _buildQuickChip('Cara Reservasi dengan Dokter'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Text Input Box
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onSubmitted: _sendMessage,
                      decoration: InputDecoration(
                        hintText: 'Tanyakan sesuatu kepada Dicy...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppColors.pink,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
      backgroundColor: Colors.green.shade50,
      side: BorderSide(color: Colors.green.shade200),
      onPressed: () => _sendMessage(label),
    );
  }
}
