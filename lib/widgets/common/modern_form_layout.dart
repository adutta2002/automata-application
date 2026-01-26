import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../../core/responsive_layout.dart';

class ModernFormLayout extends StatelessWidget {
  final String title;
  final Widget leftCard;
  final Widget rightCard;
  final List<Widget>? actions;

  const ModernFormLayout({
    super.key,
    required this.title,
    required this.leftCard,
    required this.rightCard,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = ResponsiveLayout.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        shape: Border(bottom: BorderSide(color: AppTheme.tableBorderColor)),
        actions: actions,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: isMobile
                ? Column(
                    children: [
                      _buildLeftCard(),
                      const SizedBox(height: 24),
                      _buildRightCard(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: _buildLeftCard(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 8,
                        child: _buildRightCard(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tableBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: leftCard,
    );
  }

  Widget _buildRightCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.tableBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: rightCard,
    );
  }
}

class FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const FormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

class FormFieldWrapper extends StatelessWidget {
  final String label;
  final Widget child;

  const FormFieldWrapper({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
