import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ar_model_detail_page.dart';

class ARModelItem {
  final String title;
  final String path;
  final IconData icon;
  final Color color;

  ARModelItem({
    required this.title,
    required this.path,
    required this.icon,
    required this.color,
  });
}

class ARViewerPage extends StatelessWidget {
  const ARViewerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<ARModelItem> models = [
      ARModelItem(
        title: 'Stomach Anatomy',
        path: 'assets/models/stomach_-_organ.glb',
        icon: Icons.science_outlined,
        color: const Color(0xFFFFD3B6),
      ),
      ARModelItem(
        title: 'Solar System',
        path: 'assets/models/solar_system_animation.glb',
        icon: Icons.public,
        color: const Color(0xFFA8E6CF),
      ),
      ARModelItem(
        title: 'Human Anatomy',
        path: 'assets/models/human_anatomy.glb',
        icon: Icons.accessibility_new_outlined,
        color: const Color(0xFFFF8B94),
      ),
      ARModelItem(
        title: 'Jet Engine',
        path: 'assets/models/jet_engine.glb',
        icon: Icons.flight_takeoff,
        color: const Color(0xFFC5CAE9),
      ),
      ARModelItem(
        title: 'Car Engine',
        path: 'assets/models/car_engine.glb',
        icon: Icons.directions_car_outlined,
        color: const Color(0xFFDCEDC1),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFB8E6D5), // Match dashboard theme
      appBar: AppBar(
        title: Text(
          'AR Models',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85, // Makes the grid items slightly taller
            ),
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ARModelDetailPage(
                        modelPath: model.path,
                        title: model.title,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: model.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        offset: Offset(4, 4),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Icon(model.icon, size: 40, color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          model.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
