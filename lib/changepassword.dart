
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController oldPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  final Color _customBlue = const Color(0xFF346CB0);

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Get employee_id and org_id from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? empId = prefs.getString('employee_id');
      final String? orgId = prefs.getString('org_id');

      // Check if employee_id and org_id are available
      if (empId == null || orgId == null || empId.isEmpty || orgId.isEmpty) {
        _showMessage("Employee ID or Organization ID not found. Please login again.", isError: true);
        setState(() => isLoading = false);
        return;
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'old_password': oldPasswordController.text.trim(),
        'password': newPasswordController.text.trim(),
        'password_confirmation': confirmPasswordController.text.trim(),
      };

      // Make API request
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/change_password'),
        headers: {
          'Content-Type': 'application/json',
          'empid': empId,
          'orgid': orgId,
        },
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        if (mounted) {
          Navigator.pop(context);
          _showMessage(data['message'] ?? "Password updated successfully!");
        }
      } else {
        _showMessage(data['message'] ?? "Failed to update password", isError: true);
      }
    } catch (e) {
      _showMessage("Error: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 0.6,
              )),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            obscureText: true,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 2),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.only(top: 16, bottom: 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Center(
        child: Text(
          "Change Password",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: _customBlue,
          ),
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                label: "Old Password *",
                controller: oldPasswordController,
                hint: "Enter your old password",
                validator: (value) =>
                    value!.isEmpty ? "Enter old password" : null,
              ),
              _buildTextField(
                label: "New Password *",
                controller: newPasswordController,
                hint: "Enter new password",
                validator: (value) =>
                    value!.isEmpty ? "Enter new password" : null,
              ),
              _buildTextField(
                label: "Confirm Password *",
                controller: confirmPasswordController,
                hint: "Retype password",
                validator: (value) {
                  if (value!.isEmpty) return "Confirm your password";
                  if (value != newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _updatePassword,
                  icon: isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.update,
                          size: 16,
                          color: Colors.white,
                        ),
                  label: Text(
                    isLoading ? "Updating..." : "Update",
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _customBlue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}