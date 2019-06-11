import 'term.dart';
import 'constants.dart';
import 'unknowns.dart';
import 'products.dart';

/// A helper object that assists in the accumulation of a number of Term objects that
/// are being added together and in simplifying the resulting summation.
class TermAccumulator {
  List<Term> terms = [];
  double constant = 0.0;

  /// Determine if two Division Terms can be combined by virtue of having a common
  /// denominator.
  ///
  /// TODO: look for denominators that share a common factor or differ only by a coefficient.
  Term combineDivisions(Division first, Division second, bool secondNegated) {
    if (first.denominator.equals(second.denominator)) {
      Term num = secondNegated
          ? Sum.sub(first.numerator, second.numerator)
          : Sum.add([first.numerator, second.numerator]);
      return (num == zero) ? num : Division.div(num, first.denominator);
    }
    return null;
  }

  /// Accumulate a Term object, consolidating all constant terms into a single constant
  /// and combining any objects which can be added directly to each other and also combine
  /// any compatible divisions.
  void accumulate(Term term, bool isNegated) {
    if (term is Constant) {
      if (isNegated) {
        constant -= term.value;
      } else {
        constant += term.value;
      }
    } else if (term is Sum) {
      for (var addend in term.addends) {
        accumulate(addend, isNegated);
      }
    } else {
      for (int i = 0; i < terms.length; i++) {
        Term sum = term.addDirect(terms[i], isNegated);
        if (sum != null) {
          if (sum is Constant) {
            constant += sum.value;
            terms.removeAt(i);
          } else {
            terms[i] = sum;
          }
          return;
        }
      }
      if (term is Division) {
        for (int i = 0; i < terms.length; i++) {
          if (terms[i] is Division) {
            Term combined = combineDivisions(terms[i], term, isNegated);
            if (combined != null) {
              terms[i] = combined;
              return;
            }
          }
        }
      }
      if (isNegated) term = term.negate();
      terms.add(term);
    }
  }

  /// Perform simplifications and return the best representation of the result.
  ///
  /// Simplifications include a constant term that overwhelms the sum such as
  /// infinities and nan, and the reduction of the list of terms into a single
  /// term.
  Term getResult() {
    if (constant.isNaN) return nan;
    if (constant.isInfinite) return (constant < 0) ? neg_inf : pos_inf;
    if (constant != 0.0) {
      terms.add(Constant.forDouble(constant));
    }
    if (terms.length == 0) {
      return zero;
    } else if (terms.length == 1) {
      return terms[0];
    }
    return Sum(terms);
  }
}

/// A Term object representing the sum of a number of other Term objects.
class Sum implements Term {
  final List<Term> addends;

  Sum(this.addends);

  /// A helper method to add a list of Term objects and return a simplified result.
  static Term add(List<Term> terms) {
    TermAccumulator accumulator = TermAccumulator();
    for (var term in terms) accumulator.accumulate(term, false);
    return accumulator.getResult();
  }

  /// A helper method to subtract two Term objects and return a simplified result.
  static Term sub(Term first, Term second) {
    TermAccumulator accumulator = TermAccumulator();
    accumulator.accumulate(first, false);
    accumulator.accumulate(second, true);
    return accumulator.getResult();
  }

  /// A helper method to find the greatest common factor of unknowns that is common to
  /// all elements of the summation.
  ///
  /// This method helps to reduce long fractions to simpler divisions by comparing the
  /// remainders of numerators and denominators in Division objects to each other.
  Term commonFactor() {
    List<Term> common;
    for (var term in addends) {
      if (term is Unknown) {
        if (common != null && !common.contains(term)) return one;
        common = [term];
      } else if (term is Product) {
        List<Term> oldCommon = common;
        common = [];
        for (var factor in term.factors) {
          if (factor is Unknown) {
            if (oldCommon == null) {
              common.add(factor);
            } else {
              for (var cTerm in oldCommon) {
                if (cTerm.equals(factor)) {
                  common.add(factor);
                  oldCommon.remove(cTerm);
                  break;
                }
              }
            }
          }
        }
        if (common.length == 0) break;
      } else {
        return one;
      }
    }
    if (common == null || common.length == 0) return one;
    if (common.length == 1) return common[0];
    return Product(factors: common);
  }

  @override
  bool negatesGracefully() {
    bool hadNegative = false;
    bool wasUngraceful = false;
    for (var term in addends) {
      wasUngraceful == wasUngraceful || !term.negatesGracefully();
      hadNegative == hadNegative && term.isNegative();
    }
    return hadNegative || !wasUngraceful;
  }

  @override
  Term negate() {
    return Sum.add([
      for (var term in addends)
        term.negate(),
    ]);
  }

  @override bool isNegative() => false;
  @override bool equals(Term other) {
    if (other is Sum) {
      List<Term> oAddends = other.addends;
      if (oAddends.length != addends.length) return false;
      List<bool> used = List.filled(addends.length, false);
      for (var term in oAddends) {
        bool foundIt = false;
        for (int i = 0; i < addends.length; i++) {
          if (!used[i] && term.equals(addends[i])) {
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

  @override Term addDirect(Term other, bool isNegated) => null;

  /// Compare the single Unknown object to the factors of the Product Term object to
  /// determine which should appear first in the String output.
  ///
  /// The list is sorted by the names of the Unknown terms so that similar terms will appear
  /// in similar locations in any lists.
  ///
  /// The intention is to make the many summations more readable for human eyes.
  static int _compareProductUnknown(Unknown a, Product b) {
    for (var factor in b.factors) {
      if (factor is Unknown) return a.name.compareTo(factor.name);
      if (factor is! Constant) return -1;
    }
    return -1;
  }

  /// Compare the factors of the Product Term objects to determine which should appear first in
  /// the String output.
  ///
  /// The list is sorted by the names of the Unknown terms so that similar terms will appear
  /// in similar locations in any lists.
  ///
  /// The intention is to make the many summations more readable for human eyes.
  static int _compareProducts(Product a, Product b) {
    int ai = 0, bi = 0;
    while (ai < a.factors.length && bi < b.factors.length) {
      if (a.factors[ai] is! Unknown) ai++;
      else if (b.factors[bi] is! Unknown) bi++;
      else {
        Unknown au = a.factors[ai++];
        Unknown bu = b.factors[bi++];
        int comp = au.name.compareTo(bu.name);
        if (comp != 0) return comp;
      }
    }
    return 0;
  }

  /// A Comparator method to create a (hopefully) pleasing ordering of the summation
  /// terms when the object is converted to a string.
  static int _sortOrder(Term a, Term b) {
    if (a is Constant) {
      if (b is Constant) return a.value.compareTo(b.value);
      return 1;
    }
    if (b is Constant) {
      return -1;
    }
    if (a is Unknown) {
      if (b is Unknown) return a.name.compareTo(b.name);
      if (b is Product) return _compareProductUnknown(a, b);
      return -1;
    }
    if (b is Unknown) {
      if (a is Product) return -_compareProductUnknown(b, a);
      return 1;
    }
    if (a is Product) {
      if (b is Product) return _compareProducts(a, b);
      return -1;
    }
    if (b is Product) {
      return 1;
    }
    return 0;
  }

  List<Term> __sortedAddends;
  List<Term> get _sortedAddends => __sortedAddends ??= [...addends]..sort(_sortOrder);

  @override bool startsWithMinus() => false;
  @override
  String toString() {
    String ret = '(';
    String add = '';
    for (Term term in _sortedAddends) {
      if (!term.startsWithMinus()) ret += add;
      ret += '$term';
      add = '+';
    }
    return ret+')';
  }
}