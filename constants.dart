import 'term.dart';

/// A Term representing an ordinary number with no unknown values.
class Constant extends Term {
  final double value;

  const Constant(this.value);

  /// Returns the appropriate Constant Term object for the given double value, while
  /// attempting to preserve the singleton nature of the hard-coded constants.
  static Constant forDouble(double v) {
    Constant special = isSpecialCoefficient(v);
    if (special != null) return special;
    if (v == 1.0) return one;
    if (v == -1.0) return neg_one;
    return Constant(v);
  }

  /// Returns the Constant Term object that represents a coefficient value that will
  /// overwhelm a Product of terms - basically infinities, nans, and zero.
  static Constant isSpecialCoefficient(double v) {
    if (v == 0) return zero;
    if (v.isInfinite) return (v < 0) ? neg_inf : pos_inf;
    if (v.isNaN) return nan;
    return null;
  }

  @override bool isNegative() => value < 0.0;
  @override bool negatesGracefully() => true;

  /// Helper method to add or subtract two values based on a signum boolean.
  static double addOrSub(double v1, double v2, bool isSub) {
    return isSub ? v1 - v2 : v1 + v2;
  }

  @override
  Term addDirect(Term other, bool isNegated) {
    if (other is Constant) {
      return Constant.forDouble(addOrSub(this.value, other.value, isNegated));
    }
    return null;
  }

  @override
  Term operator -() {
    if (this == nan)     return nan;
    if (this == one)     return neg_one;
    if (this == zero)    return zero;
    if (this == neg_one) return one;
    if (this == pos_inf) return neg_inf;
    if (this == neg_inf) return pos_inf;
    return Constant(-this.value);
  }

  static String stringFor(double val) {
    if (val.isFinite && val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toString();
  }

  @override bool equals(Term term) {
    return (term is Constant && term.value == this.value);
  }
  @override String toString() => stringFor(this.value);
  @override String toOutline() => 'K';
  @override bool startsWithMinus() => value < 0.0;
}

const nan = Constant(0.0 / 0.0);
const pos_inf = Constant( 1.0 / 0.0);
const neg_inf = Constant(-1.0 / 0.0);
const zero = Constant(0.0);
const one = Constant(1.0);
const neg_one = Constant(-1.0);
