import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:convert' show base64;
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOTP Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'TOTP Authentication Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer timer;
  int timercountdown = 30;

  void startTimer() {
    timercountdown = getTimeUntilNextStep();
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (timercountdown <= 0) {
        setState(() {
          timercountdown = getTimeUntilNextStep();
        });
      } else {
        setState(() {
          timercountdown--;
        });
      }
    });
  }

  void initState() {
    super.initState();
    startTimer();
  }

  String generateTOTP(String secret,
      {int timeStep = 30, int digits = 6, int? currentTime}) {
    currentTime ??= DateTime.now().millisecondsSinceEpoch ~/ 1000;
    currentTime += 3; //added time difference

    currentTime ~/= timeStep;

    final timeBytes = ByteData(8);
    timeBytes.setUint64(0, currentTime);

    final secretBytes = base64.decode(secret);
    final hmac = Hmac(sha1, secretBytes);
    final hmacResult = hmac.convert(timeBytes.buffer.asUint8List());

    final offset = hmacResult.bytes[hmacResult.bytes.length - 1] & 0xF;

    final truncatedHash = hmacResult.bytes.sublist(offset, offset + 4);
    final int otp =
        truncatedHash.fold<int>(0, (value, element) => (value << 8) + element) %
            (pow(10, digits) as int);

    final otpStr = otp.toString().padLeft(digits, '0');

    return otpStr;
  }

  int getTimeUntilNextStep({int timeStep = 30}) {
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return timeStep - ((currentTime + 3) % timeStep);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(timercountdown.toString()),
            SizedBox(
              height: 10,
            ),
            Text(
              generateTOTP("adfbcdefghij"),
              style: TextStyle(fontSize: 20),
            )
          ],
        ),
      ),
    );
  }
}
