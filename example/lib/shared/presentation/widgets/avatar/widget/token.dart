import 'package:flutter/material.dart';

class AvatarToken extends StatelessWidget {
  const AvatarToken({
    super.key,
    this.avatar,
    required this.tokenName,
    required this.forceAvatarProxy,
    required this.width,
    required this.height,
  });

  final String? avatar;
  final String tokenName;
  final bool forceAvatarProxy;
  final double width, height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: CircleAvatar(
      backgroundColor: const Color(0xFFF7931A),
      foregroundColor: Colors.white,
      child: Text(
        tokenName == 'BTC' ? '₿' : tokenName.characters.firstOrNull ?? '?',
        style: TextStyle(fontSize: width * .72, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
