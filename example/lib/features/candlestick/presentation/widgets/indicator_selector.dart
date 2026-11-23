import 'package:candle_axis/candlestick_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/l10n.dart';
import '../../../../themes/colors.dart';
import '../cubit/selection/selection_params_cubit.dart';
import '../cubit/selection/selection_params_state.dart';
import 'indicator_button.dart';
import 'indicator_settings_sheet.dart';
import 'settings_button.dart';

class IndicatorSelector extends StatelessWidget {
  const IndicatorSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectionParamsCubit, SelectionParamsState>(
      builder: (context, state) {
        final cubit = context.read<SelectionParamsCubit>();

        return Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...MainState.values.map(
                      (indicator) => IndicatorButton(
                        label: indicator.name,
                        isSelected: state.mainStates.contains(indicator),
                        onPressed: () => cubit.toggleMainState(indicator),
                      ),
                    ),
                    _buildDivider(context),
                    IndicatorButton(
                      label: 'VOL',
                      isSelected: !state.volHidden,
                      onPressed: cubit.toggleVolHidden,
                    ),
                    ...SecondaryState.values.map(
                      (indicator) => IndicatorButton(
                        label: indicator.name,
                        isSelected: state.secondaryStates.contains(indicator),
                        onPressed: () => cubit.toggleSecondaryState(indicator),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDivider(
              context,
              key: const Key('indicator-settings-divider'),
            ),
            SizedBox(
              width: 36.w,
              child: SettingsButton(
                tooltip: S.of(context).indicatorSettingsTitle,
                onPressed: () => showIndicatorSettingsSheet(
                  context,
                  selection: state,
                  onSave: cubit.updateIndicators,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context, {Key? key}) {
    return Container(
      key: key,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      height: MediaQuery.textScalerOf(context).scale(12.sp),
      width: 1,
      color: AppColors.textQuaternary(context),
    );
  }
}
