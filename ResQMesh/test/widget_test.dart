import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resqmesh/app.dart';

void main() {
  testWidgets('ResQMesh home screen renders core actions', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ResQMeshApp()));
    expect(find.text('ResQMesh'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Nearby mesh'), findsOneWidget);
  });
}
