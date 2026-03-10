import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'getattendance.dart';
import 'config.dart';
import 'attendancepage.dart';
import 'settingspage.dart';
import 'profilepage.dart';
import 'attendancerequestpage.dart';
import 'lateinhistory.dart';
import 'overtimehistory.dart';
import 'fieldvisithistory.dart';
import 'adsalaryhistory.dart';
import 'allowancehistory.dart';
import 'dailyreporthistory.dart';
import 'substituteleavehistory.dart';
import 'leavehistory.dart';
import 'loginpage.dart';
import 'moreattendancepage.dart';
import 'changepassword.dart';
import 'workfromhistory.dart';
import 'workonholidayhistory.dart';
import 'workonweekendhistory.dart';
import 'employeeinfo.dart';

class DashboardPage extends StatefulWidget {
  final String? token;
  const DashboardPage({Key? key, this.token}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final Color headerColor = const Color(0xFF346CB0);
  int _currentIndex = 0;
  late final List<Widget> _pages;

  bool _showAppBar(int index) => index == 0 || index == 3;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(token: widget.token),
      AttendanceHomePage(),
      const SettingsPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: _showAppBar(_currentIndex)
            ? AppBar(
                backgroundColor: headerColor,
                elevation: 0,
                leading: const Icon(Icons.menu, color: Colors.white),
                title: const Text(
                  'HRMS Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {},
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Text('0',
                              style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      )
                    ],
                  ),


                  
            

Padding(
  padding: const EdgeInsets.only(right: 10),
  child: PopupMenuButton<int>(
    offset: const Offset(0, 50), 
    color: const Color(0xFF346CB0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    icon: const Icon(Icons.account_circle, size: 25, color: Colors.white),
    onSelected: (value) async {
      if (value == 1) {
        // Profile
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
      } 
      else if (value == 2) {
        // 🔹 Show Change Password Dialog (no page navigation)
        showDialog(
          context: context,
          builder: (context) => const ChangePasswordDialog(),
        );
      } 
      else if (value == 3) {
        // Logout logic
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        if (context.mounted) {
        

          Navigator.pushAndRemoveUntil(
           context,
           MaterialPageRoute(builder: (_) => const LoginScreen()),
           (route) => false,
         );

        }
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem<int>(
        value: 1,
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Profile", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      const PopupMenuItem<int>(
        value: 2,
        child: Row(
          children: [
            Icon(Icons.lock, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Change Password", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      const PopupMenuItem<int>(
        value: 3,
        child: Row(
          children: [
            Icon(Icons.logout, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Logout", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    ],
  ),
),


                ],
              )
            : null,
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white, 
          currentIndex: _currentIndex,
          selectedItemColor: headerColor,
          unselectedItemColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Attendance"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String? token;
  const HomePage({Key? key, this.token}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color headerColor = const Color(0xFF346CB0);
  final Set<String> _activeIcons = {};

  String name = '';
  String designation = '';
  String serviceDuration = '';
  String branch = '';
 // String photoUrl = '';
   String photo = '';
  bool isLoading = true;

  final List<Map<String, dynamic>> gridItems = [
    {"icon": Icons.calendar_today, "label": " Manual Attendance"},
    {"icon": Icons.fingerprint, "label": "Late In / Early Out"},
    {"icon": Icons.access_time_filled, "label": "Over Time"},
    {"icon": Icons.location_on, "label": "Field Visit"},
    {"icon": Icons.attach_money, "label": "Advance Salary"},
    {"icon": Icons.card_giftcard, "label": "Allowances"},
    {"icon": Icons.article, "label": "Daily Report"},
    {"icon": Icons.home_work, "label": "Work From Home"},
    {"icon": Icons.holiday_village, "label": "Work on Holiday"},
    {"icon": Icons.weekend, "label": "Work on Weekend"},
    ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
   
  }



  Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    name = prefs.getString('name') ?? 'Not Available';
    designation = prefs.getString('designation') ?? 'Not Available';
    serviceDuration = prefs.getString('serviceDuration') ?? 'Not Available';
    branch = prefs.getString('branch') ?? 'Not Available';
     // photoUrl = prefs.getString('photoUrl') ?? '';
    photo = prefs.getString('photo') ?? '';
    isLoading = false;
    
  });
  
}



  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          

// maintain the size between the profile and the my attendance container

Stack(
  clipBehavior: Clip.none,
  children: [
    _buildHeader(),
    Positioned(
     // bottom: -80, 
      bottom: -55,
      left: 8,
      right: 8,
      child: _buildAttendanceCard(),
    ),
  ],
),

// space between the my attendance and the grid icon

 const SizedBox(height: 65),
 

          if (isLoading)
            const CircularProgressIndicator()
          else
            _buildGridSection(),
          const SizedBox(height: 10),

          /// ✅ Leave Balance Section (ADDED HERE)
          _buildLeaveBalanceSection(context),

          const SizedBox(height: 10),

          _buildRequestSection(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 150,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerColor, const Color(0xFF346CB0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CircleAvatar(
          //   radius: 35,
          // backgroundImage: photo.isNotEmpty
          //       ? NetworkImage(photo)
          //       : const NetworkImage(
          //           'http://demo.smarthajiri.com/uploads/manipal/emp_img/505490192.jpg'),
          // ),
          GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => HRISApp()),
    );
  },
  child: CircleAvatar(
    radius: 35,
    backgroundImage: photo.isNotEmpty
        ? NetworkImage(photo)
        : const NetworkImage(
            'http://demo.smarthajiri.com/uploads/manipal/emp_img/505490192.jpg'),
  ),
),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  Text('Designation: $designation',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('Service Duration: $serviceDuration',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('Branch: $branch',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildAttendanceCard() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("My Attendance Log",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                     // color: Colors.indigo[900])
                      color: Color(0xFF346CB0))
                      ),
                      

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                   
                    builder: (context) => MoreAttendancePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.indigo, width: 1),
                  ),
                  child: const Text(
                    "More",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
       // const SizedBox(height: 3),
          const SizedBox(height: 1),
        //  const SizedBox(width: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today",
                  style: TextStyle(color: Colors.black, fontSize: 13)),
              Row(
                children: [
                  _attendanceInfoCard("In", "--"),
                  const SizedBox(width: 12),
                  _attendanceInfoCard("Out", "--"),
                  const SizedBox(width: 12),
                  _attendanceInfoCard("Tot hr", "--"),
                ],
              ),
            ],
          ),
       

  // ✅ YESTERDAY SECTION
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Yesterday",
              style: TextStyle(color: Colors.black, fontSize: 13),
            ),
            Row(
              children: [
                _attendanceInfoCard("In", "--"),
                const SizedBox(width: 12),
                _attendanceInfoCard("Out", "--"),
                const SizedBox(width: 12),
                _attendanceInfoCard("Tot hr", "--"),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}


  Widget _attendanceInfoCard(String title, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: Colors.indigo[900],
                fontWeight: FontWeight.bold,
                fontSize: 10)),
        const SizedBox(height: 2),
        Container(
         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),

          decoration: BoxDecoration(
            color: Colors.indigo[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(time,
              style: TextStyle(color: Colors.indigo[900], fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildGridSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
           crossAxisCount: 3,
           mainAxisSpacing: 8,      
            crossAxisSpacing: 8,    
            childAspectRatio: 1.1, 
          children: gridItems
              .map((item) => _gridIcon(item['icon'], item['label']))
              .toList(),
        ),
      ),
    );
  }

  Widget _gridIcon(IconData icon, String label) {
    bool isActive = _activeIcons.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isActive) {
            _activeIcons.remove(label);
          } else {
            _activeIcons.add(label);
          }
        });

        if (label == " Manual Attendance") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AttendanceHistoryPage()));
        } else if (label == "Late In / Early Out") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => LateInHistoryPage()));
        } else if (label == "Over Time") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => OverTimeHistoryPage()));
        } else if (label == "Field Visit") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => FieldVisitHistoryPage()));
        } else if (label == "Advance Salary") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AdvanceSalaryHistoryPage()));
        } else if (label == "Allowances") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => AllowanceHistoryPage()));
        } else if (label == "Daily Report") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => DailyReportHistoryPage()));
       // }
     } else  if (label == "Work From Home") {
      Navigator.push(context,
      MaterialPageRoute(builder: (_) => WorkFromHistoryPage()));
      } 
    else if (label == "Work on Holiday") {
    Navigator.push(context,
     MaterialPageRoute(builder: (_) =>WorkonHolidayHistoryPage()));
    } else if (label == "Work on Weekend") {
     Navigator.push(context, 
     MaterialPageRoute(builder: (_) => WorkonWeekendHistoryPage()));
      }

      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
          backgroundColor: headerColor, // always headerColor
          radius: 20,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
            const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

Widget _buildLeaveBalanceSection(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Leave Balance",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF346CB0)
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 110,
                height: 32,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubstituteHistoryPage(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    

                    side: const BorderSide(color: Color(0xFF346CB0)),
                    foregroundColor: Color(0xFF346CB0),

                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                
                  child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
          Icon(
          Icons.description,  
          size: 14,
          color: Color(0xFF346CB0), 
           ),
        SizedBox(width: 4),
       Text(
      "Substitute Leave",
      style: TextStyle(fontSize: 10),
      overflow: TextOverflow.ellipsis,
    ),
  ],
),

                ),
                
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 110,
                height: 32,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LeaveHistoryPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send, size: 14),
                  label: const Text(
                    "Apply Leave",
                    style: TextStyle(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF346CB0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

 Widget _buildRequestSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Text("My Requests",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF346CB0))
                    ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text("More", style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}