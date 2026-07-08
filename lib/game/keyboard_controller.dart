import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';

class KeyboardController extends Component with KeyboardHandler {
  final void Function(bool left, bool right, bool up, bool down, bool fire)
      onChanged;

  bool left = false;
  bool right = false;
  bool up = false;
  bool down = false;
  bool fire = false;

  KeyboardController({required this.onChanged});

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    left = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);

    right = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);

    up = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW);

    down = keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS);

    fire = keysPressed.contains(LogicalKeyboardKey.space);

    onChanged(left, right, up, down, fire);

    return KeyEventResult.handled;
  }
}
