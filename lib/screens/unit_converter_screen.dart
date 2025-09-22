import 'package:flutter/material.dart';
import 'dart:math';

class UnitConverterScreen extends StatefulWidget {
  const UnitConverterScreen({super.key});

  @override
  State<UnitConverterScreen> createState() => _UnitConverterScreenState();
}

class _UnitConverterScreenState extends State<UnitConverterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  
  String _selectedCategory = 'Length';
  String _fromUnit = 'Meter';
  String _toUnit = 'Kilometer';
  String _errorMessage = '';

  final Map<String, Map<String, double>> _conversionData = {
    'Length': {
      'Millimeter': 0.001,
      'Centimeter': 0.01,
      'Meter': 1.0,
      'Kilometer': 1000.0,
      'Inch': 0.0254,
      'Foot': 0.3048,
      'Yard': 0.9144,
      'Mile': 1609.344,
      'Nautical Mile': 1852.0,
    },
    'Weight': {
      'Milligram': 0.000001,
      'Gram': 0.001,
      'Kilogram': 1.0,
      'Pound': 0.453592,
      'Ounce': 0.0283495,
      'Stone': 6.35029,
      'Ton (Metric)': 1000.0,
      'Ton (US)': 907.185,
    },
    'Temperature': {
      'Celsius': 1.0,
      'Fahrenheit': 1.0,
      'Kelvin': 1.0,
      'Rankine': 1.0,
    },
    'Volume': {
      'Milliliter': 0.001,
      'Liter': 1.0,
      'Cubic Meter': 1000.0,
      'Gallon (US)': 3.78541,
      'Gallon (UK)': 4.54609,
      'Quart (US)': 0.946353,
      'Pint (US)': 0.473176,
      'Cup (US)': 0.236588,
      'Fluid Ounce (US)': 0.0295735,
      'Tablespoon': 0.0147868,
      'Teaspoon': 0.00492892,
    },
    'Area': {
      'Square Millimeter': 0.000001,
      'Square Centimeter': 0.0001,
      'Square Meter': 1.0,
      'Square Kilometer': 1000000.0,
      'Square Inch': 0.00064516,
      'Square Foot': 0.092903,
      'Square Yard': 0.836127,
      'Acre': 4046.86,
      'Hectare': 10000.0,
    },
    'Time': {
      'Millisecond': 0.001,
      'Second': 1.0,
      'Minute': 60.0,
      'Hour': 3600.0,
      'Day': 86400.0,
      'Week': 604800.0,
      'Month': 2629746.0,
      'Year': 31556952.0,
    },
    'Speed': {
      'Meter/Second': 1.0,
      'Kilometer/Hour': 0.277778,
      'Mile/Hour': 0.44704,
      'Foot/Second': 0.3048,
      'Knot': 0.514444,
      'Mach': 343.0,
    },
    'Energy': {
      'Joule': 1.0,
      'Kilojoule': 1000.0,
      'Calorie': 4.184,
      'Kilocalorie': 4184.0,
      'BTU': 1055.06,
      'Watt Hour': 3600.0,
      'Kilowatt Hour': 3600000.0,
    },
    'Pressure': {
      'Pascal': 1.0,
      'Kilopascal': 1000.0,
      'Bar': 100000.0,
      'Atmosphere': 101325.0,
      'PSI': 6894.76,
      'Torr': 133.322,
      'mmHg': 133.322,
    },
    'Data Storage': {
      'Bit': 0.125,
      'Byte': 1.0,
      'Kilobyte': 1024.0,
      'Megabyte': 1048576.0,
      'Gigabyte': 1073741824.0,
      'Terabyte': 1099511627776.0,
      'Petabyte': 1125899906842624.0,
    },
  };

  List<String> get _availableUnits {
    return _conversionData[_selectedCategory]?.keys.toList() ?? [];
  }

  void _convert() {
    setState(() {
      _errorMessage = '';
      _outputController.clear();
    });

    try {
      final input = _inputController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter a value to convert';
        });
        return;
      }

      final inputValue = double.parse(input);
      double result;

      if (_selectedCategory == 'Temperature') {
        result = _convertTemperature(inputValue, _fromUnit, _toUnit);
      } else {
        final fromFactor = _conversionData[_selectedCategory]![_fromUnit]!;
        final toFactor = _conversionData[_selectedCategory]![_toUnit]!;
        result = (inputValue * fromFactor) / toFactor;
      }

      setState(() {
        _outputController.text = _formatResult(result);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid input. Please enter a valid number.';
      });
    }
  }

  double _convertTemperature(double value, String from, String to) {
    // Convert to Celsius first
    double celsius;
    switch (from) {
      case 'Celsius':
        celsius = value;
        break;
      case 'Fahrenheit':
        celsius = (value - 32) * 5 / 9;
        break;
      case 'Kelvin':
        celsius = value - 273.15;
        break;
      case 'Rankine':
        celsius = (value - 491.67) * 5 / 9;
        break;
      default:
        celsius = value;
    }

    // Convert from Celsius to target
    switch (to) {
      case 'Celsius':
        return celsius;
      case 'Fahrenheit':
        return celsius * 9 / 5 + 32;
      case 'Kelvin':
        return celsius + 273.15;
      case 'Rankine':
        return (celsius + 273.15) * 9 / 5;
      default:
        return celsius;
    }
  }

  String _formatResult(double result) {
    if (result == result.roundToDouble()) {
      return result.round().toString();
    } else {
      return result.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
    }
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      
      final tempValue = _inputController.text;
      _inputController.text = _outputController.text;
      _outputController.text = tempValue;
      
      _errorMessage = '';
    });
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _outputController.clear();
      _errorMessage = '';
    });
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory != null && newCategory != _selectedCategory) {
      setState(() {
        _selectedCategory = newCategory;
        final units = _availableUnits;
        _fromUnit = units.first;
        _toUnit = units.length > 1 ? units[1] : units.first;
        _inputController.clear();
        _outputController.clear();
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit Converter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _conversionData.keys.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: _onCategoryChanged,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Conversion Section
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // From Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _fromUnit,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  items: _availableUnits.map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _fromUnit = newValue;
                                        _errorMessage = '';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Value:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _inputController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Enter value',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty) {
                                      _convert();
                                    } else {
                                      setState(() {
                                        _outputController.clear();
                                        _errorMessage = '';
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Swap Button
                      Center(
                        child: IconButton(
                          onPressed: _swapUnits,
                          icon: const Icon(Icons.swap_vert),
                          iconSize: 32,
                          tooltip: 'Swap units',
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // To Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _toUnit,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  items: _availableUnits.map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(unit, style: const TextStyle(fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _toUnit = newValue;
                                        _errorMessage = '';
                                      });
                                      if (_inputController.text.isNotEmpty) {
                                        _convert();
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Result:',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _outputController,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Result',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _clearAll,
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _convert,
                              icon: const Icon(Icons.calculate),
                              label: const Text('Convert'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}