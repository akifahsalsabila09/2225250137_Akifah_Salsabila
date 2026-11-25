import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Pemutar animasi instruksional dengan kontrol siswa (EL04):
/// putar/jeda, langkah berikutnya, ulangi, kecepatan 0,5×.
/// Berhenti otomatis di setiap checkpoint dan menunggu siswa. Tidak pernah pindah layar sendiri.
class AnimationPlayer extends StatefulWidget {
  final Duration duration;
  final List<double> checkpoints;
  final List<String> captions;
  final Widget Function(BuildContext context, double t) builder;
  final VoidCallback? onFinished;
  final String startCaption;

  const AnimationPlayer({
    super.key,
    required this.duration,
    required this.checkpoints,
    required this.captions,
    required this.builder,
    this.onFinished,
    this.startCaption = 'Tekan ▶ untuk mulai.',
  }) : assert(checkpoints.length == captions.length);

  @override
  State<AnimationPlayer> createState() => _AnimationPlayerState();
}

class _AnimationPlayerState extends State<AnimationPlayer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration)
    ..addListener(_onTick);
  int _next = 0;
  String? _caption;
  bool _slow = false;
  bool _finished = false;

  void _onTick() {
    if (_next < widget.checkpoints.length && _c.value >= widget.checkpoints[_next] - 1e-6) {
      final i = _next;
      _next++; // dinaikkan dulu agar perubahan value di bawah tidak memicu checkpoint yang sama lagi
      _c.stop();
      _c.value = widget.checkpoints[i];
      setState(() => _caption = widget.captions[i]);
      if (_next >= widget.checkpoints.length && !_finished) {
        _finished = true;
        widget.onFinished?.call();
      }
    }
  }

  void _play() {
    if (_next >= widget.checkpoints.length) {
      _replay();
    }
    setState(() => _caption = null);
    _c.forward();
  }

  void _pause() {
    _c.stop();
    setState(() {});
  }

  void _skip() {
    if (_next >= widget.checkpoints.length) return;
    _c.stop();
    _c.value = widget.checkpoints[_next];
    _onTick();
  }

  void _replay() {
    _c.stop();
    _c.value = 0;
    setState(() {
      _next = 0;
      _caption = null;
    });
  }

  void _toggleSlow() {
    setState(() => _slow = !_slow);
    final running = _c.isAnimating;
    _c.duration = widget.duration * (_slow ? 2 : 1);
    if (running) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _c.isAnimating;
    final atEnd = _next >= widget.checkpoints.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(animation: _c, builder: (ctx, _) => widget.builder(ctx, _c.value)),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _caption != null ? const Color(0xFFFFF6D6) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _caption != null ? AppColors.taxi : const Color(0xFFE5E5E5), width: 2),
          ),
          child: Text(
            _caption ?? (playing ? '…' : (_c.value == 0 ? widget.startCaption : 'Dijeda.')),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ctrl(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, playing ? 'Jeda' : (atEnd ? 'Putar ulang' : 'Putar'),
                playing ? _pause : _play,
                big: true),
            _ctrl(Icons.skip_next_rounded, 'Langkah berikutnya', atEnd ? null : _skip),
            _ctrl(Icons.replay_rounded, 'Ulangi dari awal', _replay),
            _ctrl(Icons.slow_motion_video_rounded, _slow ? 'Kecepatan normal' : 'Lambat 0,5×', _toggleSlow, active: _slow),
          ],
        ),
      ],
    );
  }

  Widget _ctrl(IconData icon, String tip, VoidCallback? onTap, {bool big = false, bool active = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tip,
        child: Material(
          color: active ? AppColors.taxi : (big ? AppColors.distance : Colors.white),
          shape: const CircleBorder(side: BorderSide(color: Color(0xFFDDDDDD))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(big ? 14 : 10),
              child: Icon(icon,
                  size: big ? 32 : 24,
                  color: onTap == null ? Colors.black26 : (big ? Colors.white : AppColors.ink),
                  semanticLabel: tip),
            ),
          ),
        ),
      ),
    );
  }
}
