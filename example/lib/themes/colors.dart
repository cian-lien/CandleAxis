import 'package:flutter/material.dart';

part 'colors_support_1.dart';

class AppColors {
  static List<Color> profileHeroLoadingGradient(BuildContext context) => const [
    Color(0xFF181C2D),
    Color(0xFF303047),
    Color(0xFF121722),
  ];

  // 二维码使用纯黑白配对，避免主题灰阶降低扫码对比度。
  static Color qrCodeBackground(BuildContext context) =>
      getColor(context, lightColor: white, darkColor: black);

  static Color qrCodeForeground(BuildContext context) =>
      getColor(context, lightColor: black, darkColor: white);

  static Color bitClawOnlineIndicator(BuildContext context) => getColor(
    context,
    lightColor: const Color(0xFF6CD878),
    darkColor: const Color(0xFF6CD878),
  );

  static Color riskNoticeIcon(BuildContext context) => getColor(
    context,
    lightColor: riskNoticeAccent,
    darkColor: riskNoticeAccent,
  );

  // Identity colors remain stable across themes and rebuilds.
  static List<Color> strategyMonitorAvatarPalette(BuildContext context) =>
      const [
        primary,
        quaternary,
        secondary,
        Color(0xFF52C41A),
        Color(0xFF9747FF),
        Color(0xFFFA8C16),
      ];

  static const Color primary = Color(0xFF0265FF); // #0265FF
  static const Color secondary = Color(0xFFFE6256); // #FE6256
  static const Color tertiary = Color(0xFFFFF000); // #FFF000
  static const Color quaternary = Color(0xFF1099FB); // #1099FB
  static const Color quinary = Color(0xFFE6F0FF); // #E6F0FF
  static const Color senary = Color(0xFFF5F5F5); // #F5F5F5
  static const Color septenary = Color(0xFF52C41A); // #52C41A
  static const Color fallRed = Color(0xFFDF3636); // #B32F29 跌
  static const Color riseGreen = Color(0xFF2D7552); // #2D7552 涨
  static const Color alertRed = Color(0xFFB32F29); // #DF3636
  static const Color errorRed = Color(0xFFF5222D); // #F5222D 校验错误
  static const Color neutralGray = Color(0xFF706F6D); // #706F6D
  static const Color transparent = Color(0x00000000);
  // 品牌色或深色媒体之上的前景色：浅色深色主题都保持白色
  static const Color onPrimary = Color(0xFFFFFFFF);
  // 导出的分享海报固定使用白色画布，不随应用主题切换。
  static const Color sharePosterBackground = Color(0xFFFFFFFF);
  // 筛选器激活指示点：仅表达「已启用」状态，两种主题下都用同一亮绿
  static const Color activeGreen = Color(0xFF32D18B);
  // 筛选使用独立的低强调蓝灰配色，避免与实心蓝交易按钮争夺视觉层级。
  static const Color radarFilterSelected = Color(0xFFEAF2FF);
  static const Color radarFilterSelectedForeground = Color(0xFF175CD3);
  // 筛选按钮与筛选栏同底：浅色白底、深色页面底，靠投影与图标区分，
  // 避免夜间在深色底上闪出一整块白方块。
  static Color radarFilterButtonBackground(BuildContext context) =>
      background(context);
  static Color radarFilterButtonForeground(BuildContext context) => getColor(
    context,
    lightColor: const Color(0xFF000000),
    darkColor: DarkThemeColors.textPrimary,
  );
  // 浅色主题沿用设计稿的低强调蓝灰；深色主题换成深蓝染底 / 卡片面，
  // 与深灰页面底拉开层级，同时保持文字对比度。
  static Color radarFilterBackground(
    BuildContext context, {
    bool selected = false,
  }) => selected
      ? getColor(
          context,
          lightColor: radarFilterSelected,
          darkColor: DarkThemeColors.accentTint,
        )
      : getColor(
          context,
          lightColor: const Color(0xFFF4F5F7),
          darkColor: DarkThemeColors.surface,
        );
  static Color radarFilterForeground(
    BuildContext context, {
    bool selected = false,
  }) => selected
      ? getColor(
          context,
          lightColor: radarFilterSelectedForeground,
          darkColor: DarkThemeColors.quaternary,
        )
      : getColor(
          context,
          lightColor: const Color(0xFF525866),
          darkColor: DarkThemeColors.textSecondary,
        );
  static Color intelligenceLeaderboardBackground(BuildContext context) =>
      getColor(
        context,
        lightColor: const Color(0xFFF4F5F7),
        darkColor: DarkThemeColors.surface,
      );
  // 情报来源标签使用低强调底色，保持浅色底与深色文字的对比。
  static const Color intelligenceSmartMoneyBadgeBackground = Color(0xFFEAF2FF);
  static const Color intelligenceSmartMoneyBadgeForeground = Color(0xFF175CD3);
  static const Color intelligenceKolBadgeBackground = Color(0xFFF2EDFF);
  static const Color intelligenceKolBadgeForeground = Color(0xFF6941C6);
  // 金狗雷达叙事评级徽章底色：设计指定的固定亮色底，浅色/深色主题下保持一致
  static const Color radarGradeS = Color(0xFFFFD427);
  static const Color radarGradeA = Color(0xFF5DF7FF);
  static const Color radarGradeB = Color(0xFF1299FB);
  static const Color radarGradeC = quinary;
  // 媒体遮罩与阴影基色：两种主题都用黑色半透明，仅透明度由调用方决定
  static const Color overlayBlack = Color(0xFF000000);

  /// 通用弹窗/底部面板蒙版色。
  static Color modalBarrier(BuildContext context) =>
      overlayBlack.withValues(alpha: 0.3);

  // 刻意常暗的沉浸式页面底（相机、生成、二维码）与品牌黑按钮
  static const Color immersiveBlack = Color(0xFF000000);
  // Flutter 首帧开屏兜底色：三张开屏图的均值色调，开屏图解码失败时用它避免白屏
  static const Color splashFallback = Color(0xFF68768F);

  static const Color bitClawQqBlue = Color(0xFF1099FB);
  static const Color bitClawQqNoticeBackground = Color(0x141099FB);
  static const Color bitClawQqNoticeBorder = Color(0x331099FB);
  static const Color bitClawTelegramBlue = Color(0xFF26A5E4);
  static const Color bitClawTelegramNoticeBackground = Color(0x1426A5E4);
  static const Color bitClawTelegramNoticeBorder = Color(0x3326A5E4);
  static const Color bitClawWechatGreen = Color(0xFF07C160);
  static const Color bitClawWechatNoticeBackground = Color(0x1407C160);
  static const Color bitClawWechatNoticeBorder = Color(0x3307C160);

  static const Color tipColor = Color.fromRGBO(82, 196, 26, 1); // #FE6256

  static const Color backgroundWhite = Color.fromRGBO(255, 255, 255, 1);

  // static const Color textQuinary = Color.fromRGBO(86, 86, 86, 1);

  static const Color gradientBlueStart = Color.fromRGBO(114, 202, 255, 1);
  static const Color gradientBlueEnd = Color.fromRGBO(24, 94, 255, 1);

  static const Color bgGradientDark = Color.fromRGBO(42, 44, 77, 1);
  static const Color bgGradientDart2 = Color.fromRGBO(161, 161, 161, 1);
  static const Color bgGradientLight = Color.fromRGBO(217, 220, 254, 1);
  static const Color bgGradientLight2 = Color.fromRGBO(250, 250, 250, 1);

  static const Color tokenPlaceholderColor = Color.fromRGBO(38, 130, 240, 1);
  static const Color white = Color.fromRGBO(255, 255, 255, 1);
  static const Color black = Color.fromRGBO(0, 0, 0, 1);
  static const Color buttonGradientStart = Color.fromRGBO(50, 68, 255, 1);
  static const Color buttonGradientEnd = Color.fromRGBO(152, 97, 250, 1);

  static const Color settingVipTitleColor = Color(0xFF024265);

  // Wallet Security Page Colors
  static const Color securityGradientStart = Color(0xFF576EED);
  static const Color securityGradientEnd = Color(0xFF0D1F8D);
  static const Color securityTextSecondary = Color(0xFFAFC1FF);

  // Level Colors (蓝色渐变，用于等级显示，L1最深最重要)
  static const Color levelBlue1 = Color(0xFF2563EB); // L1 深蓝
  static const Color levelBlue2 = Color(0xFF3B82F6); // L2
  static const Color levelBlue3 = Color(0xFF60A5FA); // L3
  static const Color levelBlue4 = Color(0xFF93C5FD); // L4 浅蓝

  // Strategy Page Colors
  static const Color primaryBlue = primary; // 兼容旧调用，统一使用品牌主色
  static const Color strategyLogGreen = Color(0xFF2D661B); // 策略日志收入绿色
  static const Color estimateBlue = Color(0xFF3076FE); // #3076FE 预估获得数字颜色

  // 策略创建页「风险说明」卡：琥珀警示色。
  // 浅色主题逐值对齐品牌原型（军火库 App 预览的 amber-50 底 + amber-500/25 描边 +
  // amber-800 标题 / amber-700 正文）；深色主题换同色系的低透明度底 + 亮琥珀文字，
  // 免得整块在深色底上糊成一片。
  static const Color riskNoticeAccent = Color(
    0xFFF59E0B,
  ); // amber-500：图标 / 折叠箭头

  static Color riskNoticeBackground(BuildContext context) => getColor(
    context,
    lightColor: const Color(0xFFFFFBEB), // amber-50
    darkColor: const Color(0x1FF59E0B), // amber-500 12%
  );

  static Color riskNoticeBorder(BuildContext context) => getColor(
    context,
    lightColor: const Color(0x40F59E0B), // amber-500 25%
    darkColor: const Color(0x4DF59E0B), // amber-500 30%
  );

  static Color riskNoticeTitle(BuildContext context) => getColor(
    context,
    lightColor: const Color(0xFF92400E), // amber-800
    darkColor: const Color(0xFFFCD34D), // amber-300
  );

  static Color riskNoticeBody(BuildContext context) => getColor(
    context,
    lightColor: const Color(0xFFB45309), // amber-700
    darkColor: const Color(0xFFFBBF24), // amber-400
  );

  static Color getColor(
    BuildContext context, {
    required Color lightColor,
    required Color darkColor,
  }) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkColor
        : lightColor;
  }

  static Color background(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.background,
    darkColor: DarkThemeColors.background,
  );

  static Color foreground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.foreground,
    darkColor: DarkThemeColors.foreground,
  );

  static Color surface(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.surface,
    darkColor: DarkThemeColors.surface,
  );

  static Color border(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.border,
    darkColor: DarkThemeColors.border,
  );

  static Color borderSecondary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.borderSecondary,
    darkColor: DarkThemeColors.borderSecondary,
  );

  static Color borderTertiary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.borderTertiary,
    darkColor: DarkThemeColors.borderTertiary,
  );

  static Color card(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.card,
    darkColor: DarkThemeColors.card,
  );

  static Color shimmerBaseColor(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.shimmerBaseColor,
    darkColor: DarkThemeColors.shimmerBaseColor,
  );

  static Color shimmerHighlightColor(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.shimmerHighlightColor,
    darkColor: DarkThemeColors.shimmerHighlightColor,
  );
  // 文本主要颜色
  static Color textPrimary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.textPrimary,
    darkColor: DarkThemeColors.textPrimary,
  );

  // 文本次要颜色
  static Color textSecondary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.textSecondary,
    darkColor: DarkThemeColors.textSecondary,
  );

  // 文本三级颜色
  static Color textTertiary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.textTertiary,
    darkColor: DarkThemeColors.textTertiary,
  );

  // 文本四级颜色
  static Color textQuaternary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.textQuaternary,
    darkColor: DarkThemeColors.textQuaternary,
  );

  // static Color textQuinary(BuildContext context) => getColor(
  //       context,
  //       lightColor: LightThemeColors.textQuinary,
  //       darkColor: DarkThemeColors.textQuinary,
  //     );

  static Color buttonPrimary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.buttonPrimary,
    darkColor: DarkThemeColors.buttonPrimary,
  );

  /// 顶部搜索栏底色（输入框填充 / 搜索页导航条）
  static Color searchBarBackground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.searchBarBackground,
    darkColor: DarkThemeColors.searchBarBackground,
  );

  /// 搜索框占位文案与搜索图标颜色
  static Color searchBarHint(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.searchBarHint,
    darkColor: DarkThemeColors.searchBarHint,
  );

  /// 搜索框动作色（如「粘贴」）
  static Color searchBarAction(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.searchBarAction,
    darkColor: DarkThemeColors.searchBarAction,
  );

  /// 分组/设置页底色
  static Color backgroundSecondary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.backgroundSecondary,
    darkColor: DarkThemeColors.backgroundSecondary,
  );

  /// 二级页面底色（设置子页等）
  static Color backgroundTertiary(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.backgroundTertiary,
    darkColor: DarkThemeColors.backgroundTertiary,
  );

  /// 霓虹紫描边（登录/验证码输入框聚焦态）
  static Color neonAccent(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.neonAccent,
    darkColor: DarkThemeColors.neonAccent,
  );

  /// 正向状态底色
  static Color positiveTint(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.positiveTint,
    darkColor: DarkThemeColors.positiveTint,
  );

  /// 正向状态文字色
  static Color textPositive(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.textPositive,
    darkColor: DarkThemeColors.textPositive,
  );

  /// 跨链 Banner 底色
  static Color crossChainBannerBackground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.crossChainBannerBackground,
    darkColor: DarkThemeColors.crossChainBannerBackground,
  );

  /// 跨链 Banner 标题强调色
  static Color crossChainBannerHighlight(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.crossChainBannerHighlight,
    darkColor: DarkThemeColors.crossChainBannerHighlight,
  );

  /// 限时倒计时强调色（模板剩余时间 / 限时活动）
  static Color countdownAccent(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.countdownAccent,
    darkColor: DarkThemeColors.countdownAccent,
  );

  /// 情报代币卡底色
  static Color intelligenceCardBackground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceCardBackground,
    darkColor: DarkThemeColors.intelligenceCardBackground,
  );

  /// 情报代币卡文字色
  static Color intelligenceCardForeground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceCardForeground,
    darkColor: DarkThemeColors.intelligenceCardForeground,
  );

  /// 情报代币卡分析标签底色
  static Color intelligenceLabelBackground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceLabelBackground,
    darkColor: DarkThemeColors.intelligenceLabelBackground,
  );

  /// 情报代币卡分析标签描边
  static Color intelligenceLabelBorder(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceLabelBorder,
    darkColor: DarkThemeColors.intelligenceLabelBorder,
  );

  /// 情报代币卡分析标签文字
  static Color intelligenceLabelForeground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceLabelForeground,
    darkColor: DarkThemeColors.intelligenceLabelForeground,
  );

  /// 情报代币卡高亮统计数值
  static Color intelligenceMetricHighlight(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.intelligenceMetricHighlight,
    darkColor: DarkThemeColors.intelligenceMetricHighlight,
  );

  /// 品牌浅色染底（信息条、选中态背景）
  static Color accentTint(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.accentTint,
    darkColor: DarkThemeColors.accentTint,
  );

  /// 与 `foreground` 相反的前景色（toast / tooltip 等反色浮层上的文字）
  static Color onForeground(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.onForeground,
    darkColor: DarkThemeColors.onForeground,
  );

  /// 卡片投影色
  static Color shadow(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.shadow,
    darkColor: DarkThemeColors.shadow,
  );

  /// InkWell 水波纹色
  static Color ripple(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.ripple,
    darkColor: DarkThemeColors.ripple,
  );

  /// 底导选中态图标/文案（浅色=纯黑，深色=纯白）
  static Color navItemSelected(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.navItemSelected,
    darkColor: DarkThemeColors.navItemSelected,
  );

  /// 弹窗顶部流光光晕色（主题品牌色，深浅主题两档强度）
  static Color panelTopShine(BuildContext context) => getColor(
    context,
    lightColor: LightThemeColors.panelTopShine,
    darkColor: DarkThemeColors.panelTopShine,
  );

  static Color bgGradientStart(BuildContext context) => getColor(
    context,
    lightColor: AppColors.bgGradientLight,
    darkColor: AppColors.bgGradientDark,
  );

  static Color bgGradientEnd(BuildContext context) => getColor(
    context,
    lightColor: AppColors.bgGradientLight2,
    darkColor: AppColors.bgGradientDart2,
  );
}
