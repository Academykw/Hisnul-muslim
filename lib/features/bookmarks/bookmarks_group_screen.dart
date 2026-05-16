import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/ad_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';
import '../dua_detail/dua_detail_screen.dart';

class BookmarksGroupScreen extends StatefulWidget {
  const BookmarksGroupScreen({super.key});

  @override
  State<BookmarksGroupScreen> createState() => _BookmarksGroupScreenState();
}

class _BookmarksGroupScreenState extends State<BookmarksGroupScreen> {
  List<Dua> _groups = [];
  bool _loading = true;
  String? _lastLoadedLocale;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = context.watch<SettingsService>().localeCode;
    if (_lastLoadedLocale != locale) {
      _lastLoadedLocale = locale;
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final settings = context.read<SettingsService>();
    final rows = await DatabaseHelper.instance.getFavoriteDuaGroups(
      locale: settings.localeCode,
    );
    if (!mounted) return;
    setState(() {
      _groups = rows.map(Dua.fromGroupCursor).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: Column(
        children: [
          // Banner Ad at Top
          const SafeTopBannerAd(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
                : _groups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border_rounded,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(
                              'No bookmarks yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the ★ on any dua to bookmark it',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primaryRed,
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _groups.length,
                          itemBuilder: (_, i) {
                            final g = _groups[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: ListTile(
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryRed,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${g.reference}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(g.title ?? ''),
                                trailing: const Icon(Icons.star_rounded,
                                    color: AppTheme.accentGold),
                                onTap: () {
                                  context.read<AdService>().showInterstitialAd(
                                    onAdDismissed: () {
                                      if (!mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => DuaDetailScreen(
                                            duaId: g.reference,
                                            duaTitle: g.title ?? '',
                                            favoritesOnly: true,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
