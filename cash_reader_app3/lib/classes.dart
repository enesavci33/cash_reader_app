enum DetectionClasses { cash5, cash10, cash20, cash50, cash100, cash200, bos }

extension DetectionClassesExtension on DetectionClasses {
  String get label {
    switch (this) {
      case DetectionClasses.cash5:
        return "5";
      case DetectionClasses.cash10:
        return "10";
      case DetectionClasses.cash20:
        return "20";
      case DetectionClasses.cash50:
        return "100";
      case DetectionClasses.cash100:
        return "50";
      case DetectionClasses.cash200:
        return "200";
      case DetectionClasses.bos:
        return "bos";
    }
  }

  static DetectionClasses fromIndex(int index) {
    switch (index) {
      case 0:
        return DetectionClasses.cash5;
      case 1:
        return DetectionClasses.cash10;
      case 2:
        return DetectionClasses.cash20;
      case 3:
        return DetectionClasses.cash50;
      case 4:
        return DetectionClasses.cash100;
      case 5:
        return DetectionClasses.cash200;
      default:
        throw ArgumentError("Invalid index for DetectionClasses");
    }
  }
}
