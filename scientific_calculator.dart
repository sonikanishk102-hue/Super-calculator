import 'package:flutter/material.dart';
import 'dart:math';

class ScientificCalculator extends StatefulWidget {
  final Function(String) onHistoryAdd;
  final bool soundOn;
  final Function() playSound;
  
  const ScientificCalculator({
    super.key,
    required this.onHistoryAdd,
    required this.soundOn,
    required this.playSound,
  });
  
  @override
  State<ScientificCalculator> createState() => _ScientificCalculatorState();
}

class _ScientificCalculatorState extends State<ScientificCalculator> {
  String display = '0';
  String previousValue = '';
  String operation = '';
  bool waitingForOperand = false;
  String history = '';

  void onButtonPressed(String value) {
    widget.playSound();
    
    setState(() {
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
      } else if (value == 'sin') {
        double number = double.tryParse(display) ?? 0;
        double result = sin(number * pi / 180);
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('sin($number°) = $display');
      } else if (value == 'cos') {
        double number = double.tryParse(display) ?? 0;
        double result = cos(number * pi / 180);
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('cos($number°) = $display');
      } else if (value == 'tan') {
        double number = double.tryParse(display) ?? 0;
        double result = tan(number * pi / 180);
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('tan($number°) = $display');
      } else if (value == 'log') {
        double number = double.tryParse(display) ?? 0;
        double result = log(number) / ln10;
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('log($number) = $display');
      } else if (value == 'ln') {
        double number = double.tryParse(display) ?? 0;
        double result = log(number);
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('ln($number) = $display');
      } else if (value == '√') {
        double number = double.tryParse(display) ?? 0;
        double result = sqrt(number);
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('√$number = $display');
      } else if (value == 'x²') {
        double number = double.tryParse(display) ?? 0;
        double result = number * number;
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('$number² = $display');
      } else if (value == 'x³') {
        double number = double.tryParse(display) ?? 0;
        double result = number * number * number;
        display = _formatResult(result);
        waitingForOperand = true;
        widget.onHistoryAdd('$number³ = $display');
      } else if (value == 'π') {
        display = _formatResult(pi);
        waitingForOperand = true;
        widget.onHistoryAdd('π = $display');
      } else if (value == 'e') {
        display = _formatResult(e);
        waitingForOperand = true;
        widget.onHistoryAdd('e = $display');
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
    }

    String formattedResult = _formatResult(result);
    widget.onHistoryAdd('$previousValue $operation $display = $formattedResult');
    
    setState(() {
      display = formattedResult;
      operation = '';
      waitingForOperand = true;
      history = '';
    });
  }

  String _formatResult(double result) {
    if (result == result.toInt()) {
      return result.toInt().toString();
    } else {
      return result.toString();
    }
  }

  Widget buildButton(String label, {bool isWide = false}) {
    return GestureDetector(
      onTap: () => onButtonPressed(label),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF7A33FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('sin')),
                Expanded(child: buildButton('cos')),
                Expanded(child: buildButton('tan')),
                Expanded(child: buildButton('log')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('ln')),
                Expanded(child: buildButton('√')),
                Expanded(child: buildButton('x²')),
                Expanded(child: buildButton('x³')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('π')),
                Expanded(child: buildButton('e')),
                Expanded(child: buildButton('(')),
                Expanded(child: buildButton(')')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('7')),
                Expanded(child: buildButton('8')),
                Expanded(child: buildButton('9')),
                Expanded(child: buildButton('÷')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('4')),
                Expanded(child: buildButton('5')),
                Expanded(child: buildButton('6')),
                Expanded(child: buildButton('×')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('1')),
                Expanded(child: buildButton('2')),
                Expanded(child: buildButton('3')),
                Expanded(child: buildButton('-')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(flex: 2, child: buildButton('0')),
                Expanded(child: buildButton('.')),
                Expanded(child: buildButton('+')),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildButton('AC')),
                Expanded(child: buildButton('C')),
                Expanded(flex: 2, child: buildButton('=')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
