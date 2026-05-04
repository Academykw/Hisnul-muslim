import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/firebase_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/daily_inspiration_card.dart';
import '../bookmarks/bookmarks_group_screen.dart';
import '../dua_detail/dua_detail_screen.dart';
import '../categories/category_grid_screen.dart';
import '../home/home_screen.dart';

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
                      color: appBarTextColor.withOpacity(0.62),
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
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.menu, color: appBarTextColor),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
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
        drawer: const AppDrawer(),
        body: RefreshIndicator(
          onRefresh: () => firebaseService.fetchDailyInspiration(),
          child: SingleChildScrollView(
            child: Column(
              children: [
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
