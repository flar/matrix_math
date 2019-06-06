import 'term.dart';
import 'constants.dart';
import 'unknowns.dart';
import 'negation.dart';
import 'products.dart';

class TermAccumulator {
  List<Term> terms = [];
  double constant = 0.0;

  Term combineDivisions(Division first, Division second, bool secondNegated) {
    if (!first.denominator.equals(second.denominator)) {
      if (!Negation.equalsNegated(first.denominator, second.denominator)) {
        return null;
      }
      secondNegated = !secondNegated;
    }
    Term num = secondNegated
        ? Sum.sub(first.numerator, second.numerator)
        : Sum.add([first.numerator, second.numerator]);
    return (num == zero) ? num : Division.div(num, first.denominator);
  }

  void accumulate(Term term, bool isNegated) {
    if (term is Constant) {
      if (isNegated) {
        constant -= term.value;
      } else {
        constant += term.value;
      }
    } else if (term is Negation) {
      accumulate(term.negated, !isNegated);
    } else if (term is Sum) {
      for (var addend in term.addends) {
        accumulate(addend, isNegated);
      }
    } else {
      for (int i = 0; i < terms.length; i++) {
        if (isNegated) {
          if (!term.equals(terms[i])) continue;
        } else {
          if (!Negation.equalsNegated(terms[i], term)) continue;
        }
//        print('canceling $term against ${terms[i]}  (isNegated = $isNegated)');
        terms.removeAt(i);
        return;
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
    terms.sort(sortOrder);
    return Sum(terms);
  }

  static int compareProductUnknown(Unknown a, Product b) {
    for (var factor in b.factors) {
      if (factor is Unknown) return a.name.compareTo(factor.name);
      if (factor is! Constant) return -1;
    }
    return -1;
  }

  static int compareProducts(Product a, Product b) {
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

  static int sortOrder(Term a, Term b) {
    if (a is Negation) return sortOrder(a.negated, b);
    if (b is Negation) return sortOrder(a, b.negated);
    if (a is Constant) {
      if (b is Constant) return a.value.compareTo(b.value);
      return 1;
    }
    if (b is Constant) {
      return -1;
    }
    if (a is Unknown) {
      if (b is Unknown) return a.name.compareTo(b.name);
      if (b is Product) return compareProductUnknown(a, b);
      return -1;
    }
    if (b is Unknown) {
      if (a is Product) return -compareProductUnknown(b, a);
      return 1;
    }
    if (a is Product) {
      if (b is Product) return compareProducts(a, b);
      return -1;
    }
    if (b is Product) {
      return 1;
    }
    return 0;
  }
}

class Sum implements Term {
  final List<Term> addends;

  Sum(this.addends);

  static Term add(List<Term> terms) {
    TermAccumulator accumulator = TermAccumulator();
    for (var term in terms) accumulator.accumulate(term, false);
    return accumulator.getResult();
  }

  static Term sub(Term first, Term second) {
    TermAccumulator accumulator = TermAccumulator();
    accumulator.accumulate(first, false);
    accumulator.accumulate(second, true);
    return accumulator.getResult();
  }

  Term commonFactor() {
    List<Term> common;
    for (var term in addends) {
      if (term is Negation) {
        Negation nTerm = term;
        term = nTerm.negated;
      }
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
    return Product(common);
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

  @override
  String toString() {
    String ret = '(';
    String add = '';
    for (Term term in addends) {
      if (term is Negation) {
        Negation x = term;
        term = x.negated;
        ret += '-';
      } else {
        ret += add;
      }
      ret += '$term';
      add = '+';
    }
    return ret+')';
  }
}