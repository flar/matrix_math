/// The fundamental element in an equation.
///
/// All Term objects should be considered immutable and all operations on them should
/// return new objects except in the rare case that the result happens to equate to an
/// existing object in which case that existing object can be returned as the result.
///
/// Possible instances of Term can be:
/// - Unknown    (a single unknown variable)
/// - Constant   (any number with no unknowns)
/// - Product    (a product of other Term objects, with a coefficient)
/// - Division   (a division of exactly 2 other Term objects)
/// - Sum        (a sum of other Term objects)
abstract class Term {
  const Term();

  /// Is this Term object naturally negative?
  ///
  ///  Used in processing of negatesGracefully()
  bool isNegative();

  /// Can this Term be negated gracefully without having to multiply
  /// it by a new coefficient of -1?
  bool negatesGracefully();

  /// Return a new Term object representing the negation of this one.
  Term negate();

  /// Return a Term object representing the negation of this one if [doNegate] is true.
  Term negateIf(bool doNegate) {
    return doNegate ? negate() : this;
  }

  /// Return true if this Term is identical to the other
  bool equals(Term other);

  /// If the other Term object can be added directly to this Term
  /// object, return a new Term object representing the sum, or
  /// null if it is not possible.
  Term addDirect(Term other, bool isNegated);

  /// Returns true if the string representation of this Term will start
  /// with a minus sign.
  bool startsWithMinus();

  /// Returns a string that shows the structure of the Term, outlining the
  /// type of this [Term] and the relationship to any component [Term]
  /// objects in the expression.
  String toOutline();
}
