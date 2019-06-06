import 'term.dart';
import 'constants.dart';
import 'unknowns.dart';
import 'negation.dart';
import 'sums.dart';

class FactorAccumulator {
  List<Term> numerators = [];
  List<Term> denominators;
  double coefficient = 1.0;

  void accumulate(Term t, bool isInverted) {
    if (t is Constant) {
      if (isInverted) {
        coefficient /= t.value;
      } else {
        coefficient *= t.value;
      }
    } else if (t is Negation) {
      coefficient = -coefficient;
      accumulate(t.negated, isInverted);
    } else if (t is Product) {
      for (var f in t.factors) accumulate(f, isInverted);
    } else if (t is Division) {
      accumulate(t.numerator, isInverted);
      accumulate(t.denominator, !isInverted);
    } else {
      if (isInverted) {
        denominators ??= [];
        denominators.add(t);
      } else {
        numerators.add(t);
      }
    }
  }

  bool _cancelTerm(Term t) {
    for (int i = 0; i < numerators.length; i++) {
      Term n = numerators[i];
      if (n.equals(t)) {
        numerators.removeAt(i);
        return true;
      }
      if (Negation.equalsNegated(n, t)) {
        numerators.removeAt(i);
        coefficient = -coefficient;
        return true;
      }
    }
    return false;
  }

  static Term _forList(double coefficient, List<Term> terms) {
    if (terms.length == 0) {
      return Constant.forDouble(coefficient);
    } else if (terms.length == 1) {
      if (coefficient == 1.0) return terms[0];
      if (coefficient == -1.0) return terms[0].negate();
    }
    if (coefficient != 1.0 && coefficient != -1.0) {
      terms.insert(0, Constant.forDouble(coefficient));
    }
    Term product = distribute(terms);
    if (coefficient == -1.0) product = product.negate();
    return product;
  }

  static Term distribute(List<Term> terms) {
    for (int i = 0; i < terms.length; i++) {
      Term term = terms[i];
      if (term is Sum) {
        List<Term> distributed = [];
        for (var dterm in term.addends) {
          distributed.add(Product.mulList([
            ...terms.sublist(0, i),
            dterm,
            ...terms.sublist(i + 1),
          ]));
        }
        return Sum.add(distributed);
      }
    }
    terms.sort(sortOrder);
    return Product(terms);
  }

  static int sortOrder(Term a, Term b) {
    if (a is Constant) {
      if (b is Constant) return a.value.compareTo(b.value);
      return -1;
    }
    if (b is Constant) {
      return 1;
    }
    if (a is Unknown) {
      if (b is Unknown) return a.name.compareTo(b.name);
      return -1;
    }
    if (b is Unknown) {
      return 1;
    }
    return 0;
  }

  static Term divideSums(Sum numerator, Sum denominator) {
    Term numCommon = numerator.commonFactor();
    Term denCommon = denominator.commonFactor();
    if (numCommon == one && denCommon == one) return null;
    Term numCross = Product.mul(numerator, denCommon);
    Term denCross = Product.mul(denominator, numCommon);
    return (numCross.equals(denCross))
        ? Division.div(numCommon, denCommon)
        : null;
  }

  Term getResult() {
    if (coefficient.isNaN) return nan;
    if (coefficient.isInfinite) return (coefficient < 0) ? neg_inf : pos_inf;
    if (coefficient == 0.0) return zero;
    if (denominators != null) {
      int keep = 0;
      for (int i = 0; i < denominators.length; i++) {
        if (!_cancelTerm(denominators[i])) {
          denominators[keep++] = denominators[i];
        }
      }
      if (keep > 0) {
        denominators.length = keep;
        Term num = _forList(coefficient, numerators);
        Term den = _forList(1.0,         denominators);
        if (num is Sum && den is Sum) {
          Term simplified = divideSums(num, den);
          if (simplified != null) return simplified;
        }
        return Division(num, den);
      }
    }
    return _forList(coefficient, numerators);
  }
}

class Product implements Term {
  final List<Term> factors;

  Product(this.factors);

  static Term mulList(List<Term> terms) {
    FactorAccumulator accumulator = FactorAccumulator();
    for (var term in terms) accumulator.accumulate(term, false);
    return accumulator.getResult();
  }

  static Term mul(Term first, Term second) {
    FactorAccumulator accumulator = FactorAccumulator();
    accumulator.accumulate(first, false);
    accumulator.accumulate(second, false);
    return accumulator.getResult();
  }

  @override
  bool isNegative() {
    bool isNeg = false;
    for (var factor in factors) {
      if (factor.isNegative()) isNeg = !isNeg;
    }
    return isNeg;
  }

  @override
  bool negatesGracefully() {
    for (var term in factors) {
      if (term.negatesGracefully()) return true;
    }
    return false;
  }

  @override
  Term negate() {
    for (int i = 0; i < factors.length; i++) {
      Term term = factors[i];
      if (term.negatesGracefully()) {
        return Product([
          ...factors.sublist(0, i),
          term.negate(),
          ...factors.sublist(i+1),
        ]);
      }
    }
    return Negation.negation(this);
  }

  @override bool equals(Term other) {
    if (other is Product) {
      List<Term> oFactors = other.factors;
      if (oFactors.length != factors.length) return false;
      List<bool> used = List.filled(factors.length, false);
      for (var term in oFactors) {
        bool foundIt = false;
        for (int i = 0; i < factors.length; i++) {
          if (!used[i] && term.equals(factors[i])) {
            used[i] = foundIt = true;
            break;
          }
        }
        if (!foundIt) return false;
      }
      return true;
    }
    return false;
  }

  @override String toString() {
    String ret = '';
    bool prevWasUnknown = false;
    String mul = '';
    for (Term term in factors) {
      if (term is Unknown) {
        if (!prevWasUnknown) {
          ret += '$mul';
          prevWasUnknown = true;
        }
        ret += '$term';
      } else {
        if (prevWasUnknown) {
          prevWasUnknown = false;
        }
        ret += '$mul$term';
      }
      mul = '*';
    }
    return ret;
  }
}

class Division implements Term {
  final Term numerator;
  final Term denominator;

  Division(this.numerator, this.denominator);

  static Term div(Term num, Term den) {
    FactorAccumulator accumulator = FactorAccumulator();
    accumulator.accumulate(num, false);
    accumulator.accumulate(den, true);
    return accumulator.getResult();
  }

  static bool isInverse(Term first, Term second) {
    if (first is Division) {
      if (second is Division) {
        return (first.numerator.equals(second.denominator) &&
            first.denominator.equals(second.numerator));
      }
      return (first.numerator == one &&
          first.denominator.equals(second));
    } else if (second is Division) {
      return (second.numerator == one &&
          second.denominator.equals(first));
    }
    return false;
  }

  @override
  bool negatesGracefully() {
    return numerator.negatesGracefully() || denominator.negatesGracefully();
  }

  @override
  Term negate() {
    if (numerator.negatesGracefully()) {
      return Division(numerator.negate(), denominator);
    }
    return Division(numerator, denominator.negate());
  }

  @override
  bool equals(Term term) {
    return term is Division &&
        term.numerator.equals(this.numerator) &&
        term.denominator.equals(this.denominator);
  }

  @override bool isNegative() => numerator.isNegative() != denominator.isNegative();
  @override String toString() => '$numerator/$denominator';
}
