import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();




  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String input = "";
  String result = "0";
  String title = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchTitle();
  }

  // 🔥 Only Firebase usage (get title)
  void fetchTitle() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('calculator')
          .get();

      setState(() {
        title = (doc.data() != null && doc.data()!['title'] != null)
            ? doc.data()!['title']
            : "Calculator";
      });
    } catch (e) {
      setState(() {
        title = "Calculator";
      });
    }
  }

  void onButtonClick(String value) {
    setState(() {
      if (value == "C") {
        input = "";
        result = "0";
      } else if (value == "=") {
        calculate();
      } else {
        input += value;
      }
    });
  }

  void calculate() {
    try {
      String finalInput =
      input.replaceAll('×', '*').replaceAll('÷', '/');

      double res = 0;

      if (finalInput.contains('+')) {
        var parts = finalInput.split('+');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a + b);
      } else if (finalInput.contains('-')) {
        var parts = finalInput.split('-');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a - b);
      } else if (finalInput.contains('*')) {
        var parts = finalInput.split('*');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a * b);
      } else if (finalInput.contains('/')) {
        var parts = finalInput.split('/');
        res = parts.map((e) => double.parse(e)).reduce((a, b) => a / b);
      } else {
        res = double.parse(finalInput);
      }

      setState(() {
        result = res.toString();
      });
    } catch (e) {
      setState(() {
        result = "Error";
      });
    }
  }

  Widget buildButton(String text) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: () => onButtonClick(text),
          child: Text(text, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title), // 🔥 from Firebase
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: const EdgeInsets.all(20),
              child: Text(input, style: const TextStyle(fontSize: 28)),
            ),
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.all(20),
            child: Text(
              result,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ),
          Row(children: [buildButton("7"), buildButton("8"), buildButton("9"), buildButton("÷")]),
          Row(children: [buildButton("4"), buildButton("5"), buildButton("6"), buildButton("×")]),
          Row(children: [buildButton("1"), buildButton("2"), buildButton("3"), buildButton("-")]),
          Row(children: [buildButton("C"), buildButton("0"), buildButton("="), buildButton("+")]),
        ],
      ),
    );
  }
}