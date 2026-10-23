import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/material.dart';

/// The Tabby cat mark, loaded from the shared asset SVG (see
/// assets/icons/README in the design-assets deliverable). Keep usage
/// sparing, per the brand brief — this is for headers and empty/success
/// states, not a repeated decorative icon.
class CatMark extends StatelessWidget {
  final double size;
  const CatMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/mark.svg',
      width: size,
      height: size,
    );
  }
}

class MascotIllustration extends StatelessWidget {
  final bool settled;
  final double width;

  const MascotIllustration({super.key, this.settled = false, this.width = 160});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      settled ? 'assets/mascots/mascot-settled.svg' : 'assets/mascots/mascot-empty.svg',
      width: width,
    );
  }
}
