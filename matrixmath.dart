import 'term.dart';
import 'vecmath4.dart';
import 'unknowns.dart';
import 'constants.dart';
import 'products.dart';

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

const ap = Unknown('a`');
const bp = Unknown('b`');
const cp = Unknown('c`');
const dp = Unknown('d`');
const ep = Unknown('e`');
const fp = Unknown('f`');
const gp = Unknown('g`');
const hp = Unknown('h`');
const ip = Unknown('i`');
const jp = Unknown('j`');
const kp = Unknown('k`');
const lp = Unknown('l`');
const mp = Unknown('m`');
const np = Unknown('n`');
const op = Unknown('o`');
const pp = Unknown('p`');

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
  m4.printOut('M4');
  Term m4det = m4.determinant();
  print('|M4| = $m4det');
  print('');
  m4m.printOut('minors(M4)');
  print('');
  m4c.printOut('cofactors(M4)');
  print('');
  m4a.printOut('M4a = adjugate(M4)');
  print('');
//  This takes a while to calculate:
//  print(m4a.determinant());
//  print('');
  Vector4 Pm = Vector4(X, Y);
  if (Pm.zVal != zero) print("z not zero!");
  if (Product.mul(Pm.zVal, m4.elements[0][2]) != zero) print("product not zero!");
  Vector4 Ps = m4.transform(Pm);
  Vector4 Psi = m4a.transform(Ps);
  print('Pm     = $Pm');
  print('Pmnorm = ${Pm.normalize()}');
  print('Ps     = $Ps');
  print('Psnorm = ${Ps.normalize()}');
  print('');
  print('Ps * M4a = $Psi');
  print('');
  print('(Ps * M4a) normalized = ${Psi.normalize()}');
  print('');
  Matrix4x4 unity = m4.multiplyMatrix(m4a).divideFactor(m4det);
  unity.printOut('(M4 x M4a) / |M4|');
//  Term Xsn = Division.div(Ps.xVal, Ps.wVal);
//  Term Ysn = Division.div(Ps.yVal, Ps.wVal);
//  Vector4 Psm0 = m4a.transform(Vector4(Xsn, Ysn, zero));
//  Vector4 Psm1 = m4a.transform(Vector4(Xsn, Ysn, one));
//  Vector4 Psm0n = Psm0.normalize();
//  Vector4 Psm1n = Psm1.normalize();
//  Vector4 Psmd = Psm1.normalize().sub(Psm0.normalize());
//  print('');
//  print('Prev(Z=0)   = $Psm0');
//  print('');
//  print('Prev(Z=1)   = $Psm1');
//  print('');
//  print('Prev(Z1-Z0) = ${Psm1.sub(Psm0)}');
//  print('');
//  print('Z1n-Z0n     = ${Psmd}');
//  Term t0 = Division.div(
//    Psm0n.zVal.negate(),
//    Sum.sub(Psm1n.zVal, Psm0n.zVal),
//  );
//  Term Zm0zm1w = Product.mul(Psm0.zVal, Psm1.wVal);
//  Term Zm1zm0w = Product.mul(Psm1.zVal, Psm0.wVal);
//  Term t0alt = Division.div(Zm0zm1w, Sum.sub(Zm0zm1w, Zm1zm0w));
//  print('');
//  print('t0 = $t0');
//  print('');
//  print('t0alt = $t0alt');
//  print('');
//  print('Zm1zm0w - Zm0zm1w = ${Sum.sub(Zm1zm0w, Zm0zm1w)}');
//
//  Matrix4x4 m4i = Matrix4x4([
//    [ ap, bp, cp, dp, ],
//    [ ep, fp, gp, hp, ],
//    [ ip, jp, kp, lp, ],
//    [ mp, np, op, pp, ],
//  ]);
//  Vector4 Psi0 = m4i.transform(Vector4(X, Y, zero));
//  Vector4 Psi1 = m4i.transform(Vector4(X, Y, one));
//  Vector4 Psi0n = Psi0.normalize();
//  Vector4 Psi1n = Psi1.normalize();
//  Vector4 Psid = Psi1n.sub(Psi0n);
//  print('');
//  print('Inv(Z=0)   = $Psi0');
//  print('');
//  print('Inv(Z=1)   = $Psi1');
//  print('');
//  print('Inv(Z1-Z0) = ${Psi1.sub(Psi0)}');
//  print('');
//  print('iZ1n-iZ0n  = ${Psid}');
}
