// The original content is temporarily commented out to allow generating a self-contained demo - feel free to uncomment later.

// import 'package:flutter/material.dart';
import 'package:silvanus/widgets/analysis_tab.dart';

import 'package:flutter/material.dart';
import 'package:silvanus/widgets/source_select.dart';
import "package:silvanus/data_sources/data_engine.dart";
import "package:silvanus/data_sources/no_source.dart";

Future<void> main() async {
  // await Engine.engine.begin();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  DataEngine? _engine;

  @override
  void initState() {
    super.initState();
    _engine =_engine ?? DataEngine(source: NoSource());
  }



  @override
  Widget build(BuildContext context) {
    final engine = _engine; // local variable
   
    
    if (engine == null) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Silvanus')),
        body: Center(
        child: Column(
          mainAxisAlignment: .center,
         children: [
          SizedBox(
              height: 300,
              child: AnalysisTab(engine: engine,  key: ValueKey(_engine!.hashCode),
            ),
            ),
            SourceSelector(onSelectionChanged: (DataEngine newEngine) { 
              engine.dispose();

              DataEngine currentEngine = newEngine;

              setState(() {
              _engine = currentEngine;
              });
            }),
          ]
        )
        ),
      ),
    );
  }
}
