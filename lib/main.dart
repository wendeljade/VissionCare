import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/custom_material_localizations.dart';
import 'Pages/welcomingPage.dart';
import 'Pages/Dashboard.dart';
import 'Pages/Scan.dart';
import 'Pages/Diagnoses.dart';
import 'Pages/AboutPage.dart';


// Create a global key to access the app state and navigator
final GlobalKey<_MyAppState> appKey = GlobalKey<_MyAppState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Track the current page widget to preserve it during rebuilds
Widget currentPage = const Dashboard();

// Add a variable to track the current route
String currentRoute = '/dashboard';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialize date formatting for all supported locales
  await initializeDateFormatting('en', null);
  await initializeDateFormatting('tl', null);
  await initializeDateFormatting('ceb', null);

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('tl'),
        Locale('ceb'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
      saveLocale: true,
      child: MyApp(key: appKey),
    ),
  );
}

// Make MyApp stateful so we can force rebuilds
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Add a key to force rebuilds
  Key _key = UniqueKey();
  
  // Method to force rebuild the entire app
  void rebuildApp() {
    if (kDebugMode) {
      print("Rebuilding entire app with new locale: ${context.locale.languageCode}");
      print("Current route is: $currentRoute");
      print("Current page type: ${currentPage.runtimeType}");
    }
    
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which page to show based on the current route
    Widget homePage;
    switch (currentRoute) {
      case '/dashboard':
        homePage = const Dashboard();
        break;
      case '/diagnoses':
        homePage = const Diagnoses();
        break;
      case '/scan':
        homePage = const Scan();
        break;
      case '/about':
        homePage = const AboutPage();
        break;
      case '/results':
        // For results, we'll handle this in the language selector
        // since we need the specific parameters
        homePage = const Dashboard(); // Default fallback
        break;
      case '/':
      default:
        homePage = const Dashboard();
    }
    
    return MaterialApp(
      key: _key,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        const CustomMaterialLocalizations(),
        const CustomCupertinoLocalizations(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        ...context.localizationDelegates,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (kDebugMode) {
          print("Resolving locale: ${locale?.languageCode}");
        }
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      title: 'Corn Disease Detection',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: homePage,
      routes: {
        '/dashboard': (context) => const Dashboard(),
        '/diagnoses': (context) => const Diagnoses(),
        '/scan': (context) => const Scan(),
        '/about': (context) => const AboutPage(),
        // We can't add Results here because it requires parameters
      },
      onGenerateRoute: (RouteSettings settings) {
        // Update the current route when navigation occurs
        if (settings.name != null) {
          currentRoute = settings.name!;
          if (kDebugMode) {
            print("Route changed to: $currentRoute");
          }
        }
        return null;
      },
    );
  }
}


