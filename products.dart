import 'term.dart';
import 'constants.dart';
import 'unknowns.dart';
import 'sums.dart';

/// A helper class to accumulate lists of factors for the numerator (and optional denominator)
/// of a bunch of Term objects that are being multiplied together.
///
/// This class will deal with a number of simplification operations including cancelling
/// common factors in the numerator and denominator and consolidating constants into the
/// coefficient term.
class FactorAccumulator {
  List<Term> numerators = [];
  List<Term> denominators;
  double coefficient = 1.0;

  /// Accumulate a single double value into the coefficient (with optional inversion).
  void accumulateValue(double val, bool isInverted) {
    if (isInverted) {
      coefficient /= val;
    } else {
      coefficient *= val;
    }
  }

  /// Accumulate an arbitrary Term object into either the numerator or the denominator
  /// depending on the isInverted boolean.
  void accumulate(Term t, bool isInverted) {
    if (t is Constant) {
      accumulateValue(t.value, isInverted);
    } else if (t is Product) {
      accumulateValue(t.coefficient, isInverted);
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

  /// Eliminate any duplicate copy of the given Term object from the list of numerator
  /// factors and return a boolean indicating the success of the elimination.
  ///
  /// Called only for factors being considered for the denominator.
  bool _cancelTerm(Term t) {
    for (int i = 0; i < numerators.length; i++) {
      Term n = numerators[i];
      if (n.equals(t)) {
        numerators.removeAt(i);
        return true;
      }
    }
    return false;
  }

  /// Return an optimized result for a list of factors, including reduction to a constant
  /// or a single term, and distributing any addition Term objects into the remaining factors.
  static Term _forList(double coefficient, List<Term> terms) {
    if (terms.length == 0) {
      return Constant.forDouble(coefficient);
    } else if (terms.length == 1) {
      if (coefficient == 1.0) return terms[0];
      if (coefficient == -1.0) return terms[0].negate();
    }
    return distribute(coefficient, terms);
  }

  /// Look for a factor that is a Sum object and distribute it into the other factors
  /// to enable a simplified form in which we can cancel terms more effectively.
  static Term distribute(double coefficient, List<Term> terms) {
    for (int i = 0; i < terms.length; i++) {
      Term term = terms[i];
      if (term is Sum) {
        List<Term> distributed = [];
        for (var addend in term.addends) {
          distributed.add(Product.mulList(coefficient, [
            ...terms.sublist(0, i),
            addend,
            ...terms.sublist(i + 1),
          ]));
        }
        return Sum.add(distributed);
      }
    }
    return Product(
      coefficient: coefficient,
      factors: terms,
    );
  }

  /// Check a numerator and a denominator that are summations of other terms for a
  /// common factor and eliminate it.
  ///
  /// The current implementation is very simple in that it first looks for common
  /// factors within the numerator and denominator and sees if the remainders of
  /// the two lists are identical.  Rather than divide out the common factor, the
  /// implementation cross-multiplies the numerator by the common factor in the
  /// denominator and vice versa and then tests those products for equality.
  ///
  /// If the "remainders" (or the "cross-multiplied factors") are identical, this
  /// division reduces to the division of the two common factors determined in the
  /// first step.
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

  /// Return the Term object representing the sum total of this entire multiply or divide
  /// operation, simplifying as much as possible.
  ///
  /// Current simplifications include the natural simplifications that occurred during
  /// factor accumulation and the additional simplifications that come from special
  /// coefficients that overwhelm the product (0, nan, infinities) and the simplifications
  /// determined by the divideSums() method.
  Term getResult() {
    Term special = Constant.isSpecialCoefficient(coefficient);
    if (special != null) return special;
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

/// A Term object representing the multiplication of a number of other Term objects.
class Product implements Term {
  final double coefficient;
  final List<Term> factors;

  Product({this.coefficient = 1.0, List<Term> factors}) : factors = unmodifiableTerms(factors);

  /// Multiply a list of Term objects with an additional coefficient and return the
  /// Term object representing the simplified result.
  static Term mulList(double coefficient, List<Term> terms) {
    FactorAccumulator accumulator = FactorAccumulator();
    accumulator.accumulateValue(coefficient, false);
    for (var term in terms) accumulator.accumulate(term, false);
    return accumulator.getResult();
  }

  /// Multiply 2 Term objects and return the Term object representing the simplified result.
  static Term mul(Term first, Term second) {
    FactorAccumulator accumulator = FactorAccumulator();
    accumulator.accumulate(first, false);
    accumulator.accumulate(second, false);
    return accumulator.getResult();
  }

  @override
  bool isNegative() {
    bool isNeg = coefficient < 0.0;
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
    if (coefficient > 0) {
      for (int i = 0; i < factors.length; i++) {
        Term term = factors[i];
        if (term.negatesGracefully()) {
          return Product(
            coefficient: coefficient,
            factors: [
              ...factors.sublist(0, i),
              term.negate(),
              ...factors.sublist(i+1),
            ],
          );
        }
      }
    }
    if (coefficient == -1.0 && factors.length == 1) {
      return factors[0];
    }
    return Product(coefficient: -coefficient, factors: factors);
  }

  @override Term addDirect(Term other, bool isNegated) {
    double delta;
    if (other is Product && equalFactors(this.factors, other.factors)) {
      delta = other.coefficient;
    } else if (other is Unknown && this.factors.length == 1 && this.factors[0].equals(other)) {
      delta = 1.0;
    } else {
      return null;
    }
    double newCoefficient = Constant.addOrSub(this.coefficient, delta, isNegated);
    Term special = Constant.isSpecialCoefficient(newCoefficient);
    if (special != null) return special;
    return Product(coefficient: newCoefficient, factors: this.factors);
  }

  @override bool equals(Term other) {
    if (other is Product) {
      return coefficient == other.coefficient && equalFactors(factors, other.factors);
    }
    return false;
  }

  /// Compare two lists of factors to determine if they are identical.
  static bool equalFactors(List<Term> factors1, List<Term> factors2) {
    if (factors1.length != factors2.length) return false;
    List<Term> factors2Copy = [...factors2];
    for (var term in factors1) {
      bool foundIt = false;
      for (int i = 0; i < factors2Copy.length; i++) {
        if (term.equals(factors2Copy[i])) {
          factors2Copy.removeAt(i);
          foundIt = true;
          break;
        }
      }
      if (!foundIt) return false;
    }
    return factors2Copy.length == 0;
  }

  /// A comparator function for ordering the factor objects for printing in a way that
  /// makes the results easier to correlate for human eyes.
  static int _sortOrder(Term a, Term b) {
    if (a is Constant) {
      // TODO: Should not happen now that we have broken out the coefficient?
      if (b is Constant) return a.value.compareTo(b.value);
      return -1;
    }
    if (b is Constant) {
      // TODO: Should not happen now that we have broken out the coefficient?
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

  List<Term> __sortedFactors;
  List<Term> get _sortedFactors => __sortedFactors ??= [...factors]..sort(_sortOrder);

  @override bool startsWithMinus() => coefficient < 0.0;
  @override String toString() {
    String ret;
    if (coefficient == -1.0) {
      ret = '-';
    } else if (coefficient == 1.0) {
      ret = '';
    } else if (coefficient == coefficient.toInt()) {
      ret = coefficient.toInt().toString();
    } else {
      ret = coefficient.toString();
    }
    bool prevWasUnknown = false;
    String mul = '';
    for (Term term in _sortedFactors) {
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

/// A Term object representing the division of 2 other Term objects.
///
/// TODO: This object could potentially be integrated into the Product object.
class Division implements Term {
  final Term numerator;
  final Term denominator;

  Division(this.numerator, this.denominator);

  /// Divide 2 Terms and return the simplified quotient.
  static Term div(Term num, Term den) {
    FactorAccumulator accumulator = FactorAccumulator();
    accumulator.accumulate(num, false);
    accumulator.accumulate(den, true);
    return accumulator.getResult();
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
  Term addDirect(Term other, isNegated) {
    if (other is Division && this.denominator.equals(other.denominator)) {
      Term newNumerator = this.numerator.addDirect(other.numerator, isNegated);
      if (newNumerator != null) {
        if (newNumerator == zero || newNumerator == nan ||
            newNumerator == pos_inf || newNumerator == neg_inf)
        {
          return newNumerator;
        }
        return Division(newNumerator, this.denominator);
      }
    }
    return null;
  }

  @override
  bool equals(Term term) {
    return term is Division &&
        term.numerator.equals(this.numerator) &&
        term.denominator.equals(this.denominator);
  }

  @override bool isNegative() => numerator.isNegative() != denominator.isNegative();
  @override bool startsWithMinus() => numerator.startsWithMinus();
  @override String toString() => '$numerator/$denominator';
}
