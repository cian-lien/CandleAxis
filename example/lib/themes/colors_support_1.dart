part of 'colors.dart';

class LightThemeColors {
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color tertiary = AppColors.tertiary;
  static const Color quaternary = AppColors.quaternary;
  static const Color quinary = AppColors.quinary;
  static const Color senary = AppColors.senary;

  static const Color background = Color.fromRGBO(255, 255, 255, 1);
  static const Color foreground = Color.fromRGBO(0, 0, 0, 1);
  static const Color surface = Color.fromRGBO(243, 243, 243, 1);

  //
  static const Color border = Color.fromRGBO(221, 227, 225, 1);
  static const Color borderSecondary = Color(0xFFEDEDED);
  static const Color borderTertiary = Color.fromRGBO(29, 171, 226, 1);
  static const Color card = Color.fromRGBO(245, 245, 245, 1);
  // Keep the loading sweep close to the surface tone so it feels calm rather
  // than like a high-contrast flash across every placeholder.
  static const Color shimmerBaseColor = Color.fromRGBO(238, 240, 240, 1);
  static const Color shimmerHighlightColor = Color.fromRGBO(245, 246, 246, 1);
  // 文本颜色
  static const Color textPrimary = Color.fromRGBO(0, 0, 0, 1);
  static const Color textSecondary = Color.fromRGBO(86, 86, 86, 1);
  static const Color textTertiary = Color.fromARGB(255, 144, 144, 144);
  static const Color textQuaternary = Color.fromRGBO(183, 183, 183, 1);
  // static const Color textQuinary = Color.fromRGBO(222, 222, 222, 1);
  static const Color buttonPrimary = AppColors.primary;

  // 顶部搜索栏（AppSearchHeader / SearchBarWidget）
  static const Color searchBarBackground = Color(0xFFF6F6F6);
  static const Color searchBarHint = Color(0xFFB7B7B7);
  static const Color searchBarAction = Color(0xFF9747FF);

  // 分组/设置页底色：比页面主底色略深，用于区分设置项分组
  static const Color backgroundSecondary = Color(0xFFF7F7F7);
  // 与卖出按钮的主蓝色 10% 叠白效果一致，使用实色避免底板影响。
  static const Color accentTint = AppColors.quinary;
  // 与 foreground 相反的前景色：浅色主题下 foreground 是深色，文字取白
  static const Color onForeground = Color(0xFFFFFFFF);
  // 卡片投影：深色主题需要更重的阴影才能在深底上看出层级
  static const Color shadow = Color(0x26000000);
  // InkWell 水波纹：浅色主题用深色波纹，深色主题反过来
  static const Color ripple = Color(0x1A000000);
  // 底导选中态图标/文案：浅色下用纯黑取得最高对比
  static const Color navItemSelected = Color(0xFF000000);
  // 弹窗顶部流光光晕：主题品牌色，浅色主题下降低强度避免浅底过曝
  static const Color panelTopShine = Color(0x4D0265FF);

  // 跨链 Banner（CrossChainBanner）：浅色沿用设计稿的淡蓝染底
  static const Color crossChainBannerBackground = Color(0xFFEFF7FD);
  // 跨链 Banner 标题强调色：浅色用品牌蓝
  static const Color crossChainBannerHighlight = AppColors.primary;

  // 情报代币卡（IntelligenceTokenCard）：浅色沿用淡蓝染底设计
  static const Color intelligenceCardBackground = Color(0xFFEFF5FF);
  static const Color intelligenceCardForeground = Color(0xFF222222);
  static const Color intelligenceLabelBackground = Color(0xFFE8EFFD);
  static const Color intelligenceLabelBorder = Color(0xFFA8CAFF);
  static const Color intelligenceLabelForeground = Color(0xFF0C6CF2);
  static const Color intelligenceMetricHighlight = Color(0xFF0C7CF7);

  // 二级页面底色（设置子页等）：比分组底色 backgroundSecondary 再深一档
  static const Color backgroundTertiary = Color(0xFFEEEEEE);
  // 霓虹紫描边（登录/验证码输入框聚焦态）
  static const Color neonAccent = Color(0xFF973DFF);

  // 正向状态（观察周期、利好标签）：浅色用深绿字配淡绿底
  static const Color positiveTint = Color(0xFFF6FFED);
  static const Color textPositive = Color(0xFF389E0D);

  // 限时倒计时（模板 `expired_at` 剩余时间）：浅底上用琥珀橙，兼顾「提醒」与可读性
  static const Color countdownAccent = Color(0xFFD97704);
}

class DarkThemeColors {
  static const Color primary = AppColors.primary;
  static const Color secondary = AppColors.secondary;
  static const Color tertiary = AppColors.tertiary;
  static const Color quaternary = AppColors.quaternary;
  static const Color quinary = AppColors.quinary;
  static const Color senary = AppColors.senary;
  // 深灰底而非纯黑：夜间不刺眼，同时保留层级对比空间
  static const Color background = Color(0xFF121212);
  static const Color foreground = Color(0xFFE6E6E6);
  // 加载扫光贴近深色页面底色，避免在占位块上闪出高对比
  static const Color shimmerBaseColor = Color(0xFF1A1A1A);
  static const Color shimmerHighlightColor = Color(0xFF242424);

  // 背景
  static const Color surface = Color(0xFF1E1E1E);

  // 深色模式下的边框色：比浅色更暗，保证深底上可辨识
  static const Color border = Color(0xFF2E2E2E);
  static const Color borderSecondary = Color(0xFF262626);
  static const Color borderTertiary = Color.fromRGBO(29, 171, 226, 1);

  static const Color card = Color(0xFF1E1E1E);

  // 文本：不用纯白，降低夜间眩光，同时保持层级递减
  static const Color textPrimary = Color(0xFFE6E6E6);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF8A8A8A);
  static const Color textQuaternary = Color(0xFF6B6B6B);
  // static const Color textQuinary = Color.fromRGBO(86, 86, 86, 1);

  static const Color buttonPrimary = AppColors.primary;

  // 顶部搜索栏：输入框在深色底板上抬一档，占位与「粘贴」提亮到可读对比度
  static const Color searchBarBackground = Color(0xFF1E1E1E);
  static const Color searchBarHint = Color(0xFF8A8A8A);
  static const Color searchBarAction = Color(0xFFB98CFF);

  // 分组/设置页底色：比页面主底色更暗，保留分组层级
  static const Color backgroundSecondary = Color(0xFF0F0F0F);
  // 深蓝染底保留品牌色相，与深灰卡片区分，避免浅色块刺眼。
  static const Color accentTint = Color(0xFF162A46);
  // 深色主题下 foreground 是浅色，其上的前景色转为深色
  static const Color onForeground = Color(0xFF121212);
  // 深底上加深投影，保证卡片层级可辨识
  static const Color shadow = Color(0x66000000);
  // 深色主题的水波纹改用浅色，否则在深底上完全看不见
  static const Color ripple = Color(0x1AFFFFFF);
  // 底导选中态图标/文案：深色下用纯白，与未选中态拉开层级
  static const Color navItemSelected = Color(0xFFFFFFFF);
  // 弹窗顶部流光光晕：主题品牌色，深色主题下加强以看清弹窗上边缘
  static const Color panelTopShine = Color(0xBF0265FF);

  // 二级页面底色（设置子页等），比分组底色再深一档
  static const Color backgroundTertiary = Color(0xFF171717);
  // 霓虹紫描边（登录/验证码输入框聚焦态）
  static const Color neonAccent = Color(0xFFB98CFF);

  // 跨链 Banner：深色下换成品牌蓝低透明度染底，避免近白色块在夜间刺眼
  static const Color crossChainBannerBackground = Color(0xFF101C2F);
  // 跨链 Banner 标题强调色：深底上品牌蓝对比不足，提亮一档
  static const Color crossChainBannerHighlight = quaternary;

  // 情报代币卡：深色下改用主题卡片色，染底标签改为品牌蓝低透明度底
  static const Color intelligenceCardBackground = DarkThemeColors.card;
  static const Color intelligenceCardForeground = DarkThemeColors.textPrimary;
  static const Color intelligenceLabelBackground = Color(0x1F0265FF);
  static const Color intelligenceLabelBorder = Color(0x4D0265FF);
  static const Color intelligenceLabelForeground = DarkThemeColors.quaternary;
  static const Color intelligenceMetricHighlight = DarkThemeColors.quaternary;

  // 正向状态：深色下用低透明度品牌绿底 + 亮绿字，避免淡绿底刺眼
  static const Color positiveTint = Color(0x1F52C41A);
  static const Color textPositive = AppColors.septenary;

  // 限时倒计时：深底上把琥珀橙提亮一档，避免在 #121212 上发灰
  static const Color countdownAccent = Color(0xFFFFA940);
}
