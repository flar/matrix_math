import 'term.dart';
import 'products.dart';

/// A Term object representing a single named unknown variable.
class Unknown implements Term {
  final String name;
  const Unknown(this.name);

  @override bool isNegative() => false;
  @override bool negatesGracefully() => false;
  @override Term negate() => Product(coefficient: -1.0, factors: [this]);
  @override bool equals(Term term) => term == this;
  @override Term addDirect(Term other, isNegated) => null;
  @override String toString() => name;
  @override bool startsWithMinus() => false;
}
