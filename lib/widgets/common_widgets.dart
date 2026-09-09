part of '../main.dart';

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Container(color: canvas, child: child),
        ),
      ),
    ),
  );
}
