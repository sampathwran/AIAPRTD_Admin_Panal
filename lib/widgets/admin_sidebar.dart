import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final List<String> menuTitles;
  final List<IconData> menuIcons;
  final ValueChanged<int> onMenuSelected;
  final bool isDriverMode;
  final VoidCallback onToggleMode;

  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.menuTitles,
    required this.menuIcons,
    required this.onMenuSelected,
    required this.isDriverMode,
    required this.onToggleMode,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final currentThemeColor = isDriverMode ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 290,
      child: Material(
        color: currentThemeColor,
        child: Column(
          children: [
            // ==========================================================
            // 🏆 1. SUPER ADMIN BRANDING & COLLAPSE ARROW BUTTON
            // ==========================================================
            Padding(
              padding: const EdgeInsets.only(top: 20.0, bottom: 8.0, left: 12.0, right: 12.0),
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                children: [
                  if (!isCollapsed)
                    const Row(
                      children: [
                        Icon(Icons.gavel_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'AIAPRTD SUPER',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),

                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: onToggleCollapse,
                  ),
                ],
              ),
            ),

            // ==========================================================
            // 🔄 2. THE DASHBOARD SWIPER / TOGGLE BUTTON
            // ==========================================================
            if (!isCollapsed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GestureDetector(
                  onTap: onToggleMode,
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        AnimatedAlign(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          alignment: isDriverMode ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            width: 125,
                            height: 37,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isDriverMode ? Colors.amber : Colors.blueAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Drivers',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(child: SizedBox()),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Passengers',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Divider(color: Colors.white24, height: 1),
            ],

            const SizedBox(height: 10),

            // ==========================================================
            // 🛠️ 3. DYNAMIC NAVIGATION MENU (අයිතම 12)
            // ==========================================================
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: menuTitles.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedIndex == index;

                  return Tooltip(
                    message: isCollapsed ? menuTitles[index] : "",
                    textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                      child: ListTile(
                        onTap: () => onMenuSelected(index),
                        dense: true,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        tileColor: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,

                        // 💡 FIXED: SizedBox(double.infinity) එක අයින් කරලා, collapsed වෙලාවට Icon එක ලස්සනට මැදට ගන්න 'Center' විජට් එකක් යෙදුවා මචං. දැන් කිසිම layout crash එකක් වෙන්නේ නැහැ.
                        leading: isCollapsed
                            ? Center(
                          widthFactor: 1.0, // Constraints ස්ථාවරව තබා ගනී
                          child: Icon(
                            menuIcons[index],
                            color: isSelected ? (isDriverMode ? Colors.amber : Colors.tealAccent) : Colors.white70,
                            size: 20,
                          ),
                        )
                            : Icon(
                          menuIcons[index],
                          color: isSelected ? (isDriverMode ? Colors.amber : Colors.tealAccent) : Colors.white70,
                          size: 20,
                        ),

                        title: isCollapsed
                            ? null
                            : Text(
                          menuTitles[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                isCollapsed ? 'v1.0' : 'Super Admin Mode v1.0',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            )
          ],
        ),
      ),
    );
  }
}