extension SplitString on String {
  String splitStartAndEnd(int start, int end, {String separator = '...'}) =>
      length <= start + end
      ? this
      : '${substring(0, start)}$separator${substring(length - end)}';
}
