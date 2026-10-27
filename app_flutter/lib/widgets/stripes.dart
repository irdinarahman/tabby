import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Five small tabby stripes, getting stronger left to right. Used once, in
/// the tab header, as the "tabby" detail.
class Stripes extends StatelessWidget {
  const Stripes({super.key});

  static const _alphas = [77, 115, 153, 199, 255];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _alphas.length; i++)
            Container(
              width: 3,
              height: 18,
              margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
              decoration: BoxDecoration(
                color: AppColors.rust.withAlpha(_alphas[i]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
