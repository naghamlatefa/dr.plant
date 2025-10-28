import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'BottomFloatingDecor.dart';
import 'services/api_service.dart';
import 'SearchAboutYourRegion.dart';
import 'login.dart';
import 'search.dart';
import 'TreatmentTrackingPage.dart';
import 'dart:ui';
import 'storage_helper.dart';
import "fastapi.dart";
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final SecureStorage = FlutterSecureStorage();

final TextEditingController plantNameController = TextEditingController();
final TextEditingController locationController = TextEditingController();
final String formattedDateFromImage = DateTime.now().toString().split(' ')[0];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _showProfileDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Profile Dialog",
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) {
        return const BlurredProfileDialog();
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          endDrawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(74, 157, 77, 1),
                  ),
                  child: Text(
                    'Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.green.shade700),
                  title: Text(
                    'Logout',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  onTap: () {
                    final rootContext = context;

                    showDialog(
                      context: rootContext,
                      builder:
                          (dialogContext) => AlertDialog(
                            title: Text(
                              "Confirm Logout?",
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                            content: const Text(
                              "Are you sure you want to logout?",
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(dialogContext).pop(),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const Login(),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                },

                                child: Text(
                                  "Logout",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.green.shade700,
                  ),
                  title: Text(
                    'About Us',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => Center(
                            child: SizedBox(
                              width: 400,
                              child: AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Our Team',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  'Ahmed Suleiman\n'
                                  'Nagham Latefa\n'
                                  'Mohammed Al-Metheab',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: const DecorationImage(
                        image: AssetImage('assets/3.jpg'),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 110),
                          child: IconButton(
                            icon: const Icon(
                              Icons.account_circle,
                              color: Colors.white,
                            ),
                            onPressed: () => _showProfileDialog(context),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: const CircleBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Text(
                            '🌿 Dr. Plant',
                            style: GoogleFonts.dancingScript(
                              textStyle: const TextStyle(
                                fontSize: 50,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 200),
                        children: [
                          buildFullWidthButton(
                            title: 'Scan Disease',
                            description: 'Detect diseases',
                            icon: Icons.search,
                            imagePath: 'assets/2.png',
                            backgroundColor: const Color(0xFF354024),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SearchPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          buildFullWidthButton(
                            title: 'Serch',
                            description: 'Sreah About Your region',
                            icon: Icons.landscape,
                            imagePath: 'assets/1.png',
                            backgroundColor: const Color(0xFF4C3D19),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const SearchAboutYourRegion(
                                        apiBaseUrl: apiBaseUrl,
                                      ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          buildFullWidthButton(
                            title: 'Treatment Tracking',
                            description: 'Follow your plant care',
                            icon: Icons.local_hospital,
                            imagePath: 'assets/1.png',
                            backgroundColor: const Color(0xFFCFB899),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TreatmentTrackingPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              Positioned(
                top: 50,
                left: 20,
                child: Builder(
                  builder:
                      (context) => Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      ),
                ),
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: const BottomFloatingDecor(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFullWidthButton({
    required String title,
    required String description,
    required IconData icon,
    required String imagePath,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return _AnimatedPressButton(
      title: title,
      description: description,
      icon: icon,
      imagePath: imagePath,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
    );
  }

  Widget buildSquareButton({
    required String title,
    required String description,
    required IconData icon,
    required String imagePath,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return _AnimatedSquareButton(
      title: title,
      description: description,
      icon: icon,
      imagePath: imagePath,
      backgroundColor: backgroundColor,
      onPressed: onPressed,
    );
  }
}

class _AnimatedPressButton extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _AnimatedPressButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 1.07);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onTapDown,
      onLongPressEnd: (_) => _onTapUp(null),
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Image.asset(
                widget.imagePath,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18,
                child: Icon(widget.icon, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedSquareButton extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _AnimatedSquareButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.imagePath,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  State<_AnimatedSquareButton> createState() => _AnimatedSquareButtonState();
}

class _AnimatedSquareButtonState extends State<_AnimatedSquareButton> {
  double _scale = 1.0;

  void _onTapDown(_) => setState(() => _scale = 1.07);
  void _onTapUp(_) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onTapDown,
      onLongPressEnd: (_) => _onTapUp(null),
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    widget.imagePath,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.description,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 16,
                  child: Icon(widget.icon, color: Colors.green, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlurredProfileDialog extends StatefulWidget {
  const BlurredProfileDialog({super.key});

  @override
  State<BlurredProfileDialog> createState() => _BlurredProfileDialogState();
}

class _BlurredProfileDialogState extends State<BlurredProfileDialog> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    // 1) اعرض من الكاش فورًا (لو موجود)
    final localData = await StorageHelper.getUserData();
    final hasLocal =
        (localData['name']?.isNotEmpty ?? false) ||
        (localData['email']?.isNotEmpty ?? false) ||
        (localData['phone']?.isNotEmpty ?? false);

    if (hasLocal) {
      nameController.text = localData['name'] ?? '';
      emailController.text = localData['email'] ?? '';
      phoneController.text = localData['phone'] ?? '';
      setState(() => _loading = false);
    }

    // 2) جرّب تحدّث من الـ API (ولو فشل، نترك القيم المحلية كما هي)
    try {
      final result = await ApiService.getUserProfile();
      if (result["success"] == true) {
        nameController.text = result["data"]["name"] ?? '';
        emailController.text = result["data"]["email"] ?? '';
        phoneController.text = result["data"]["phone"] ?? '';
      }
    } catch (_) {}

    if (!hasLocal) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
      child: Center(
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Profile'),
          content:
              _loading
                  ? const SizedBox(
                    height: 48,
                    width: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          icon: Icon(
                            Icons.person,
                            color: Colors.green.shade700,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          icon: Icon(Icons.email, color: Colors.green.shade700),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          labelStyle: TextStyle(color: Colors.green.shade700),
                          icon: Icon(Icons.phone, color: Colors.green.shade700),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
