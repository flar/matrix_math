import 'term.dart';
import 'constants.dart';
import 'products.dart';
import 'sums.dart';

/// A Term object representing a single named unknown variable.
class Unknown implements Term {
  final String name;
  const Unknown(this.name);

  @override bool isNegative() => false;
  @override bool negatesGracefully() => false;
  @override Term negate() => Product(coefficient: -1.0, factors: [this]);
  @override bool equals(Term term) => term == this;
  @override Term addDirect(Term other, isNegated) {
    if (other is Product) {
      if (other.factors.length == 1 && other.factors[0].equals(this)) {
        return isNegated ? Sum.sub(this, other) : Sum.add([this, other]);
      }
    } else if (other is Unknown) {
      if (other.equals(this)) {
        if (isNegated) return zero;
        return Product(
          coefficient: 2.0,
          factors: [this],
        );
      }
    }
    return null;
  }
  @override String toString() => name;
  @override bool startsWithMinus() => false;
}
