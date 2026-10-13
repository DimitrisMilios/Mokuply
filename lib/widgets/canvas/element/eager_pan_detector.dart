import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Pan detector that claims the gesture on pointer down, so the outer
/// InteractiveViewer never steals an element drag.
class EagerPanDetector extends StatelessWidget {
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
  final Widget child;

  const EagerPanDetector({
    super.key,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
          _EagerPanGestureRecognizer.new,
          (instance) {
            instance.onStart = onStart;
            instance.onUpdate = onUpdate;
            instance.onEnd = (_) => onEnd();
            instance.onCancel = onCancel;
          },
        ),
      },
      child: child,
    );
  }
}

class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
