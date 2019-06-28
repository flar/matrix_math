import 'term.dart';
import 'unknowns.dart';
import 'constants.dart';
import 'products.dart';
import 'sums.dart';
import 'vecmath3.dart';
import 'vecmath4.dart';

void main(List<String> args) {
  bool foundOne = false;
  for (var arg in args) {
    switch (arg) {
      case 'rect_transform':
        runRectTransforms();
        foundOne = true;
        break;
      case 'pick_ray':
        runPickRays();
        foundOne = true;
        break;
      default:
        print('Unrecognized arg ($arg) ignored');
        break;
    }
  }
  if (!foundOne) {
    print('usage: dart main.dart [rect_transform] [pick_ray]');
  }
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

Unknown L = Unknown('L');
Unknown T = Unknown('T');
Unknown W = Unknown('W');
Unknown H = Unknown('H');
Term R = Sum.add([L, W]);
Term B = Sum.add([T, H]);

void runTransforms(Matrix4x4 M4) {
  Vector4 lt = Vector4(L, T);
  Vector4 rt = Vector4(R, T);
  Vector4 lb = Vector4(L, B);
  Vector4 rb = Vector4(R, B);
  Vector4 dw = Vector4(W, zero, zero, zero);
  Vector4 dh = Vector4(zero, H, zero, zero);

  Vector4 Tlt = M4.transform(lt);
  Vector4 Trt = M4.transform(rt);
  Vector4 Tlb = M4.transform(lb);
  Vector4 Trb = M4.transform(rb);
  Vector4 Tdw = M4.transform(dw);
  Vector4 Tdh = M4.transform(dh);
  Vector4 Tdltw = Tlt.add(Tdw);
  Vector4 Tdlth = Tlt.add(Tdh);
  Vector4 Tdltwh = Tdltw.add(Tdh);

  Vector4 TltN = Tlt.normalize();
  Vector4 TrtN = Trt.normalize();
  Vector4 TlbN = Tlb.normalize();
  Vector4 TrbN = Trb.normalize();

  Vector4 Wt = TrtN.sub(TltN);
  Vector4 Wb = TrbN.sub(TlbN);
  Vector4 Hl = TlbN.sub(TltN);
  Vector4 Hr = TrbN.sub(TrtN);
  Vector4 Diag = TrbN.sub(TltN);

  M4.printOut('M4');
  print('');
  print('TxLT = M4 * $lt = $Tlt');
  print('TxRT = M4 * $rt = $Trt');
  print('TxLB = M4 * $lb = $Tlb');
  print('TxRB = M4 * $rb = $Trb');
  print('DTx(W,0) = $Tdw');
  print('DTx(0,H) = $Tdh');
  print('TxLT + DTx(W,0) = $Tdltw - TxRT = ${Trt.sub(Tdltw)}');
  print('TxLT + DTx(0,H) = $Tdlth - TxLB = ${Tlb.sub(Tdlth)}');
  print('TxLT + DTx(W,0) + DTx(0,H) = $Tdltwh - TxRB = ${Trb.sub(Tdltwh)}');
  print('');
  print('TxLT normalized = $TltN');
  print('TxRT normalized = $TrtN');
  print('TxLB normalized = $TlbN');
  print('TxRB normalized = $TrbN');
  print('');
  Wt.printOut('WidthTop    = TxRTnorm - TxLTnorm = ');
  Hl.printOut('HeightLeft  = TxLBnorm - TxLTnorm = ');
  Wb.printOut('WidthBottom = TxRBnorm - TxLBnorm = ');
  Hr.printOut('HeightRight = TxRBnorm - TxRTnorm = ');
  Diag.printOut('Diagonal    = TxRBnorm - TxLTnorm = ');
  print('');
  Wb.sub(Wt).printOut('WidthBottom - WidthTop   = ');
  Hr.sub(Hl).printOut('HeightRight - HeightLeft = ');
}

void runRectTransforms() {
  print(' Doing the rectangle transform with a full 4x4 matrix:');
  print('');

  Matrix4x4 M4 = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ m, n, o, p, ],
  ]);

  runTransforms(M4);

  print('');
  print('');
  print(' And now for the non-perspective case');
  print('');

  Matrix4x4 M4np = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ zero, zero, zero, one, ],
  ]);

  runTransforms(M4np);


  print('');
  print('');
  print(' And now doing it with a basic camera perspective matrix:');
  print('');

  Matrix4x4 M4cam = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ zero, zero, o, p, ],
  ]);

  runTransforms(M4cam);
}

void runPickRays() {
//  testMath();
  Matrix4x4 M4 = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ m, n, o, p, ],
  ]);
  Matrix4x4 M4m = M4.minors();
  Matrix4x4 M4c = M4m.cofactors();
  Matrix4x4 M4a = M4c.transpose();
  M4.printOut('M4');
  Term M4det = M4.determinant();
  print('|M4| = $M4det');
  print('');
  M4m.printOut('minors(M4)');
  print('');
  M4c.printOut('cofactors(minors(M4))');
  print('');
  M4a.printOut('M4a = adjugate(M4) = transpose(cofactors(minors(M4)))');
  print('');
//  This takes a while to calculate:
//  print(m4a.determinant());
//  print('');
  Vector4 P4m = Vector4(X, Y);
  if (P4m.zVal != zero) print("z not zero!");
  if (Product.mul(P4m.zVal, M4.elements[0][2]) != zero) print("product not zero!");
  Vector4 P4s = M4.transform(P4m);
  Vector4 P4si = M4a.transform(P4s);
  print('P4m      = $P4m');
  print('P4m norm = ${P4m.normalize()}');
  print('P4s      = $P4s');
  print('P4s norm = ${P4s.normalize()}');
  print('');
  print('P4s * M4a = $P4si');
  print('');
  print('(P4s * M4a) normalized = ${P4si.normalize()}');
  print('');
  Matrix4x4 M4u = M4.multiplyMatrix(M4a).divideFactor(M4det);
  M4u.printOut('(M4 x M4a) / |M4|');

  Vector4 P4sz0 = Vector4(X, Y, zero);
  Vector4 P4sz1 = Vector4(X, Y, one);
  Vector4 P4mz0 = M4a.transform(P4sz0);
  Vector4 P4mz1 = M4a.transform(P4sz1);
  print('P4s(Z=0) = $P4sz0');
  print('P4s(Z=1) = $P4sz1');
  print('');
  print('P4m(Z=0) = $P4mz0');
  print('');
  print('P4m(Z=1) = $P4mz1');
  print('');
  print('P4m(Z=1) - P4m(Z=0) = ${P4mz1.sub(P4mz0)}');

  // P4mz0.z = Z0 + (t=0)*(Z1 - Z0) = Z0
  // P4mz1.z = Z0 + (t=1)*(Z1 - Z0) = Z0 + Z1-Z0 = Z1
  // 0 = Z0 + (t=t0)*(Z1 - Z0)
  // t0 = -Z0 / (Z1 - Z0)
  // t0 = Z0 / (Z0 - Z1)

  Vector4 P4mz0n = P4mz0.normalize();
  Vector4 P4mz1n = P4mz1.normalize();
  Term Z0 = P4mz0n.zVal;
  Term Z1 = P4mz1n.zVal;
  Term Z0mZ1 = Sum.sub(Z0, Z1);
  Term t0 = Division.div(Z0, Z0mZ1);
  print('');
  print('t0 = $t0');
  print('t0 outline = ${t0.toOutline()}');

  print('');
  print('Alternate Method:');
  print('');

  Matrix3x3 M3 = M4.without(skipRow: 2, skipCol: 2);
  Matrix3x3 M3m = M3.minors();
  Matrix3x3 M3c = M3m.cofactors();
  Matrix3x3 M3a = M3c.transpose();
  M3.printOut('M3');
  Term M3det = M3.determinant();
  print('|M3| = $M3det');
  print('');
  M3m.printOut('minors(M3)');
  M3c.printOut('cofactors(minors(M3))');
  M3a.printOut('M3a = adjugate(M3) = transpose(cofactors(minors(M3)))');
  Vector3 P3m = Vector3(X, Y);
  Vector3 P3s = M3.transform(P3m);
  Vector3 P3si = M3a.transform(P3s);
  print('');
  print('P3m      = $P3m');
  print('P3m norm = ${P3m.normalize()}');
  print('P3s      = $P3s');
  print('P3s norm = ${P3s.normalize()}');
  print('');
  print('P3s * M3a = $P3si');
  print('');
  print('(P3s * M3a) normalized = ${P3si.normalize()}');
  print('');
  Matrix3x3 M3u = M3.multiplyMatrix(M3a).divideFactor(M3det);
  M3u.printOut('(M3 x M3a) / |M3|');
  Vector3 P3malt = M3a.transform(P3s.normalize());
  print('');
  print('P3m alternate inverse = $P3malt');
}
