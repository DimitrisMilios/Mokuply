import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/viewmodels/editor_viewmodel.dart';

void main() {
  test('EditorViewModel smoke test', () {
    final vm = EditorViewModel();
    expect(vm.isHomeScreen, isTrue);
    expect(vm.screenshots.length, greaterThan(0));
  });
}
