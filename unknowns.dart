import 'term.dart';
import 'negation.dart';

class Unknown implements Term {
  final String name;
  const Unknown(this.name);

  @override bool isNegative() => false;
  @override bool negatesGracefully() => false;
  @override Term negate() => Negation(this);
  @override bool equals(Term term) => term == this;
  @override String toString() => name;
}
