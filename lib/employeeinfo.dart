
// import 'package:flutter/material.dart';

// void main() {
//   runApp(const HRISApp());
// }

// class HRISApp extends StatelessWidget {
//   const HRISApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'HRIS Pro',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorSchemeSeed: const Color(0xFF346CB0),
//         useMaterial3: true,
//         fontFamily: 'Roboto',
//       ),
//       home: const EmployeeProfilePage(),
//     );
//   }
// }


// class AppColors {
//   static const primary       = Color(0xFF346CB0);
//   static const primaryDark   = Color(0xFF244F87);
//   static const primaryLight  = Color(0xFF4A85CC);
//   static const primaryXLight = Color(0xFFDDEAF8);
//   static const accent        = Color(0xFFF5A623);
//   static const success       = Color(0xFF27AE60);
//   static const danger        = Color(0xFFE74C3C);
//   static const textDark      = Color(0xFF1A2640);
//   static const textMid       = Color(0xFF4A5870);
//   static const textLight     = Color(0xFF8A9AB8);
//   static const surface       = Color(0xFFF0F4FA);
//   static const card          = Colors.white;
//   static const border        = Color(0xFFDDE5F2);
// }


// class Employee {
//   final String name;
//   final String empId;
//   final String role;
//   final String department;
//   final String location;
//   final String phone;
//   final String email;
//   final String gender;
//   final String dobAD;
//   final String dobBS;
//   final int age;
//   final String employeeType;
//   final String? employeeCategory;
//   final String joinDateAD;
//   final String joinDateBS;
//   final String servicePeriod;
//   final String? renewPeriod;
//   final String contractExpiryAD;
//   final String contractExpiryBS;
//   final String contractLeft;
//   final String retirementAD;
//   final String retirementBS;
//   final String retirementLeft;
//   final String permanentAddress;
//  final String temporaryAddress;

  
//   const Employee({
//     required this.name,
//     required this.empId,
//     required this.role,
//     required this.department,
//     required this.location,
//     required this.phone,
//     required this.email,
//     required this.gender,
//     required this.dobAD,
//     required this.dobBS,
//     required this.age,
//     required this.employeeType,
//     this.employeeCategory,
//     required this.joinDateAD,
//     required this.joinDateBS,
//     required this.servicePeriod,
//     this.renewPeriod,
//     required this.contractExpiryAD,
//     required this.contractExpiryBS,
//     required this.contractLeft,
//     required this.retirementAD,
//     required this.retirementBS,
//     required this.retirementLeft,
//     required this.permanentAddress,
//     required this.temporaryAddress,
    
//   });
// }

// final sampleEmployee = const Employee(
//   name: 'Sushma Paudel',
//   empId: '16',
//   role: 'Sr. Staff Nurse',
//   department: 'Outpatient',
//   location: 'Kathmandu',
//   phone: '9849269721',
//   email: 'sushama.bashistha@gmail.com',
//   gender: 'Female',
//   dobAD: '1991/10/01',
//   dobBS: '2048/06/15',
//   age: 34,
//   employeeType: 'Probationary',
//   employeeCategory: null,
//   joinDateAD: '2023/12/03',
//   joinDateBS: '2080/08/17',
//   servicePeriod: '2 Years, 3 Months, 8 Days',
//   renewPeriod: null,
//   contractExpiryAD: '2024/11/29',
//   contractExpiryBS: '2081/08/14',
//   contractLeft: '1Y, 3M, 10D Left',
//   retirementAD: '2049/10/01',
//   retirementBS: '2106/06/15',
//   retirementLeft: '23Y, 6M, 22D Remaining',
//   permanentAddress: 'Kathmandu',
// temporaryAddress: 'Lamjung',
 
// );


// class EmployeeProfilePage extends StatelessWidget {
//   const EmployeeProfilePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final emp = sampleEmployee;
//     return Scaffold(
//       backgroundColor: AppColors.surface,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             _ProfileHero(emp: emp),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _QuickStatsRow(emp: emp),
//                   const SizedBox(height: 20),
//                   _SectionLabel(title: 'Personal Information', icon: Icons.person_outline),
//                   const SizedBox(height: 12),
//                   _PersonalInfoGrid(emp: emp),
//                   const SizedBox(height: 20),
//                   _SectionLabel(title: 'Employment Details', icon: Icons.work_outline),
//                   const SizedBox(height: 12),
//                   _EmploymentGrid(emp: emp),
//                   const SizedBox(height: 20),
                 
                  
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _ProfileHero extends StatelessWidget {
//   final Employee emp;
//   const _ProfileHero({required this.emp});

//   @override
//   Widget build(BuildContext context) {
//     final topPad = MediaQuery.of(context).padding.top;
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Stack(
//         children: [
//           // Decorative Circles
//           Positioned(top: -40, right: -40,
//             child: _DecorCircle(size: 180, opacity: 0.07)),
//           Positioned(bottom: -30, left: -30,
//             child: _DecorCircle(size: 140, opacity: 0.05)),
//           Positioned(top: 60, right: 80,
//             child: _DecorCircle(size: 60, opacity: 0.06)),

//           Padding(
//             padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Back button row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     GestureDetector(
//                     //  onTap: () => Navigator.maybePop(context),
//                     onTap: () => Navigator.pop(context),
//                       child: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(color: Colors.white.withOpacity(0.2)),
//                         ),
//                         child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
//                       ),
//                     ),
//                   const SizedBox(),
//                   ],
//                 ),
//                 const SizedBox(height: 24),

              

                
// // Column(
// Center(
//   child: Column(
 
//    crossAxisAlignment: CrossAxisAlignment.center,
//   children: [
    
//     Container(
//       width: 82, height: 82,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: const LinearGradient(
//           colors: [Color(0xFF6BA3D6), Color(0xFF244F87)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         border: Border.all(color: Colors.white, width: 3),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.25),
//             blurRadius: 16,
//             offset: const Offset(0, 6),
//           ),
//         ],
//       ),
//       child: Center(
//         child: Text(
//           emp.name.split(' ').map((e) => e[0]).take(2).join(),
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 26,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//       ),
//     ),
//     const SizedBox(height: 14),
//     // Name
//     Text(
//       emp.name,
//       style: const TextStyle(
//         color: Colors.white,
//         fontSize: 20,
//         fontWeight: FontWeight.w800,
//         letterSpacing: -0.3,
//       ),
//     ),
//     const SizedBox(height: 4),
//     // Role badge
//     Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//       decoration: BoxDecoration(
//         color: AppColors.accent.withOpacity(0.25),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: AppColors.accent.withOpacity(0.5)),
//       ),
//       child: Text(
//         emp.role,
//         style: const TextStyle(
//           color: Color(0xFFFFE0A3),
//           fontSize: 11.5,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     ),
//     const SizedBox(height: 8),
//     // Tags
//     Wrap(
//       spacing: 6, runSpacing: 4,
//       children: [
//         _MiniTag(icon: Icons.badge_outlined,       label: 'ID: ${emp.empId}'),
//         _MiniTag(icon: Icons.location_on_outlined, label: emp.location),
//         _MiniTag(icon: Icons.business_outlined,    label: emp.department),
//       ],
//     ),
//   ],
// ),
//  ), 
//                 const SizedBox(height: 20),

//                 // Contact row
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(14),
//                     border: Border.all(color: Colors.white.withOpacity(0.15)),
//                   ),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Row(
//                           children: [
//                             Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.7), size: 14),
//                             const SizedBox(width: 6),
//                             Flexible(
//                               child: Text(
//                                 emp.phone,
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2)),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Row(
//                           children: [
//                             Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7), size: 14),
//                             const SizedBox(width: 6),
//                             Flexible(
//                               child: Text(
//                                 emp.email,
//                                 style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DecorCircle extends StatelessWidget {
//   final double size;
//   final double opacity;
//   const _DecorCircle({required this.size, required this.opacity});
//   @override
//   Widget build(BuildContext context) => Container(
//         width: size, height: size,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           color: Colors.white.withOpacity(opacity),
//         ),
//       );
// }

// class _MiniTag extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   const _MiniTag({required this.icon, required this.label});
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.12),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: Colors.white.withOpacity(0.18)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 10, color: Colors.white.withOpacity(0.75)),
//           const SizedBox(width: 4),
//           Text(label,
//               style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
//         ],
//       ),
//     );
//   }
// }

// class _QuickStatsRow extends StatelessWidget {
//   final Employee emp;
//   const _QuickStatsRow({required this.emp});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         _QuickStat(label: 'Service',   value: '2Y 3M',       icon: Icons.timelapse,       color: AppColors.primary),
//         const SizedBox(width: 10),
//         _QuickStat(label: 'Age',       value: '${emp.age}Y', icon: Icons.cake_outlined,   color: AppColors.accent),
//         const SizedBox(width: 10),
//         _QuickStat(label: 'Retire In', value: '23Y 6M',      icon: Icons.shield_outlined, color: AppColors.success),
//       ],
//     );
//   }
// }

// class _QuickStat extends StatelessWidget {
//   final String label;
//   final String value;
//   final IconData icon;
//   final Color color;
//   const _QuickStat({required this.label, required this.value, required this.icon, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
//         decoration: BoxDecoration(
//           color: AppColors.card,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: AppColors.border),
//           boxShadow: const [BoxShadow(color: Color(0x0A346CB0), blurRadius: 10, offset: Offset(0, 3))],
//         ),
//         child: Column(
//           children: [
//             Container(
//               width: 38, height: 38,
//               decoration: BoxDecoration(
//                 color: color.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(icon, color: color, size: 18),
//             ),
//             const SizedBox(height: 6),
//             Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
//             Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textLight, fontWeight: FontWeight.w500)),
//           ],
//         ),
//       ),
//     );
//   }
// }


// class _SectionLabel extends StatelessWidget {
//   final String title;
//   final IconData icon;
//   const _SectionLabel({required this.title, required this.icon});

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(6),
//           decoration: BoxDecoration(
//             color: AppColors.primaryXLight,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(icon, size: 14, color: AppColors.primary),
//         ),
//         const SizedBox(width: 8),
//         Text(title,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
//         const SizedBox(width: 10),
//         const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
//       ],
//     );
//   }
// }


// class _PersonalInfoGrid extends StatelessWidget {
//   final Employee emp;
//   const _PersonalInfoGrid({required this.emp});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.person_outline,
//                 label: 'Gender',
//                 value: emp.gender,
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: 
//              _InfoTile(
//   icon: Icons.cake_outlined,
//   label: 'Date of Birth',
//   value: emp.dobAD,
//   sub: '${emp.dobBS} BS',
// ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),

//         Row(
//           children: [
//             Expanded(
//               child:
//               _InfoTile(
//   icon: Icons.badge_outlined,
//   label: 'Employee Type',
//   value: emp.employeeType,
// ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.category_outlined,
//                 label: 'Employee Category',
//                 value: emp.employeeCategory ?? 'Not Assigned',
//                 valueColor: emp.employeeCategory == null ? AppColors.textLight : AppColors.textDark,
//               ),
//             ),
//           ],
//         ),
       
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.location_on_outlined,
//                 iconBg: const Color(0xFFFDF0EE),
//                 iconFg: AppColors.danger,
//                 label: 'Permanent Address',
//                 value: emp.permanentAddress,
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.home_outlined,
//                 label: 'Temporary Address',
//                 value: emp.temporaryAddress,
//               ),
//             ),
//           ],
//         ),
//       ], 
//     );
//   }
// }
     


// class _EmploymentGrid extends StatelessWidget {
//   final Employee emp;
//   const _EmploymentGrid({required this.emp});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: 
//              _InfoTile(
//   icon: Icons.event_available_outlined,
//   label: 'Joining Date',
//   value: emp.joinDateAD,
//   sub: '${emp.joinDateBS} BS',
// ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.autorenew_outlined,
//                 iconBg: const Color(0xFFFFF5E0),
//                 iconFg: AppColors.accent,
//                 label: 'Renew Period',
//                 value: emp.renewPeriod ?? 'Not Specified',
//                 valueColor: emp.renewPeriod == null ? AppColors.textLight : null,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           children: [
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.timer_outlined,
//                 iconBg: const Color(0xFFFDF0EE),
//                 iconFg: AppColors.danger,
//                 label: 'Contract Expiry',
//                 value: emp.contractExpiryAD,
//                 sub: '${emp.contractExpiryBS} BS',
//                 valueColor: AppColors.danger,
//                 chip: _ChipData(label: emp.contractLeft, type: ChipType.danger, icon: Icons.access_time_outlined),
//               ),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: _InfoTile(
//                 icon: Icons.shield_outlined,
//                 iconBg: const Color(0xFFE6F9F0),
//                 iconFg: AppColors.success,
//                 label: 'Retirement Date',
//                 value: emp.retirementAD,
//                 sub: '${emp.retirementBS} BS',
//                 valueColor: AppColors.success,
//                 chip: _ChipData(label: emp.retirementLeft, type: ChipType.success, icon: Icons.access_time_outlined),
//               ),
//             ),
//           ],
//         ),
        
//       ],
//     );
//   }
// }


 

// enum ChipType { primary, warning, success, danger }

// class _ChipData {
//   final String label;
//   final ChipType type;
//   final IconData? icon;
//   const _ChipData({required this.label, required this.type, this.icon});
// }

// class _InfoTile extends StatelessWidget {
//   final IconData icon;
//   final Color? iconBg;
//   final Color? iconFg;
//   final String label;
//   final String value;
//   final String? sub;
//   final Color? valueColor;
//   final _ChipData? chip;
//   final bool showProgress;
//   final double progressValue;
//   final String? progressLabel;
//   final bool isFullWidth;

//   const _InfoTile({
//     required this.icon,
//     this.iconBg,
//     this.iconFg,
//     required this.label,
//     required this.value,
//     this.sub,
//     this.valueColor,
//     this.chip,
//     this.showProgress = false,
//     this.progressValue = 0,
//     this.progressLabel,
//     this.isFullWidth = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: isFullWidth ? double.infinity : null,
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: AppColors.card,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: AppColors.border),
//         boxShadow: const [BoxShadow(color: Color(0x0A346CB0), blurRadius: 10, offset: Offset(0, 3))],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 34, height: 34,
//                 decoration: BoxDecoration(
//                   color: iconBg ?? AppColors.primaryXLight,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(icon, size: 16, color: iconFg ?? AppColors.primary),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   label.toUpperCase(),
//                   style: const TextStyle(
//                     fontSize: 9.5,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.textLight,
//                     letterSpacing: 0.8,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w700,
//               color: valueColor ?? AppColors.textDark,
//             ),
//           ),
//           if (sub != null) ...[
//             const SizedBox(height: 2),
//             Text(sub!, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
//           ],
//           if (chip != null) ...[
//             const SizedBox(height: 8),
//             _ChipWidget(data: chip!),
//           ],
//           if (showProgress) ...[
//             const SizedBox(height: 10),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text('Service Progress', style: TextStyle(fontSize: 9.5, color: AppColors.textLight)),
//                 Text(progressLabel ?? '', style: const TextStyle(fontSize: 9.5, color: AppColors.textLight)),
//               ],
//             ),
//             const SizedBox(height: 5),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(4),
//               child: LinearProgressIndicator(
//                 value: progressValue,
//                 backgroundColor: AppColors.border,
//                 valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
//                 minHeight: 5,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }


// class _ChipWidget extends StatelessWidget {
//   final _ChipData data;
//   const _ChipWidget({required this.data});

//   (Color bg, Color fg, Color border) get _colors {
//     switch (data.type) {
//       case ChipType.warning:
//         return (const Color(0xFFFFF5E0), const Color(0xFFC87C00), const Color(0xFFFFE0A0));
//       case ChipType.success:
//         return (const Color(0xFFE6F9F0), const Color(0xFF1E8E4D), const Color(0xFFB0E8CC));
//       case ChipType.danger:
//         return (const Color(0xFFFDF0EE), const Color(0xFFB83228), const Color(0xFFF5C0BC));
//       case ChipType.primary:
//         return (AppColors.primaryXLight, AppColors.primaryDark, const Color(0xFFB6D4F0));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final (bg, fg, bdr) = _colors;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: bdr),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (data.icon != null) ...[
//             Icon(data.icon, size: 11, color: fg),
//             const SizedBox(width: 4),
//           ] else ...[
//             Container(width: 6, height: 6,
//                 decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
//             const SizedBox(width: 5),
//           ],
//           Flexible(
//             child: Text(data.label,
//                 style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
//                 overflow: TextOverflow.ellipsis),
//           ),
//         ],
//       ),
//     );
//   }
// }



import 'package:flutter/material.dart';

void main() {
  runApp(const HRISApp());
}

class HRISApp extends StatelessWidget {
  const HRISApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HRIS Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF346CB0),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const EmployeeProfilePage(),
    );
  }
}

class AppColors {
  static const primary       = Color(0xFF346CB0);
  static const primaryDark   = Color(0xFF244F87);
  static const primaryLight  = Color(0xFF4A85CC);
  static const primaryXLight = Color(0xFFDDEAF8);
  static const accent        = Color(0xFFF5A623);
  static const success       = Color(0xFF27AE60);
  static const danger        = Color(0xFFE74C3C);
  static const textDark      = Color(0xFF1A2640);
  static const textMid       = Color(0xFF4A5870);
  static const textLight     = Color(0xFF8A9AB8);
  static const surface       = Color(0xFFF0F4FA);
  static const card          = Colors.white;
  static const border        = Color(0xFFDDE5F2);
}

class Employee {
  final String name;
  final String empId;
  final String role;
  final String department;
  final String location;
  final String phone;
  final String email;
  final String gender;
  final String dobAD;
  final String dobBS;
  final int age;
  final String employeeType;
  final String? employeeCategory;
  final String joinDateAD;
  final String joinDateBS;
  final String servicePeriod;
  final String? renewPeriod;
  final String contractExpiryAD;
  final String contractExpiryBS;
  final String contractLeft;
  final String retirementAD;
  final String retirementBS;
  final String retirementLeft;
  final String permanentAddress;
  final String temporaryAddress;
 

  const Employee({
    required this.name,
    required this.empId,
    required this.role,
    required this.department,
    required this.location,
    required this.phone,
    required this.email,
    required this.gender,
    required this.dobAD,
    required this.dobBS,
    required this.age,
    required this.employeeType,
    this.employeeCategory,
    required this.joinDateAD,
    required this.joinDateBS,
    required this.servicePeriod,
    this.renewPeriod,
    required this.contractExpiryAD,
    required this.contractExpiryBS,
    required this.contractLeft,
    required this.retirementAD,
    required this.retirementBS,
    required this.retirementLeft,
    required this.permanentAddress,
    required this.temporaryAddress,
  });
}

final sampleEmployee = const Employee(
  name: 'Sushma Paudel',
  empId: '16',
  role: 'Sr. Staff Nurse',
  department: 'Outpatient',
  location: 'Kathmandu',
  phone: '9849269721',
  email: 'sushama.bashistha@gmail.com',
  gender: 'Female',
  dobAD: '1991/10/01',
  dobBS: '2048/06/15',
  age: 34,
  employeeType: 'Probationary',
  employeeCategory: null,
  joinDateAD: '2023/12/03',
  joinDateBS: '2080/08/17',
  servicePeriod: '2 Years, 3 Months, 8 Days',
  renewPeriod: null,
  contractExpiryAD: '2024/11/29',
  contractExpiryBS: '2081/08/14',
  contractLeft: '1Y, 3M, 10D Left',
  retirementAD: '2049/10/01',
  retirementBS: '2106/06/15',
  retirementLeft: '23Y, 6M, 22D Remaining',
  permanentAddress: 'Kathmandu',
  temporaryAddress: 'Lamjung',
);


enum LayoutStyle { rowList, stripSection, timelineAccordion }


const kCurrentLayout = LayoutStyle.rowList; 
class EmployeeProfilePage extends StatelessWidget {
  const EmployeeProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final emp = sampleEmployee;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHero(emp: emp),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuickStatsRow(emp: emp),
                  const SizedBox(height: 24),

                  // ── STYLE 1: Clean Row List (iOS-settings style) ──────────
                  if (kCurrentLayout == LayoutStyle.rowList) ...[
                    _SectionLabel(title: 'Personal Information', icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _RowListSection(items: _personalRows(emp)),
                    const SizedBox(height: 20),
                    _SectionLabel(title: 'Employment Details', icon: Icons.work_outline),
                    const SizedBox(height: 12),
                    _RowListSection(items: _employmentRows(emp)),
                  ],

                  // ── STYLE 2: Colored Strip Sections ──────────────────────
                  if (kCurrentLayout == LayoutStyle.stripSection) ...[
                    _StripSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      accentColor: AppColors.primary,
                      items: _personalRows(emp),
                    ),
                    const SizedBox(height: 16),
                    _StripSection(
                      title: 'Employment Details',
                      icon: Icons.work_outline,
                      accentColor: AppColors.accent,
                      items: _employmentRows(emp),
                    ),
                  ],

                  // ── STYLE 3: Timeline / Accordion ────────────────────────
                  if (kCurrentLayout == LayoutStyle.timelineAccordion) ...[
                    _TimelineSection(
                      title: 'Personal Information',
                      icon: Icons.person_outline,
                      items: _personalRows(emp),
                    ),
                    const SizedBox(height: 16),
                    _TimelineSection(
                      title: 'Employment Details',
                      icon: Icons.work_outline,
                      items: _employmentRows(emp),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  List<_RowItem> _personalRows(Employee emp) => [
    _RowItem(icon: Icons.person_outline,       label: 'Gender',             value: emp.gender),
    _RowItem(icon: Icons.cake_outlined,        label: 'Date of Birth',      value: emp.dobAD,           sub: '${emp.dobBS} BS'),
    _RowItem(icon: Icons.badge_outlined,       label: 'Employee Type',      value: emp.employeeType),
    _RowItem(icon: Icons.category_outlined,    label: 'Employee Category',  value: emp.employeeCategory ?? 'Not Assigned', muted: emp.employeeCategory == null),
    _RowItem(icon: Icons.location_on_outlined, label: 'Permanent Address',  value: emp.permanentAddress, iconColor: AppColors.danger),
    _RowItem(icon: Icons.home_outlined,        label: 'Temporary Address',  value: emp.temporaryAddress),
  ];

  List<_RowItem> _employmentRows(Employee emp) => [
    _RowItem(icon: Icons.event_available_outlined, label: 'Joining Date',      value: emp.joinDateAD,       sub: '${emp.joinDateBS} BS'),
    _RowItem(icon: Icons.autorenew_outlined,       label: 'Renew Period',      value: emp.renewPeriod ?? 'Not Specified', muted: emp.renewPeriod == null, iconColor: AppColors.accent),
    _RowItem(icon: Icons.timer_outlined,           label: 'Contract Expiry',   value: emp.contractExpiryAD, sub: '${emp.contractExpiryBS} BS', valueColor: AppColors.danger, badge: emp.contractLeft, badgeType: ChipType.danger),
    _RowItem(icon: Icons.shield_outlined,          label: 'Retirement Date',   value: emp.retirementAD,     sub: '${emp.retirementBS} BS',    valueColor: AppColors.success, badge: emp.retirementLeft, badgeType: ChipType.success),
  ];
}


class _RowItem {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final String? sub;
  final Color? valueColor;
  final bool muted;
  final String? badge;
  final ChipType? badgeType;

  const _RowItem({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.sub,
    this.valueColor,
    this.muted = false,
    this.badge,
    this.badgeType,
  });
}


class _RowListSection extends StatelessWidget {
  final List<_RowItem> items;
  const _RowListSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0A346CB0), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return _RowListTile(item: item, isLast: isLast);
        }).toList(),
      ),
    );
  }
}

class _RowListTile extends StatelessWidget {
  final _RowItem item;
  final bool isLast;
  const _RowListTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon dot
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: (item.iconColor ?? AppColors.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 15, color: item.iconColor ?? AppColors.primary),
              ),
              const SizedBox(width: 12),
              // Label + Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item.muted
                            ? AppColors.textLight
                            : (item.valueColor ?? AppColors.textDark),
                        fontStyle: item.muted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (item.sub != null) ...[
                      const SizedBox(height: 2),
                      Text(item.sub!, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                    if (item.badge != null && item.badgeType != null) ...[
                      const SizedBox(height: 6),
                      _ChipWidget(data: _ChipData(label: item.badge!, type: item.badgeType!, icon: Icons.access_time_outlined)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 60),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
      ],
    );
  }
}


class _StripSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_RowItem> items;
  const _StripSection({required this.title, required this.icon, required this.accentColor, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border(
              left: BorderSide(color: accentColor, width: 3),
              top: BorderSide(color: accentColor.withOpacity(0.2)),
              right: BorderSide(color: accentColor.withOpacity(0.2)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: accentColor),
              ),
            ],
          ),
        ),
        // Items
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            border: Border(
              left: BorderSide(color: accentColor, width: 3),
              bottom: BorderSide(color: AppColors.border),
              right: BorderSide(color: AppColors.border),
            ),
            boxShadow: const [BoxShadow(color: Color(0x08346CB0), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return _StripTile(item: entry.value, isLast: isLast, accentColor: accentColor);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StripTile extends StatelessWidget {
  final _RowItem item;
  final bool isLast;
  final Color accentColor;
  const _StripTile({required this.item, required this.isLast, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Label side
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Icon(item.icon, size: 13, color: item.iconColor ?? accentColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMid, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              // Value side
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.value,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.muted ? AppColors.textLight : (item.valueColor ?? AppColors.textDark),
                        fontStyle: item.muted ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    if (item.sub != null)
                      Text(item.sub!, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                    if (item.badge != null && item.badgeType != null) ...[
                      const SizedBox(height: 4),
                      _ChipWidget(data: _ChipData(label: item.badge!, type: item.badgeType!, icon: Icons.access_time_outlined)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
      ],
    );
  }
}


class _TimelineSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_RowItem> items;
  const _TimelineSection({required this.title, required this.icon, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(title: title, icon: icon),
        const SizedBox(height: 14),
        // Timeline items
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return _TimelineTile(item: item, isLast: isLast);
        }),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _RowItem item;
  final bool isLast;
  const _TimelineTile({required this.item, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final dotColor = item.iconColor ?? AppColors.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline spine
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    boxShadow: [BoxShadow(color: dotColor.withOpacity(0.35), blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
                // Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content block
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [BoxShadow(color: Color(0x08346CB0), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 14, color: dotColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textLight, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: item.muted ? AppColors.textLight : (item.valueColor ?? AppColors.textDark),
                              fontStyle: item.muted ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                          if (item.sub != null) ...[
                            const SizedBox(height: 1),
                            Text(item.sub!, style: const TextStyle(fontSize: 10.5, color: AppColors.textLight)),
                          ],
                          if (item.badge != null && item.badgeType != null) ...[
                            const SizedBox(height: 6),
                            _ChipWidget(data: _ChipData(label: item.badge!, type: item.badgeType!, icon: Icons.access_time_outlined)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _ProfileHero extends StatelessWidget {
  final Employee emp;
  const _ProfileHero({required this.emp});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -40, right: -40, child: _DecorCircle(size: 180, opacity: 0.07)),
          Positioned(bottom: -30, left: -30, child: _DecorCircle(size: 140, opacity: 0.05)),
          Positioned(top: 60, right: 80, child: _DecorCircle(size: 60, opacity: 0.06)),
          Padding(
           // padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
           padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    const SizedBox(),
                  ],
                ),
               // const SizedBox(height: 24),
               const SizedBox(height: 12),
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                       // width: 82, height: 82,
                       width: 68, height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6BA3D6), Color(0xFF244F87)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            emp.name.split(' ').map((e) => e[0]).take(2).join(),
                            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(emp.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accent.withOpacity(0.5)),
                        ),
                        child: Text(emp.role, style: const TextStyle(color: Color(0xFFFFE0A3), fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6, runSpacing: 4,
                        children: [
                          _MiniTag(icon: Icons.badge_outlined,       label: 'ID: ${emp.empId}'),
                          _MiniTag(icon: Icons.location_on_outlined, label: emp.location),
                          _MiniTag(icon: Icons.business_outlined,    label: emp.department),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, color: Colors.white.withOpacity(0.7), size: 14),
                            const SizedBox(width: 6),
                            Flexible(child: Text(emp.phone, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 20, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7), size: 14),
                            const SizedBox(width: 6),
                            Flexible(child: Text(emp.email, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _DecorCircle({required this.size, required this.opacity});
  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
      );
}

class _MiniTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniTag({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white.withOpacity(0.75)),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10.5, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final Employee emp;
  const _QuickStatsRow({required this.emp});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickStat(label: 'Service',   value: '2Y 3M',       icon: Icons.timelapse,       color: AppColors.primary),
        const SizedBox(width: 10),
        _QuickStat(label: 'Age',       value: '${emp.age}Y', icon: Icons.cake_outlined,   color: AppColors.accent),
        const SizedBox(width: 10),
        _QuickStat(label: 'Retire In', value: '23Y 6M',      icon: Icons.shield_outlined, color: AppColors.success),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _QuickStat({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A346CB0), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionLabel({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.primaryXLight, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    );
  }
}


enum ChipType { primary, warning, success, danger }

class _ChipData {
  final String label;
  final ChipType type;
  final IconData? icon;
  const _ChipData({required this.label, required this.type, this.icon});
}

class _ChipWidget extends StatelessWidget {
  final _ChipData data;
  const _ChipWidget({required this.data});

  (Color bg, Color fg, Color border) get _colors {
    switch (data.type) {
      case ChipType.warning: return (const Color(0xFFFFF5E0), const Color(0xFFC87C00), const Color(0xFFFFE0A0));
      case ChipType.success: return (const Color(0xFFE6F9F0), const Color(0xFF1E8E4D), const Color(0xFFB0E8CC));
      case ChipType.danger:  return (const Color(0xFFFDF0EE), const Color(0xFFB83228), const Color(0xFFF5C0BC));
      case ChipType.primary: return (AppColors.primaryXLight, AppColors.primaryDark, const Color(0xFFB6D4F0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, bdr) = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: bdr)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (data.icon != null) ...[
            Icon(data.icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ] else ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: fg)),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(data.label,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}