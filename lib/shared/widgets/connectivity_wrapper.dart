import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/connectivity_service.dart';

/// Wraps the entire app and shows a top banner when there's no internet.
class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<bool> _sub;
  bool _isConnected = true;
  bool _showBanner = false;
  bool _hasHadOfflineError = false;
  bool _isInitialCheck = true;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Listen to changes
    _sub = ConnectivityService.instance.onConnectivityChanged.listen((connected) {
      if (mounted) _updateStatus(connected);
    });

    // Check initial state
    ConnectivityService.instance.isConnected().then((connected) {
      if (mounted) {
        if (!connected) {
          // If initially offline, show the banner
          _hasHadOfflineError = true;
          setState(() {
            _isConnected = false;
            _showBanner = true;
          });
          _animCtrl.forward();
        }
        _isInitialCheck = false;
      }
    });
  }

  void _updateStatus(bool connected) {
    if (_isInitialCheck) {
      return;
    }

    if (!connected) {
      setState(() {
        _isConnected = false;
        _showBanner = true;
        _hasHadOfflineError = true;
      });
      _animCtrl.forward();
    } else {
      if (_hasHadOfflineError) {
        setState(() {
          _isConnected = true;
          _showBanner = true;
        });
        _animCtrl.forward();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _animCtrl.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showBanner = false;
                  _hasHadOfflineError = false;
                });
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,

        if (_showBanner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 24,
            right: 24,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -2),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animCtrl,
                curve: Curves.easeOutCubic,
              )),
              child: _Banner(isConnected: _isConnected),
            ),
          ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final bool isConnected;
  const _Banner({required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(50),
      shadowColor: Colors.black26,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: isConnected
              ? const Color(0xFF2E7D32)   // dark green — back online
              : const Color(0xFFD97706),  // amber warning — offline
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Back online' : 'No internet connection',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
