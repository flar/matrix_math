import 'term.dart';
import 'constants.dart';
import 'products.dart';

/// A Term object representing a single named unknown variable.
class Unknown extends Term {
  final String name;

  const Unknown(this.name);

  @override bool isNegative() => false;
  @override bool negatesGracefully() => false;
  @override Term operator -() => Product(coefficient: neg_one, factors: [this]);
  @override bool equals(Term term) => term == this;
  @override Term addDirect(Term other, isNegated) {
    if (other is Product) {
      if (other.factors.length == 1 && other.factors[0].equals(this)) {
        return isNegated ? (this - other) : (this + other);
      }
    } else if (other is Unknown) {
      if (other.equals(this)) {
        if (isNegated) return zero;
        return Product(
          coefficient: one + one,
          factors: [this],
        );
      }
    }
    return null;
  }
  @override String toString() => name;
  @override String toOutline() => 'v';
  @override bool startsWithMinus() => false;
}
