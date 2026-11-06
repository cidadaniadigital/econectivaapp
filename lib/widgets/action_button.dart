import 'package:flutter/material.dart';
import 'package:widgets_spo/widgets_spo.dart';

enum ActionButtonTheme { white, blue, grey, lightGrey }

class ActionButton extends StatelessWidget {
  final ActionButtonTheme theme;
  final String title;
  final Function()? onPressed;
  final Widget? icon;

  const ActionButton({
    super.key,
    required this.theme,
    required this.title,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    switch (theme) {
      case ActionButtonTheme.blue:
        buttonColor = const Color(0xFFF28B50);
        break;
      case ActionButtonTheme.grey:
        buttonColor = Color(0xffe8e8e8);
        break;
      case ActionButtonTheme.lightGrey:
        buttonColor = Color(0xffcadcfc);
        break;
      case ActionButtonTheme.white:
        buttonColor = Colors.white;
        break;
    }

    Color textColor =
        theme == ActionButtonTheme.blue ? Colors.white : Colors.black;

    Color? borderColor =
        theme == ActionButtonTheme.white ? Color(0xFFf2f2f2) : null;

    return ButtonRectDefault(
      icon: icon,
      label: Text(
        title,
        style: primaryTextStyle(
          size: 14,
          color: textColor,
          weight: FontWeight.w600,
        ),
      ),
      borderColor: borderColor,
      borderRadius: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: buttonColor,
      onPressed: onPressed,
    );
  }
}
