import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ZoomableCachedImage extends StatelessWidget {
  String url;

  ZoomableCachedImage(this.url, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZoomablePhotoViewer(
      url: url,
    );
  }
}

class ZoomablePhotoViewer extends StatefulWidget {
  const ZoomablePhotoViewer({Key? key, required this.url}) : super(key: key);

  final String url;

  @override
  _ZoomablePhotoViewerState createState() => _ZoomablePhotoViewerState();
}

class _ZoomablePhotoViewerState extends State<ZoomablePhotoViewer>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<Offset>? _flingAnimation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  Offset? _normalizedOffset;
  double? _previousScale;
  HitTestBehavior? behavior;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addListener(_handleFlingAnimation);
  }

  @override
  void dispose() {
    _controller!.dispose();
    super.dispose();
  }

  // The maximum offset value is 0,0. If the size of this renderer's box is w,h
  // then the minimum offset value is w - _scale * w, h - _scale * h.
  Offset _clampOffset(Offset offset) {
    final Size size = context.size!;
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
  }

  void _handleFlingAnimation() {
    setState(() {
      _offset = _flingAnimation!.value;
    });
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // The fling animation stops if an input gesture starts.
      _controller!.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale! * details.scale).clamp(1.0, 4.0);
      // Ensure that image location under the focal point stays in the same place despite scaling.
      _offset = _clampOffset(details.focalPoint - _normalizedOffset! * _scale);
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    const double _kMinFlingVelocity = 800.0;
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    final double distance = (Offset.zero & context.size!).shortestSide;
    _flingAnimation = Tween<Offset>(
            begin: _offset, end: _clampOffset(_offset + direction * distance))
        .animate(_controller!);
    _controller!
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        AllowMultipleScaleRecognizer:
            GestureRecognizerFactoryWithHandlers<AllowMultipleScaleRecognizer>(
          () => AllowMultipleScaleRecognizer(), //constructor
          (AllowMultipleScaleRecognizer instance) {
            //initializer
            instance.onStart = (details) => _handleOnScaleStart(details);
            instance.onEnd = (details) => _handleOnScaleEnd(details);
            instance.onUpdate = (details) => _handleOnScaleUpdate(details);
          },
        ),
        AllowMultipleHorizontalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<
                AllowMultipleHorizontalDragRecognizer>(
          () => AllowMultipleHorizontalDragRecognizer(),
          (AllowMultipleHorizontalDragRecognizer instance) {
            instance.onStart =
                (details) => _handleHorizontalDragAcceptPolicy(instance);
            instance.onUpdate =
                (details) => _handleHorizontalDragAcceptPolicy(instance);
          },
        ),
        AllowMultipleVerticalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<
                AllowMultipleVerticalDragRecognizer>(
          () => AllowMultipleVerticalDragRecognizer(),
          (AllowMultipleVerticalDragRecognizer instance) {
            instance.onStart =
                (details) => _handleVerticalDragAcceptPolicy(instance);
            instance.onUpdate =
                (details) => _handleVerticalDragAcceptPolicy(instance);
          },
        ),
      },
      //Creates the nested container within the first.
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        child: Transform(
          transform: Matrix4.identity()
            ..translate(_offset.dx, _offset.dy)
            ..scale(_scale),
          child: Image.file(
            File(widget.url),
          ),
        ),
      ),
    );
  }

  void _handleHorizontalDragAcceptPolicy(
      AllowMultipleHorizontalDragRecognizer instance) {
    _scale > 1.0 ? instance.alwaysAccept = true : instance.alwaysAccept = false;
  }

  void _handleVerticalDragAcceptPolicy(
      AllowMultipleVerticalDragRecognizer instance) {
    _scale > 1.0 ? instance.alwaysAccept = true : instance.alwaysAccept = false;
  }
}

class AllowMultipleVerticalDragRecognizer
    extends VerticalDragGestureRecognizer {
  bool? alwaysAccept;

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (alwaysAccept == true) {
      super.resolve(GestureDisposition.accepted);
    } else {
      super.resolve(GestureDisposition.rejected);
    }
  }
}

class AllowMultipleHorizontalDragRecognizer
    extends HorizontalDragGestureRecognizer {
  bool? alwaysAccept;

  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }

  @override
  void resolve(GestureDisposition disposition) {
    if (alwaysAccept == true) {
      super.resolve(GestureDisposition.accepted);
    } else {
      super.resolve(GestureDisposition.rejected);
    }
  }
}

class AllowMultipleScaleRecognizer extends ScaleGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}
