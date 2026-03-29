import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  

  @override
 State<ResetPasswordPage> createState() => _ResetPasswordPageState();
  }


class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final Color _primaryBlue = const Color(0xFF346CB0);
  

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
 
 bool _obscureNew = true;
 bool _obscureConfirm = true;
 bool _isLoading = false;

  
  // Password strength
  int _strengthLevel = 0; // 0=empty,1=weak,2=fair,3=strong
  String _strengthLabel = '';

  

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
    _newPasswordController.addListener(_evaluateStrength);
    
  }

  void _evaluateStrength() {
    final val = _newPasswordController.text;
  
    setState(() {
      if (val.isEmpty) {
        _strengthLevel = 0;
        _strengthLabel = '';
      } else if (val.length < 6) {
        _strengthLevel = 1;
        _strengthLabel = 'Weak';
      } else if (val.length < 10 ||
          (!val.contains(RegExp(r'[A-Z]')) ||
              !val.contains(RegExp(r'[0-9]')))) {
        _strengthLevel = 2;
        _strengthLabel = 'Fair';
      } else {
        _strengthLevel = 3;
        _strengthLabel = 'Strong';
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Color get _strengthColor {
    switch (_strengthLevel) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orangeAccent;
      case 3:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  void _onResetPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isLoading = false);

    if (!mounted) return;

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.12),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Password Reset!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your password has been successfully updated. You can now log in with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF346CB0),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Reset Your Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          //icon: const Icon(Icons.arrow_back_ios_new_rounded,
           icon: const Icon(Icons.arrow_back,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero Section with wave ──
              _buildHeroSection(),

              // ── Form Section ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // New Password
                          _buildFieldLabel('New Password'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            hint: 'Enter your new password',
                            obscure: _obscureNew,
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please enter a new password';
                              if (val.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),

                          // Strength indicator
                          if (_strengthLevel > 0) ...[
                            const SizedBox(height: 10),
                            _buildStrengthIndicator(),
                          ],

                          const SizedBox(height: 20),

                          // Confirm Password
                          _buildFieldLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            hint: 'Re-enter your new password',
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: (val) {
                              if (val == null || val.isEmpty)
                                return 'Please confirm your password';
                              if (val != _newPasswordController.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Password tips card
                         // _buildPasswordTips(),

                          const SizedBox(height: 32),

                          // Reset Button
                          _buildResetButton(),

                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Section ──
  Widget _buildHeroSection() {
    return Stack(
      children: [
        // Blue background
        Container(
          color: _primaryBlue,
          width: double.infinity,
          //height: 160,
          height: 180,
        ),
        // Wave at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(double.infinity, 40),
            painter: _WavePainter(),
          ),
        ),
        // Icon + text
        SizedBox(
          width: double.infinity,
         // height: 160,
          height: 180,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Layered icon
              // Container(
              //   width: 84,
              //   height: 84,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     color: Colors.white.withOpacity(0.15),
              //   ),
              //   child: Center(
              //     child: Container(
              //       width: 62,
              //       height: 62,
              //       decoration: BoxDecoration(
              //         shape: BoxShape.circle,
              //         color: Colors.white.withOpacity(0.22),
              //       ),
              //       child: Center(
              //         child: Container(
              //           width: 46,
              //           height: 46,
              //           decoration: const BoxDecoration(
              //             shape: BoxShape.circle,
              //             color: Colors.white,
              //           ),
              //           child: Icon(
              //             Icons.lock_reset_rounded,
              //             color: _primaryBlue,
              //             size: 24,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              Container(
  width: 62,
  height: 62,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withOpacity(0.22),
  ),
  child: Center(
    child: Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Icon(
        Icons.lock_reset_rounded,
        color: _primaryBlue,
        size: 24,
      ),
    ),
  ),
),
              const SizedBox(height: 10),
              const Text(
                'Create a strong new password\nfor your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1E293B),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
        prefixIcon: Icon(Icons.lock_outline_rounded,
            color: _primaryBlue, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            //color: const Color(0xFF94A3B8),
             color: _primaryBlue, 
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 5,
                decoration: BoxDecoration(
                  color: i < _strengthLevel
                      ? _strengthColor
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Password strength: $_strengthLabel',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _strengthColor,
          ),
        ),
      ],
    );
  }

  

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_primaryBlue, const Color(0xFF4A85C8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _onResetPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
  
  : const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Wave Painter ──
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(
        size.width / 2, 0, size.width, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}