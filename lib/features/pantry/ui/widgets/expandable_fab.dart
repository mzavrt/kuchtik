import 'package:flutter/material.dart';

class ExpandableFabAction {
  const ExpandableFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.actions,
    this.heroTagPrefix = 'expandable_fab',
  });

  final List<ExpandableFabAction> actions;
  final String heroTagPrefix;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool open = false;

  late final AnimationController controller;
  late final Animation<double> expand;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    expand = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() {
      open = !open;
      open ? controller.forward() : controller.reverse();
    });
  }

  void close() {
    if (!open) return;
    toggle();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 80 + widget.actions.length * 64,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Positioned(
            right: 0,
            bottom: 72,
            child: SizeTransition(
              sizeFactor: expand,
              axisAlignment: -1,
              child: FadeTransition(
                opacity: expand,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < widget.actions.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FloatingActionButton.extended(
                          heroTag: '${widget.heroTagPrefix}_action_$index',
                          onPressed: () {
                            close();
                            widget.actions[index].onPressed();
                          },
                          icon: Icon(widget.actions[index].icon),
                          label: Text(widget.actions[index].label),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: FloatingActionButton(
              heroTag: '${widget.heroTagPrefix}_main',
              onPressed: toggle,
              child: AnimatedRotation(
                turns: open ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }
}