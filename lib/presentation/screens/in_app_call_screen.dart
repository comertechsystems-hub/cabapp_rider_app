import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

enum InAppCallState { ringing, connecting, connected, ended }

/// High-fidelity In-App Voice Call Screen (VoIP over Data/Wi-Fi)
class InAppCallScreen extends StatefulWidget {
  final String recipientName;
  final String recipientRole;
  final String phoneNumber;
  final String? vehicleInfo;
  final String? rideId;
  final bool isIncoming;
  final String? callId;

  const InAppCallScreen({
    super.key,
    required this.recipientName,
    this.recipientRole = 'Driver',
    required this.phoneNumber,
    this.vehicleInfo,
    this.rideId,
    this.isIncoming = false,
    this.callId,
  });

  @override
  State<InAppCallScreen> createState() => _InAppCallScreenState();
}

class _InAppCallScreenState extends State<InAppCallScreen> with SingleTickerProviderStateMixin {
  late InAppCallState _callState;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int _callDurationSeconds = 0;
  int _ringingSeconds = 0;
  bool _showCellularFallback = false;
  String? _activeCallId;

  Timer? _callTimer;
  Timer? _ringingTimer;
  Timer? _statusPollTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _activeCallId = widget.callId;
    _callState = widget.isIncoming ? InAppCallState.connecting : InAppCallState.ringing;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCall();
    });
  }

  Future<void> _initializeCall() async {
    final client = _resolveApiClient();

    if (widget.isIncoming) {
      // Recipient answering
      if (widget.rideId != null && client != null) {
        try {
          await client.post(
            ApiEndpoints.answerInAppCall,
            body: {
              'ride_id': widget.rideId,
              'call_id': widget.callId,
            },
          );
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _callState = InAppCallState.connected;
        });
        _startTimer();
        HapticFeedback.mediumImpact();
      }
    } else {
      // Outgoing call initiation
      if (widget.rideId != null && client != null) {
        try {
          final res = await client.post(
            ApiEndpoints.initiateInAppCall,
            body: {'ride_id': widget.rideId},
          );
          if (res is Map && res['call_data'] is Map) {
            _activeCallId = res['call_data']['call_id']?.toString();
          }
        } catch (_) {}
      }

      // Start ringing countdown and polling
      _startRingingTracker();
      _startStatusPolling();
    }
  }

  IApiClient? _resolveApiClient() {
    try {
      return context.read<IApiClient>();
    } catch (_) {
      try {
        return context.read<ApiClient>();
      } catch (_) {
        return null;
      }
    }
  }

  void _startRingingTracker() {
    _ringingTimer?.cancel();
    _ringingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _ringingSeconds++;
        if (_ringingSeconds >= 10) {
          _showCellularFallback = true;
        }
      });
    });
  }

  void _startStatusPolling() {
    if (widget.rideId == null) {
      // Fallback auto-connect after 3s if no backend ride
      Timer(const Duration(milliseconds: 3000), () {
        if (mounted && _callState == InAppCallState.ringing) {
          setState(() {
            _callState = InAppCallState.connected;
          });
          _startTimer();
        }
      });
      return;
    }

    final client = _resolveApiClient();
    if (client == null) return;

    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted || _callState == InAppCallState.ended) {
        timer.cancel();
        return;
      }
      try {
        final res = await client.post(
          ApiEndpoints.getCallStatus,
          body: {'ride_id': widget.rideId},
        );
        if (res is Map && res['active_call'] is Map) {
          final status = res['active_call']['status']?.toString().toUpperCase();
          if (status == 'CONNECTED' && _callState == InAppCallState.ringing) {
            if (mounted) {
              _ringingTimer?.cancel();
              setState(() {
                _callState = InAppCallState.connected;
                _showCellularFallback = false;
              });
              _startTimer();
              HapticFeedback.mediumImpact();
            }
          } else if (status == 'ENDED') {
            _handleCallTerminated('Call Ended');
          }
        } else if (res is Map && res['active_call'] == null && _callState == InAppCallState.ringing && _ringingSeconds > 5) {
          // No active call record, declined
          _handleCallTerminated('Call Declined');
        }
      } catch (_) {}
    });
  }

  void _handleCallTerminated(String msg) {
    _callTimer?.cancel();
    _ringingTimer?.cancel();
    _statusPollTimer?.cancel();
    if (mounted) {
      setState(() {
        _callState = InAppCallState.ended;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  void _startTimer() {
    _ringingTimer?.cancel();
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
    _ringingTimer?.cancel();
    _statusPollTimer?.cancel();
    HapticFeedback.heavyImpact();

    final client = _resolveApiClient();
    if (widget.rideId != null && client != null) {
      client.post(
        ApiEndpoints.endInAppCall,
        body: {
          'ride_id': widget.rideId,
          'call_id': _activeCallId,
          'reason': 'user_ended',
        },
      ).catchError((_) => null);
    }

    setState(() {
      _callState = InAppCallState.ended;
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _switchToCellularCall() async {
    _callTimer?.cancel();
    _ringingTimer?.cancel();
    _statusPollTimer?.cancel();

    final cleanPhone = widget.phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final telUri = Uri.parse('tel:$cleanPhone');

    final client = _resolveApiClient();
    if (widget.rideId != null && client != null) {
      client.post(
        ApiEndpoints.endInAppCall,
        body: {'ride_id': widget.rideId, 'reason': 'switched_to_cellular'},
      ).catchError((_) => null);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }

    try {
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(telUri);
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _ringingTimer?.cancel();
    _statusPollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.recipientName.isNotEmpty
        ? widget.recipientName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'DR';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                        ? 'HD Audio · Encrypted Voice'
                        : (_callState == InAppCallState.ringing ? 'Ringing ${widget.recipientRole}\'s Phone...' : 'Connecting...'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Pulsing Avatar
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _callState == InAppCallState.ringing ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF334155), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_callState == InAppCallState.connected ? AppColors.green : AppColors.gold)
                              .withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                      border: Border.all(
                        color: _callState == InAppCallState.connected ? AppColors.green : AppColors.gold,
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Recipient Name
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

            // Recipient Role & Vehicle Info
            Text(
              widget.vehicleInfo != null && widget.vehicleInfo!.isNotEmpty
                  ? '${widget.recipientRole} · ${widget.vehicleInfo}'
                  : widget.recipientRole,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Live Timer or Status Label
            if (_callState == InAppCallState.connected)
              Text(
                _formatDuration(_callDurationSeconds),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _callState == InAppCallState.ringing ? 'Waiting for answer...' : 'Connecting audio stream...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

            // 1-Tap Fallback to Cellular Carrier Call if no answer
            if (_showCellularFallback && _callState == InAppCallState.ringing) ...[
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade900.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.amber.shade400.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Text(
                      'No answer on internet call? You can switch to regular cellular call directly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.amber.shade200, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: _switchToCellularCall,
                      icon: const Icon(Icons.phone_forwarded, size: 16),
                      label: Text(
                        'Switch to Regular Call (${widget.phoneNumber})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(flex: 3),

            // Call Action Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute Mic
                  _buildCallActionButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Muted' : 'Mute',
                    isActive: _isMuted,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                      HapticFeedback.lightImpact();
                    },
                  ),

                  // End Call (Red)
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x66EF4444),
                            blurRadius: 18,
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

                  // Speakerphone
                  _buildCallActionButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    label: _isSpeakerOn ? 'Speaker On' : 'Speaker',
                    isActive: _isSpeakerOn,
                    onTap: () {
                      setState(() {
                        _isSpeakerOn = !_isSpeakerOn;
                      });
                      HapticFeedback.lightImpact();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCallActionButton({
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? const Color(0xFF0F172A) : Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Modal Bottom Sheet offering Free In-App Voice Call vs. Regular Phone Call
void showCallSelectionSheet({
  required BuildContext context,
  required String recipientName,
  String recipientRole = 'Driver',
  required String phoneNumber,
  String? vehicleInfo,
  String? rideId,
}) {
  final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call, color: AppColors.navy, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call $recipientName',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        cleanPhone.isNotEmpty ? cleanPhone : 'Phone call options',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Option 1: Free In-App Voice Call (Mobile Data / Wi-Fi)
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
                      rideId: rideId,
                      isIncoming: false,
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

/// Incoming Call Dialog when other party calls
void showIncomingCallDialog(
  BuildContext context, {
  required String callerName,
  required String callerRole,
  required String callerPhone,
  required String rideId,
  required String callId,
  String? vehicleInfo,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.wifi_calling_3, color: Color(0xFF22C55E)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Incoming $callerRole Call',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.navy,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 14),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Free CabApp Data Voice Call',
              style: TextStyle(color: Colors.green.shade400, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            icon: const Icon(Icons.call_end),
            label: const Text('Decline'),
            onPressed: () {
              Navigator.of(ctx).pop();
              try {
                final client = ctx.read<IApiClient>();
                client.post(ApiEndpoints.endInAppCall, body: {
                  'ride_id': rideId,
                  'call_id': callId,
                  'reason': 'declined',
                });
              } catch (_) {}
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.call),
            label: const Text('Answer Call', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InAppCallScreen(
                    recipientName: callerName,
                    recipientRole: callerRole,
                    phoneNumber: callerPhone,
                    vehicleInfo: vehicleInfo,
                    rideId: rideId,
                    isIncoming: true,
                    callId: callId,
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
