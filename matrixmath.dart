
abstract class Term {
  bool isNegative();
  bool negatesGracefully();
  Term negate();
  bool equals(Term other);
}

class Unknown implements Term {
  final String name;
  const Unknown(this.name);

  @override bool isNegative() => false;
  @override bool negatesGracefully() => false;
  @override Term negate() => Negation(this);
  @override bool equals(Term term) => term == this;
  @override String toString() => name;
}

const a = Unknown('a');
const b = Unknown('b');
const c = Unknown('c');
const d = Unknown('d');
const e = Unknown('e');
const f = Unknown('f');
const g = Unknown('g');
const h = Unknown('h');
const i = Unknown('i');
const j = Unknown('j');
const k = Unknown('k');
const l = Unknown('l');
const m = Unknown('m');
const n = Unknown('n');
const o = Unknown('o');
const p = Unknown('p');

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
    return Product(terms);
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
    Term secondNum = second.numerator;
    if (secondNegated) secondNum = secondNum.negate();
    return Division(Sum.add([first.numerator, secondNum]), first.denominator);
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
    return Sum(terms);
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
    if (negatesGracefully()) {
      List<Term> newList = [];
      for (var term in addends) {
        term = term.negate();
        if (term.isNegative()) {
          newList.add(term);
        } else {
          newList.insert(0, term);
        }
      }
      return Sum(newList);
    }
    return Negation.negation(this);
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

class Vector4 {
  final Term xVal, yVal, zVal, wVal;

  Vector4([this.xVal = zero, this.yVal = zero, this.zVal = zero, this.wVal = one]);

  Vector4 add(Vector4 other) {
    return Vector4(
      Sum.add([this.xVal, other.xVal]),
      Sum.add([this.yVal, other.yVal]),
      Sum.add([this.zVal, other.zVal]),
      Sum.add([this.wVal, other.wVal]),
    );
  }

  Vector4 sub(Vector4 other) {
    return Vector4(
      Sum.sub(this.xVal, other.xVal),
      Sum.sub(this.yVal, other.yVal),
      Sum.sub(this.zVal, other.zVal),
      Sum.sub(this.wVal, other.wVal),
    );
  }

  Vector4 normalize() => Vector4(
      Division.div(xVal, wVal),
      Division.div(yVal, wVal),
      Division.div(zVal, wVal),
    );

  @override
  String toString() => 'Vector4($xVal, $yVal, $zVal, $wVal)';
}

class Matrix4x4 {
  final List<List<Term>> elements;

  Matrix4x4(this.elements) {
    assert(elements.length == 4 &&
           elements[0].length == 4 &&
           elements[1].length == 4 &&
           elements[2].length == 4 &&
           elements[3].length == 4);
  }

  Vector4 transform(Vector4 vec) {
    vec = vec.normalize();
    Term xN = vec.xVal;
    Term yN = vec.yVal;
    Term zN = vec.zVal;
    return Vector4(
      Sum.add([
        Product.mul(xN, elements[0][0]),
        Product.mul(yN, elements[0][1]),
        Product.mul(zN, elements[0][2]),
                        elements[0][3],
      ]),
      Sum.add([
        Product.mul(xN, elements[1][0]),
        Product.mul(yN, elements[1][1]),
        Product.mul(zN, elements[1][2]),
                        elements[1][3],
      ]),
      Sum.add([
        Product.mul(xN, elements[2][0]),
        Product.mul(yN, elements[2][1]),
        Product.mul(zN, elements[2][2]),
                        elements[2][3],
      ]),
      Sum.add([
        Product.mul(xN, elements[3][0]),
        Product.mul(yN, elements[3][1]),
        Product.mul(zN, elements[3][2]),
                        elements[3][3],
      ]),
    );
  }

  Matrix4x4 mul(Term factor) {
    factor = factor;
    if (factor == one) return this;
    return Matrix4x4(
      [
        for (var row in elements) [
          for (var term in row)
            Product.mul(term, factor),
        ],
      ]
    );
  }

  Matrix4x4 div(Term factor) {
    factor = factor;
    if (factor == one) return this;
    return Matrix4x4(
      [
        for (var row in elements) [
          for (var term in row)
            Division.div(term, factor),
        ],
      ],
    );
  }

  Term determinant2x2(int row1, int row2, int col1, int col2) {
    return Sum.sub(Product.mul(elements[row1][col1], elements[row2][col2]),
                   Product.mul(elements[row1][col2], elements[row2][col1]));
  }

  List<int> _allBut(int rc) => [...[0,1,2,3].where((i) => i != rc)];

  Term minor(int row, int col) {
    var r = _allBut(row);
    var c = _allBut(col);
    return Sum.add([
      Product.mul(elements[r[0]][c[0]],
                  determinant2x2(r[1], r[2], c[1], c[2])),
      Product.mul(elements[r[0]][c[1]],
                  determinant2x2(r[1], r[2], c[2], c[0])),
      Product.mul(elements[r[0]][c[2]],
                  determinant2x2(r[1], r[2], c[0], c[1])),
    ]);
  }

  Term determinant() {
    List<Term> terms = [];
    for (int col = 0; col < 4; col++) {
      Term m = minor(0, col);
      if ((col & 1) == 1) m.negate();
      terms.add(Product.mul(elements[0][col], m));
    }
    return Sum.add(terms);
  }

  Matrix4x4 minors() {
    return Matrix4x4(
      [
        for (int row = 0; row < 4; row++) [
          for (int col = 0; col < 4; col++)
            minor(row, col),
        ]
      ]
    );
  }

  Matrix4x4 cofactors() {
    return Matrix4x4(
      [
        for (int row = 0; row < 4; row++) [
          for (int col = 0; col < 4; col++)
            ((row^col&1) == 0)
                ? elements[row][col]
                : elements[row][col].negate(),
        ]
      ]
    );
  }

  Matrix4x4 transpose() {
    return Matrix4x4(
      [
        for (int col = 0; col < 4; col++) [
          for (int row = 0; row < 4; row++)
            elements[row][col],
        ]
      ]
    );
  }
  void printOut() {
    var m = elements;
    print('[ ${m[0][0]}  ${m[0][1]}  ${m[0][2]}  ${m[0][3]} ]');
    print('[ ${m[1][0]}  ${m[1][1]}  ${m[1][2]}  ${m[1][3]} ]');
    print('[ ${m[2][0]}  ${m[2][1]}  ${m[2][2]}  ${m[2][3]} ]');
    print('[ ${m[3][0]}  ${m[3][1]}  ${m[3][2]}  ${m[3][3]} ]');
  }
}

const X = Unknown('X');
const Y = Unknown('Y');

void printOps(Constant v1, Constant v2) {
  double v1val = v1.value;
  double v2val = v2.value;
  print('$v1val + $v2val = ${v1val + v2val}');
  print('$v1val - $v2val = ${v1val - v2val}');
  print('$v1val * $v2val = ${v1val * v2val}');
  print('$v1val / $v2val = ${v1val / v2val}');
  print('$v1val == $v2val = ${v1val == v2val}');
  print('$v1val != $v2val = ${v1val != v2val}');
  print('$v1val >= $v2val = ${v1val >= v2val}');
  print('$v1val <= $v2val = ${v1val <= v2val}');
  print('$v1val > $v2val = ${v1val > v2val}');
  print('$v1val < $v2val = ${v1val < v2val}');
}

void testMath() {
  printOps(one, zero);
  printOps(neg_one, zero);
  printOps(pos_inf, zero);
  printOps(neg_inf, zero);
  printOps(pos_inf, neg_inf);
  printOps(neg_inf, pos_inf);
  printOps(pos_inf, pos_inf);
  printOps(nan, nan);
  printOps(nan, one);
  printOps(one, nan);
  printOps(nan, pos_inf);
  printOps(neg_inf, nan);
}

void main() {
//  testMath();
  Matrix4x4 m4 = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ m, n, o, p, ],
  ]);
  Matrix4x4 m4m = m4.minors();
  Matrix4x4 m4c = m4m.cofactors();
  Matrix4x4 m4a = m4c.transpose();
  m4.printOut();
  print(m4.determinant());
  m4a.printOut();
//  print(m4a.determinant());
  Vector4 Pm = Vector4(X, Y);
  if (Pm.zVal != zero) print("z not zero!");
  if (Product.mul(Pm.zVal, m4.elements[0][2]) != zero) print("product not zero!");
  Vector4 Ps = m4.transform(Pm);
  Term Xsn = Division.div(Ps.xVal, Ps.wVal);
  Term Ysn = Division.div(Ps.yVal, Ps.wVal);
  Vector4 Psm0 = m4a.transform(Vector4(Xsn, Ysn, zero));
  Vector4 Psm1 = m4a.transform(Vector4(Xsn, Ysn, one));
  print('');
  print('Pm     = $Pm');
  print('Pmnorm = ${Pm.normalize()}');
  print('Ps     = $Ps');
  print('Psnorm = ${Ps.normalize()}');
  print('');
  print('Prev(Z=0)   = $Psm0');
  print('');
  print('Prev(Z=1)   = $Psm1');
  print('');
  print('Prev(Z1-Z0) = ${Psm1.sub(Psm0)}');
}