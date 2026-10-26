import 'package:chillingz/core/constants/app_icons.dart';
import 'package:chillingz/core/constants/app_strings.dart';
import 'package:chillingz/core/navigation/app_navigator.dart';
import 'package:chillingz/core/utils/account_access_prompt.dart';
import 'package:chillingz/routes/app_routes.dart';
import 'package:chillingz/widgets/app_logo.dart';
import 'package:chillingz/widgets/content_links_button.dart';
import 'package:chillingz/widgets/profile_settings_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logo has a contrast treatment in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: const Scaffold(body: AppLogo()),
      ),
    );
    expect(find.byType(ColorFiltered), findsOneWidget);
  });

  testWidgets('logo keeps original artwork in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: const Scaffold(body: AppLogo()),
      ),
    );
    expect(find.byType(ColorFiltered), findsNothing);
  });

  test('save and favourite actions share bookmark iconography', () {
    expect(AppIcons.saved, Icons.bookmark_rounded);
    expect(AppIcons.savedOutlined, Icons.bookmark_border_rounded);
    expect(AppIcons.favorite, Icons.bookmark_rounded);
    expect(AppIcons.favoriteBorder, Icons.bookmark_border_rounded);
    expect(AppIcons.heartOutline, Icons.bookmark_border_rounded);
  });

  test('category navigation uses an edge-swipe capable route', () {
    final route = AppRoutes.onGenerateRoute(
      const RouteSettings(name: AppRoutes.music),
    );
    expect(route, isA<CupertinoPageRoute<void>>());
  });

  test('location pre-permission action uses neutral wording', () {
    expect(AppStrings.continueLabel, 'Continue');
    expect(AppStrings.continueAsGuest, 'Continue as Guest');
    expect(AppStrings.locationNotSpecified, 'Not specified');
  });

  testWidgets('account-only action explains login requirement', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: appNavigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AccountAccessPrompt.show(context),
              child: const Text('Save item'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.accountRequiredTitle), findsOneWidget);
    expect(find.text(AppStrings.accountRequiredMessage), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('See More opens a bottom sheet on phone layouts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentLinksButton(
            websiteLink: 'https://example.com',
            mapLink: 'https://maps.google.com/?q=London',
            ticketLink: '',
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.seeMore));
    await tester.pumpAndSettle();

    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Google Map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('See More opens a dialog on iPad layouts', (tester) async {
    tester.view.physicalSize = const Size(1180, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContentLinksButton(
            websiteLink: 'https://example.com',
            mapLink: 'https://maps.google.com/?q=London',
            ticketLink: '',
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.seeMore));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Website'), findsOneWidget);
    expect(find.text('Google Map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete verification requires password and acknowledgement', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) =>
                      const DeleteAccountVerificationDialog(usesPassword: true),
                );
              },
              child: const Text('Open deletion'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open deletion'));
    await tester.pumpAndSettle();

    TextButton continueButton() =>
        tester.widget<TextButton>(find.widgetWithText(TextButton, 'Continue'));

    expect(find.text('Current password'), findsOneWidget);
    expect(continueButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'qa-password');
    await tester.pump();
    expect(continueButton().onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(result, 'qa-password');
    expect(tester.takeException(), isNull);
  });

  testWidgets('final deletion confirmation can keep the account', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<bool>(
                  context: context,
                  builder: (_) => const DeleteAccountFinalConfirmationDialog(),
                );
              },
              child: const Text('Open final confirmation'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open final confirmation'));
    await tester.pumpAndSettle();
    expect(find.text('Permanently delete account?'), findsOneWidget);
    expect(find.text('Delete permanently'), findsOneWidget);

    await tester.tap(find.text('Keep my account'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(tester.takeException(), isNull);
  });
}
