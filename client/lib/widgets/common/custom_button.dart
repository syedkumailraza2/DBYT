import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final double? width;
  final double height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.width,
    this.height = 56,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : widget.width,
          height: widget.height,
          child: _buildButton(),
        ),
      ),
    );
  }

  Widget _buildButton() {
    switch (widget.type) {
      case ButtonType.primary:
        return _buildPrimaryButton();
      case ButtonType.secondary:
        return _buildSecondaryButton();
      case ButtonType.outlined:
        return _buildOutlinedButton();
      case ButtonType.text:
        return _buildTextButton();
    }
  }

  Widget _buildPrimaryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.onPressed != null && !widget.isLoading
            ? AppColors.primaryGradient
            : null,
        color: widget.onPressed == null || widget.isLoading
            ? AppColors.grey400
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: widget.onPressed != null && !widget.isLoading
            ? [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : _buildButtonContent(AppColors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.onPressed != null && !widget.isLoading
            ? AppColors.accentGradient
            : null,
        color: widget.onPressed == null || widget.isLoading
            ? AppColors.grey400
            : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: widget.onPressed != null && !widget.isLoading
            ? [
                BoxShadow(
                  color: AppColors.ctaOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : _buildButtonContent(AppColors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled ? AppColors.primaryTeal : AppColors.grey400,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isEnabled ? AppColors.primaryTeal : AppColors.grey400,
                      ),
                    ),
                  )
                : _buildButtonContent(
                    isEnabled ? AppColors.primaryTeal : AppColors.grey400,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextButton() {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.isLoading ? null : widget.onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isEnabled ? AppColors.ctaBlue : AppColors.grey400,
                    ),
                  ),
                )
              : _buildButtonContent(
                  isEnabled ? AppColors.ctaBlue : AppColors.grey400,
                ),
        ),
      ),
    );
  }

  Widget _buildButtonContent(Color color) {
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.text,
            style: AppTextStyles.buttonLarge.copyWith(color: color),
          ),
        ],
      );
    }
    return Text(
      widget.text,
      style: AppTextStyles.buttonLarge.copyWith(color: color),
    );
  }
}
