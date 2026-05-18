import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/controllers/profile_provider.dart';

class FaithSafetyScreen extends ConsumerStatefulWidget {
  final String messId;
  const FaithSafetyScreen({super.key, required this.messId});

  @override
  ConsumerState<FaithSafetyScreen> createState() => _FaithSafetyScreenState();
}

class _FaithSafetyScreenState extends ConsumerState<FaithSafetyScreen> {
  bool _isSilentModeEnabled = false;

  Widget _buildIceRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                value != null && value.isNotEmpty ? value : 'Not Configured',
                style: TextStyle(
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  color: value != null && value.isNotEmpty ? AppTheme.textDark : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user profile to pull their specific ICE details
    final userState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Faith & Safety Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundLight,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SECTION 1: Spiritual Wisdom & Community (Sanatani Bandhan focus)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text('DAILY VEDIC WISDOM', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ॐ सह नाववतु ।\nसह नौ भुनक्तु ।\nसह वीर्यं करवावहै ।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '"May the Divine protect us both together. May He nourish us both together. May we work conjointly with great energy."\n— Krishna Yajurveda (Taittiriya Upanishad)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.white, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to share in Sanatani Bandhan group!'), backgroundColor: Colors.orange),
                      );
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share to Community'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // SECTION 2: Sadhana / Prayer Silent Mode
            const Text('Mindfulness & Peace', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: SwitchListTile(
                value: _isSilentModeEnabled,
                onChanged: (val) => setState(() => _isSilentModeEnabled = val),
                activeColor: Colors.orange,
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_paused_rounded, color: Colors.orange),
                ),
                title: const Text('Sadhana Silent Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                subtitle: const Text('Mute all non-urgent mess notifications during morning and evening prayer times.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 32),

            // SECTION 3: ICE (In Case of Emergency) Vault
            const Row(
              children: [
                Icon(Icons.health_and_safety_rounded, color: Colors.redAccent),
                SizedBox(width: 8),
                Text('Personal ICE Vault', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              ],
            ),
            const SizedBox(height: 12),
            userState.when(
              data: (user) {
                if (user == null) return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text('Profile not loaded.')));
                
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                    boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIceRow(Icons.bloodtype_rounded, 'Blood Group', user.bloodGroup),
                      const Divider(height: 24),
                      _buildIceRow(Icons.person_outline_rounded, 'Emergency Contact', user.iceName),
                      const Divider(height: 24),
                      _buildIceRow(Icons.phone_in_talk_rounded, 'Emergency Phone', user.icePhone),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // In a real device, you could wire this to url_launcher to dial the number
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Routing to phone dialer...'), backgroundColor: Colors.redAccent),
                            );
                          },
                          icon: const Icon(Icons.call_rounded, size: 18),
                          label: const Text('Call Emergency Contact'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading ICE data: $e')),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
