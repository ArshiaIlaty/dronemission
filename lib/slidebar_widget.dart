import 'package:flutter/material.dart';

class SliderExample extends StatefulWidget {
  @override
  _SliderExampleState createState() => _SliderExampleState();
}

class _SliderExampleState extends State<SliderExample> {
  double _speedValue = 0.0;
  double _heightValue = 20.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slider Example'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Speed: ${_speedValue.toStringAsFixed(1)} m/s',
            style: TextStyle(fontSize: 20.0),
          ),
          SizedBox(height: 20.0),
          Slider(
            value: _speedValue,
            min: 0.0,
            max: 50.0,
            divisions: 50,
            label: _speedValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _speedValue = value;
              });
            },
          ),
          SizedBox(height: 40.0),
          Text(
            'Height: ${_heightValue.toStringAsFixed(1)} meters',
            style: TextStyle(fontSize: 20.0),
          ),
          SizedBox(height: 20.0),
          Slider(
            value: _heightValue,
            min: 20.0,
            max: 100.0,
            divisions: 80,
            label: _heightValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _heightValue = value;
              });
            },
          ),
        ],
      ),
    );
  }
}

class OverlapPage extends StatefulWidget {
  const OverlapPage({super.key});

  @override
  _OverlapPageState createState() => _OverlapPageState();
}

class _OverlapPageState extends State<OverlapPage> {
  double _speedValue = 2.0;
  double _altitudeValue = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(20.0),
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text("Speed"),
                            Slider(
                              min: 2.0,
                              max: 15.0,
                              value: _speedValue,
                              onChanged: (newValue) {
                                setState(() {
                                  _speedValue = newValue;
                                });
                              },
                            ),
                            const Text("Altitude"),
                            Slider(
                              min: 2.0,
                              max: 500.0,
                              value: _altitudeValue,
                              onChanged: (newValue) {
                                setState(() {
                                  _altitudeValue = newValue;
                                });
                              },
                            ),
                            const SizedBox(
                              height: 20.0,
                            ),
                            ElevatedButton(
                              child: const Text("Close"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    });
              },
              child: const Text("Overlap"),
            ),
          ),
        ],
      ),
    );
  }
}
