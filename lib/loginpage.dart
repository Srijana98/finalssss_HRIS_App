import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboardpage.dart';
import 'submitattendancepage.dart';
import 'config.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: LoginScreen(),
  ));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials();
  }

  // ✅ Load saved credentials if "Remember Me" was checked
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('rememberMe') ?? false;
    
    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('savedEmail') ?? '';
        _passwordController.text = prefs.getString('savedPassword') ?? '';
      });
    }
  }

Future<void> _login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    _showMessage("Please enter both email and password.", isError: true);
    return;
  }

  final hasInternet = await _checkInternetConnection();
  if (!hasInternet) {
    _showMessage("No internet connection.", isError: true);
    return;
  }

  setState(() => _isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/mobile_login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (data["status"] == "success") {
      // ✅ CHECK IF EMPLOYEE DATA EXISTS
      if (data["employee_data"] == null) {
        _showMessage("No valid employee found.", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Save "Remember Me" credentials
      await prefs.setBool('rememberMe', _rememberMe);
      if (_rememberMe) {
        await prefs.setString('savedEmail', email);
        await prefs.setString('savedPassword', password);
      } else {
        await prefs.remove('savedEmail');
        await prefs.remove('savedPassword');
      }

      final token = data["token"];
      final user = data["employee_data"];
      
      // ✅ ADDITIONAL CHECK: Verify essential fields exist
      final empId = (user["id"] ?? user["employee_id"])?.toString() ?? '';
      final orgId = (user["orgid"] ?? user["org_id"])?.toString() ?? '';
      final locationId = (user["locationid"] ?? user["location_id"])?.toString() ?? '';

      if (empId.isEmpty || orgId.isEmpty) {
        _showMessage("No valid employee found.", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Debug print to confirm values are correctly fetched
      print("====== DEBUG LOGIN STORED VALUES ======");
      print("employee_id: $empId");
      print("org_id: $orgId");
      print("locationid: $locationId");
      print("=======================================");

      // ✅ Save to SharedPreferences
      await prefs.setString('employee_id', empId);
      await prefs.setString('org_id', orgId);
      await prefs.setString('location_id', locationId);

      // ✅ Store full user profile info
      await prefs.setString('name', user["full_name"] ?? '');
      await prefs.setString('designation', user["designation_name"] ?? '');
      await prefs.setString('serviceDuration', user["service_duration"] ?? '');
      await prefs.setString('branch', user["location_name"] ?? '');
      await prefs.setString('photo', user["image_url"] ?? '');

      _showMessage("Login successful!");

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage(token: token)),
      );
    } else {
      _showMessage(data["message"] ?? "Login failed", isError: true);
    }
  } catch (e) {
    _showMessage("Error during login: $e", isError: true);
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToAttendancePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubmitAttendancePage()),
    );
  }

  void _forgotPassword() {
    _showMessage("Forgot password clicked.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight * 0.30),
                  painter: CurvedPainter(),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: constraints.maxHeight * 0.04),
                          

                             ClipOval(
  child: Container(
    width: 150,   
    height: 100,  
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 10,
          spreadRadius: 3,
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Image.asset(
        'assets/xelwel logo1.png',
        fit: BoxFit.contain,
      ),
    ),
  ),
),                   

                            const SizedBox(height: 24),
                           const SizedBox(height: 50),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.email, color: Color(0xFF346CB0)),
                                      hintText: 'Username / Email',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  TextField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF346CB0)),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Color(0xFF346CB0),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      hintText: 'Password',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(15),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 25),
                                  
                                  // ✅ REMEMBER ME CHECKBOX
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: const Color(0xFF346CB0),
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _rememberMe = !_rememberMe;
                                          });
                                        },
                                        child: const Text(
                                          'Remember me?',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                            decoration: TextDecoration.underline,
                                            decorationThickness: 1.5,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _forgotPassword,
                                      child: const Text(
                                        "Forgot password?",
                                        style: TextStyle(
                                          color: Color(0xFF346CB0),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF346CB0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                      minimumSize: const Size(140, 30),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'Submit',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 15),
                                  ElevatedButton(
                                    onPressed: _navigateToAttendancePage,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                                      minimumSize: const Size(140, 30),
                                    ),
                                    child: const Text(
                                      'Submit Attendance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class CurvedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF346CB0)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..lineTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width / 2,
        size.height,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




//loginpage.dart of the gwt with the checkbox
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dashboardpage.dart';
// import 'submitattendancepage.dart';
// import 'config.dart';

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: LoginScreen(),
//   ));
// }

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   Future<void> _login() async {
   
//     final Uri url = Uri.parse('https://gwt.xelwel.com');

//     try {
//       await launchUrl(
//         url,
//         mode: LaunchMode.externalApplication,
//       );
//     } catch (e) {
//       _showMessage('the browser should be opened: ${e.toString()}', isError: true);
//     }
//   }

//   void _showMessage(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _navigateToAttendancePage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => const SubmitAttendancePage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
               
//                 CustomPaint(
//                   size: Size(
//                     constraints.maxWidth,
//                     constraints.maxHeight * 0.30,
//                   ),
//                   painter: CurvedPainter(),
//                 ),

              
//                 SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 32),
//                     child: Column(
//                       children: [
//                         SizedBox(height: constraints.maxHeight * 0.32),

//                         const Center(
//                           child: Text(
//                             'Xelwel HRMS',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF346CB0),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 100),

//                         Align(
//                           alignment: Alignment.center,
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade50,
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 10,
//                                   spreadRadius: 2,
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const SizedBox(height: 20),

//                                 // LOGIN BUTTON - No loading state
//                                 ElevatedButton(
//                                   onPressed: _login,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF346CB0),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 15,
//                                       vertical: 8,
//                                     ),
//                                     minimumSize: const Size(130, 25),
//                                   ),
//                                   child: const Text(
//                                     'Log In',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),

//                                 const SizedBox(height: 20),

//                                 // SUBMIT ATTENDANCE BUTTON
//                                 ElevatedButton(
//                                   onPressed: _navigateToAttendancePage,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 18,
//                                       vertical: 6,
//                                     ),
//                                     minimumSize: const Size(170, 25),
//                                   ),
//                                   child: const Text(
//                                     'Submit Attendance',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 50),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // LOGO
//                 Positioned(
//                   top: (constraints.maxHeight * 0.40) / 2 - 90,
//                   left: 0,
//                   right: 0,
//                   child: Center(
                    
//                     child: Container(
//   width: 130,
//   height: 130,
//   decoration: BoxDecoration(
//     color: Colors.white,
//     borderRadius: BorderRadius.circular(16), 
//     boxShadow: [
//       BoxShadow(
//         color: Colors.black26,
//         blurRadius: 8,
//         spreadRadius: 2,
//       ),
//     ],
//   ),
//   child: ClipRRect(
//     borderRadius: BorderRadius.circular(16),
//     child: Image.asset(
//       'assets/gwt logo.jpg',
//       width: 130,
//       height: 130,
//       fit: BoxFit.cover,
//     ),
//   ),
// ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class CurvedPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = const Color(0xFF346CB0)
//       ..style = PaintingStyle.fill;

//     Path path = Path();
//     path.lineTo(0, size.height - 50);
//     path.quadraticBezierTo(
//       size.width * 0.5,
//       size.height + 20,
//       size.width,
//       size.height - 50,
//     );
//     path.lineTo(size.width, 0);
//     path.close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }











 //login page for the medibiz
// import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'submitattendancepage.dart';

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: LoginScreen(),
//   ));
// }

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   Future<void> _login() async {
//     final Uri url = Uri.parse('https://medibiz.xelwel.com/');

//     try {
//       await launchUrl(
//         url,
//         mode: LaunchMode.externalApplication,
//       );
//     } catch (e) {
//       _showMessage('the browser should be opened: ${e.toString()}', isError: true);
//     }
//   }

//   void _showMessage(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _navigateToAttendancePage() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => const SubmitAttendancePage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Stack(
//               children: [
//                 CustomPaint(
//                   size: Size(
//                     constraints.maxWidth,
//                     constraints.maxHeight * 0.30,
//                   ),
//                   painter: CurvedPainter(),
//                 ),

//                 SingleChildScrollView(
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 32),
//                     child: Column(
//                       children: [
//                         SizedBox(height: constraints.maxHeight * 0.32),

//                         const Center(
//                           child: Text(
//                             'Medibiz HRMS',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Color(0xFF346CB0),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 100),

//                         Align(
//                           alignment: Alignment.center,
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(20),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade50,
//                               borderRadius: BorderRadius.circular(20),
//                               boxShadow: const [
//                                 BoxShadow(
//                                   color: Colors.black12,
//                                   blurRadius: 10,
//                                   spreadRadius: 2,
//                                 ),
//                               ],
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.center,
//                               children: [
//                                 const SizedBox(height: 20),

//                                 // LOGIN BUTTON
//                                 ElevatedButton(
//                                   onPressed: _login,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: const Color(0xFF346CB0),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 15,
//                                       vertical: 8,
//                                     ),
//                                     minimumSize: const Size(130, 25),
//                                   ),
//                                   child: const Text(
//                                     'Log In',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),

//                                 const SizedBox(height: 20),

//                                 // SUBMIT ATTENDANCE BUTTON
//                                 ElevatedButton(
//                                   onPressed: _navigateToAttendancePage,
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: Colors.green,
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     padding: const EdgeInsets.symmetric(
//                                       horizontal: 18,
//                                       vertical: 6,
//                                     ),
//                                     minimumSize: const Size(170, 25),
//                                   ),
//                                   child: const Text(
//                                     'Submit Attendance',
//                                     style: TextStyle(
//                                       color: Colors.white,
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 50),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // LOGO - Circular container for Medibiz
//                 Positioned(
//                   top: (constraints.maxHeight * 0.40) / 2 - 90,
//                   left: 0,
//                   right: 0,
//                   child: Center(
//                     child: Container(
//                       width: 130,
//                       height: 130,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         boxShadow: const [
//                           BoxShadow(
//                             color: Colors.black26,
//                             blurRadius: 8,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: ClipOval(
//                         child: Image.asset(
//                           'assets/medibiz logo.jpg',
//                           width: 130,
//                           height: 130,
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class CurvedPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint()
//       ..color = const Color(0xFF346CB0)
//       ..style = PaintingStyle.fill;

//     Path path = Path();
//     path.lineTo(0, size.height - 50);
//     path.quadraticBezierTo(
//       size.width * 0.5,
//       size.height + 20,
//       size.width,
//       size.height - 50,
//     );
//     path.lineTo(size.width, 0);
//     path.close();

//     canvas.drawPath(path, paint);
//   }

//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => false;
// }
