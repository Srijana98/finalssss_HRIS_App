// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'config.dart';

// class ProfilePage extends StatefulWidget {
//   const ProfilePage({super.key});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   Map<String, dynamic>? profileData;
//   bool isLoading = true;
//   String? empId;
//   String? orgId;
//   String? imageUrl;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserDataAndFetchProfile();
//   }

//   Future<void> _loadUserDataAndFetchProfile() async {
//     final prefs = await SharedPreferences.getInstance();
//     empId = prefs.getString('employee_id');
//     orgId = prefs.getString('org_id');
//     imageUrl = prefs.getString('image_url'); 

//     if (empId != null && orgId != null) {
//       await _fetchProfile();
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _fetchProfile() async {
//     final url = Uri.parse('$baseUrl/api/v1/get_my_profile');

//     final headers = {
//       'Content-Type': 'application/json',
//       'empid': empId!,
//       'orgid': orgId!,
//     };
//     print("📦 Headers: $headers");

//     try {
//       final response = await http.post(url, headers: headers);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['status'] == 'success') {
//           final prefs = await SharedPreferences.getInstance();
//           await prefs.setString('image_url', data['employee_data']['image_url'] ?? '');

//           setState(() {
//             profileData = data['employee_data'];
//             imageUrl = data['employee_data']['image_url'];
//             isLoading = false;
//           });
//         } else {
//           setState(() => isLoading = false);
//         }
//       } else {
//         print('Failed to fetch profile: ${response.statusCode}');
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print('Error fetching profile: $e');
//       setState(() => isLoading = false);
//     }
//   }


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: SafeArea(
//         child: isLoading
//             ? const Center(child: CircularProgressIndicator())
//             : profileData == null
//                 ? const Center(child: Text('Failed to load profile'))
//                 : SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         const SizedBox(height: 20),
//                         Card(
//                           margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           elevation: 4,
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             child: Column(
//                               children: [
//                                 const Text(
//                                   "Profile",
//                                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 Stack(
//                                   alignment: Alignment.bottomRight,
//                                   children: [
//                                     CircleAvatar(
//                                       radius: 55,
//                                       backgroundImage: profileData!['image_url'] != null
//                                           ? NetworkImage(profileData!['image_url'])
//                                           : const AssetImage('http://demo.smarthajiri.com/uploads/birat/emp_img/505490192.jpg') as ImageProvider,
//                                     ),
                                    
           
//                                     Positioned(
//                                       bottom: 4,
//                                       right: 4,
//                                       child: Container(
//                                         decoration: const BoxDecoration(
//                                           color: Colors.blue,
//                                           shape: BoxShape.circle,
//                                         ),
//                                         child: IconButton(
//                                           icon: const Icon(Icons.edit, color: Colors.white, size: 18),
//                                           onPressed: () {},
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 12),
//                                 const Text(
//                                   "PROFILE",
//                                   style: TextStyle(
//                                     color: Colors.lightBlue,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 20),

//                                 buildInfoRow("Username", profileData!['empcode'] ?? ''),
//                                 buildInfoRow("Email", profileData!['email'] ?? ''),
//                                 buildInfoRow("Full Name", profileData!['full_name'] ?? ''),
//                                 buildInfoRow("Department", profileData!['depname'] ?? ''),
//                                 buildInfoRow("Designation", profileData!['designation_name'] ?? ''),
//                                 buildInfoRow("Contact", profileData!['mobile'] ?? 'N/A'),
//                                 buildInfoRow("Location", profileData!['location_name'] ?? ''),
//                                 buildInfoRow("Usergroup", profileData!['groupname'] ?? ''),
//                                 const SizedBox(height: 10),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//       ),
//     );
//   }

//   Widget buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 3,
//             child: Text(
//               "$label:",
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             flex: 6,
//             child: Text(
//               value,
//            style: const TextStyle(color: Colors.black87, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// } 









import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;
  String? empId;
  String? orgId;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchProfile();
  }

  Future<void> _loadUserDataAndFetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    empId = prefs.getString('employee_id');
    orgId = prefs.getString('org_id');
    imageUrl = prefs.getString('image_url');

    if (empId != null && orgId != null) {
      await _fetchProfile();
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchProfile() async {
    final url = Uri.parse('$baseUrl/api/v1/get_my_profile');
    final headers = {
      'Content-Type': 'application/json',
      'empid': empId!,
      'orgid': orgId!,
    };

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'image_url', data['employee_data']['image_url'] ?? '');
          setState(() {
            profileData = data['employee_data'];
            imageUrl = data['employee_data']['image_url'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching profile: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : profileData == null
                ? const Center(child: Text('Failed to load profile'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black12,
                      child: Column(
                        children: [
                          // ── Blue gradient header ──
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 22),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF1565C0),
                                  Color(0xFF42A5F5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Avatar with edit icon
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 45,
                                        backgroundColor: Colors.white,
                                        backgroundImage: (profileData![
                                                        'image_url'] !=
                                                    null &&
                                                profileData!['image_url']
                                                    .toString()
                                                    .isNotEmpty)
                                            ? NetworkImage(
                                                profileData!['image_url'])
                                            : const AssetImage(
                                                    'http://demo.smarthajiri.com/uploads/birat/emp_img/505490192.jpg')
                                                as ImageProvider,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Color(0xFF1565C0),
                                            size: 15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                // Profile text below avatar
                                const Text(
                                  "Profile",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── Info rows ──
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                buildInfoRow(
                                    Icons.badge_outlined,
                                    "Username",
                                    profileData!['empcode'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.email_outlined,
                                    "Email",
                                    profileData!['email'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.person_outline,
                                    "Full Name",
                                    profileData!['full_name'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.business_outlined,
                                    "Department",
                                    profileData!['depname'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.work_outline,
                                    "Designation",
                                    profileData!['designation_name'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.phone_outlined,
                                    "Contact",
                                    profileData!['mobile'] ?? 'N/A'),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.location_on_outlined,
                                    "Location",
                                    profileData!['location_name'] ?? ''),
                                buildDivider(),
                                buildInfoRow(
                                    Icons.group_outlined,
                                    "Usergroup",
                                    profileData!['groupname'] ?? ''),
                                const SizedBox(height: 14),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget buildDivider() {
    return const Divider(
      height: 1,
      thickness: 0.6,
      indent: 30,
      color: Color(0xFFEEEEEE),
    );
  }

  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF555555),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}