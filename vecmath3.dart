import 'term.dart';
import 'constants.dart';
import 'products.dart';
import 'sums.dart';

class Vector3 {
  final Term xVal, yVal, wVal;

  Vector3([this.xVal = zero, this.yVal = zero, this.wVal = one]);

  Vector3 add(Vector3 other) {
    return Vector3(
      Sum.add([this.xVal, other.xVal]),
      Sum.add([this.yVal, other.yVal]),
      Sum.add([this.wVal, other.wVal]),
    );
  }

  Vector3 sub(Vector3 other) {
    return Vector3(
      Sum.sub(this.xVal, other.xVal),
      Sum.sub(this.yVal, other.yVal),
      Sum.sub(this.wVal, other.wVal),
    );
  }

  Vector3 multiplyFactor(Term factor) {
    return Vector3(
      Product.mul(xVal, factor),
      Product.mul(yVal, factor),
      Product.mul(wVal, factor),
    );
  }

  Vector3 divideFactor(Term factor) {
    return Vector3(
      Division.div(xVal, factor),
      Division.div(yVal, factor),
      Division.div(wVal, factor),
    );
  }

  Vector3 normalize() => Vector3(
    Division.div(xVal, wVal),
    Division.div(yVal, wVal),
  );

  @override
  String toString() => 'Vector4($xVal, $yVal, $wVal)';
}

class Matrix3x3 {
  final List<List<Term>> elements;

  Matrix3x3(this.elements) {
    assert(elements.length == 3 &&
        elements[0].length == 3 &&
        elements[1].length == 3 &&
        elements[2].length == 3);
  }

  Vector3 transform(Vector3 vec) {
    Term xN = vec.xVal;
    Term yN = vec.yVal;
    Term wN = vec.wVal;
    return Vector3(
      Sum.add([
        Product.mul(xN, elements[0][0]),
        Product.mul(yN, elements[0][1]),
        Product.mul(wN, elements[0][2]),
      ]),
      Sum.add([
        Product.mul(xN, elements[1][0]),
        Product.mul(yN, elements[1][1]),
        Product.mul(wN, elements[1][2]),
      ]),
      Sum.add([
        Product.mul(xN, elements[2][0]),
        Product.mul(yN, elements[2][1]),
        Product.mul(wN, elements[2][2]),
      ]),
    );
  }

  Matrix3x3 multiplyFactor(Term factor) {
    factor = factor;
    if (factor == one) return this;
    return Matrix3x3(
      [
        for (var row in elements) [
          for (var term in row)
            Product.mul(term, factor),
        ],
      ],
    );
  }

  Matrix3x3 divideFactor(Term factor) {
    factor = factor;
    if (factor == one) return this;
    return Matrix3x3(
      [
        for (var row in elements) [
          for (var term in row)
            Division.div(term, factor),
        ],
      ],
    );
  }

  Matrix3x3 multiplyMatrix(Matrix3x3 other) {
    return Matrix3x3(
      [
        for (int row = 0; row < 3; row++) [
          for (int col = 0; col < 3; col++)
            crossMultiply(this, row, other, col),
        ],
      ],
    );
  }

  static Term crossMultiply(Matrix3x3 rowMatrix, int row, Matrix3x3 colMatrix, int col) {
    return Sum.add([
      Product.mul(rowMatrix.elements[row][0], colMatrix.elements[0][col]),
      Product.mul(rowMatrix.elements[row][1], colMatrix.elements[1][col]),
      Product.mul(rowMatrix.elements[row][2], colMatrix.elements[2][col]),
    ]);
  }

  Term determinant2x2(int row1, int row2, int col1, int col2) {
    return Sum.sub(Product.mul(elements[row1][col1], elements[row2][col2]),
                   Product.mul(elements[row1][col2], elements[row2][col1]));
  }

  List<int> _allBut(int rc) => [...[0,1,2].where((i) => i != rc)];

  Term minor(int row, int col) {
    var r = _allBut(row);
    var c = _allBut(col);
    return determinant2x2(r[0], r[1], c[0], c[1]);
  }

  Term determinant() {
    List<Term> terms = [];
    for (int col = 0; col < 3; col++) {
      Term m = minor(0, col);
      if ((col & 1) == 1) m = m.negate();
      terms.add(Product.mul(elements[0][col], m));
    }
    return Sum.add(terms);
  }

  Matrix3x3 minors() {
    return Matrix3x3(
      [
        for (int row = 0; row < 3; row++) [
          for (int col = 0; col < 3; col++)
            minor(row, col),
        ],
      ],
    );
  }

  Matrix3x3 cofactors() {
    return Matrix3x3(
      [
        for (int row = 0; row < 3; row++) [
          for (int col = 0; col < 3; col++)
            (((row^col)&1) == 0)
                ? elements[row][col]
                : elements[row][col].negate(),
        ],
      ],
    );
  }

  Matrix3x3 transpose() {
    return Matrix3x3(
      [
        for (int row = 0; row < 3; row++) [
          for (int col = 0; col < 3; col++)
            elements[col][row],
        ],
      ],
    );
  }

  void printOut(String label) {
    var m = elements;
    print('$label =');
    print('  [ ${m[0][0]}  ${m[0][1]}  ${m[0][2]} ]');
    print('  [ ${m[1][0]}  ${m[1][1]}  ${m[1][2]} ]');
    print('  [ ${m[2][0]}  ${m[2][1]}  ${m[2][2]} ]');
  }
}
