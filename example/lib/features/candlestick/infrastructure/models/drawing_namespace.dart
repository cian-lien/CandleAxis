import 'dart:convert';

/// Contract addresses are intentionally case sensitive, including non-EVM chains.
class DrawingNamespace {
  const DrawingNamespace({
    required this.chain,
    required this.address,
    required this.source,
  });

  final String chain;
  final String address;
  final String source;

  String get storageKey =>
      'candlestick_drawings_${base64Url.encode(utf8.encode(jsonEncode([chain, address, source])))}';
}
