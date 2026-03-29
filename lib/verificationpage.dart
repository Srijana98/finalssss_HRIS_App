import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'resetpasswordpage.dart';


class VerificationPage extends StatefulWidget {
  final String sentTo;
  const VerificationPage({super.key, required this.sentTo});
  
  

  @override
  State<VerificationPage> createState() => _VerificationPageState();
  
}


class _VerificationPageState extends State<VerificationPage>
   with SingleTickerProviderStateMixin {
  final Color _customBlue = const Color(0xFF346CB0);


  final int _otpLength = 4;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  final _formKey = GlobalKey<FormState>();
 
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  String get _otpValue =>
      _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final bool isEmail = widget.sentTo == 'email';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _customBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Verify Your OTP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Top Icon ──
                 
                  _buildTopIcon(),
                  const SizedBox(height: 28),

                  // ── Subtitle ──
                  Text(
                    isEmail
                        ? 'Enter the OTP sent to your email\nto verify your identity and continue securely.'
                        : 'Enter the OTP sent to your phone\nto verify your identity and continue securely.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // ── OTP Fields ──
                  Form(
                    key: _formKey,
                    child: _buildOtpFields(),
                  ),
                 // const SizedBox(height: 12),

                  // ── Resend ──
                 // _buildResendRow(),
                  const SizedBox(height: 32),

                  // ── Verify Button ──
                  _buildVerifyButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _customBlue.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: _customBlue.withOpacity(0.18),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_customBlue, const Color(0xFF4A85C8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _customBlue.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //mnAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_otpLength, (index) {
        return SizedBox(
          width: 48,
          height: 56,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color:_customBlue,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: _customBlue.withOpacity(0.05),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                    
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _customBlue, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
            onChanged: (value) => _onOtpChanged(value, index),
            validator: (val) {
              if (val == null || val.isEmpty) return '';
              return null;
            },
          ),
        );
      }),
    );
  }



  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [_customBlue, const Color(0xFF4A85C8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _customBlue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              // if (_otpValue.length == _otpLength) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: const Text('OTP verified successfully!'),
              //       backgroundColor: _customBlue,
              //       behavior: SnackBarBehavior.floating,
              //       shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(12)),
              //     ),
              //   );
              // } 

              if (_otpValue.length == _otpLength) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ResetPasswordPage(),
    ),
  );
}
              else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter the complete OTP.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
             'Send OTP',
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