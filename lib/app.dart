import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/contact_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/contacts/add_contact_screen.dart';
import 'screens/transactions/add_transaction_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContactProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'SmartInterestX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        initialRoute: '/splash',
        routes: {
          '/splash':      (ctx) => const SplashScreen(),
          '/onboarding':  (ctx) => const OnboardingScreen(),
          '/home':        (ctx) => const HomeScreen(),
          '/add-contact': (ctx) => const AddContactScreen(),
          '/add-txn':     (ctx) => const AddTransactionScreen(),
        },
      ),
    );
  }
}
