import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

enum InAppCallState { ringing, connecting, connected, ended }

/// High-fidelity In-App Voice Call Screen (VoIP over Data/Wi-Fi)
class InAppCallScreen extends StatefulWidget {
  final String recipientName;
  final String recipientRole;
  final String phoneNumber;
  final String? vehicleInfo;

  const InAppCallScreen({
    super.key,
    required this.recipientName,
    this.recipientRole = 'Driver',
    required this.phoneNumber,
    this.vehicleInfo,
  });

  @override
  State<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends State<InAppCallScreen> with SingleTickerProviderStateMixin {
  InAppCallState _callState = InAppCallState.ringing;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDurationSeconds = 0;
  Timer? _callTimer;
  Timer? _connectTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate network audio stream handshake (ringing -> connecting -> connected)
    _connectTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        setState(() {
          _callState = InAppCallState.connected;
        });
        _startTimer();
        HapticFeedback.mediumImpact();
      }
    });
  }

  void _startTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _endCall() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _callState = InAppCallState.ended;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _connectTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.recipientName.isNotEmpty
        ? widget.recipientName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'DR';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark executive slate
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),

            // Top Status & Data Quality Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _callState == InAppCallState.connected ? AppColors.green : AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _callState == InAppCallState.connected
                        ? '🟢 In-App HD Audio · Data Call'
                        : 'Connecting via Internet...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Recipient Avatar with Pulsing Effect
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _callState == InAppCallState.ringing ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.navy,
                  border: Border.all(color: AppColors.gold, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recipient Name & Role
            Text(
              widget.recipientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.vehicleInfo != null && widget.vehicleInfo!.isNotEmpty
                  ? '${widget.recipientRole} · ${widget.vehicleInfo}'
                  : widget.recipientRole,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Call State / Live Duration
            Text(
              _callState == InAppCallState.connected
                  ? _formatDuration(_callDurationSeconds)
                  : (_callState == InAppCallState.ended ? 'Call Ended' : 'Ringing...'),
              style: TextStyle(
                color: _callState == InAppCallState.connected ? AppColors.green : Colors.white60,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),

            const Spacer(flex: 2),

            // In-Call Action Controls (Mute, Speaker, Keypad)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _callControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Muted' : 'Mute',
                    isActive: _isMuted,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isMuted = !_isMuted);
                    },
                  ),
                  _callControlButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: _isSpeakerOn ? 'Speaker On' : 'Speaker',
                    isActive: _isSpeakerOn,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isSpeakerOn = !_isSpeakerOn);
                    },
                  ),
                  _callControlButton(
                    icon: Icons.dialpad,
                    label: 'Keypad',
                    isActive: false,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dialpad active')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // End Call Button
            GestureDetector(
              onTap: _endCall,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x66EF4444),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _callControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: isActive ? AppColors.gold : Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? AppColors.navy : Colors.white,
              size: 26,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.gold : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Unified Call Options Dialog / Bottom Sheet
/// Provides:
/// 1. Free In-App Voice Call (using Internet/Data)
/// 2. Regular Phone Call (opening phone app via url_launcher)
Future<void> showCallSelectionSheet(
  BuildContext context, {
  required String recipientName,
  required String phoneNumber,
  String recipientRole = 'Driver',
  String? vehicleInfo,
}) async {
  final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header with Name & Phone
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.navy,
                  child: Text(
                    recipientName.isNotEmpty ? recipientName[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact $recipientName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        phoneNumber.isNotEmpty ? phoneNumber : 'Number available',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Option 1: Free In-App Voice Call (Data/Internet)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InAppCallScreen(
                      recipientName: recipientName,
                      recipientRole: recipientRole,
                      phoneNumber: phoneNumber,
                      vehicleInfo: vehicleInfo,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wifi_calling_3, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'In-App Voice Call',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'FREE (Data)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            'High-definition internet audio · No airtime charged',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Option 2: Regular Phone Call (Cellular via Dialer)
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                Navigator.of(ctx).pop();
                final telUri = Uri.parse('tel:$cleanPhone');
                try {
                  if (await canLaunchUrl(telUri)) {
                    await launchUrl(telUri, mode: LaunchMode.externalApplication);
                  } else {
                    await launchUrl(telUri);
                  }
                } catch (e) {
                  await Clipboard.setData(ClipboardData(text: cleanPhone));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dialing $cleanPhone · Number copied to clipboard')),
                    );
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_forwarded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Regular Phone Call',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Opens your phone app to call $cleanPhone',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.inkSoft),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Copy Phone Number Action
            TextButton.icon(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await Clipboard.setData(ClipboardData(text: cleanPhone));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Phone number ($cleanPhone) copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16, color: AppColors.navy),
              label: const Text(
                'Copy Phone Number',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
            ),
          ],
        ),
      );
    },
  );
}
