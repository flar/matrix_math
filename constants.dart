import 'term.dart';

enum _SpecialType {
  neg_infinity,  // unbounded negative limit
  neg_overflow,  // negative number too large to represent
  neg_underflow, // negative number too small to represent
  neg_vanishing, // approaching zero from below in the limit

  pos_vanishing, // approaching zero from above in the limit
  pos_underflow, // positive number too small to represent
  pos_overflow,  // positive number too large to represent
  pos_infinity,  // unbounded positive limit

  indeterminate, // indeterminate or impossible number
}

/// A Term representing an ordinary number with no unknown values.
abstract class Constant extends Term {
  const Constant._();

  /// Returns the appropriate Constant Term object for the given double value, while
  /// attempting to preserve the singleton nature of the hard-coded constants.
  static Constant _forDouble(double v) {
    if (v.isInfinite) return (v < 0) ? neg_infinity : pos_infinity;
    if (v.isNaN) return indeterminate;
    if (v == 0) return zero;
    if (v == 1.0) return one;
    if (v == -1.0) return neg_one;
    return _Number(v);
  }

  @override bool negatesGracefully() => true;
  bool overwhelmsProducts();
  bool overwhelmsSums();

  /// Helper method to add or subtract two values based on a signum boolean.
  static double addOrSub(double v1, double v2, bool isSub) {
    return isSub ? v1 - v2 : v1 + v2;
  }

  @override
  Term addDirect(Term other, bool isNegated) {
    if (other is Constant) {
      return isNegated ? this - other : this + other;
    }
    return null;
  }

  @override bool equals(Term term) {
    return (term is Constant && this._equals(term));
  }
  bool _equals(Constant other);

  int compareTo(Constant other);

  @override String toOutline() => 'K';
  @override bool startsWithMinus() => isNegative();
}

class _Special extends Constant {
  final _SpecialType _type;
  final String _name;

  const _Special(this._type, this._name) : super._();

  @override
  bool isNegative() {
    switch (_type) {
      case _SpecialType.neg_infinity:
      case _SpecialType.neg_overflow:
      case _SpecialType.neg_underflow:
      case _SpecialType.neg_vanishing:
        return true;
      default:
        return false;
    }
  }

  @override
  bool overwhelmsProducts() {
    switch (_type) {
      case _SpecialType.neg_infinity:
      case _SpecialType.pos_infinity:
      case _SpecialType.indeterminate:
        return true;

      default:
        return false;
    }
  }

  @override
  bool overwhelmsSums() {
    switch (_type) {
      case _SpecialType.neg_infinity:
      case _SpecialType.pos_infinity:
      case _SpecialType.indeterminate:
        return true;

      default:
        return false;
    }
  }

  @override
  Term operator -() {
    switch (_type) {
      case _SpecialType.neg_infinity:  return pos_infinity;
      case _SpecialType.neg_overflow:  return pos_overflow;
      case _SpecialType.neg_underflow: return pos_underflow;
      case _SpecialType.neg_vanishing: return pos_vanishing;

      case _SpecialType.pos_vanishing: return neg_vanishing;
      case _SpecialType.pos_underflow: return neg_underflow;
      case _SpecialType.pos_overflow:  return neg_overflow;
      case _SpecialType.pos_infinity:  return neg_infinity;

      default: break;
    }
    return indeterminate;
  }

  _Special reciprocal() {
    switch (_type) {
      case _SpecialType.neg_infinity:  return neg_vanishing;
      case _SpecialType.neg_overflow:  return neg_underflow;
      case _SpecialType.neg_underflow: return neg_overflow;
      case _SpecialType.neg_vanishing: return neg_infinity;

      case _SpecialType.pos_vanishing: return pos_infinity;
      case _SpecialType.pos_underflow: return pos_overflow;
      case _SpecialType.pos_overflow:  return pos_underflow;
      case _SpecialType.pos_infinity:  return pos_vanishing;

      default: break;
    }
    return indeterminate;
  }

  @override
  Term operator +(Term other) {
    if (other is! Constant) {
      return super + other;
    }
    if (other == indeterminate) return other;
    switch (_type) {
      case _SpecialType.neg_infinity:
        if (other == pos_infinity) return indeterminate;
        return this;
      case _SpecialType.neg_overflow:
        if (other == neg_infinity) return other;
        if (other == pos_infinity) return other;
        if (other == pos_overflow) return indeterminate;
        return this;
      case _SpecialType.neg_underflow:
        if (other == neg_underflow) return this;
        if (other == neg_vanishing) return this;
        if (other == zero)          return this;
        if (other == pos_vanishing) return this;
        if (other == pos_underflow) return indeterminate;
        return other;
      case _SpecialType.neg_vanishing:
        if (other == neg_vanishing) return this;
        if (other == zero)          return this;
        if (other == pos_vanishing) return indeterminate;
        return other;

      case _SpecialType.pos_vanishing:
        if (other == pos_vanishing) return this;
        if (other == zero)          return this;
        if (other == neg_vanishing) return indeterminate;
        return other;
      case _SpecialType.pos_underflow:
        if (other == pos_underflow) return this;
        if (other == pos_vanishing) return this;
        if (other == zero)          return this;
        if (other == neg_vanishing) return this;
        if (other == neg_underflow) return indeterminate;
        return other;
      case _SpecialType.pos_overflow:
        if (other == pos_infinity) return other;
        if (other == neg_infinity) return other;
        if (other == neg_overflow) return indeterminate;
        return this;
      case _SpecialType.pos_infinity:
        if (other == neg_infinity) return indeterminate;
        return this;

      default:
        return this;
    }
  }

  @override
  Term operator -(Term other) {
    if (other is! Constant) {
      return super - other;
    }
    if (other == indeterminate) return other;
    return this + -other;
  }

  @override
  Term operator *(Term other) {
    if (other is! Constant) {
      return super * other;
    }
    if (other == indeterminate) return other;
    if (other == zero)          return other;
    switch (_type) {
      case _SpecialType.neg_infinity:
        if (other == pos_vanishing) return indeterminate;
        if (other == neg_vanishing) return indeterminate;
        if (other.isNegative())     return pos_infinity;
        return this;
      case _SpecialType.neg_overflow:
        if (other == neg_infinity)  return pos_infinity;
        if (other == neg_underflow) return indeterminate;
        if (other == neg_vanishing) return pos_vanishing;
        if (other == pos_vanishing) return neg_vanishing;
        if (other == pos_underflow) return indeterminate;
        if (other == pos_infinity)  return neg_infinity;
        if (other.isNegative())     return pos_overflow;
        return this;
      case _SpecialType.neg_underflow:
        if (other == neg_infinity)  return pos_infinity;
        if (other == neg_overflow)  return indeterminate;
        if (other == neg_vanishing) return pos_vanishing;
        if (other == pos_vanishing) return neg_vanishing;
        if (other == pos_overflow)  return indeterminate;
        if (other == pos_infinity)  return neg_infinity;
        if (other.isNegative())     return pos_underflow;
        return this;
      case _SpecialType.neg_vanishing:
        if (other == neg_infinity) return indeterminate;
        if (other == pos_infinity) return indeterminate;
        if (other.isNegative())    return pos_vanishing;
        return this;

      case _SpecialType.pos_vanishing:
        if (other == neg_infinity) return indeterminate;
        if (other == pos_infinity) return indeterminate;
        if (other.isNegative())    return neg_vanishing;
        return this;
      case _SpecialType.pos_underflow:
        if (other == neg_infinity)  return neg_infinity;
        if (other == neg_overflow)  return indeterminate;
        if (other == neg_vanishing) return neg_vanishing;
        if (other == pos_vanishing) return pos_vanishing;
        if (other == pos_overflow)  return indeterminate;
        if (other == pos_infinity)  return pos_infinity;
        if (other.isNegative())     return neg_underflow;
        return this;
      case _SpecialType.pos_overflow:
        if (other == neg_infinity)  return neg_infinity;
        if (other == neg_underflow) return indeterminate;
        if (other == neg_vanishing) return neg_vanishing;
        if (other == pos_vanishing) return pos_vanishing;
        if (other == pos_underflow) return indeterminate;
        if (other == pos_infinity)  return pos_infinity;
        if (other.isNegative())     return neg_overflow;
        return this;
      case _SpecialType.pos_infinity:
        if (other == pos_vanishing) return indeterminate;
        if (other == neg_vanishing) return indeterminate;
        if (other.isNegative())     return neg_infinity;
        return this;

      default:
        return this;
    }
  }

  @override
  Term operator /(Term other) {
    if (other is! Constant) {
      return super * other;
    }
    if (other == indeterminate) return other;
    if (other == zero) {
      if (this == indeterminate) return this;
      if (this.isNegative()) return neg_infinity;
      return pos_infinity;
    }
    switch (_type) {
      case _SpecialType.neg_infinity:
        if (other == neg_infinity) return indeterminate;
        if (other == pos_infinity) return indeterminate;
        if (other.isNegative())    return pos_infinity;
        return this;
      case _SpecialType.neg_overflow:
        if (other == neg_infinity)  return pos_vanishing;
        if (other == neg_overflow)  return indeterminate;
        if (other == neg_vanishing) return pos_infinity;
        if (other == pos_vanishing) return neg_infinity;
        if (other == pos_overflow)  return indeterminate;
        if (other == pos_infinity)  return neg_vanishing;
        if (other.isNegative())     return pos_overflow;
        return this;
      case _SpecialType.neg_underflow:
        if (other == neg_infinity)   return pos_vanishing;
        if (other == neg_underflow)  return indeterminate;
        if (other == neg_vanishing)  return pos_infinity;
        if (other == pos_vanishing)  return neg_infinity;
        if (other == pos_underflow)  return indeterminate;
        if (other == pos_infinity)   return neg_vanishing;
        if (other.isNegative())      return pos_overflow;
        return this;
      case _SpecialType.neg_vanishing:
        if (other == neg_vanishing) return indeterminate;
        if (other == pos_vanishing) return indeterminate;
        if (other.isNegative())     return pos_vanishing;
        return this;

      case _SpecialType.pos_vanishing:
        if (other == neg_vanishing) return indeterminate;
        if (other == pos_vanishing) return indeterminate;
        if (other.isNegative())     return neg_vanishing;
        return this;
      case _SpecialType.pos_underflow:
        if (other == neg_infinity)   return neg_vanishing;
        if (other == neg_underflow)  return indeterminate;
        if (other == neg_vanishing)  return neg_infinity;
        if (other == pos_vanishing)  return pos_infinity;
        if (other == pos_underflow)  return indeterminate;
        if (other == pos_infinity)   return pos_vanishing;
        if (other.isNegative())      return neg_overflow;
        return this;
      case _SpecialType.pos_overflow:
        if (other == neg_infinity)  return neg_vanishing;
        if (other == neg_overflow)  return indeterminate;
        if (other == neg_vanishing) return neg_infinity;
        if (other == pos_vanishing) return pos_infinity;
        if (other == pos_overflow)  return indeterminate;
        if (other == pos_infinity)  return pos_vanishing;
        if (other.isNegative())     return neg_overflow;
        return this;
      case _SpecialType.pos_infinity:
        if (other == neg_infinity) return indeterminate;
        if (other == pos_infinity) return indeterminate;
        if (other.isNegative())    return neg_infinity;
        return this;

      default:
        return this;
    }
  }

  @override bool _equals(Constant other) =>
      this != indeterminate && this == other;

  @override
  int compareTo(Constant other) {
    if (other is _Special) {
      return _type.index - other._type.index;
    }
    int index;
    if (other.isNegative()) {
      index = _SpecialType.neg_overflow.index;
    } else if (other == zero) {
      index = _SpecialType.neg_vanishing.index;
    } else {
      index = _SpecialType.pos_underflow.index;
    }
    return index <= _type.index ? -1 : 1;
  }

  @override String toString() => _name;
}

class _Number extends Constant {
  final double _value;

  const _Number(this._value) : super._();

  @override bool isNegative() => (_value < 0.0);
  @override bool overwhelmsProducts() => _value == 0.0;
  @override bool overwhelmsSums() => false;

  @override
  Term operator -() {
    if (_value == -1.0) return one;
    if (_value ==  1.0) return neg_one;
    if (_value ==  0.0) return zero;
    return _Number(-this._value);
  }

  Term operator +(Term other) {
    if (other is _Special) {
      return other + this;
    }
    if (other is _Number) {
      return Constant._forDouble(_value + other._value);
    }
    return super + other;
  }

  Term operator -(Term other) {
    if (other is _Special) {
      return -other + this;
    }
    if (other is _Number) {
      return Constant._forDouble(_value - other._value);
    }
    return super - other;
  }

  Term operator *(Term other) {
    if (this == zero) return this;
    if (other is _Special) {
      return other * this;
    }
    if (other is _Number) {
      return Constant._forDouble(_value * other._value);
    }
    return super * other;
  }

  Term operator /(Term other) {
    if (this == zero) return other == zero ? indeterminate : this;
    if (other is _Special) {
      return other.reciprocal() * this;
    }
    if (other is _Number) {
      return Constant._forDouble(_value / other._value);
    }
    return super * other;
  }

  @override
  int compareTo(Constant other) {
    if (other is _Number) {
      if (_value < other._value) return -1;
      if (_value > other._value) return 1;
      return 0;
    }
    return -other.compareTo(this);
  }

  @override bool _equals(Constant other) =>
      other is _Number && _value == other._value;

  String toString() {
    if (_value.isFinite && _value == _value.toInt()) {
      return _value.toInt().toString();
    }
    return _value.toString();
  }
}

const indeterminate = _Special(_SpecialType.indeterminate, 'indeterminate');

const neg_infinity  = _Special(_SpecialType.neg_infinity,  '-Infinity');
const neg_overflow  = _Special(_SpecialType.neg_overflow,  '-overflow');
const neg_underflow = _Special(_SpecialType.neg_underflow, '-underflow');
const neg_vanishing = _Special(_SpecialType.neg_vanishing, '-vanishing');

const pos_vanishing = _Special(_SpecialType.pos_vanishing, '+vanishing');
const pos_underflow = _Special(_SpecialType.pos_underflow, '+underflow');
const pos_overflow  = _Special(_SpecialType.pos_overflow,  '+overflow');
const pos_infinity  = _Special(_SpecialType.pos_infinity,  '+Infinity');

const neg_one = _Number(-1.0);
const zero = _Number(0.0);
const one = _Number(1.0);
