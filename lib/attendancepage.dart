import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'clientcheckinpage.dart';
import 'config.dart';
import 'dashboardpage.dart';

class AttendanceHomePage extends StatefulWidget {
  const AttendanceHomePage({super.key});

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingLocation = false;
  String _currentAddress = "Fetching location...";
  Position? _currentPosition;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hasInternetConnection = true;
  bool _locationServiceDisabled = false;
  bool _locationPermissionDenied = false;

  String _attendanceType = 'check_in';
  final TextEditingController _remarksController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeConnectivity();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _tabController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    _handleConnectivityChange(result);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_handleConnectivityChange);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    setState(() {
      _hasInternetConnection = result != ConnectivityResult.none;
      if (_hasInternetConnection) _getCurrentLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationServiceDisabled = false;
      _locationPermissionDenied = false;
    });

    if (!_hasInternetConnection) {
      setState(() {
        _isLoadingLocation = false;
        _currentAddress = "Waiting for internet connection...";
      });
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationServiceDisabled = true;
          _currentAddress = "Location services disabled.";
          _isLoadingLocation = false;
        });
        return;
      }

      final status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationPermissionDenied = true;
          _currentAddress = "Location permission denied.";
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
          .timeout(const Duration(seconds: 15));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty) {
        final formattedAddress = _formatAddress(placemarks.first);
        setState(() {
          _currentAddress = formattedAddress;
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _currentAddress = "Location request timed out.";
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _currentAddress = "Error: ${e.toString()}";
        _isLoadingLocation = false;
      });
    }
  }

  String _formatAddress(Placemark place) {
    return [
      place.street,
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ].where((part) => part != null && part.isNotEmpty).join(', ');
  }

  Future<void> _submitAttendance() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPosition == null) {
      _showSnackbar("Location not available. Please refresh.", isError: true);
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employee_id') ?? '';
    final orgId = prefs.getString('org_id') ?? '';

    
    final now = DateTime.now();
    final String formattedDate =
    "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}";
     final String formattedTime =
    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";


    final apiUrl = Uri.parse('$baseUrl/api/v1/save_attendance');

    final body = {
      'date': formattedDate,
      'time': formattedTime,
      'gps_latitude': _currentPosition!.latitude.toString(),
      'gps_longitude': _currentPosition!.longitude.toString(),
      'user_location': _currentAddress,
      'att_type': _attendanceType,
      'remarks': _remarksController.text.trim(),
    };

    final headers = {
      'Content-Type': 'application/json',
      'empid': empId,
      'orgid': orgId,
    };

    try {
      final response = await http.post(apiUrl, body: jsonEncode(body), headers: headers);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSnackbar('Attendance submitted successfully');
        _remarksController.clear();
      } else {
        final message = data['message'];
        String errorMessage;
        if (message is String) {
          errorMessage = message;
        } else if (message is List) {
          errorMessage = message.join(', ');
        } else {
          errorMessage = 'Failed to submit attendance.';
        }
        _showSnackbar(errorMessage, isError: true);
      }
    } catch (e) {
      _showSnackbar('Error: $e', isError: true);
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      color: Colors.red,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildForm() {
    const primaryColor = Color(0xFF346CB0);
    const borderColor = Color(0xFFCCCCCC);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              readOnly: true,
              controller: TextEditingController(text: _currentAddress),
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on, color: primaryColor),
                suffixIcon: _isLoadingLocation
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
                isDense: true,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Attendance Type:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Flexible(
                  child: RadioListTile<String>(
                    title: const Text('Check In', style: TextStyle(fontSize: 13)),
                    value: 'check_in',
                    groupValue: _attendanceType,
                    onChanged: (value) => setState(() => _attendanceType = value!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryColor,
                  ),
                ),
                Flexible(
                  child: RadioListTile<String>(
                    title: const Text('Check Out', style: TextStyle(fontSize: 13)),
                    value: 'check_out',
                    groupValue: _attendanceType,
                    onChanged: (value) => setState(() => _attendanceType = value!),
                    contentPadding: EdgeInsets.zero,
                    activeColor: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _remarksController,
              maxLines: 3,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Remarks',
                alignLabelWithHint: true,
                floatingLabelStyle: const TextStyle(
                    color: primaryColor, fontWeight: FontWeight.w600),
                contentPadding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 170,
                height: 40,
                child: ElevatedButton(
                  onPressed: _submitAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Submit Attendance',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
  backgroundColor: const Color(0xFF346CB0),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
  
   // Navigate to DashboardPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) =>  DashboardPage()),
    );
  },
),
  title: const Text(
    'Mobile Attendance',
    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
  ),
  bottom: TabBar(
    controller: _tabController,
    labelColor: Colors.white,
    unselectedLabelColor: Colors.white70,
    indicatorColor: Colors.white,
    tabs: const [
      Tab(text: 'Attendance'),
      Tab(text: 'Client Check-In'),
    ],
  ),
),

      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildForm(),
                const ClientCheckInPage(),
              ],
            ),
          ),
          if (!_hasInternetConnection)
            _buildWarningBanner("No internet connection. Please check your connection."),
          if (_locationServiceDisabled)
            _buildWarningBanner("Location services are disabled. Please enable them."),
          if (_locationPermissionDenied)
            _buildWarningBanner("Location permission denied. Please enable it from settings."),
        ],
      ),
    );
  }
}
