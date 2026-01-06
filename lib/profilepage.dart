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
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    final url = Uri.parse('$baseUrl/api/v1/get_my_profile');

    final headers = {
      'Content-Type': 'application/json',
      'empid': empId!,
      'orgid': orgId!,
    };
    print("📦 Headers: $headers");

    try {
      final response = await http.post(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('image_url', data['employee_data']['image_url'] ?? '');

          setState(() {
            profileData = data['employee_data'];
            imageUrl = data['employee_data']['image_url'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        print('Failed to fetch profile: ${response.statusCode}');
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : profileData == null
                ? const Center(child: Text('Failed to load profile'))
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Column(
                              children: [
                                const Text(
                                  "Profile",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 55,
                                      backgroundImage: profileData!['image_url'] != null
                                          ? NetworkImage(profileData!['image_url'])
                                          : const AssetImage('http://demo.smarthajiri.com/uploads/birat/emp_img/505490192.jpg') as ImageProvider,
                                    ),
                                    
           
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                                          onPressed: () {},
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "USER PROFILE",
                                  style: TextStyle(
                                    color: Colors.lightBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                /// Replace empty fields with real data
                                buildInfoRow("Username", profileData!['empcode'] ?? ''),
                                buildInfoRow("Email", profileData!['email'] ?? ''),
                                buildInfoRow("Full Name", profileData!['full_name'] ?? ''),
                                buildInfoRow("Department", profileData!['depname'] ?? ''),
                                buildInfoRow("Designation", profileData!['designation_name'] ?? ''),
                                buildInfoRow("Contact", profileData!['mobile'] ?? 'N/A'),
                                buildInfoRow("Location", profileData!['location_name'] ?? ''),
                                buildInfoRow("Usergroup", profileData!['groupname'] ?? ''),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
} 

