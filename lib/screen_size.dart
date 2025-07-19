enum ScreenSizeType { phone, tablet, desktop }

class ScreenSize {
  static ScreenSizeType of(double width) {
    if (width >= 1200) {
      return ScreenSizeType.desktop;
    } else if (width >= 600) {
      return ScreenSizeType.tablet;
    } else {
      return ScreenSizeType.phone;
    }
  }
} 