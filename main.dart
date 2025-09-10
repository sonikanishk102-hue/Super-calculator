import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final soundOn = prefs.getBool('soundOn') ?? false; // Default to OFF
  runApp(MyApp(soundOn: soundOn));
}

class MyApp extends StatefulWidget {
  final bool soundOn;
  const MyApp({super.key, required this.soundOn});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool soundOn;
  
  @override
  void initState() {
    super.initState();
    soundOn = widget.soundOn;
  }
  
  void updateSound(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundOn', val);
    setState(() => soundOn = val);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Super Calculator 3D',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: HomeScreen(soundOn: soundOn, onSoundChanged: updateSound),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool soundOn;
  final Function(bool) onSoundChanged;
  
  const HomeScreen({super.key, required this.soundOn, required this.onSoundChanged});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _player = AudioPlayer();
  
  // Calculator state - centralized
  String display = '0';
  String previousValue = '';
  String operation = '';
  bool waitingForOperand = false;
  String history = '';
  
  String activeCalculator = 'Basic';
  int switchCount = 0;
  List<String> calculationHistory = [];
  String? _currentInputField; // For keypad input

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _player.dispose();
    // Dispose all text controllers to prevent memory leaks
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('calculationHistory') ?? [];
    setState(() {
      calculationHistory = historyList;
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('calculationHistory', calculationHistory);
  }

  void addToHistory(String calculation) {
    setState(() {
      calculationHistory.insert(0, calculation);
      if (calculationHistory.length > 100) {
        calculationHistory = calculationHistory.take(100).toList();
      }
    });
    _saveHistory();
  }

  Future<void> _playClick() async {
    if (!widget.soundOn) return;
    try {
      // Non-blocking sound play
      _player.play(AssetSource('sound/mixkit-arcade-game-jump-coin-216.wav'), volume: 0.3);
    } catch (_) {
      // Silent fail if sound file not found
    }
  }

  // Centralized button handler - optimized for instant response
  void onButtonPressed(String value) {
    // Play sound without blocking (only if enabled)
    if (widget.soundOn) {
      _playClick();
    }
    
    // Immediate state update for instant response
    setState(() {
      // Handle input field input
      if (_currentInputField != null) {
        String fieldKey = _currentInputField!;
        String currentValue = calculatorState[fieldKey]?.toString() ?? '0';
        
        if (value == 'AC') {
          calculatorState[fieldKey] = '0';
        } else if (value == 'C') {
          if (currentValue.length > 1) {
            calculatorState[fieldKey] = currentValue.substring(0, currentValue.length - 1);
          } else {
            calculatorState[fieldKey] = '0';
          }
        } else if (value == '=') {
          _currentInputField = null; // Exit input mode
        } else if (['+', '-', '×', '÷', '%', '√', 'sin', 'cos', 'tan', 'log', 'ln', 'x²', 'x³', 'π', 'e', '(', ')', '^', '!'].contains(value)) {
          // Ignore operators in input mode
        } else if (value == '.') {
          // Handle decimal point
          if (!currentValue.contains('.')) {
            calculatorState[fieldKey] = '$currentValue.';
          }
        } else {
          // Handle number input
          if (currentValue == '0') {
            calculatorState[fieldKey] = value;
          } else {
            calculatorState[fieldKey] = currentValue + value;
          }
        }
        return;
      }
      
      // Handle normal calculator operations - optimized for speed
      if (value == 'AC') {
        display = '0';
        previousValue = '';
        operation = '';
        waitingForOperand = false;
        history = '';
      } else if (value == 'C') {
        if (display.length > 1) {
          display = display.substring(0, display.length - 1);
        } else {
          display = '0';
        }
      } else if (value == '√') {
        double number = double.tryParse(display) ?? 0;
        double result = sqrt(number);
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('√$number = $display');
      } else if (value == 'x²') {
        double number = double.tryParse(display) ?? 0;
        double result = number * number;
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('$number² = $display');
      } else if (value == 'x³') {
        double number = double.tryParse(display) ?? 0;
        double result = number * number * number;
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('$number³ = $display');
      } else if (value == 'sin') {
        double number = double.tryParse(display) ?? 0;
        double result = sin(number * pi / 180); // Convert to radians
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('sin($number°) = $display');
      } else if (value == 'cos') {
        double number = double.tryParse(display) ?? 0;
        double result = cos(number * pi / 180); // Convert to radians
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('cos($number°) = $display');
      } else if (value == 'tan') {
        double number = double.tryParse(display) ?? 0;
        double result = tan(number * pi / 180); // Convert to radians
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('tan($number°) = $display');
      } else if (value == 'log') {
        double number = double.tryParse(display) ?? 0;
        double result = log(number) / ln10;
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('log($number) = $display');
      } else if (value == 'ln') {
        double number = double.tryParse(display) ?? 0;
        double result = log(number);
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('ln($number) = $display');
      } else if (value == 'π') {
        display = _formatResult(pi);
        waitingForOperand = true;
        addToHistory('π = $display');
      } else if (value == 'e') {
        display = _formatResult(e);
        waitingForOperand = true;
        addToHistory('e = $display');
      } else if (value == '%') {
        double number = double.tryParse(display) ?? 0;
        double result = number / 100;
        display = _formatResult(result);
        waitingForOperand = true;
        addToHistory('$number% = $display');
      } else if (value == '^') {
        if (operation.isNotEmpty && !waitingForOperand) {
          _calculate();
        }
        previousValue = display;
        operation = '^';
        waitingForOperand = true;
        history = '$display ^';
      } else if (value == '!') {
        int number = int.tryParse(display) ?? 0;
        if (number < 0 || number > 20) {
          display = 'Error';
          addToHistory('$number! = Error (invalid range)');
        } else {
          int result = factorial(number);
          display = result.toString();
          waitingForOperand = true;
          addToHistory('$number! = $display');
        }
      } else if (value == '=') {
        _calculate();
      } else if (['+', '-', '×', '÷'].contains(value)) {
        if (operation.isNotEmpty && !waitingForOperand) {
          _calculate();
        }
        previousValue = display;
        operation = value;
        waitingForOperand = true;
        history = '$display $operation';
      } else {
        if (waitingForOperand) {
          display = value;
          waitingForOperand = false;
        } else {
          display = display == '0' ? value : display + value;
        }
      }
    });
  }

  void _calculate() {
    double prev = double.tryParse(previousValue) ?? 0;
    double current = double.tryParse(display) ?? 0;
    double result = 0;

    switch (operation) {
      case '+':
        result = prev + current;
        break;
      case '-':
        result = prev - current;
        break;
      case '×':
        result = prev * current;
        break;
      case '÷':
        result = current != 0 ? prev / current : 0;
        break;
      case '^':
        result = power(prev, current);
        break;
    }

    String formattedResult = _formatResult(result);
    addToHistory('$previousValue $operation $display = $formattedResult');
    
    setState(() {
      display = formattedResult;
      operation = '';
      waitingForOperand = true;
      history = '';
    });
  }

  String _formatResult(double result) {
    // Handle special cases
    if (result.isInfinite) {
      return result.isNegative ? '-∞' : '∞';
    }
    if (result.isNaN) {
      return 'Error';
    }
    
    // Limit decimal precision to maximum 7 digits
    String formatted;
    if (result == result.toInt()) {
      formatted = result.toInt().toString();
    } else {
      // Use toStringAsFixed with 7 decimal places, then remove trailing zeros
      formatted = result.toStringAsFixed(7);
      // Remove trailing zeros and unnecessary decimal point
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    }
    
    // If the number is still too long, use scientific notation for very large numbers
    if (formatted.length > 15) {
      return result.toStringAsExponential(6);
    }
    
    return formatted;
  }

  // Power function
  double power(num base, num exponent) {
    return pow(base, exponent).toDouble();
  }

  // Factorial function
  int factorial(int n) {
    if (n < 0) throw ArgumentError("Negative numbers not allowed");
    if (n == 0 || n == 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  // Helper method for improved result display
  // Widget _buildResultBox(String resultText) {
  //   return Container(
  //     width: double.infinity,
  //     height: 120, // Increased height for better visibility
  //     margin: const EdgeInsets.only(top: 16),
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [
  //           const Color(0xFF1A1F2E).withOpacity(0.9),
  //           const Color(0xFF2A2F3E).withOpacity(0.9),
  //         ],
  //       ),
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.4)),
  //       boxShadow: [
  //         BoxShadow(
  //           color: const Color(0xFF00E5FF).withOpacity(0.3),
  //           blurRadius: 12,
  //           spreadRadius: 2,
  //         ),
  //       ],
  //     ),
  //     child: FittedBox(
  //       fit: BoxFit.scaleDown,
  //       child: Text(
  //         resultText,
  //         style: const TextStyle(
  //           color: Colors.white,
  //           fontSize: 18,
  //           fontWeight: FontWeight.w500,
  //           fontFamily: 'Roboto',
  //         ),
  //         textAlign: TextAlign.center,
  //         maxLines: 10,
  //         overflow: TextOverflow.ellipsis,
  //       ),
  //     ),
  //   );
  // }

  void openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B0F1A).withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_up, color: Color(0xFF00E5FF)),
                      const SizedBox(width: 12),
                      const Text(
                        'Button Sound',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const Spacer(),
                      Switch(
                        value: widget.soundOn,
                        activeColor: const Color(0xFF00E5FF),
                        onChanged: (v) {
                          widget.onSoundChanged(v);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showHistoryDialog();
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.history, color: Color(0xFF00E5FF)),
                        SizedBox(width: 12),
                        Text(
                          'Calculation History',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B0F1A),
        title: const Text('Calculation History', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: calculationHistory.isEmpty
              ? const Center(child: Text('No calculations yet', style: TextStyle(color: Colors.white70)))
              : ListView.builder(
                  itemCount: calculationHistory.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                      ),
                      child: Text(
                        calculationHistory[index],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                calculationHistory.clear();
              });
              _saveHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear History', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
        ],
      ),
    );
  }

  void switchCalculator(String calculator) {
    setState(() {
      activeCalculator = calculator;
      switchCount++;
      display = '0';
      previousValue = '';
      operation = '';
      waitingForOperand = false;
      history = '';
      _currentInputField = null; // Reset input field
    });
    
    Navigator.pop(context);
    
    // Show ad on every 2nd switch
    if (switchCount % 2 == 0) {
      // Ad logic would go here
    }
  }

  Widget buildDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (history.isNotEmpty)
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: Text(
                    history,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white60,
                      fontFamily: 'Roboto',
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.bottomRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: Text(
                  display,
                  style: const TextStyle(
                    fontSize: 42,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                    shadows: [
                      Shadow(
                        color: Color(0xFF00E5FF),
                        blurRadius: 12,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(String label, {bool isWide = false}) {
    return Container(
      margin: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onButtonPressed(label),
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xFF00E5FF).withOpacity(0.3),
          highlightColor: const Color(0xFF7A33FF).withOpacity(0.2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.9),
                  const Color(0xFF7A33FF).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDrawerItem(String title, IconData icon, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: isSelected 
            ? const LinearGradient(
                colors: [Color(0xFF00E5FF), Color(0xFF7A33FF)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected 
            ? Border.all(color: const Color(0xFF00E5FF), width: 1)
            : null,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00E5FF),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () => switchCalculator(title),
      ),
    );
  }

  Widget buildCalculatorScreen() {
    switch (activeCalculator) {
      case 'Basic':
        return buildBasicCalculator();
      case 'Scientific':
        return buildScientificCalculator();
      case 'EMI':
        return buildEMICalculator();
      case 'SIP':
        return buildSIPCalculator();
      case 'Lump Sum':
        return buildLumpSumCalculator();
      case 'SWP':
        return buildSWPCalculator();
      case 'Discount':
        return buildDiscountCalculator();
      case 'BMI':
        return buildBMICalculator();
      case 'GST':
        return buildGSTCalculator();
      case 'Unit Converter':
        return buildUnitConverterCalculator();
      case 'Currency':
        return buildCurrencyConverterCalculator();
      case 'Date':
        return buildDateCalculator();
      case 'Percentage':
        return buildPercentageCalculator();
      case 'Age':
        return buildAgeCalculator();
      case 'Area/Volume':
        return buildAreaVolumeCalculator();
      case 'Loan':
        return buildLoanCalculator();
      default:
        return buildBasicCalculator();
    }
  }

  Widget buildBasicCalculator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: buildButton('AC')),
                Expanded(child: buildButton('C')),
                Expanded(child: buildButton('%')),
                Expanded(child: buildButton('÷')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: buildButton('7')),
                Expanded(child: buildButton('8')),
                Expanded(child: buildButton('9')),
                Expanded(child: buildButton('×')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: buildButton('4')),
                Expanded(child: buildButton('5')),
                Expanded(child: buildButton('6')),
                Expanded(child: buildButton('-')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: buildButton('1')),
                Expanded(child: buildButton('2')),
                Expanded(child: buildButton('3')),
                Expanded(child: buildButton('+')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 11,
            child: Row(
              children: [
                Expanded(child: buildButton('0')),
                Expanded(child: buildButton('.')),
                Expanded(child: buildButton('=')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildScientificCalculator() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('AC')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('C')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('log')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('√')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('sin')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('cos')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('tan')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('÷')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('x²')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('x³')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('π')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('×')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('e')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('(')),
                const SizedBox(width: 4),
                Expanded(child: buildButton(')')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('-')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('7')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('8')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('9')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('+')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('4')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('5')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('6')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('!')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('1')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('2')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('3')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('in')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Expanded(child: buildButton('0')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('.')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('^')),
                const SizedBox(width: 4),
                Expanded(child: buildButton('=')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEMICalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextFieldInput('Loan Amount (₹)', 'loanAmount'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Interest Rate (%)', 'interestRate'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Loan Tenure (Years)', 'tenure'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateEMI,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate EMI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          // Result box removed - using individual calculator screens
        ],
      ),
    );
  }

  Widget buildSIPCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextFieldInput('Monthly Investment (₹)', 'monthlyInvestment'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Expected Return (%)', 'expectedReturn'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Investment Period (Years)', 'investmentPeriod'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateSIP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate SIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          // Result box removed - using individual calculator screens
        ],
      ),
    );
  }

  Widget buildLumpSumCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextFieldInput('Investment Amount (₹)', 'investmentAmount'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Expected Return (%)', 'expectedReturn'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Investment Period (Years)', 'investmentPeriod'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateLumpSum,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate Lump Sum', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDiscountCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Original Price (₹)', 'originalPrice'),
          const SizedBox(height: 16),
          _buildTextFieldInput('Discount Percentage (%)', 'discountPercentage'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateDiscount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate Discount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          // Result box removed - using individual calculator screens
        ],
      ),
    );
  }

  Widget buildBMICalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Age (Years)', 'age'),
          const SizedBox(height: 16),
          _buildDropdown('Gender', 'gender', ['Male', 'Female']),
          const SizedBox(height: 16),
          _buildTextFieldInput('Height (cm)', 'height'),
          const SizedBox(height: 16),
          _buildTextFieldInput('Weight (kg)', 'weight'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateBMI,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Calculate BMI', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget buildGSTCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Amount (₹)', 'amount'),
          const SizedBox(height: 16),
          _buildTextFieldInput('GST Rate (%)', 'gstRate'),
          const SizedBox(height: 16),
          _buildDropdown('GST Type', 'gstType', ['Add GST', 'Remove GST']),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateGST,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate GST', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUnitConverterCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Value', 'value'),
          const SizedBox(height: 16),
          _buildDropdown('From Unit', 'fromUnit', ['Meter', 'Kilometer', 'Centimeter', 'Inch', 'Foot', 'Yard']),
          const SizedBox(height: 16),
          _buildDropdown('To Unit', 'toUnit', ['Meter', 'Kilometer', 'Centimeter', 'Inch', 'Foot', 'Yard']),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _convertUnit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Convert', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCurrencyConverterCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Amount', 'amount'),
          const SizedBox(height: 16),
          _buildDropdown('From Currency', 'fromCurrency', ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'SEK', 'NZD', 'MXN', 'SGD', 'HKD', 'NOK', 'TRY', 'RUB', 'ZAR', 'BRL', 'KRW']),
          const SizedBox(height: 16),
          _buildDropdown('To Currency', 'toCurrency', ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'SEK', 'NZD', 'MXN', 'SGD', 'HKD', 'NOK', 'TRY', 'RUB', 'ZAR', 'BRL', 'KRW']),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _convertCurrency,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              child: const Text('Convert Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDateCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDatePicker('Start Date', 'startDate'),
          const SizedBox(height: 16),
          _buildDatePicker('End Date', 'endDate'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateDate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
              ),
              child: const Text('Calculate Days', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          if (display != '0' && display.contains('Date'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                display,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPercentageCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildTextFieldInput('Number', 'number'),
          const SizedBox(height: 16),
          _buildTextFieldInput('Percentage (%)', 'percentage'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculatePercentage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate Percentage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          // Result box removed - using individual calculator screens
        ],
      ),
    );
  }

  Widget buildAgeCalculator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDatePicker('Birth Date', 'birthDate'),
          const SizedBox(height: 16),
          _buildDatePicker('Current Date', 'currentDate'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculateAge,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Calculate Age', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 24),
          if (display != '0' && display.contains('Age'))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              ),
              child: Text(
                display,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget buildAreaVolumeCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildDropdown('Shape', 'shape', ['Circle', 'Rectangle', 'Triangle', 'Sphere', 'Cylinder', 'Cube']),
          const SizedBox(height: 16),
          _buildTextFieldInput('Length/Radius', 'length'),
          const SizedBox(height: 16),
          _buildTextFieldInput('Width/Height', 'width'),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateAreaVolume,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSWPCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextFieldInput('Initial Investment (₹)', 'initialInvestment'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Annual Return Rate (%)', 'annualReturnRate'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Withdrawal Amount (₹)', 'withdrawalAmount'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Period (Years)', 'period'),
          const SizedBox(height: 12),
          _buildDropdown('Frequency', 'frequency', ['Monthly', 'Quarterly', 'Yearly']),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateSWP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate SWP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoanCalculator() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextFieldInput('Loan Amount (₹)', 'loanAmount'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Interest Rate (%)', 'interestRate'),
          const SizedBox(height: 12),
          _buildTextFieldInput('Loan Tenure (Years)', 'tenure'),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculateLoan,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('Calculate Loan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for input fields and calculations
  Map<String, dynamic> calculatorState = {};
  Map<String, TextEditingController> _textControllers = {};

  // Widget _buildInputField(String label, String key) {
  //   // Initialize field if not exists
  //   if (!calculatorState.containsKey(key)) {
  //     calculatorState[key] = '0';
  //   }
  //   
  //   return GestureDetector(
  //     onTap: () {
  //       // Set current input field for keypad input
  //       setState(() {
  //         _currentInputField = key;
  //       });
  //     },
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           colors: [
  //             Colors.white.withOpacity(0.1),
  //             Colors.white.withOpacity(0.05),
  //           ],
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //         ),
  //         borderRadius: BorderRadius.circular(16),
  //         border: Border.all(
  //           color: _currentInputField == key 
  //               ? const Color(0xFF00E5FF) 
  //               : const Color(0xFF00E5FF).withOpacity(0.3),
  //           width: _currentInputField == key ? 2 : 1,
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: _currentInputField == key 
  //                 ? const Color(0xFF00E5FF).withOpacity(0.3)
  //                 : Colors.black.withOpacity(0.1),
  //             blurRadius: _currentInputField == key ? 8 : 4,
  //             spreadRadius: 1,
  //           ),
  //         ],
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   label,
  //                   style: const TextStyle(
  //                     color: Colors.white70,
  //                     fontSize: 12,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 6),
  //                 Text(
  //                   calculatorState[key]?.toString() ?? '0',
  //                   style: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.w600,
  //                     fontFamily: 'Roboto',
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           Icon(
  //             _currentInputField == key ? Icons.keyboard : Icons.touch_app,
  //             color: _currentInputField == key ? const Color(0xFF00E5FF) : Colors.white70,
  //             size: 20,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTextFieldInput(String label, String key) {
    // Initialize controller if not exists
    if (!_textControllers.containsKey(key)) {
      _textControllers[key] = TextEditingController();
    }
    
    // Initialize calculator state if not exists
    if (!calculatorState.containsKey(key)) {
      calculatorState[key] = '';
    }
    
    // Sync controller text with calculator state
    if (_textControllers[key]!.text != (calculatorState[key]?.toString() ?? '')) {
      _textControllers[key]!.text = calculatorState[key]?.toString() ?? '';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextField(
        controller: _textControllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: 'Enter value',
          hintStyle: const TextStyle(
            color: Colors.white38,
            fontSize: 16,
          ),
        ),
        onChanged: (value) {
          // Update calculator state without calling setState to avoid losing focus
          calculatorState[key] = value;
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String key, List<String> options) {
    return DropdownButtonFormField<String>(
      value: calculatorState[key] ?? options.first,
      onChanged: (value) {
        setState(() {
          calculatorState[key] = value;
        });
      },
      dropdownColor: const Color(0xFF1A1F2E),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E5FF)),
        ),
      ),
      items: options.map((option) => DropdownMenuItem(
        value: option,
        child: Text(option, style: const TextStyle(color: Colors.white)),
      )).toList(),
    );
  }

  Widget _buildDatePicker(String label, String key) {
    String currentDate = calculatorState[key]?.toString() ?? DateTime.now().toString().split(' ')[0];
    
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(currentDate) ?? DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Color(0xFF00E5FF),
                  onPrimary: Colors.white,
                  surface: Color(0xFF1A1F2E),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        
        if (picked != null) {
          setState(() {
            calculatorState[key] = picked.toString().split(' ')[0];
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.calendar_today,
              color: Color(0xFF00E5FF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  void _calculateEMI() {
    double amount = double.tryParse(_textControllers['loanAmount']?.text ?? '') ?? 0;
    double rate = double.tryParse(_textControllers['interestRate']?.text ?? '') ?? 0;
    double tenure = double.tryParse(_textControllers['tenure']?.text ?? '') ?? 0;
    
    if (amount > 0 && rate > 0 && tenure > 0) {
      double monthlyRate = rate / 12 / 100;
      double months = tenure * 12;
      double emi = (amount * monthlyRate * pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1);
      double total = emi * months;
      // double interest = total - amount; // Removed unused variable
      
      // Display removed - using individual calculator screens
      addToHistory('EMI Calculation: ₹${amount.toStringAsFixed(0)} @ $rate% for $tenure years = ₹${emi.toStringAsFixed(2)}');
    }
  }

  void _calculateSIP() {
    double investment = double.tryParse(_textControllers['monthlyInvestment']?.text ?? '') ?? 0;
    double returnRate = double.tryParse(_textControllers['expectedReturn']?.text ?? '') ?? 0;
    double period = double.tryParse(_textControllers['investmentPeriod']?.text ?? '') ?? 0;
    
    if (investment > 0 && returnRate > 0 && period > 0) {
      double monthlyRate = returnRate / 12 / 100;
      double months = period * 12;
      double maturity = investment * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);
      double total = investment * months;
      // double returns = maturity - total; // Removed unused variable
      
      // Display removed - using individual calculator screens
      addToHistory('SIP: ₹${investment.toStringAsFixed(0)}/month @ $returnRate% for $period years = ₹${maturity.toStringAsFixed(2)}');
    }
  }

  void _calculateLumpSum() {
    double amount = double.tryParse(_textControllers['investmentAmount']?.text ?? '') ?? 0;
    double returnRate = double.tryParse(_textControllers['expectedReturn']?.text ?? '') ?? 0;
    double period = double.tryParse(_textControllers['investmentPeriod']?.text ?? '') ?? 0;
    
    if (amount > 0 && returnRate > 0 && period > 0) {
      double maturity = amount * pow(1 + returnRate / 100, period);
      double returns = maturity - amount;
      
      setState(() {
        display = 'Lump Sum Maturity: ₹${maturity.toStringAsFixed(2)}\nReturns: ₹${returns.toStringAsFixed(2)}';
      });
      addToHistory('Lump Sum: ₹${amount.toStringAsFixed(0)} @ $returnRate% for $period years = ₹${maturity.toStringAsFixed(2)}');
    }
  }

  void _calculateDiscount() {
    double originalPrice = double.tryParse(_textControllers['originalPrice']?.text ?? '') ?? 0;
    double discountPercentage = double.tryParse(_textControllers['discountPercentage']?.text ?? '') ?? 0;
    
    if (originalPrice > 0 && discountPercentage > 0) {
      double discountAmount = originalPrice * discountPercentage / 100;
      double finalPrice = originalPrice - discountAmount;
      
      // Display removed - using individual calculator screens
      addToHistory('Discount: ₹${originalPrice.toStringAsFixed(0)} - ${discountPercentage}% = ₹${finalPrice.toStringAsFixed(2)}');
    }
  }

  void _calculateBMI() {
    double age = double.tryParse(_textControllers['age']?.text ?? '') ?? 0;
    String gender = calculatorState['gender'] ?? 'Male';
    double height = double.tryParse(_textControllers['height']?.text ?? '') ?? 0;
    double weight = double.tryParse(_textControllers['weight']?.text ?? '') ?? 0;
    
    if (age > 0 && height > 0 && weight > 0) {
      double heightInMeters = height / 100;
      double bmi = weight / (heightInMeters * heightInMeters);
      String category;
      
      if (bmi < 18.5) {
        category = 'Underweight';
      } else if (bmi < 25) {
        category = 'Normal';
      } else if (bmi < 30) {
        category = 'Overweight';
      } else {
        category = 'Obese';
      }
      
      setState(() {
        display = 'BMI: ${bmi.toStringAsFixed(1)}\nCategory: $category\nAge: ${age.toInt()}, Gender: $gender';
      });
      addToHistory('BMI: ${age.toInt()}yr $gender, ${height.toInt()}cm, ${weight.toInt()}kg = ${bmi.toStringAsFixed(1)} ($category)');
    }
  }

  void _calculateGST() {
    double amount = double.tryParse(_textControllers['amount']?.text ?? '') ?? 0;
    double gstRate = double.tryParse(_textControllers['gstRate']?.text ?? '') ?? 0;
    String gstType = calculatorState['gstType'] ?? 'Add GST';
    
    if (amount > 0 && gstRate > 0) {
      double gstAmount;
      double finalAmount;
      
      if (gstType == 'Add GST') {
        gstAmount = amount * gstRate / 100;
        finalAmount = amount + gstAmount;
        setState(() {
          display = 'GST Amount: ₹${gstAmount.toStringAsFixed(2)}\nFinal Amount: ₹${finalAmount.toStringAsFixed(2)}';
        });
      } else {
        gstAmount = amount * gstRate / (100 + gstRate);
        finalAmount = amount - gstAmount;
        setState(() {
          display = 'GST Amount: ₹${gstAmount.toStringAsFixed(2)}\nBase Amount: ₹${finalAmount.toStringAsFixed(2)}';
        });
      }
      addToHistory('GST: ₹${amount.toStringAsFixed(0)} @ ${gstRate}% ($gstType) = ₹${finalAmount.toStringAsFixed(2)}');
    }
  }

  void _convertUnit() {
    double value = double.tryParse(_textControllers['value']?.text ?? '') ?? 0;
    String fromUnit = calculatorState['fromUnit'] ?? 'Meter';
    String toUnit = calculatorState['toUnit'] ?? 'Meter';
    
    if (value > 0) {
      // Convert to meters first
      double inMeters = value;
      switch (fromUnit) {
        case 'Kilometer': inMeters = value * 1000; break;
        case 'Centimeter': inMeters = value / 100; break;
        case 'Inch': inMeters = value * 0.0254; break;
        case 'Foot': inMeters = value * 0.3048; break;
        case 'Yard': inMeters = value * 0.9144; break;
      }
      
      // Convert from meters to target unit
      double result = inMeters;
      switch (toUnit) {
        case 'Kilometer': result = inMeters / 1000; break;
        case 'Centimeter': result = inMeters * 100; break;
        case 'Inch': result = inMeters / 0.0254; break;
        case 'Foot': result = inMeters / 0.3048; break;
        case 'Yard': result = inMeters / 0.9144; break;
      }
      
      setState(() {
        display = 'Convert: ${value.toStringAsFixed(2)} $fromUnit = ${result.toStringAsFixed(4)} $toUnit';
      });
      addToHistory('Convert: ${value.toStringAsFixed(2)} $fromUnit = ${result.toStringAsFixed(4)} $toUnit');
    }
  }

  Future<double> fetchExchangeRate(String from, String to) async {
    final response = await http.get(
      Uri.parse('https://api.frankfurter.app/latest?from=$from&to=$to')
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["rates"][to];
    } else {
      throw Exception("Failed to fetch exchange rate");
    }
  }

  void _convertCurrency() async {
    double amount = double.tryParse(_textControllers['amount']?.text ?? '') ?? 0;
    String fromCurrency = calculatorState['fromCurrency'] ?? 'USD';
    String toCurrency = calculatorState['toCurrency'] ?? 'USD';
    
    if (amount > 0) {
      setState(() {
        display = 'Loading...';
      });
      
      try {
        // Check cache first
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('currency_${fromCurrency}_$toCurrency');
        final cacheTime = prefs.getInt('currency_${fromCurrency}_${toCurrency}_time') ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Use cache if less than 30 minutes old
        if (cachedData != null && (now - cacheTime) < 30 * 60 * 1000) {
          final rate = double.parse(cachedData);
          double result = amount * rate;
          final minutesOld = ((now - cacheTime) / (60 * 1000)).round();
          
          setState(() {
            display = 'Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency\nRate: 1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency\n(Using cached rate - ${minutesOld} mins old)';
          });
          addToHistory('Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency (cached)');
          return;
        }
        
        // Fetch fresh data from Frankfurter API
        final response = await http.get(
          Uri.parse('https://api.frankfurter.app/latest?from=$fromCurrency&to=$toCurrency'),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['rates'] != null && data['rates'][toCurrency] != null) {
            double rate = data['rates'][toCurrency].toDouble();
            double result = amount * rate;
            String date = data['date'] ?? 'Unknown';
            
            // Cache the result
            await prefs.setString('currency_${fromCurrency}_$toCurrency', rate.toString());
            await prefs.setInt('currency_${fromCurrency}_${toCurrency}_time', now);
            
            setState(() {
              display = 'Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency\nRate: 1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency\n(Live rate from ECB - $date)';
            });
            addToHistory('Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency');
          } else {
            setState(() {
              display = 'Error: Invalid response from Frankfurter API';
            });
          }
        } else {
          setState(() {
            display = 'Error: Failed to fetch rates (${response.statusCode})';
          });
        }
      } catch (e) {
        // Try to use cached data on network error
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString('currency_${fromCurrency}_$toCurrency');
        
        if (cachedData != null) {
          final rate = double.parse(cachedData);
          double result = amount * rate;
          
          setState(() {
            display = 'Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency\nRate: 1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency\n(Using cached rate - network error)';
          });
          addToHistory('Currency: ${amount.toStringAsFixed(2)} $fromCurrency = ${result.toStringAsFixed(2)} $toCurrency (cached)');
        } else {
          setState(() {
            display = 'Unable to fetch rates. Please check your connection.';
          });
        }
      }
    }
  }

  void _calculateDate() {
    String startDate = calculatorState['startDate']?.toString() ?? '';
    String endDate = calculatorState['endDate']?.toString() ?? '';
    
    if (startDate.isNotEmpty && endDate.isNotEmpty) {
      try {
        DateTime start = DateTime.parse(startDate);
        DateTime end = DateTime.parse(endDate);
        int days = end.difference(start).inDays;
        
        setState(() {
          display = 'Date Calculation: $days days between $startDate and $endDate';
        });
        addToHistory('Date: $startDate to $endDate = $days days');
      } catch (e) {
        setState(() {
          display = 'Invalid date format. Use YYYY-MM-DD';
        });
      }
    }
  }

  void _calculatePercentage() {
    double number = double.tryParse(_textControllers['number']?.text ?? '') ?? 0;
    double percentage = double.tryParse(_textControllers['percentage']?.text ?? '') ?? 0;
    
    if (number > 0 && percentage > 0) {
      double result = number * percentage / 100;
      
      // Display removed - using individual calculator screens
      addToHistory('Percentage: ${percentage}% of ${number} = ${result.toStringAsFixed(2)}');
    }
  }

  void _calculateAge() {
    String birthDate = calculatorState['birthDate']?.toString() ?? '';
    String currentDate = calculatorState['currentDate']?.toString() ?? '';
    
    if (birthDate.isNotEmpty && currentDate.isNotEmpty) {
      try {
        DateTime birth = DateTime.parse(birthDate);
        DateTime current = DateTime.parse(currentDate);
        int years = current.year - birth.year;
        int months = current.month - birth.month;
        int days = current.day - birth.day;
        
        if (days < 0) {
          months--;
          days += DateTime(current.year, current.month, 0).day;
        }
        if (months < 0) {
          years--;
          months += 12;
        }
        
        setState(() {
          display = 'Age: $years years, $months months, $days days';
        });
        addToHistory('Age: $birthDate to $currentDate = $years years, $months months, $days days');
      } catch (e) {
        setState(() {
          display = 'Invalid date format. Use YYYY-MM-DD';
        });
      }
    }
  }

  void _calculateAreaVolume() {
    String shape = calculatorState['shape'] ?? 'Circle';
    double length = double.tryParse(_textControllers['length']?.text ?? '') ?? 0;
    double width = double.tryParse(_textControllers['width']?.text ?? '') ?? 0;
    
    if (length > 0) {
      double result = 0;
      String unit = '';
      
      switch (shape) {
        case 'Circle':
          result = 3.14159 * length * length;
          unit = 'sq units';
          break;
        case 'Rectangle':
          result = length * width;
          unit = 'sq units';
          break;
        case 'Triangle':
          result = 0.5 * length * width;
          unit = 'sq units';
          break;
        case 'Sphere':
          result = (4/3) * 3.14159 * length * length * length;
          unit = 'cubic units';
          break;
        case 'Cylinder':
          result = 3.14159 * length * length * width;
          unit = 'cubic units';
          break;
        case 'Cube':
          result = length * length * length;
          unit = 'cubic units';
          break;
      }
      
      setState(() {
        display = 'Area/Volume: $shape = ${result.toStringAsFixed(2)} $unit';
      });
      addToHistory('Area/Volume: $shape (${length}x${width}) = ${result.toStringAsFixed(2)} $unit');
    }
  }

  void _calculateSWP() {
    double initialInvestment = double.tryParse(_textControllers['initialInvestment']?.text ?? '') ?? 0;
    double annualReturnRate = double.tryParse(_textControllers['annualReturnRate']?.text ?? '') ?? 0;
    double withdrawalAmount = double.tryParse(_textControllers['withdrawalAmount']?.text ?? '') ?? 0;
    double period = double.tryParse(_textControllers['period']?.text ?? '') ?? 0;
    String frequency = calculatorState['frequency']?.toString() ?? 'Monthly';
    
    if (initialInvestment > 0 && annualReturnRate > 0 && withdrawalAmount > 0 && period > 0) {
      // Calculate periods per year based on frequency
      int periodsPerYear = 1;
      switch (frequency) {
        case 'Monthly': periodsPerYear = 12; break;
        case 'Quarterly': periodsPerYear = 4; break;
        case 'Yearly': periodsPerYear = 1; break;
      }
      
      double periodRate = annualReturnRate / 100 / periodsPerYear;
      int totalPeriods = (period * periodsPerYear).round();
      
      // Simulate SWP
      double balance = initialInvestment;
      double totalWithdrawn = 0;
      double totalReturns = 0;
      int periodsUntilExhausted = 0;
      
      for (int i = 0; i < totalPeriods; i++) {
        if (balance <= 0) break;
        
        // Add returns
        double returns = balance * periodRate;
        balance += returns;
        totalReturns += returns;
        
        // Withdraw
        if (balance >= withdrawalAmount) {
          balance -= withdrawalAmount;
          totalWithdrawn += withdrawalAmount;
          periodsUntilExhausted = i + 1;
        } else {
          totalWithdrawn += balance;
          balance = 0;
          periodsUntilExhausted = i + 1;
          break;
        }
      }
      
      setState(() {
        display = 'SWP Results:\n'
            'Periods until exhausted: $periodsUntilExhausted\n'
            'Total withdrawn: ₹${totalWithdrawn.toStringAsFixed(2)}\n'
            'Total returns: ₹${totalReturns.toStringAsFixed(2)}\n'
            'Remaining balance: ₹${balance.toStringAsFixed(2)}';
      });
      addToHistory('SWP: ₹${initialInvestment.toStringAsFixed(0)} @ ${annualReturnRate}% ${frequency} withdrawal ₹${withdrawalAmount.toStringAsFixed(0)} = ${periodsUntilExhausted} periods');
    }
  }

  void _calculateLoan() {
    double amount = double.tryParse(_textControllers['loanAmount']?.text ?? '') ?? 0;
    double rate = double.tryParse(_textControllers['interestRate']?.text ?? '') ?? 0;
    double tenure = double.tryParse(_textControllers['tenure']?.text ?? '') ?? 0;
    
    if (amount > 0 && rate > 0 && tenure > 0) {
      double monthlyRate = rate / 12 / 100;
      double months = tenure * 12;
      double emi = (amount * monthlyRate * pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1);
      double total = emi * months;
      double interest = total - amount;
      
      setState(() {
        display = 'Loan EMI: ₹${emi.toStringAsFixed(2)}\nTotal Payment: ₹${total.toStringAsFixed(2)}\nInterest: ₹${interest.toStringAsFixed(2)}';
      });
      addToHistory('Loan: ₹${amount.toStringAsFixed(0)} @ ${rate}% for ${tenure} years = ₹${emi.toStringAsFixed(2)} EMI');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawerEnableOpenDragGesture: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B0F1A),
              Color(0xFF1A0F2E),
              Color(0xFF2A0F3E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          endDrawerEnableOpenDragGesture: true,
      endDrawer: Drawer(
        backgroundColor: const Color(0xFF0B0F1A).withOpacity(0.95),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Calculators',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    children: [
                      buildDrawerItem('Basic', Icons.calculate, activeCalculator == 'Basic'),
                      buildDrawerItem('Scientific', Icons.functions, activeCalculator == 'Scientific'),
                      buildDrawerItem('EMI', Icons.account_balance, activeCalculator == 'EMI'),
                      buildDrawerItem('SIP', Icons.savings, activeCalculator == 'SIP'),
                      buildDrawerItem('Lump Sum', Icons.bar_chart, activeCalculator == 'Lump Sum'),
                      buildDrawerItem('SWP', Icons.trending_down, activeCalculator == 'SWP'),
                      buildDrawerItem('Discount', Icons.local_offer, activeCalculator == 'Discount'),
                      buildDrawerItem('BMI', Icons.person, activeCalculator == 'BMI'),
                      buildDrawerItem('GST', Icons.receipt, activeCalculator == 'GST'),
                      buildDrawerItem('Unit Converter', Icons.swap_horiz, activeCalculator == 'Unit Converter'),
                      buildDrawerItem('Currency', Icons.attach_money, activeCalculator == 'Currency'),
                      buildDrawerItem('Date', Icons.calendar_today, activeCalculator == 'Date'),
                      buildDrawerItem('Percentage', Icons.percent, activeCalculator == 'Percentage'),
                      buildDrawerItem('Age', Icons.cake, activeCalculator == 'Age'),
                      buildDrawerItem('Area/Volume', Icons.crop_square, activeCalculator == 'Area/Volume'),
                      buildDrawerItem('Loan', Icons.credit_card, activeCalculator == 'Loan'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          activeCalculator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF00E5FF)),
            onPressed: openSettings,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1F2E), Color(0xFF2A2F3E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF00E5FF)),
                onPressed: () => Scaffold.of(ctx).openEndDrawer(),
              ),
            ),
          ),
        ],
      ),
          body: SafeArea(
            child: Column(
              children: [
                // Display area - 50% of screen
                Expanded(
                  flex: 1,
                  child: buildDisplay(),
                ),
                // Calculator screen area - 50% of screen
                Expanded(
                  flex: 1,
                  child: buildCalculatorScreen(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}