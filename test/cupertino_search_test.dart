import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:cupertino_search/cupertino_search.dart';

const _names = const [
  'Igor Minar',
  'Brad Green',
  'Dave Geddes',
  'Naomi Black',
  'Greg Weber',
  'Dean Sofer',
  'Wes Alvaro',
  'John Scott',
  'Daniel Nadasi',
];

class SelectMock<T> extends Mock {
  onSelect(T value) {}
}

void main() {
  testWidgets('CupertinoSearch Selection', (WidgetTester tester) async {
    var selectMock = new SelectMock<String>();

    await tester.pumpWidget(
      new StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return new CupertinoApp(
            home: new CupertinoSearch(
              placeholder: 'Find something',
              results: _names
                  .map((String v) => new CupertinoSearchResult<String>(
                        icon: CupertinoIcons.person,
                        value: v,
                        text: v,
                      ))
                  .toList(),
              onSelect: selectMock.onSelect,
            ),
          );
        },
      ),
    );

    _names.forEach((String name) {
      expect(find.text(name), findsOneWidget);
    });

    expect(find.text('Find something'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.clear), findsNothing);

    await tester.enterText(find.byType(CupertinoTextField), _names[2]);
    await tester.pump();

    //clear button, to empty the search
    //only shown when some text is typed
    expect(find.byIcon(CupertinoIcons.clear), findsOneWidget);

    expect(
        find.text(_names[2]), findsNWidgets(2)); //the text input and the result

    _names.where((String name) => name != _names[2]).forEach((String name) {
      expect(find.text(name), findsNothing);
    });

    return;
  });
}
