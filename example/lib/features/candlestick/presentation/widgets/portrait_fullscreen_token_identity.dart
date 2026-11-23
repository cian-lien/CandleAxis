import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/presentation/widgets/avatar/widget/token.dart';
import '../../../../themes/colors.dart';
import '../../../../utils/clipboard.dart';
import '../../../../utils/extensions/string.dart';
import '../../../../utils/toast.dart';
import '../../../token_detail/presentation/cubits/token_info/token_info_cubit.dart';

/// Identity shown only in the portrait fullscreen chart header.
class PortraitFullscreenTokenIdentity extends StatelessWidget {
  const PortraitFullscreenTokenIdentity({super.key, required this.symbol});

  final String symbol;

  /// Root fullscreen routes retain the detail session's live token info.
  static Widget inheritTokenInfo(BuildContext context, Widget child) {
    final tokenInfo = context.read<TokenInfoCubit?>();
    return tokenInfo == null
        ? child
        : BlocProvider<TokenInfoCubit>.value(value: tokenInfo, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final tokenInfo = context.read<TokenInfoCubit?>();
    if (tokenInfo == null) return _identity(context, null);
    return BlocBuilder<TokenInfoCubit, TokenInfoState>(
      bloc: tokenInfo,
      buildWhen: (previous, current) =>
          previous.tokenInfo?.base != current.tokenInfo?.base ||
          previous.address != current.address,
      builder: _identity,
    );
  }

  Widget _identity(BuildContext context, TokenInfoState? state) {
    final token = state?.tokenInfo?.base;
    final displaySymbol = token?.symbol.isNotEmpty == true
        ? token!.symbol
        : symbol;
    final address = (token?.address ?? state?.address ?? '').trim();
    return Row(
      children: [
        AvatarToken(
          avatar: token?.tokenLogo,
          tokenName: displaySymbol,
          forceAvatarProxy: true,
          width: 24,
          height: 24,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            displaySymbol,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
        ),
        if (address.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              key: const Key('candlestick-portrait-token-address'),
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                await ClipboardUtils.copy(address);
                if (!context.mounted) return;
                ToastUtils.showCenterToast(context, S.of(context).copied);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        address.splitStartAndEnd(4, 4, separator: '…'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.copy,
                      size: 12,
                      color: AppColors.textTertiary(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
