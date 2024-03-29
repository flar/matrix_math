import 'dart:io';
import 'term.dart';
import 'sums.dart';
import 'constants.dart';

abstract class VectorN {
  final List<Term> coordinates;
  int get dimension => coordinates.length;

  VectorN(int dim, List<Term> coordinates)
      : coordinates = List.unmodifiable(coordinates),
        assert(coordinates.length == dim);

  VectorN makeVector(List<Term> coordinates);

  /// Add this Vector to the other and return a new result object.
  VectorN operator +(covariant VectorN other) {
    assert(other.dimension == this.dimension);
    return makeVector([
      for (int i = 0; i < dimension; i++)
        (this.coordinates[i] + other.coordinates[i]),
    ]);
  }

  /// Subtract the other Vector from this Vector3 and return a new result object.
  VectorN operator -(covariant VectorN other) {
    assert(other.dimension == this.dimension);
    return makeVector([
      for (int i = 0; i < dimension; i++)
        (this.coordinates[i] - other.coordinates[i]),
    ]);
  }

  /// Multiply the coordinates of this Vector by a common Term and return a new result object.
  VectorN operator *(Term factor) {
    return makeVector([
      for (var coordinate in coordinates)
        (coordinate * factor),
    ]);
  }

  /// Divide the coordinates of this Vector by a common Term and return a new result object.
  VectorN operator /(Term factor) {
    return makeVector([
      for (var coordinate in coordinates)
        (coordinate / factor),
    ]);
  }

  /// Return a new vector with the normalized homogeneous version of this Vector3.
  VectorN normalize() {
    Term wVal = coordinates[dimension-1];
    return makeVector([
      for (int i = 0; i < dimension-1; i++)
        (coordinates[i] / wVal),
      one,
    ]);
  }

  String toString() {
    String ret = 'Vector$dimension(';
    String sep = '';
    for (var coordinate in coordinates) {
      ret += sep + coordinate.toString();
      sep = ', ';
    }
    return ret+')';
  }

  void printOut(String label) {
    String str = toString();
    if (label.length + str.length < 100) {
      print('$label$str');
      return;
    }
    String prefix = '${label}Vector$dimension(';
    bool first = true;
    for (var coordinate in coordinates) {
      if (first) { first = false; } else { print(','); }
      stdout.write('$prefix$coordinate');
      prefix = ' ' * prefix.length;
    }
    print(')');
  }
}

abstract class MatrixNxN {
  final List<List<Term>> elements;
  final List<int> indices;
  int get dimension => elements.length;

  MatrixNxN(int dim, List<List<Term>> elements)
      : elements = _unmodifiableSquareMatrix(dim, elements),
        indices = List<int>.unmodifiable(List<int>.generate(elements.length, (i) => i));

  static List<List<Term>> _unmodifiableSquareMatrix(int dim, List<List<Term>> elements) {
    assert(elements.length == dim);
    for (var row in elements) {
      assert(row.length == dim);
    }
    return List.unmodifiable([
      for (List<Term> row in elements)
        List<Term>.unmodifiable(row),
    ]);
  }

  /// Factory method for subclasses to ensure return type from methods below
  MatrixNxN makeMatrix(List<List<Term>> elements);

  static List<int> _listBut(List<int> indices, int but) => [...indices.where((i) => i != but)];
  List<int> allIndicesBut(int but) => _listBut(indices, but);

  /// Transform a VectorN by this matrix by post-multiplying it as a column vector and
  /// return a new result object:
  ///
  /// [ mat[1][1] mat[1][2] mat[1][3] ... ]   [ vec.xVal ]
  /// [ mat[2][1] mat[2][2] mat[2][3] ... ] x [ vec.yVal ]
  /// [                ...                ]   [   ...    ]
  /// [ mat[N][1] mat[N][2] mat[N][3] ... ]   [ vec.wVal ]
  VectorN transform(covariant VectorN vec) {
    assert(this.dimension == vec.dimension);
    return vec.makeVector(multiplyVector(vec.coordinates));
  }

  /// Multiply all elements of this matrix by a common Term factor and return a new result object.
  MatrixNxN operator *(dynamic factor) {
    if (factor is Term) {
      return makeMatrix(
        [
          for (var row in elements) [
            for (var term in row)
              (term * factor),
          ],
        ],
      );
    } else if (factor is MatrixNxN) {
      assert(dimension == factor.dimension);
      return makeMatrix(
        [
          for (int row = 0; row < dimension; row++) [
            for (int col = 0; col < dimension; col++)
              _crossMultiply(this, row, factor, col),
          ],
        ],
      );
    } else {
      throw 'Matrix multiplication only supported for Term and Matrix arguments';
    }
  }

  /// Divide all elements of this matrix by a common Term factor and return a new result object.
  MatrixNxN operator /(Term factor) {
    return makeMatrix(
      [
        for (var row in elements) [
          for (var term in row)
            (term / factor),
        ],
      ],
    );
  }

  /// Multiply this matrix by a vector of the indicated coordinates and return the
  /// list of transformed coordinates.
  List<Term> multiplyVector(List<Term> coordinates) {
    assert(coordinates.length == dimension);
    return [
      for (int row in indices)
        Sum.addList(
          [
            for (int col in indices)
              (elements[row][col] * coordinates[col]),
          ],
        ),
    ];
  }

  /// Cross-multiply a row from the first matrix with a column from the second
  /// and return a Term object for the result.
  ///
  /// sum(rowMatrix[row][i] * colMatrix[i][col]) where (0 <= i < dimension)
  static Term _crossMultiply(MatrixNxN rowMatrix, int row, MatrixNxN colMatrix, int col) {
    return Sum.addList([
      for (int i = 0; i < rowMatrix.dimension; i++)
        (rowMatrix.elements[row][i] * colMatrix.elements[i][col]),
    ]);
  }

  /// Return a 2x2 determinant consisting of the four elements of this matrix taken as:
  ///
  /// [ mat[row1][col1]  mat[row1][col2] ]
  /// [ mat[row2][col1]  mat[row2][col2] ]
  Term _subDeterminant2x2(int row1, int row2, int col1, int col2) {
    return ((elements[row1][col1] * elements[row2][col2]) -
            (elements[row1][col2] * elements[row2][col1]));
  }

  Term _subDeterminant(List<int> rows, List<int> cols) {
    assert(rows.length == cols.length);
    if (rows.length == 1) return elements[rows[0]][cols[0]];
    if (rows.length == 2) return _subDeterminant2x2(rows[0], rows[1], cols[0], cols[1]);
    int row = rows[0];
    List<int> oRows = rows.sublist(1);
    return Sum.addList([
      for (int i = 0; i < cols.length; i++)
        (elements[row][cols[i]] * _subDeterminant(oRows, _listBut(cols, cols[i])))
            .negateIf(((i & 1) == 1)),
    ]);
  }

  /// Return the determinant of this matrix.
  Term determinant() {
    return _subDeterminant(indices, indices);
  }

  /// Return the minor for the indicated row and column.
  Term minor(int row, int col) {
    return _subDeterminant(allIndicesBut(row), allIndicesBut(col));
  }

  /// Return a new matrix consisting of the minors for every element in this matrix.
  MatrixNxN minors() {
    return makeMatrix(
      [
        for (int row in indices) [
          for (int col in indices)
            minor(row, col),
        ],
      ],
    );
  }

  /// Return a new matrix consisting of the cofactors for every element in this matrix.
  MatrixNxN cofactors() {
    return makeMatrix(
      [
        for (int row in indices) [
          for (int col in indices)
            elements[row][col].negateIf(((row ^ col) & 1) != 0),
        ],
      ],
    );
  }

  /// Return a new matrix consisting of the elements of this matrix transposed.
  MatrixNxN transpose() {
    return makeMatrix(
      [
        for (int row in indices) [
          for (int col in indices)
            elements[col][row],
        ],
      ],
    );
  }

  /// Return a new 2D list of elements consisting of every row and column in this matrix except
  /// for the specified skipRow and skipCol.
  List<List<Term>> elementsWithout({int skipRow, int skipCol}) {
    List<int> rows = allIndicesBut(skipRow);
    List<int> cols = allIndicesBut(skipCol);
    return [
      for (int rowIndex in rows) [
        for (int colIndex in cols)
          elements[rowIndex][colIndex],
      ],
    ];
  }

  void printOut(String label) {
    print('$label =');
    for (var row in elements) {
      stdout.write('  [');
      for (var col in row) stdout.write(' $col ');
      print(']');
    }
  }
}
