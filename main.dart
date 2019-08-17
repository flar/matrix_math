import 'dart:math' as math;
import 'dart:io' as io;

import 'term.dart';
import 'unknowns.dart';
import 'constants.dart';
import 'vecmath3.dart';
import 'vecmath4.dart';

int padding = 1;

void usage() {
  print('usage: dart main.dart [rect_transform] [pick_ray] [math_test] [--nopad] [--padding N]');
}

void main(List<String> args) {
  bool foundOne = false;
  for (int i = 0; i < args.length; i++) {
    var arg = args[i];
    switch (arg) {
      case 'rect_transform':
        runRectTransforms();
        foundOne = true;
        break;
      case 'pick_ray':
        runPickRays();
        foundOne = true;
        break;
      case 'math_test':
        testMath();
        foundOne = true;
        break;
      case '--nopad':
        padding = 0;
        break;
      case '--padding':
        if (++i < args.length) {
          try {
            padding = int.parse(args[i]);
          } catch(e) {
            print('--padding requires numeric argument');
            usage();
            return;
          }
        } else {
          print('No argument for --padding');
          usage();
          return;
        }
        break;
      default:
        print('Unrecognized arg ($arg) ignored');
        break;
    }
  }
  if (!foundOne) {
    usage();
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

//void printOps(Constant v1, Constant v2) {
//  double v1val = v1.value;
//  double v2val = v2.value;
//  print('$v1val + $v2val = ${v1val + v2val}');
//  print('$v1val - $v2val = ${v1val - v2val}');
//  print('$v1val * $v2val = ${v1val * v2val}');
//  print('$v1val / $v2val = ${v1val / v2val}');
//  print('$v1val == $v2val = ${v1val == v2val}');
//  print('$v1val != $v2val = ${v1val != v2val}');
//  print('$v1val >= $v2val = ${v1val >= v2val}');
//  print('$v1val <= $v2val = ${v1val <= v2val}');
//  print('$v1val > $v2val = ${v1val > v2val}');
//  print('$v1val < $v2val = ${v1val < v2val}');
//}
//
//void testMath() {
//  printOps(one, zero);
//  printOps(neg_one, zero);
//  printOps(pos_infinity, zero);
//  printOps(neg_infinity, zero);
//  printOps(pos_infinity, neg_infinity);
//  printOps(neg_infinity, pos_infinity);
//  printOps(pos_infinity, pos_infinity);
//  printOps(indeterminate, indeterminate);
//  printOps(indeterminate, one);
//  printOps(one, indeterminate);
//  printOps(indeterminate, pos_infinity);
//  printOps(neg_infinity, indeterminate);
//}

List<Constant> all_values = [
  neg_infinity,
  neg_overflow,
  neg_one,
  neg_underflow,
  neg_vanishing,
  zero,
  pos_vanishing,
  pos_underflow,
  one,
  pos_overflow,
  pos_infinity,
  indeterminate,
];

String pad(String val, String padChar, int width) {
  while (val.length < width) {
    val = val + padChar;
    if (val.length < width) {
      val = padChar + val;
    }
  }
  return val;
}

void printRow(String label, List values, List<int> columnWidths) {
  io.stdout.write(pad(label, ' ', columnWidths[0]));
  for (int c = 0; c < values.length; c++) {
    io.stdout.write('|');
    io.stdout.write(pad(values[c].toString(), ' ', columnWidths[c+1]));
  }
  io.stdout.write('\n');
}

void checkSymmetry(List<List<Constant>> results, String operator) {
  for (int r = 0; r < all_values.length; r++) {
    for (int c = 0; c < all_values.length; c++) {
      if (results[r][c].compareTo(results[c][r]) != 0) {
        print('${all_values[r]} $operator ${all_values[c]} == ${results[r][c]}');
        print('${all_values[c]} $operator ${all_values[r]} == ${results[c][r]}');
        print('');
      }
    }
  }
}

void show(List<List<Constant>> results, String operator) {
  List<int> columnWidths = [
    0,
    for (Constant c in all_values) c.toString().length,
  ];
  for (int w in columnWidths) {
    columnWidths[0] = math.max(columnWidths[0], w);
  }
  for (int r = 0; r < results.length; r++) {
    List<Constant> row = results[r];
    for (int c = 0; c < row.length; c++) {
      Constant result = row[c];
      int len = result.toString().length;
      columnWidths[c+1] = math.max(columnWidths[c+1], len);
    }
  }
  if (padding > 0) {
    for (int c = 0; c < columnWidths.length; c++) {
      columnWidths[c] += padding * 2;
    }
  }
  printRow(operator, all_values, columnWidths);
  List<String> dashes = [
    for (int c = 0; c < all_values.length; c++)
      pad('-', '-', columnWidths[c+1]),
  ];
  printRow(pad('-', '-', columnWidths[0]), dashes, columnWidths);
  for (int r = 0; r < results.length; r++) {
    printRow(all_values[r].toString(), results[r], columnWidths);
  }
}

List<List<Constant>> calculate(Constant calc(Constant a, Constant b)) {
  return [
    for (Constant a in all_values) [
      for (Constant b in all_values)
        calc(a, b),
    ],
  ];
}

void testMath() {
  List<List<Constant>> sums = calculate((a,b) => a + b);
  checkSymmetry(sums, '+');
  show(sums, '+');
  print('');

  List<List<Constant>> products = calculate((a,b) => a * b);
  checkSymmetry(products, '*');
  show(products, '*');
  print('');

  List<List<Constant>> differences = calculate((a,b) => a - b);
//  checkSymmetry(differences, '-');
  show(differences, '-');
  print('');

  List<List<Constant>> divisions = calculate((a,b) => a / b);
//  checkSymmetry(divisions, '/');
  show(divisions, '/');
  print('');
}

Unknown L = Unknown('L');
Unknown T = Unknown('T');
Unknown W = Unknown('W');
Unknown H = Unknown('H');
Term R = (L + W);
Term B = (T + H);

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
  Vector4 Tdltw = Tlt + Tdw;
  Vector4 Tdlth = Tlt + Tdh;
  Vector4 Tdltwh = Tdltw + Tdh;

  Vector4 TltN = Tlt.normalize();
  Vector4 TrtN = Trt.normalize();
  Vector4 TlbN = Tlb.normalize();
  Vector4 TrbN = Trb.normalize();

  Vector4 Wt = TrtN - TltN;
  Vector4 Wb = TrbN - TlbN;
  Vector4 Hl = TlbN - TltN;
  Vector4 Hr = TrbN - TrtN;
  Vector4 WH = TrbN - TltN;

  M4.printOut('M4');
  print('');
  print('TxLT = M4 * $lt = $Tlt');
  print('TxRT = M4 * $rt = $Trt');
  print('TxLB = M4 * $lb = $Tlb');
  print('TxRB = M4 * $rb = $Trb');
  print('DTx(W,0) = $Tdw');
  print('DTx(0,H) = $Tdh');
  print('TxLT + DTx(W,0) = $Tdltw');
  print('    ... then compared to TxRT = ${Tdltw - Trt}');
  print('TxLT + DTx(0,H) = $Tdlth');
  print('    ... then compared to TxLB = ${Tdlth - Tlb}');
  print('TxLT + DTx(W,0) + DTx(0,H) = $Tdltwh');
  print('    ... then compared to TxRB = ${Tdltwh - Trb}');
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
  WH.printOut('Diagonal    = TxRBnorm - TxLTnorm = ');
  print('');
  (Wb - Wt).printOut('WidthBottom - WidthTop   = ');
  (Hr - Hl).printOut('HeightRight - HeightLeft = ');
}

void runRectTransforms() {
  print(' First, rectangle transformation for the non-perspective (affine 3D) case');
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
  print(' And now adding a basic camera perspective matrix, but no 3D operations:');
  print('');

  Matrix4x4 M4cam = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ zero, zero, o, p, ],
  ]);

  runTransforms(M4cam);


  print('');
  print('');
  print(' Finally, considering the rectangle transform with a full 4x4 matrix:');
  print('');

  Matrix4x4 M4full = Matrix4x4([
    [ a, b, c, d, ],
    [ e, f, g, h, ],
    [ i, j, k, l, ],
    [ m, n, o, p, ],
  ]);

  runTransforms(M4full);
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
  if ((P4m.zVal * M4.elements[0][2]) != zero) print("product not zero!");
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
  Matrix4x4 M4u = (M4 * M4a) / M4det;
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
  print('P4m(Z=1) - P4m(Z=0) = ${P4mz1 - P4mz0}');

  // P4mz0.z = Z0 + (t=0)*(Z1 - Z0) = Z0
  // P4mz1.z = Z0 + (t=1)*(Z1 - Z0) = Z0 + Z1-Z0 = Z1
  // 0 = Z0 + (t=t0)*(Z1 - Z0)
  // t0 = -Z0 / (Z1 - Z0)
  // t0 = Z0 / (Z0 - Z1)

  Vector4 P4mz0n = P4mz0.normalize();
  Vector4 P4mz1n = P4mz1.normalize();
  Term Z0 = P4mz0n.zVal;
  Term Z1 = P4mz1n.zVal;
  Term Z0mZ1 = Z0 - Z1;
  Term t0 = Z0 / Z0mZ1;
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
  Matrix3x3 M3u = (M3 * M3a) / M3det;
  M3u.printOut('(M3 x M3a) / |M3|');
  Vector3 P3malt = M3a.transform(P3s.normalize());
  print('');
  print('P3m alternate inverse = $P3malt');
}
