import 'package:flutter_test/flutter_test.dart';
import 'package:kuchtik/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter', () {
    test('same unit returns same amount', () {
      expect(
        UnitConverter.convert(amount: 12.34, fromUnit: 'g', toUnit: 'g'),
        12.34,
      );
      expect(
        UnitConverter.convert(amount: 1, fromUnit: '  ML ', toUnit: 'ml'),
        1,
      );
    });

    test('linear weight conversions g <-> kg', () {
      expect(
        UnitConverter.convert(amount: 1500, fromUnit: 'g', toUnit: 'kg'),
        closeTo(1.5, 1e-9),
      );
      expect(
        UnitConverter.convert(amount: 2.25, fromUnit: 'kg', toUnit: 'g'),
        closeTo(2250, 1e-9),
      );
    });

    test('linear volume conversions ml <-> l', () {
      expect(
        UnitConverter.convert(amount: 1500, fromUnit: 'ml', toUnit: 'l'),
        closeTo(1.5, 1e-9),
      );
      expect(
        UnitConverter.convert(amount: 2.25, fromUnit: 'l', toUnit: 'ml'),
        closeTo(2250, 1e-9),
      );
    });

    test('culinary volume constants', () {
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'lžička', toUnit: 'ml'),
        closeTo(5.0, 1e-9),
      );
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'lžíce', toUnit: 'ml'),
        closeTo(15.0, 1e-9),
      );
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'hrnek', toUnit: 'ml'),
        closeTo(250.0, 1e-9),
      );
    });

    test('volume -> weight requires density', () {
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'lžíce', toUnit: 'g'),
        isNull,
      );

      // water density: 1 g/ml -> 15 ml = 15 g
      expect(
        UnitConverter.convert(
          amount: 1,
          fromUnit: 'lžíce',
          toUnit: 'g',
          densityGml: 1,
        ),
        closeTo(15, 1e-9),
      );

      // to kg
      expect(
        UnitConverter.convert(
          amount: 2,
          fromUnit: 'hrnek',
          toUnit: 'kg',
          densityGml: 1,
        ),
        closeTo(0.5, 1e-9),
      );
    });

    test('weight -> volume requires density', () {
      expect(
        UnitConverter.convert(amount: 100, fromUnit: 'g', toUnit: 'ml'),
        isNull,
      );

      // water density: 1 g/ml -> 100 g = 100 ml
      expect(
        UnitConverter.convert(
          amount: 100,
          fromUnit: 'g',
          toUnit: 'ml',
          densityGml: 1,
        ),
        closeTo(100, 1e-9),
      );

      // density 0.8 g/ml (e.g., oil-ish): 80 g => 100 ml
      expect(
        UnitConverter.convert(
          amount: 80,
          fromUnit: 'g',
          toUnit: 'ml',
          densityGml: 0.8,
        ),
        closeTo(100, 1e-9),
      );
    });

    test('unknown or incompatible units return null', () {
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'pcs', toUnit: 'g'),
        isNull,
      );
      expect(
        UnitConverter.convert(amount: 1, fromUnit: 'ml', toUnit: 'pcs'),
        isNull,
      );
      expect(
        UnitConverter.convert(
          amount: 1,
          fromUnit: 'ml',
          toUnit: 'g',
          densityGml: 0,
        ),
        isNull,
      );
    });
  });
}
