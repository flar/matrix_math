import 'term.dart';
import 'constants.dart';

class Negation implements Term {
  final Term negated;

  Negation(this.negated);

  @override bool isNegative() => !negated.isNegative();

  static Term negation(Term term) {
    if (term is Negation) return term.negated;

    if (term == nan)     return nan;
    if (term == one)     return neg_one;
    if (term == neg_one) return one;
    if (term == pos_inf) return neg_inf;
    if (term == neg_inf) return pos_inf;

    return Negation(term);
  }

  @override bool negatesGracefully() => true;
  @override Term negate() => negated;

  @override
  bool equals(Term other) {
    if (other is Negation) return other.negated.equals(this.negated);
    return false;
  }

  static bool equalsNegated(Term first, Term second) {
    if (first == one)     return second == neg_one;
    if (first == neg_one) return second == one;
    if (first == pos_inf) return second == neg_inf;
    if (first == neg_inf) return second == pos_inf;
    if (first is Negation) {
      if (second is Negation) return false;
      return first.negated.equals(second);
    } else if (second is Negation) {
      return second.negated.equals(first);
    } else {
      return false;
    }
  }

  @override String toString() => '-$negated';
}
