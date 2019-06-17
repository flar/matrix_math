import 'term.dart';
import 'constants.dart';
import 'vecmath.dart';

/// A 3-value homogeneous coordinate representing X, Y, and a homogeneous factor W.
class Vector3 extends VectorN {
  Term get xVal => coordinates[0];
  Term get yVal => coordinates[1];
  Term get wVal => coordinates[2];

  Vector3([Term xVal = zero, Term yVal = zero, Term wVal = one])
      : super(3, [xVal, yVal, wVal]);

  Vector3.fromList(List<Term> coordinates)
      : super(3, coordinates);

  Vector3 makeVector(List<Term> coordinates) => Vector3.fromList(coordinates);

  Vector3 add(Vector3 other) => super.add(other);
  Vector3 sub(Vector3 other) => super.sub(other);
  Vector3 multiplyFactor(Term factor) => super.multiplyFactor(factor);
  Vector3 divideFactor(Term factor) => super.divideFactor(factor);
  Vector3 normalize() => super.normalize();
}

/// A 3x3 coordinate matrix
class Matrix3x3 extends MatrixNxN {
  Matrix3x3(List<List<Term>> elements) : super(3, elements);

  Matrix3x3 makeMatrix(List<List<Term>> elements) => Matrix3x3(elements);

  @override Vector3 transform(Vector3 vec) => super.transform(vec);
  @override Matrix3x3 multiplyFactor(Term factor) => super.multiplyFactor(factor);
  @override Matrix3x3 divideFactor(Term factor) => super.divideFactor(factor);
  @override Matrix3x3 multiplyMatrix(MatrixNxN other) => super.multiplyMatrix(other);
  @override Matrix3x3 minors() => super.minors();
  @override Matrix3x3 cofactors() => super.cofactors();
  @override Matrix3x3 transpose() => super.transpose();
}
