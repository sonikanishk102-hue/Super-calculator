import 'package:flutter/material.dart';
import '../services/sound_manager.dart';

class PercentageCalculatorScreen extends StatefulWidget {
  const PercentageCalculatorScreen({super.key});

  @override
  State<PercentageCalculatorScreen> createState() => _PercentageCalculatorScreenState();
}

class _PercentageCalculatorScreenState extends State<PercentageCalculatorScreen> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _percentageController = TextEditingController();
  final TextEditingController _obtainedController = TextEditingController();
  final SoundManager _soundManager = SoundManager();
  
  String _selectedMode = 'Find Number from Percentage';
  double _value = 0;
  double _percentage = 0;
  double _obtained = 0;
  double _result = 0;

  Future<void> _playButtonSound() async {
    await _soundManager.playButtonSound();
  }

  void _calculatePercentage() {
    _playButtonSound();
    
    final value = double.tryParse(_valueController.text) ?? 0;
    
    if (value > 0) {
      setState(() {
        _value = value;
        
        if (_selectedMode == 'Find Number from Percentage') {
          final percentage = double.tryParse(_percentageController.text) ?? 0;
          if (percentage >= 0) {
            _percentage = percentage;
            _result = (value * percentage) / 100;
          }
        } else {
          final obtained = double.tryParse(_obtainedController.text) ?? 0;
          if (obtained >= 0) {
            _obtained = obtained;
            _result = (obtained / value) * 100;
          }
        }
      });
    }
  }

  void _clearAll() {
    _playButtonSound();
    setState(() {
      _valueController.clear();
      _percentageController.clear();
      _obtainedController.clear();
      _value = 0;
      _percentage = 0;
      _obtained = 0;
      _result = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Text(
            'Percentage Calculator',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 30),
          
          // Results - At the very top
          if (_value > 0) ...[
            _buildResultBox(),
            const SizedBox(height: 30),
          ],
          
          // Mode Selection Dropdown
          _buildModeDropdown(),
          const SizedBox(height: 20),
          
          // Input Fields
          _buildInputField(
            controller: _valueController,
            label: 'Base Number',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          if (_selectedMode == 'Find Number from Percentage')
            _buildInputField(
              controller: _percentageController,
              label: 'Percentage %',
              icon: Icons.percent,
              keyboardType: TextInputType.number,
            )
          else
            _buildInputField(
              controller: _obtainedController,
              label: 'Obtained Number',
              icon: Icons.calculate,
              keyboardType: TextInputType.number,
            ),
          const SizedBox(height: 30),
          
          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _calculatePercentage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FFFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Calculate Percentage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Clear Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _clearAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _selectedMode == 'Find Number from Percentage'
                ? 'Enter a base number and percentage to find what number that percentage represents.'
                : 'Enter a base number and obtained number to find what percentage the obtained number represents.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBox() {
    return Container(
      width: double.infinity,
      height: 250, // Increased height
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00FFFF), Color(0xFF8A2BE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FFFF).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Percentage Calculation Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 28), // Increased spacing
          
          // Main Result
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Result',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                _buildAutoSizedText(
                  _selectedMode == 'Find Number from Percentage' 
                    ? _result.toStringAsFixed(2)
                    : '${_result.toStringAsFixed(2)}%',
                  maxFontSize: 40,
                  minFontSize: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedMode == 'Find Number from Percentage'
                    ? '${_percentage.toStringAsFixed(1)}% of ${_value.toStringAsFixed(2)}'
                    : '${_obtained.toStringAsFixed(2)} is ${_result.toStringAsFixed(2)}% of ${_value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary Details
          Row(
            children: [
              Expanded(
                child: _buildSummaryDetail('Base Number', _value.toStringAsFixed(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryDetail(
                  _selectedMode == 'Find Number from Percentage' ? 'Percentage' : 'Obtained Number',
                  _selectedMode == 'Find Number from Percentage' 
                    ? '${_percentage.toStringAsFixed(1)}%'
                    : _obtained.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSizedText(String text, {double maxFontSize = 24, double minFontSize = 12}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate font size based on text length and available width
        double fontSize = maxFontSize;
        if (text.length > 12) {
          fontSize = maxFontSize * 0.9;
        }
        if (text.length > 18) {
          fontSize = maxFontSize * 0.8;
        }
        if (text.length > 25) {
          fontSize = maxFontSize * 0.7;
        }
        if (text.length > 35) {
          fontSize = maxFontSize * 0.6;
        }
        if (text.length > 50) {
          fontSize = maxFontSize * 0.5;
        }
        
        fontSize = fontSize.clamp(minFontSize, maxFontSize);
        
        return Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildSummaryDetail(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF00FFFF),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }


  Widget _buildModeDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00FFFF), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMode,
          isExpanded: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: Color(0xFF00FFFF),
          ),
          items: const [
            DropdownMenuItem(
              value: 'Find Number from Percentage',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Find Number from Percentage'),
              ),
            ),
            DropdownMenuItem(
              value: 'Find Percentage from Number',
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('Find Percentage from Number'),
              ),
            ),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedMode = newValue;
                // Clear the result when switching modes
                _result = 0;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _valueController.dispose();
    _percentageController.dispose();
    _obtainedController.dispose();
    super.dispose();
  }
}
