import 'term.dart';
import 'constants.dart';
import 'products.dart';
import 'sums.dart';

/// A 3-value homogeneous coordinate representing X, Y, and a homogeneous factor W.
class Vector3 {
  final Term xVal, yVal, wVal;

  Vector3([this.xVal = zero, this.yVal = zero, this.wVal = one]);

  /// Add this Vector3 to the other and return a new result object.
  Vector3 add(Vector3 other) {
    return Vector3(
      Sum.add([this.xVal, other.xVal]),
      Sum.add([this.yVal, other.yVal]),
      Sum.add([this.wVal, other.wVal]),
    );
  }

  /// Subtract the other Vector3 from this Vector3 and return a new result object.
  Vector3 sub(Vector3 other) {
    return Vector3(
      Sum.sub(this.xVal, other.xVal),
      Sum.sub(this.yVal, other.yVal),
      Sum.sub(this.wVal, other.wVal),
    );
  }

  /// Multiply the coordinates of this Vector3 by a common Term and return a new result object.
  Vector3 multiplyFactor(Term factor) {
    return Vector3(
      Product.mul(xVal, factor),
      Product.mul(yVal, factor),
      Product.mul(wVal, factor),
    );
  }

  /// Divide the coordinates of this Vector3 by a common Term and return a new result object.
  Vector3 divideFactor(Term factor) {
    return Vector3(
      Division.div(xVal, factor),
      Division.div(yVal, factor),
      Division.div(wVal, factor),
    );
  }

  /// Return a new vector with the normalized homogeneous version of this Vector3.
  Vector3 normalize() => Vector3(
    Division.div(xVal, wVal),
    Division.div(yVal, wVal),
  );

  @override
  String toString() => 'Vector3($xVal, $yVal, $wVal)';
}

/// A 3x3 coordinate matrix
class Matrix3x3 {
  final List<List<Term>> elements;

  Matrix3x3(List<List<Term>> elements)
      : elements = unmodifiableMatrix(elements)
  {
    assert(elements.length == 3 &&
        elements[0].length == 3 &&
        elements[1].length == 3 &&
        elements[2].length == 3);
  }

  /// Transform a Vector3 by this matrix by post-multiplying it as a column vector and
  /// return a new result object:
  ///
  /// [ mat[0][0] mat[0][1] mat[0][2] ]   [ vec.xVal ]
  /// [ mat[1][0] mat[1][1] mat[1][2] ] x [ vec.yVal ]
  /// [ mat[2][0] mat[2][1] mat[2][2] ]   [ vec.wVal ]
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

  /// Multiply all elements of this matrix by a common Term factor and return a new result object.
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

  /// Divide all elements of this matrix by a common Term factor and return a new result object.
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

  /// Multiply this matrix by another matrix and return a new result object:
  ///
  /// [ mat[0][0] mat[0][1] mat[0][2] ]   [ other[0][0] other[0][1] other[0][2] ]
  /// [ mat[1][0] mat[1][1] mat[1][2] ] x [ other[1][0] other[1][1] other[1][2] ]
  /// [ mat[2][0] mat[2][1] mat[2][2] ]   [ other[2][0] other[2][1] other[2][2] ]
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

  /// Cross-multiply a row from the first matrix with a column from the second
  /// and return a Term object for the result.
  ///
  /// (rowMatrix[row][0] * colMatrix[0][col] +
  ///  rowMatrix[row][1] * colMatrix[1][col] +
  ///  rowMatrix[row][2] * colMatrix[2][col])
  static Term crossMultiply(Matrix3x3 rowMatrix, int row, Matrix3x3 colMatrix, int col) {
    return Sum.add([
      Product.mul(rowMatrix.elements[row][0], colMatrix.elements[0][col]),
      Product.mul(rowMatrix.elements[row][1], colMatrix.elements[1][col]),
      Product.mul(rowMatrix.elements[row][2], colMatrix.elements[2][col]),
    ]);
  }

  /// Return a 2x2 determinant consisting of the four elements of this matrix taken as:
  ///
  /// [ mat[row1][col1]  mat[row1][col2] ]
  /// [ mat[row2][col1]  mat[row2][col2] ]
  Term determinant2x2(int row1, int row2, int col1, int col2) {
    return Sum.sub(Product.mul(elements[row1][col1], elements[row2][col2]),
                   Product.mul(elements[row1][col2], elements[row2][col1]));
  }

  List<int> _allBut(int rc) => [...[0,1,2].where((i) => i != rc)];

  /// Return the minor for the indicated row and column.
  Term minor(int row, int col) {
    var r = _allBut(row);
    var c = _allBut(col);
    return determinant2x2(r[0], r[1], c[0], c[1]);
  }

  /// Return the determinant of this matrix.
  Term determinant() {
    List<Term> terms = [];
    for (int col = 0; col < 3; col++) {
      Term m = minor(0, col);
      if ((col & 1) == 1) m = m.negate();
      terms.add(Product.mul(elements[0][col], m));
    }
    return Sum.add(terms);
  }

  /// Return a new matrix consisting of the minors for every element in this matrix.
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

  /// Return a new matrix consisting of the cofactors for every element in this matrix.
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

  /// Return a new matrix consisting of the elements of this matrix transposed.
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

  /// Print out the matrix in a format that might be pretty if the terms are short and
  /// similar in length.
  void printOut(String label) {
    var m = elements;
    print('$label =');
    print('  [ ${m[0][0]}  ${m[0][1]}  ${m[0][2]} ]');
    print('  [ ${m[1][0]}  ${m[1][1]}  ${m[1][2]} ]');
    print('  [ ${m[2][0]}  ${m[2][1]}  ${m[2][2]} ]');
  }
}
