import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../demo_market.dart';

/// Chart-header quote supplied by the standalone demo.
class TokenInfoCubit extends Cubit<TokenInfoState> {
  TokenInfoCubit() : super(const TokenInfoState());

  void update({
    required double price,
    required double change,
    required double volume,
  }) {
    emit(
      TokenInfoState(
        tokenInfo: DemoTokenInfo(
          DemoTokenQuote(
            price: price.toString(),
            marketCap: (price * DemoMarket.marketCapFactor).toString(),
            priceChange24h: change.toStringAsFixed(2),
            liquidity: (volume * .42).toString(),
            volume24h: volume.toString(),
          ),
        ),
      ),
    );
  }
}

class TokenInfoState {
  const TokenInfoState({this.tokenInfo});
  final DemoTokenInfo? tokenInfo;
  String? get address => null;
}

class DemoTokenInfo {
  const DemoTokenInfo(this.base);
  final DemoTokenQuote base;
  String? get hodlersValue => null;
}

class DemoTokenQuote {
  const DemoTokenQuote({
    required this.price,
    required this.marketCap,
    required this.priceChange24h,
    required this.liquidity,
    required this.volume24h,
  });

  final String price, marketCap, priceChange24h, liquidity, volume24h;
  String get symbol => 'BTC';
  String get address => '';
  String? get tokenLogo => null;
}
