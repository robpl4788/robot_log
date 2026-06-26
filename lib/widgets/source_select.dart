
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:silvanus/data_sources/data_engine.dart';
import 'package:file_picker/file_picker.dart';
import 'package:silvanus/data_sources/no_source.dart';
import 'package:silvanus/data_sources/csv_source.dart';

class SourceSelector extends StatefulWidget{

  final void Function(DataEngine) onSelectionChanged;

  const SourceSelector({super.key, required this.onSelectionChanged});
  
  @override
  State<SourceSelector> createState() => SourceSelectorState();
}

class SourceSelectorState extends State<SourceSelector> {
  SourceOption currentSourceOption = SourceOptionNone();

  @override
  void initState() {
    super.initState();
  }


  void selectOption(SourceOption selected, {String serialPort = ""}) async {
    setState(() {
      currentSourceOption = selected;
    });
    
    DataEngine newEngine;
    // Initialise a new engine based on the selected option
    switch (selected) {
      case SourceOptionCSV():
        FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], allowMultiple: false);
        String? path = result?.files.single.path;
        if (path != null) {
          newEngine = DataEngine(source: CSVSource(path));
        } else {
          newEngine = DataEngine(source: NoSource());
        }
        break;
      // case SourceOptionSerial():
      //   String? serialPortName = selected.serialPortName;
      //   if (serialPortName == null) {
      //     newEngineFuture = loadNone();
      //   } else {
      //     newEngineFuture = loadSerial(port: serialPortName);
      //   }
      //   break;
      case SourceOptionNone():
          newEngine = DataEngine(source: NoSource());
        break;
    }

    newEngine.start();

    widget.onSelectionChanged(newEngine);
  }

  @override
  Widget build(BuildContext context) {
    return Row( children: [DropdownMenu(
            dropdownMenuEntries:  [
              // DropdownMenuEntry(value: SourceOptionRandom(), label: SourceOptionRandom().label),
              // DropdownMenuEntry(value: SourceOptionSerial(), label: SourceOptionSerial().label),
              DropdownMenuEntry(value: SourceOptionCSV(), label: SourceOptionCSV().label) ,
              DropdownMenuEntry(value: SourceOptionNone(), label: SourceOptionNone().label), ] ,
            onSelected: (dynamic value) {
              if (value is SourceOption) {
                selectOption(value);
              }
            }),
            // if (currentSourceOption.label == SourceOptionSerial().label) serialPortMenu(),
            ]);
  }

  Stream<List<String>> serialPortStream() async* {
  while (true) {
    final ports = SerialPort.availablePorts..sort();
    yield ports;
    await Future.delayed(const Duration(seconds: 1));
  }
  }

  Widget serialPortMenu() {
    return StreamBuilder(
      stream: serialPortStream(), 
      builder: (context, snapshot) { 
          List<String> serialPortOptions = snapshot.data ?? [];
        return DropdownMenu<String>(
        dropdownMenuEntries: [for (String serialPortName in serialPortOptions) DropdownMenuEntry<String>(value: serialPortName, label: serialPortName)],
    onSelected: (String? value) {
      if (value != null) {
        currentSourceOption.setSerialPort(value);
        selectOption(currentSourceOption);
      }
    },); });
  }
}

// Currently available options
sealed class SourceOption {
  SourceOption(this.label);

  final String label;
  String? serialPortName; 

  void setSerialPort(String? newSerialPortName) {
    serialPortName = newSerialPortName;
  }

}

// class SourceOptionRandom extends SourceOption {
//   SourceOptionRandom() : super("Random");
// }

class SourceOptionCSV extends SourceOption {
  SourceOptionCSV() : super("CSV");
}

// class SourceOptionSerial extends SourceOption {
//   SourceOptionSerial() : super("Serial");
// }

class SourceOptionNone extends SourceOption {
  SourceOptionNone() : super("None");
}