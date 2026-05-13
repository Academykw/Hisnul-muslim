import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/ad_service.dart';
import '../../shared/theme/app_theme.dart';
import '../dua_group/filtered_dua_list_screen.dart';

class _Category {
  final String name;
  final String imageAsset;
  final IconData icon;
  final List<int> filterIds;

  const _Category({
    required this.name,
    required this.imageAsset,
    required this.icon,
    required this.filterIds,
  });
}

const _categories = [
  _Category(
    name: 'Illness',
    imageAsset: 'assets/img/illness.png',
    icon: Icons.medical_services_rounded,
    filterIds: [49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 124, 133],
  ),
  _Category(
    name: 'Daily Life',
    imageAsset: 'assets/img/daily_life.png',
    icon: Icons.wb_sunny_rounded,
    filterIds: [
      1, 2, 3, 4, 5, 6, 7, 10, 11, 28, 29, 30, 31, 41, 61, 62, 63, 64,
      65, 66, 67, 68, 69, 70, 71, 72, 76, 77, 78, 79, 80, 81, 82, 83, 97, 84,
      85, 86, 87, 89, 90, 107, 98, 106, 123, 108, 110, 112, 113, 122, 125, 111,
      126, 75, 127
    ],
  ),
  _Category(
    name: 'Travel',
    imageAsset: 'assets/img/travel.png',
    icon: Icons.flight_rounded,
    filterIds: [10, 99, 96, 97, 98, 95, 100, 101, 102, 103, 104, 105],
  ),
  _Category(
    name: 'Morning/Night',
    imageAsset: 'assets/img/morning_night.png',
    icon: Icons.bedtime_rounded,
    filterIds: [1, 27, 134, 28, 29, 30, 31, 129, 135],
  ),
  _Category(
    name: 'Prayer',
    imageAsset: 'assets/img/prayer.png',
    icon: Icons.accessibility_new_rounded,
    filterIds: [8, 9, 12, 13, 14, 15, 16, 17, 18, 119, 20, 21, 22, 23, 24, 25, 26, 32, 33, 127],
  ),
  _Category(
    name: 'Wellbeing',
    imageAsset: 'assets/img/wellbeing.png',
    icon: Icons.favorite_rounded,
    filterIds: [48, 88, 128, 35],
  ),
  _Category(
    name: 'Trials',
    imageAsset: 'assets/img/trials.png',
    icon: Icons.warning_rounded,
    filterIds: [34, 35, 36, 40, 41, 42, 43, 44, 45, 65, 66, 83, 88, 91, 92, 94, 123, 112, 38, 37, 125, 124, 128, 129],
  ),
  _Category(
    name: 'Hajj/Umrah',
    imageAsset: 'assets/img/hajj_umrah.png',
    icon: Icons.mosque_rounded,
    filterIds: [116, 117, 119, 118, 120, 121, 115],
  ),
  _Category(
    name: 'Quranic Duas',
    imageAsset: 'assets/img/quranic_duas.png',
    icon: Icons.menu_book_rounded,
    filterIds: [120, 121, 122, 123],
  ),
  _Category(
    name: 'Azkar',
    imageAsset: 'assets/img/azkar.png',
    icon: Icons.format_list_bulleted_rounded,
    filterIds: [107, 129, 84, 131],
  ),
];

class CategoryGridScreen extends StatelessWidget {
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CategoryGridScreen({
    super.key,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _categories.length,
      itemBuilder: (_, index) => _CategoryCard(category: _categories[index]),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final _Category category;

  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.93,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) async {
    await _ctrl.forward();
    if (!mounted) return;

    context.read<AdService>().showInterstitialAd(
          onAdDismissed: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FilteredDuaListScreen(
                  filterIds: widget.category.filterIds,
                  categoryTitle: widget.category.name,
                ),
              ),
            );
          },
        );
  }

  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                widget.category.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.primaryRed.withOpacity(0.15),
                ),
              ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.65),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(widget.category.icon,
                        color: Colors.white70, size: 22),
                    const SizedBox(height: 6),
                    Text(
                      widget.category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
