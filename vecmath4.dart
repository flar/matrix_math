import 'term.dart';
import 'constants.dart';
import 'vecmath3.dart';
import 'vecmath.dart';

/// A 4-value homogeneous coordinate representing X, Y, Z, and a homogeneous factor W.
class Vector4 extends VectorN {
  Term get xVal => coordinates[0];
  Term get yVal => coordinates[1];
  Term get zVal => coordinates[2];
  Term get wVal => coordinates[3];

  Vector4([Term xVal = zero, Term yVal = zero, Term zVal = zero, Term wVal = one])
      : super(4, [xVal, yVal, zVal, wVal]);

  Vector4.fromList(List<Term> coordinates)
      : super(4, coordinates);

  Vector4 makeVector(List<Term> coordinates) => Vector4.fromList(coordinates);

  Vector4 normalize() => super.normalize();
}

/// A 4x4 coordinate matrix
class Matrix4x4 extends MatrixNxN {
  Matrix4x4(List<List<Term>> elements) : super(4, elements);

  Matrix4x4 makeMatrix(List<List<Term>> elements) => Matrix4x4(elements);

  @override Vector4 transform(Vector4 vec) => super.transform(vec);
  @override Matrix4x4 minors() => super.minors();
  @override Matrix4x4 cofactors() => super.cofactors();
  @override Matrix4x4 transpose() => super.transpose();

  /// Return a 3x3 matrix consisting of every row and column in this matrix except
  /// for the specified skipRow and skipCol.
  Matrix3x3 without({int skipRow, int skipCol}) =>
      Matrix3x3(elementsWithout(skipRow: skipRow, skipCol: skipCol));
}
