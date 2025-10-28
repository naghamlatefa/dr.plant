import 'dart:math' as math;
import 'package:flutter/material.dart';

class BottomFloatingDecor extends StatefulWidget {
  const BottomFloatingDecor({super.key});

  @override
  State<BottomFloatingDecor> createState() => _BottomFloatingDecorState();
}

class _BottomFloatingDecorState extends State<BottomFloatingDecor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final _rand = math.Random();

  late final List<double> _xFractions = List.generate(
    7,
    (_) => _rand.nextDouble(),
  )..sort();

  late final List<double> _phase = List.generate(
    7,
    (_) => _rand.nextDouble() * 2 * math.pi,
  );
  late final List<double> _amp = List.generate(
    7,
    (_) => 6 + _rand.nextDouble() * 10,
  );
  late final List<double> _rot = List.generate(
    7,
    (_) => (_rand.nextDouble() * 0.25) + 0.05,
  );
  late final List<double> _size = List.generate(
    7,
    (_) => 18 + _rand.nextDouble() * 14,
  );

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return IgnorePointer(
      // مجرد ديكور
      child: SizedBox(
        height: 160,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            return Stack(
              children: List.generate(_xFractions.length, (i) {
                final dy = math.sin((t * 2 * math.pi) + _phase[i]) * _amp[i];
                final angle = math.sin((t * 2 * math.pi) + _phase[i]) * _rot[i];

                final colors = <Color>[
                  Colors.green.shade400,
                  Colors.green.shade600,
                  Colors.green.shade700,
                  Colors.teal.shade400,
                ];
                final color = colors[i % colors.length];

                final icons = <IconData>[
                  Icons.eco,
                  Icons.local_florist,
                  Icons.spa,
                  Icons.filter_vintage,
                ];
                final icon = icons[i % icons.length];

                return Positioned(
                  left: _xFractions[i] * w - (_size[i] / 2),
                  bottom: 12 + dy,
                  child: Opacity(
                    opacity: 0.9,
                    child: Transform.rotate(
                      angle: angle,
                      child: Icon(icon, size: _size[i], color: color),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}
