import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool biometricEnabled = true;
  bool passwordVisible = false;
  final TextEditingController passwordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPasswordFocused = passwordFocusNode.hasFocus;

    return Scaffold(
      
      appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: const Text(
    "Settings",
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  ),
  centerTitle: true, // ✅ Title centered
  backgroundColor: const Color(0xFF346CB0),
  foregroundColor: Colors.white,
  elevation: 0,
),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Biometric Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Enable Biometric Authentication",
                  style: TextStyle(fontSize: 14),
                ),
               
                Transform.scale(
  scale: 0.8, 
  child: Switch(
    value: biometricEnabled,
   // activeColor: Colors.orange,
   activeColor: Color(0xFF346CB0),

    onChanged: (value) {
      setState(() {
        biometricEnabled = value;
      });
    },
  ),
),

              ],
            ),
            const SizedBox(height: 24),


            Container(
  height: 40, // 🔹 reduced height
  padding: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    border: Border.all(
      color: isPasswordFocused
          ? const Color(0xFF346CB0)
          : Colors.grey,
    ),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      const Icon(Icons.lock, color: Color(0xFF346CB0), size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: TextField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: !passwordVisible,
          decoration: const InputDecoration(
            hintText: 'Password',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
          onTap: () => setState(() {}),
          onEditingComplete: () => setState(() {}),
        ),
      ),
      IconButton(
        padding: EdgeInsets.zero, 
        constraints: const BoxConstraints(),
        icon: Icon(
          passwordVisible
              ? Icons.visibility_off
              : Icons.visibility,
          color: Color(0xFF346CB0),
          size: 18,
        ),
        onPressed: () {
          setState(() {
            passwordVisible = !passwordVisible;
          });
        },
      ),
    ],
  ),
),


            const SizedBox(height: 24),

            
            Align(
              alignment: Alignment.center,
              

              child: ElevatedButton(
  onPressed: () {
    
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF346CB0),
    minimumSize: const Size(120, 36), 
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  ),
  child: const Text(
    "Enable",
    style: TextStyle(color: Colors.white, fontSize: 14),
  ),
),

            ),

            const SizedBox(height: 24),
            const Divider(),

            // App Status
            const SizedBox(height: 12),
            

            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      "App is up to date",
      style: TextStyle(
        color: Colors.green,
        fontWeight: FontWeight.bold,
      ),
    ),
   

    IconButton(
  icon: const Icon(Icons.refresh, color: Colors.green),
   onPressed: () {
  },
),

  ],
),

          ],
        ),
      ),
    );
  }
}
