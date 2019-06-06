import 'term.dart';

class Constant implements Term {
  final double value;

  const Constant(this.value);
  static Constant forDouble(double v) {
    if (v == 0.0) return zero;
    if (v == 1.0) return one;
    if (v == -1.0) return neg_one;
    if (v.isInfinite) return (v < 0) ? neg_inf : pos_inf;
    if (v.isNaN) return nan;
    return Constant(v);
  }

  @override bool isNegative() => value < 0.0;
  @override bool negatesGracefully() => true;

  @override
  Term negate() {
    if (this == nan)     return nan;
    if (this == one)     return neg_one;
    if (this == zero)    return zero;
    if (this == neg_one) return one;
    if (this == pos_inf) return neg_inf;
    if (this == neg_inf) return pos_inf;
    return Constant(-this.value);
  }

  @override bool equals(Term term) {
    return (term is Constant && term.value == this.value);
  }
  @override String toString() => value.toString();
}

const nan = Constant(0.0 / 0.0);
const pos_inf = Constant( 1.0 / 0.0);
const neg_inf = Constant(-1.0 / 0.0);
const zero = Constant(0.0);
const one = Constant(1.0);
const neg_one = Constant(-1.0);
