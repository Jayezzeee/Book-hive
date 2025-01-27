import 'package:flutter/material.dart';
import 'login_page.dart';
import 'book_finder.dart';

void main() {
  runApp(MainApp());
}

class MainApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeHive App',
      theme: ThemeData(primarySwatch: Colors.yellow),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(
              onLogin: (email, password, username) {
                // Once logged in, navigate to the BookFinder page
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookFinderApp(username: username),
                  ),
                );
              },
            ),
        '/bookfinder': (context) {
          final username = ModalRoute.of(context)!.settings.arguments as String;
          return BookFinderApp(username: username);
        },
      },
    );
  }
}