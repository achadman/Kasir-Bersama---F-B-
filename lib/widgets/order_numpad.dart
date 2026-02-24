import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OrderNumpadMode { qty, disc, price }

class OrderNumpad extends StatelessWidget {
  final OrderNumpadMode mode;
  final Function(OrderNumpadMode) onModeChanged;
  final Function(String) onTap;
  final VoidCallback onBackspace;
  final VoidCallback onToggleSign;

  const OrderNumpad({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onTap,
    required this.onBackspace,
    required this.onToggleSign,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBtnColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!;
    final activeBtnColor = const Color(0xFFEA5700);
    final defaultTextColor = isDark ? Colors.white : Colors.black87;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double slotWidth = constraints.maxWidth / 4;
        final double slotHeight = (constraints.maxHeight / 4).clamp(40, 60);
        final double fontSize = (slotWidth * 0.25).clamp(16, 20);

        return Column(
          children: [
            _buildRow([
              _buildBtn("1", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("2", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("3", defaultBtnColor, defaultTextColor, fontSize),
              _buildModeBtn("Qty", OrderNumpadMode.qty, activeBtnColor, defaultTextColor, fontSize),
            ], slotHeight),
            _buildRow([
              _buildBtn("4", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("5", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("6", defaultBtnColor, defaultTextColor, fontSize),
              _buildModeBtn("%", OrderNumpadMode.disc, activeBtnColor, defaultTextColor, fontSize),
            ], slotHeight),
            _buildRow([
              _buildBtn("7", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("8", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("9", defaultBtnColor, defaultTextColor, fontSize),
              _buildModeBtn("Price", OrderNumpadMode.price, activeBtnColor, defaultTextColor, fontSize),
            ], slotHeight),
            _buildRow([
              _buildBtn("+/-", defaultBtnColor, defaultTextColor, fontSize, onTap: onToggleSign),
              _buildBtn("0", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn(".", defaultBtnColor, defaultTextColor, fontSize),
              _buildBtn("backspace", defaultBtnColor, defaultTextColor, fontSize, 
                icon: Icons.backspace_outlined, onTap: () => onBackspace()),
            ], slotHeight),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<Widget> children, double height) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildBtn(String value, Color color, Color tColor, double fSize, {IconData? icon, Function()? onTap}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tColor.withOpacity(0.05), width: 0.5),
        ),
        child: Material(
          color: color,
          child: InkWell(
            onTap: onTap ?? () => this.onTap(value),
            child: Center(
              child: icon != null
                  ? Icon(icon, color: tColor, size: fSize * 1.2)
                  : Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: fSize,
                        fontWeight: FontWeight.w600,
                        color: tColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeBtn(String label, OrderNumpadMode targetMode, Color activeColor, Color tColor, double fSize) {
    final isActive = mode == targetMode;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: tColor.withOpacity(0.05), width: 0.5),
        ),
        child: Material(
          color: isActive ? activeColor : Colors.blueGrey.withOpacity(0.1),
          child: InkWell(
            onTap: () => onModeChanged(targetMode),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: fSize * 0.9,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : tColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
