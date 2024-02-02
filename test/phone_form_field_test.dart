import 'package:circle_flags/circle_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:phone_form_field/src/country_selection/country_list_view.dart';

void main() {
  group('PhoneFormField', () {
    final formKey = GlobalKey<FormState>();
    final phoneKey = GlobalKey<FormFieldState<PhoneNumber>>();
    Widget getWidget({
      Function(PhoneNumber?)? onChanged,
      Function(PhoneNumber?)? onSaved,
      Function(PointerDownEvent)? onTapOutside,
      PhoneNumber? initialValue,
      PhoneController? controller,
      bool showFlagInInput = true,
      bool showDialCode = true,
      IsoCode defaultCountry = IsoCode.US,
      bool shouldFormat = false,
      PhoneNumberInputValidator? validator,
      bool enabled = true,
    }) =>
        MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            PhoneFieldLocalization.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            body: Form(
              key: formKey,
              child: PhoneFormField(
                key: phoneKey,
                initialValue: initialValue,
                onChanged: onChanged,
                onSaved: onSaved,
                onTapOutside: onTapOutside,
                showFlagInInput: showFlagInInput,
                showDialCode: showDialCode,
                controller: controller,
                defaultCountry: defaultCountry,
                shouldFormat: shouldFormat,
                validator: validator,
                enabled: enabled,
              ),
            ),
          ),
        );

    group('display', () {
      testWidgets('Should display input', (tester) async {
        await tester.pumpWidget(getWidget());
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('Should display country code', (tester) async {
        await tester.pumpWidget(getWidget());
        expect(find.byType(CountryChip), findsWidgets);
      });

      testWidgets('Should display flag', (tester) async {
        await tester.pumpWidget(getWidget());
        expect(find.byType(CircleFlag), findsWidgets);
      });

      testWidgets(
          'disabled, tap on country chip - country list dialog is not shown',
          (tester) async {
        await tester.pumpWidget(getWidget(enabled: false));
        final countryChip =
            tester.widget<CountryChip>(find.byType(CountryChip));
        expect(countryChip.enabled, false);

        await tester.tap(find.byType(CountryChip));
        await tester.pumpAndSettle();

        expect(find.byType(CountryListView), findsNothing);
      });
    });

    group('Country code', () {
      testWidgets('Should open dialog when country code is clicked',
          (tester) async {
        await tester.pumpWidget(getWidget());
        expect(find.byType(CountryListView), findsNothing);
        await tester.tap(find.byType(PhoneFormField));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byType(CountryChip));
        await tester.pumpAndSettle();
        expect(find.byType(CountryListView), findsOneWidget);
      });
      testWidgets('Should have a default country', (tester) async {
        await tester.pumpWidget(getWidget(defaultCountry: IsoCode.FR));
        expect(find.text('+ 33'), findsWidgets);
      });

      testWidgets('Should hide flag', (tester) async {
        await tester.pumpWidget(getWidget(showFlagInInput: false));
        expect(find.byType(CircleFlag), findsNothing);
      });

      testWidgets('Should format when shouldFormat is true', (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(
            getWidget(initialValue: phoneNumber, shouldFormat: true));
        await tester.pump(const Duration(seconds: 1));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '677777777');
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('6 77 77 77 77'), findsOneWidget);
      });

      testWidgets('Should show dial code when showDialCode is true',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(getWidget(
            initialValue: phoneNumber,
            showDialCode: true,
            defaultCountry: IsoCode.FR));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('+ 33'), findsOneWidget);
      });

      testWidgets('Should hide dial code when showDialCode is false',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(getWidget(
            initialValue: phoneNumber,
            showDialCode: false,
            defaultCountry: IsoCode.FR));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('+ 33'), findsNothing);
      });
    });

    group('value changes', () {
      testWidgets('Should display initial value', (tester) async {
        await tester.pumpWidget(getWidget(
            initialValue: PhoneNumber.parse('478787827',
                destinationCountry: IsoCode.FR)));
        expect(find.text('+ 33'), findsWidgets);
        expect(find.text('478787827'), findsOneWidget);
      });

      testWidgets('Should change value of controller', (tester) async {
        final controller = PhoneController();
        PhoneNumber? newValue;
        controller.addListener(() {
          newValue = controller.value;
        });
        await tester.pumpWidget(
            getWidget(controller: controller, defaultCountry: IsoCode.US));
        final phoneField = find.byType(PhoneFormField);
        await tester.tap(phoneField);
        // non digits should not work
        await tester.enterText(phoneField, '123456789');
        expect(
          newValue,
          equals(
            PhoneNumber.parse(
              '123456789',
              destinationCountry: IsoCode.US,
            ),
          ),
        );
      });

      testWidgets('Should change value of input when controller changes',
          (tester) async {
        final controller = PhoneController();
        // ignore: unused_local_variable
        PhoneNumber? newValue;
        controller.addListener(() {
          newValue = controller.value;
        });
        await tester.pumpWidget(
            getWidget(controller: controller, defaultCountry: IsoCode.US));
        controller.value =
            PhoneNumber.parse('488997722', destinationCountry: IsoCode.FR);
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('+ 33'), findsWidgets);
        expect(find.text('488997722'), findsOneWidget);
      });
      testWidgets(
          'Should change value of country code chip when full number copy pasted',
          (tester) async {
        final controller = PhoneController();
        // ignore: unused_local_variable
        PhoneNumber? newValue;
        controller.addListener(() {
          newValue = controller.value;
        });
        await tester.pumpWidget(
            getWidget(controller: controller, defaultCountry: IsoCode.US));
        final phoneField = find.byType(PhoneFormField);
        await tester.tap(phoneField);
        // non digits should not work
        await tester.enterText(phoneField, '+33 0488 99 77 22');
        await tester.pump();
        expect(controller.value.isoCode, equals(IsoCode.FR));
        expect(controller.value.nsn, equals('488997722'));
      });

      testWidgets('Should call onChange', (tester) async {
        bool changed = false;
        PhoneNumber? phoneNumber =
            PhoneNumber.parse('', destinationCountry: IsoCode.FR);
        void onChanged(PhoneNumber? p) {
          changed = true;
          phoneNumber = p;
        }

        await tester.pumpWidget(
          getWidget(
            initialValue: phoneNumber,
            onChanged: onChanged,
          ),
        );
        final phoneField = find.byType(PhoneFormField);
        await tester.tap(phoneField);
        // non digits should not work
        await tester.enterText(phoneField, 'aaa');
        await tester.pump(const Duration(seconds: 1));
        expect(changed, equals(false));
        await tester.enterText(phoneField, '123');
        await tester.pump(const Duration(seconds: 1));
        expect(changed, equals(true));
        expect(phoneNumber,
            equals(PhoneNumber.parse('123', destinationCountry: IsoCode.FR)));
      });
    });

    group('validity', () {
      testWidgets('Should tell when a phone number is not valid',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );
        await tester.pumpWidget(getWidget(initialValue: phoneNumber));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '9984');
        await tester.pump(const Duration(seconds: 1));

        expect(find.text('Invalid phone number'), findsOneWidget);
      });

      testWidgets(
          'Should tell when a phone number is not valid for a given phone number type',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.BE,
        );
        // valid fixed line
        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          validator: PhoneValidator.validFixedLine(),
        ));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '77777777');
        await tester.pumpAndSettle();
        expect(find.text('Invalid'), findsNothing);
        // invalid mobile
        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          validator: PhoneValidator.validMobile(
            errorText: 'Invalid phone number',
          ),
        ));
        final phoneField2 = find.byType(PhoneFormField);
        await tester.pumpAndSettle();
        await tester.enterText(phoneField2, '77777777');
        await tester.pumpAndSettle();
        expect(find.text('Invalid phone number'), findsOneWidget);

        // valid mobile
        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          validator: PhoneValidator.validMobile(
            errorText: 'Invalid phone number',
          ),
        ));
        final phoneField3 = find.byType(PhoneFormField);
        await tester.enterText(phoneField3, '477668899');
        await tester.pumpAndSettle();
        expect(find.text('Invalid'), findsNothing);
      });
    });

    group('Format', () {
      testWidgets('Should format when shouldFormat is true', (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(
            getWidget(initialValue: phoneNumber, shouldFormat: true));
        await tester.pump(const Duration(seconds: 1));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '677777777');
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('6 77 77 77 77'), findsOneWidget);
      });
      testWidgets('Should not format when shouldFormat is false',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(
            getWidget(initialValue: phoneNumber, shouldFormat: false));
        await tester.pump(const Duration(seconds: 1));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '677777777');
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('677777777'), findsOneWidget);
      });
    });

    group('form field', () {
      testWidgets('Should call onSaved', (tester) async {
        bool saved = false;
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );
        void onSaved(PhoneNumber? p) {
          saved = true;
          phoneNumber = p;
        }

        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          onSaved: onSaved,
        ));
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '479281938');
        await tester.pump(const Duration(seconds: 1));
        formKey.currentState?.save();
        await tester.pump(const Duration(seconds: 1));
        expect(saved, isTrue);
        expect(
            phoneNumber,
            equals(PhoneNumber.parse(
              '479281938',
              destinationCountry: IsoCode.FR,
            )));
      });
      testWidgets('Should call onTapOutside', (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        void onTapOutside(PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
        }

        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          onTapOutside: onTapOutside,
        ));

        final FocusScopeNode primaryFocus =
            FocusManager.instance.primaryFocus as FocusScopeNode;

        // Verify that the PhoneFormField is unfocused
        expect(primaryFocus.focusedChild, isNull);

        // Tap on the PhoneFormField to focus it
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, '479281938');
        await tester.pump(const Duration(seconds: 1));

        // Verify that the PhoneFormField has focus
        expect(primaryFocus.focusedChild, isNotNull);

        // Tap outside the PhoneFormField to unfocus it
        await tester.tap(find.byType(Scaffold));
        await tester.pumpAndSettle();

        // Verify that the PhoneFormField is unfocused
        expect(primaryFocus.focusedChild, isNull);
      });
      testWidgets(
          'Should call onTapOutside not unfocus keyboard if already unfocused',
          (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        void onTapOutside(PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
        }

        await tester.pumpWidget(getWidget(
          initialValue: phoneNumber,
          onTapOutside: onTapOutside,
        ));

        // Verify that the PhoneFormField is unfocused initially
        expect(
          (FocusManager.instance.primaryFocus as FocusScopeNode).focusedChild,
          isNull,
        );
        // Tap outside the PhoneFormField
        await tester.tap(find.byType(Scaffold));
        await tester.pump();

        // Verify that the PhoneFormField is still unfocused
        expect(
          (FocusManager.instance.primaryFocus as FocusScopeNode).focusedChild,
          isNull,
        );
      });

      testWidgets('Should reset', (tester) async {
        PhoneNumber? phoneNumber = PhoneNumber.parse(
          '',
          destinationCountry: IsoCode.FR,
        );

        await tester.pumpWidget(getWidget(initialValue: phoneNumber));
        await tester.pump(const Duration(seconds: 1));
        const national = '123456';
        final phoneField = find.byType(PhoneFormField);
        await tester.enterText(phoneField, national);
        expect(find.text(national), findsOneWidget);
        formKey.currentState?.reset();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(national), findsNothing);
      });
    });

    group('Directionality', () {
      testWidgets('Using textDirection.LTR on RTL context', (tester) async {
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.rtl,
          child: getWidget(),
        ));
        final finder = find.byType(Directionality);
        final widget = finder.at(1).evaluate().single.widget as Directionality;
        expect(widget.textDirection, TextDirection.ltr);
      });
    });
  });
}
