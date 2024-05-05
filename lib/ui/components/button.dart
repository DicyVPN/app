import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/colors.dart';

enum CustomButtonTheme { dark, light }

enum CustomButtonColor {
  blue(
    darkColor: CustomColors.blue500,
    lightColor: CustomColors.blue100,
    darkTextColor: Colors.white,
    lightTextColor: CustomColors.blue600,
  ),
  red(
    darkColor: CustomColors.red500,
    lightColor: CustomColors.red100,
    darkTextColor: Colors.white,
    lightTextColor: CustomColors.red600,
  ),
  green(
    darkColor: CustomColors.green500,
    lightColor: CustomColors.green100,
    darkTextColor: Colors.white,
    lightTextColor: CustomColors.green600,
  ),
  transparent(
    darkColor: Colors.transparent,
    lightColor: Colors.transparent,
    darkTextColor: Colors.white,
    lightTextColor: Colors.black,
  );

  const CustomButtonColor({
    required this.darkColor,
    required this.lightColor,
    required this.darkTextColor,
    required this.lightTextColor,
  });

  final Color darkColor;
  final Color lightColor;
  final Color darkTextColor;
  final Color lightTextColor;
}

enum CustomButtonSize { normal, big }

class Button extends StatelessWidget {
  const Button({
    super.key,
    required this.child,
    required this.onPressed,
    required this.color,
    this.theme = CustomButtonTheme.dark,
    this.size = CustomButtonSize.normal,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool enabled;
  final CustomButtonTheme theme;
  final CustomButtonColor color;
  final CustomButtonSize size;
  final _borderRadius = const BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    var bgColor = (theme == CustomButtonTheme.dark) ? color.darkColor : color.lightColor;
    var contentColor = (theme == CustomButtonTheme.dark) ? color.darkTextColor : color.lightTextColor;
    if (!enabled) {
      contentColor = contentColor.withOpacity(0.5);
      if (color != CustomButtonColor.transparent) {
        bgColor = bgColor.withOpacity(0.5);
      }
    }

    double horizontalPadding = (size == CustomButtonSize.normal) ? 24 : 32;
    double verticalPadding = (size == CustomButtonSize.normal) ? 8 : 12;

    var textTheme = Theme.of(context).textTheme;
    var textStyle = ((size == CustomButtonSize.normal) ? textTheme.labelLarge : textTheme.titleSmall)
        ?.copyWith(color: contentColor);

    return Material(
      elevation: color == CustomButtonColor.transparent ? 0 : 8,
      borderRadius: _borderRadius,
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _InnerShadow(
              shadows: (enabled && color != CustomButtonColor.transparent)
                  ? <Shadow>[
                      Shadow(
                        color: Colors.white.withOpacity(0.25),
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
              // background layer
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _borderRadius,
                  color: bgColor,
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: _borderRadius,
              child: DefaultTextStyle.merge(
                style: textStyle,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                  child: Center(child: child),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InnerShadow extends SingleChildRenderObjectWidget {
  const _InnerShadow({
    this.shadows = const <Shadow>[],
    super.child,
  });

  final List<Shadow> shadows;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final renderObject = _RenderInnerShadow();
    updateRenderObject(context, renderObject);
    return renderObject;
  }

  @override
  void updateRenderObject(BuildContext context, _RenderInnerShadow renderObject) {
    renderObject.shadows = shadows;
  }
}

class _RenderInnerShadow extends RenderProxyBox {
  late List<Shadow> shadows;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    final bounds = offset & size;

    context.canvas.saveLayer(bounds, Paint());
    context.paintChild(child!, offset);

    for (final shadow in shadows) {
      final shadowRect = bounds.inflate(shadow.blurSigma);
      final shadowPaint = Paint()
        ..blendMode = BlendMode.srcATop
        ..colorFilter = ColorFilter.mode(shadow.color, BlendMode.srcOut)
        ..imageFilter = ImageFilter.blur(sigmaX: shadow.blurSigma, sigmaY: shadow.blurSigma);
      context.canvas
        ..saveLayer(shadowRect, shadowPaint)
        ..translate(shadow.offset.dx, shadow.offset.dy);
      context.paintChild(child!, offset);
      context.canvas.restore();
    }

    context.canvas.restore();
  }
}
