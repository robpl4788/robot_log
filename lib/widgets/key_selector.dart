import 'dart:async';

import 'package:flutter/material.dart';
import 'package:silvanus/data_sources/data_engine.dart';
import 'package:silvanus/types/color_option.dart';
import 'package:silvanus/types/series_request.dart';

class KeySelector extends StatefulWidget{
  final DataEngine engine;


  final void Function(SeriesGroupRequest selected) onSelectionChanged;

  const KeySelector({super.key, required this.onSelectionChanged, required this.engine});
  
  @override
  State<KeySelector> createState() => KeySelectorState();
}

class KeySelectorState extends State<KeySelector> {
  SeriesGroupRequest options = SeriesGroupRequest.empty();
  final SeriesGroupRequest selected = SeriesGroupRequest.empty();
  late final StreamSubscription _keySub;

  @override
  void initState() {
    super.initState();
    options.addFreshKeys(widget.engine.getAvailableKeys());

    
    // If new keys are available update the options to be selected
    _keySub = widget.engine.keyStream.listen((keys){
      setState(() {
        options.addFreshKeys(keys);
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final request in options.getAllRequests())
          Row(
            children: [
              if (selected.contains(request)) colourPicker(request),
              Expanded(child: CheckboxListTile(
                title: Text(request.name),
                value: selected.contains(request),
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      selected.addRequest(request);
                    } else {
                      selected.removeRequest(request);
                    }
                  });

                  widget.onSelectionChanged(selected);
                },
              )),
      ],)]
    );
  }

  // Colour picker menu for a series
  DropdownMenu colourPicker(SeriesRequest request) {
    return  DropdownMenu(
            dropdownMenuEntries: [
              // Add each option in the colour pickers to the menu
              for (final option in ColorPickerOption.values) DropdownMenuEntry(value: option.color, label: option.label) ],
            onSelected: (dynamic value) {
              // The value should always be a colour since thats what we defined
              if (value is Color) {
                request.setColor(value);
                setState(() {
                  // Overwrite the series in selected and options with the new colour
                  selected.addRequest(request);
                  options.addRequest(request);
                } ); } },
            initialSelection: request.getColor(),
            );
  }

  // Stop listening to the key subscription when destroying this object
  @override
  void dispose() {
    super.dispose();
    _keySub.cancel();
  }
}

