import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/prayer_service.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/share_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/daily_inspiration_card.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../about/about_screen.dart';
import '../bookmarks/bookmarks_group_screen.dart';
import '../dua_detail/dua_detail_screen.dart';
import '../categories/category_grid_screen.dart';
import '../calendar/hijri_calendar_screen.dart';
import '../prayer_times/prayer_times_screen.dart';
import '../settings/settings_screen.dart';
import '../zakat/zakat_calculator_screen.dart';

enum _ViewMode { grid, list }

class DuaGroupScreen extends StatefulWidget {
  const DuaGroupScreen({super.key});

  @override
  State<DuaGroupScreen> createState() => _DuaGroupScreenState();
}

class _DuaGroupScreenState extends State<DuaGroupScreen> {
  _ViewMode _viewMode = _ViewMode.grid;
  List<Dua> _duaGroups = [];
  List<Dua> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  bool _searchActive = false;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rows = await DatabaseHelper.instance.getDuaGroups(
      searchFilter: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (!mounted) return;
    setState(() {
      _duaGroups = rows.map(Dua.fromGroupCursor).toList();
      _filtered = _duaGroups;
      _loading = false;
    });
  }

  void _onSearch(String query) async {
    setState(() => _searchQuery = query);
    final rows = await DatabaseHelper.instance.getDuaGroups(searchFilter: query);
    if (!mounted) return;
    setState(() => _filtered = rows.map(Dua.fromGroupCursor).toList());
  }

  void _openDetail(Dua dua) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuaDetailScreen(duaId: dua.reference, duaTitle: dua.title ?? ''),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_searchActive) {
      setState(() {
        _searchActive = false;
        _searchController.clear();
        _onSearch('');
      });
      return false;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 1)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press once again to exit!'),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final appBarTextColor = isDark ? theme.colorScheme.onSurface : Colors.white;
    final firebaseService = context.watch<FirebaseService>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDark ? theme.appBarTheme.backgroundColor : AppTheme.primaryRed,
          title: _searchActive
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: appBarTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search duas...',
                    hintStyle: TextStyle(
                      color: appBarTextColor.withValues(alpha: 0.62),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearch,
                )
              : Text(
                  'Deen Azkar',
                  style: TextStyle(
                    color: appBarTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ClipOval(
              child: Image.asset(
                'assets/img/app_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          actions: [
            if (_searchActive)
              IconButton(
                icon: Icon(Icons.close, color: appBarTextColor),
                onPressed: () {
                  setState(() {
                    _searchActive = false;
                    _searchController.clear();
                    _onSearch('');
                  });
                },
              )
            else ...[
              IconButton(
                icon: Icon(Icons.search, color: appBarTextColor),
                onPressed: () => setState(() => _searchActive = true),
              ),
              IconButton(
                icon: Icon(Icons.bookmark_border, color: appBarTextColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksGroupScreen()),
                ),
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => firebaseService.fetchDailyInspiration(),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Banner Ad at Top
                const SafeTopBannerAd(),
                if (firebaseService.dailyInspiration != null)
                  DailyInspirationCard(
                    inspiration: firebaseService.dailyInspiration!,
                    isLoading: firebaseService.isLoading,
                  ),
                _buildOptionBar(),
                _loading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryRed)),
                      )
                    : _viewMode == _ViewMode.grid
                        ? const CategoryGridScreen(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                          )
                        : _buildListView(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _HomeBottomPanel(
          onPrayer: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
          ),
          onZakat: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ZakatCalculatorScreen()),
          ),
          onHijri: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HijriCalendarScreen()),
          ),
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionBar() {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            _OptionButton(
              icon: Icons.grid_view_rounded,
              label: 'Categories',
              isActive: _viewMode == _ViewMode.grid,
              onTap: () => setState(() => _viewMode = _ViewMode.grid),
            ),
            const SizedBox(width: 8),
            _OptionButton(
              icon: Icons.list_rounded,
              label: 'All Duas',
              isActive: _viewMode == _ViewMode.list,
              onTap: () => setState(() => _viewMode = _ViewMode.list),
            ),
            const SizedBox(width: 8),
            _OptionButton(
              icon: Icons.bookmark_rounded,
              label: 'Bookmarks',
              isActive: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookmarksGroupScreen()),
              ),
            ),
            const SizedBox(width: 8),
            _OptionButton(
              icon: Icons.search_rounded,
              label: 'Search',
              isActive: _searchActive,
              onTap: () => setState(() => _searchActive = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: Text('No duas found', style: TextStyle(color: AppTheme.subTextColor)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filtered.length,
      itemBuilder: (_, index) => _DuaGroupListItem(
        dua: _filtered[index],
        onTap: () => _openDetail(_filtered[index]),
        onFavToggle: (newFav) async {
          await DatabaseHelper.instance.setGroupFavStatus(_filtered[index].reference, newFav);
          setState(() => _filtered[index] = _filtered[index].copyWith(isFav: newFav));
        },
      ),
    );
  }
}

// ─── Option Bar Button ──────────────────────────────────────────────────────

class _HomeBottomPanel extends StatefulWidget {
  final VoidCallback onPrayer;
  final VoidCallback onZakat;
  final VoidCallback onHijri;
  final VoidCallback onSettings;

  const _HomeBottomPanel({
    required this.onPrayer,
    required this.onZakat,
    required this.onHijri,
    required this.onSettings,
  });

  @override
  State<_HomeBottomPanel> createState() => _HomeBottomPanelState();
}

class _HomeBottomPanelState extends State<_HomeBottomPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor =
        isDark ? theme.colorScheme.surface : const Color(0xFFFFFBF4);
    final settings = context.watch<SettingsService>();
    final prayerService = context.read<PrayerService>();
    final isEnabled = settings.dailyRemindersEnabled;

    return SafeArea(
      top: false,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            decoration: BoxDecoration(
              color: surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          color: isEnabled 
                              ? AppTheme.accentGold 
                              : theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Reminder',
                              style: TextStyle(
                                color: isEnabled
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Don't miss your daily adhkar",
                              style: TextStyle(
                                color: isEnabled
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.82)
                                    : theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isEnabled,
                        activeColor: theme.colorScheme.onPrimary,
                        activeTrackColor: AppTheme.accentGold.withValues(alpha: 0.8),
                        inactiveThumbColor: theme.colorScheme.outline,
                        inactiveTrackColor:
                            theme.colorScheme.surfaceContainerHighest,
                        onChanged: (value) async {
                          await settings.setDailyRemindersEnabled(value);
                          await prayerService.refreshDuaReminders();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BottomNavAction(
                        icon: Icons.access_time_rounded,
                        label: 'Prayer',
                        onTap: widget.onPrayer,
                      ),
                    ),
                    Expanded(
                      child: _BottomNavAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Hijri',
                        onTap: widget.onHijri,
                      ),
                    ),
                    Expanded(
                      child: _BottomNavAction(
                        icon: Icons.calculate_rounded,
                        label: 'Zakat',
                        onTap: widget.onZakat,
                      ),
                    ),
                    Expanded(
                      child: _BottomNavAction(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        onTap: widget.onSettings,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  State<_BottomNavAction> createState() => _BottomNavActionState();
}

class _BottomNavActionState extends State<_BottomNavAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
      lowerBound: 0.9,
      upperBound: 1,
      value: 1,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final color = widget.selected
        ? selectedColor
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.reverse(),
      onTapCancel: () => _controller.forward(),
      onTapUp: (_) {
        _controller.forward();
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? selectedColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: color, size: 23),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _OptionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _OptionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_OptionButton> createState() => _OptionButtonState();
}

class _OptionButtonState extends State<_OptionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.9,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _ctrl;
  }

  void _onTapDown(TapDownDetails _) => _ctrl.reverse();
  void _onTapUp(TapUpDetails _) {
    _ctrl.forward();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = theme.colorScheme.onSurfaceVariant;
    final activeColor = theme.colorScheme.primary;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? activeColor.withOpacity(0.16)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive
                  ? activeColor
                  : theme.colorScheme.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isActive ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.isActive
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.isActive ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dua Group List Item ────────────────────────────────────────────────────

class _DuaGroupListItem extends StatelessWidget {
  final Dua dua;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavToggle;

  const _DuaGroupListItem({
    required this.dua,
    required this.onTap,
    required this.onFavToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Reference badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${dua.reference}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dua.title ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              _AnimatedFavButton(
                isFav: dua.isFav,
                onTap: () => onFavToggle(!dua.isFav),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Fav Button ────────────────────────────────────────────────────

class _AnimatedFavButton extends StatefulWidget {
  final bool isFav;
  final VoidCallback onTap;

  const _AnimatedFavButton({required this.isFav, required this.onTap});

  @override
  State<_AnimatedFavButton> createState() => _AnimatedFavButtonState();
}

class _AnimatedFavButtonState extends State<_AnimatedFavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0);
        widget.onTap();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Icon(
          widget.isFav ? Icons.star_rounded : Icons.star_border_rounded,
          color: widget.isFav
              ? AppTheme.accentGold
              : Theme.of(context).colorScheme.onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }
}
