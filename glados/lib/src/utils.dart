import 'dart:math';

import 'structured_text.dart';

/// A function with one input that's intended to be called in a test context.
typedef Tester<T> = void Function(T input);

/// A function with two inputs that's intended to be called in a test context.
typedef Tester2<A, B> = void Function(A firstInput, B secondInput);

/// A function with three inputs that's intended to be called in a test context.
typedef Tester3<A, B, C> = void Function(
    A firstInput, B secondInput, C thirdInput);

/// A simple class storing statistics.
class Statistics {
  var exploreCounter = 0;
  var shrinkCounter = 0;
}

extension RandomUtils on Random {
  T choose<T>(List<T> list) => list[nextInt(nextInt(list.length))];
  int nextIntInRange(int min, int max) {
    assert(min == null || max == null || min <= max);
    return nextInt(max - min) + min;
  }
}

/// Runs the [tester] with the [input]. Catches thrown errors and instead
/// returns a [bool] indicating whether the tester ran through successfully.
bool succeeds<T>(Tester<T> tester, T input) {
  try {
    tester(input);
    return true;
  } catch (e) {
    return false;
  }
}

extension CamelCasing on String {
  String toLowerCamelCase() => this[0].toLowerCase() + substring(1);
}

extension JoinableStrings on List<String> {
  String joinLines() => join('\n');
  String joinParts() => join('\n\n');
}

extension LowerCasedType on Type {
  String get lowerCamelCased => toString().toLowerCamelCase();
}

/// While you shouldn't rely on [Type.toString()] to return something useful, we
/// depend on it _only_ for better developer experience.
class RichType {
  factory RichType.from(Type type) =>
      _TypeParser(type.toString().replaceAll(' ', '')).parse();
  RichType(this.name, [this.children = const []]);

  final String name;
  final List<RichType> children;

  bool get hasGenerics => children.isNotEmpty;
  Set<String> allTypes() =>
      [name, ...children.expand((child) => child.allTypes())].toSet();
  bool operator ==(Object other) =>
      other is RichType &&
      name == other.name &&
      children.length == other.children.length &&
      [
        for (var i = 0; i < children.length; i++)
          children[i] == other.children[i],
      ].every((it) => it);
  int get hashCode =>
      name.hashCode +
      children.map((child) => child.hashCode).fold(0, (a, b) => a + b);
  String toString() => '$name<${children.join(', ')}>';
  String toGeneratorString() {
    final string = StringBuffer('any.${name.toLowerCamelCase()}');
    if (children.isNotEmpty) {
      string
        ..write('(')
        ..write(children.map((child) => child.toGeneratorString()).join(', '))
        ..write(')');
    }
    return string.toString();
  }
}

class _TypeParser {
  _TypeParser(this.string);

  final String string;
  int cursor = 0;

  String get current => cursor < string.length ? string[cursor] : '';
  void advance() => cursor++;

  RichType parse() {
    var name = StringBuffer();
    var types = <RichType>[];
    while (!['<', '>', ',', ''].contains(current)) {
      name.write(current);
      advance();
    }
    if (current == '>' || current == ',') {
      return RichType(name.toString());
    }
    if (current == '<') {
      while (current == '<' || current == ',') {
        advance();
        types.add(parse());
      }
    }
    return RichType(name.toString(), types);
  }
}
