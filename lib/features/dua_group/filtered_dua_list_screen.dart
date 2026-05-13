import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/ad_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../dua_detail/dua_detail_screen.dart';

class FilteredDuaListScreen extends StatefulWidget {
  final List<int> filterIds;
  final String categoryTitle;

  const FilteredDuaListScreen({
    super.key,
    required this.filterIds,
    required this.categoryTitle,
  });

  @override
  State<FilteredDuaListScreen> createState() => _FilteredDuaListScreenState();
}

class _FilteredDuaListScreenState extends State<FilteredDuaListScreen> {
  List<Dua> _duas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final rows = await DatabaseHelper.instance.getDuaGroupsFiltered(widget.filterIds);
    if (!mounted) return;
    setState(() {
      _duas = rows.map(Dua.fromGroupCursor).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
      ),
      body: Column(
        children: [
          // Banner Ad at Top
          const SafeTopBannerAd(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
                : _duas.isEmpty
                    ? Center(
                        child: Text(
                          'No duas found',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _duas.length,
                        itemBuilder: (_, index) {
                          final dua = _duas[index];
                          return _DuaListItem(
                            dua: dua,
                            onTap: () {
                              context.read<AdService>().showInterstitialAd(
                                onAdDismissed: () {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DuaDetailScreen(
                                        duaId: dua.reference,
                                        duaTitle: dua.title ?? '',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            onFavToggle: (newFav) async {
                              await DatabaseHelper.instance.setGroupFavStatus(dua.reference, newFav);
                              setState(() => _duas[index] = dua.copyWith(isFav: newFav));
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _DuaListItem extends StatelessWidget {
  final Dua dua;
  final VoidCallback onTap;
  final ValueChanged<bool> onFavToggle;

  const _DuaListItem({
    required this.dua,
    required this.onTap,
    required this.onFavToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
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
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          dua.title ?? '',
          style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface),
        ),
        trailing: GestureDetector(
          onTap: () => onFavToggle(!dua.isFav),
          child: Icon(
            dua.isFav ? Icons.star_rounded : Icons.star_border_rounded,
            color: dua.isFav
                ? AppTheme.accentGold
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
