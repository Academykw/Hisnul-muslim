
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/dua.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/share_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/banner_ad_widget.dart';

class DuaDetailScreen extends StatefulWidget {
  final int duaId;
  final String duaTitle;
  final bool favoritesOnly;

  const DuaDetailScreen({
    super.key,
    required this.duaId,
    required this.duaTitle,
    this.favoritesOnly = false,
  });

  @override
  State<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends State<DuaDetailScreen> {
  List<Dua> _duas = [];
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
    final rows = widget.favoritesOnly
        ? await DatabaseHelper.instance.getFavoriteDuaDetails(
            widget.duaId,
            locale: settings.localeCode,
          )
        : await DatabaseHelper.instance.getDuaDetails(
            widget.duaId,
            locale: settings.localeCode,
          );
    if (!mounted) return;
    setState(() {
      _duas = rows.map(Dua.fromDetailCursor).toList();
      _loading = false;
    });
  }

  Future<void> _togglePlay(BuildContext context, int reference) async {
    final audioService = context.read<AudioService>();
    try {
      await audioService.togglePlay(reference);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio not available for this dua')),
        );
      }
    }
  }

  Future<void> _toggleFav(int index) async {
    final dua = _duas[index];
    final newFav = !dua.isFav;
    final success =
        await DatabaseHelper.instance.toggleDuaFavorite(dua.reference, newFav);
    if (success && mounted) {
      setState(() => _duas[index] = dua.copyWith(isFav: newFav));
    }
  }

  Future<void> _shareAll(BuildContext context) async {
    debugPrint('DuaDetailScreen: _shareAll');
    final parts = <String>[];
    parts.add('--- ${widget.duaTitle} ---');
    
    for (var i = 0; i < _duas.length; i++) {
      final dua = _duas[i];
      if (_duas.length > 1) parts.add('[Dua ${i + 1}]');
      
      String cleanArabic = _cleanHtml(dua.arabic ?? '');
      String cleanTransliteration = _cleanHtml(dua.transliteration ?? '');
      String cleanTranslation = _cleanHtml(dua.translation ?? '');
      String cleanReference = _cleanHtml(dua.bookReference ?? '');

      if (cleanArabic.isNotEmpty) parts.add(cleanArabic);
      if (cleanTransliteration.isNotEmpty) parts.add(cleanTransliteration);
      if (cleanTranslation.isNotEmpty) parts.add(cleanTranslation);
      if (cleanReference.isNotEmpty) parts.add(cleanReference);
      parts.add(''); // spacer between items
    }
    
    parts.add('Shared from Deen Azkar app');
    final text = parts.join('\n\n');

    await ShareService.shareText(
      context,
      text: text,
      subject: widget.duaTitle,
    );
  }

  Future<void> _performShare(BuildContext shareContext, Dua dua) async {
    debugPrint('DuaDetailScreen: _performShare for dua id=${dua.reference}');
    
    // Clean HTML from fields before sharing
    String cleanArabic = _cleanHtml(dua.arabic ?? '');
    String cleanTransliteration = _cleanHtml(dua.transliteration ?? '');
    String cleanTranslation = _cleanHtml(dua.translation ?? '');
    String cleanReference = _cleanHtml(dua.bookReference ?? '');

    // Build share text with only non-empty sections
    final parts = <String>[];
    parts.add(widget.duaTitle);
    if (cleanArabic.isNotEmpty) parts.add(cleanArabic);
    if (cleanTransliteration.isNotEmpty) parts.add(cleanTransliteration);
    if (cleanTranslation.isNotEmpty) parts.add(cleanTranslation);
    if (cleanReference.isNotEmpty) parts.add(cleanReference);
    parts.add('Shared from Deen Azkar app');

    final text = parts.join('\n\n');

    await ShareService.shareText(
      shareContext,
      text: text,
      subject: widget.duaTitle,
    );
  }

  // Remove HTML tags, convert <br> to newlines and unescape common entities
  String _cleanHtml(String html) {
    if (html.isEmpty) return '';

    // Replace <br> and <br/> with newline
    String s = html.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Remove any other HTML tags
    s = s.replaceAll(RegExp(r'<[^>]*>'), '');

    // Unescape common HTML entities
    s = s
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Collapse multiple blank lines
    s = s.replaceAll(RegExp(r'\n{2,}'), '\n\n');

    return s.trim();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final audioService = context.watch<AudioService>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            isDark ? theme.appBarTheme.backgroundColor : AppTheme.primaryRed,
        foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.duaTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '#${widget.duaId}',
              style: TextStyle(
                fontSize: 12,
                color: (isDark ? theme.colorScheme.onSurface : Colors.white)
                    .withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        actions: [
    /*      Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _duas.isEmpty ? null : () => _shareAll(ctx),
              tooltip: 'Share all duas',
            ),
          ),*/
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showFontSettings(context, settings),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : _duas.isEmpty
              ? const Center(child: Text('No content found'))
              : Column(
                  children: [
                    const BannerAdWidget(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _duas.length,
                        itemBuilder: (_, index) {
                          final dua = _duas[index];
                          final isCurrentPlaying =
                              audioService.playingReference == dua.reference;
                          return _DuaDetailCard(
                            dua: dua,
                            duaTitle: widget.duaTitle,
                            arabicFont: settings.arabicFont,
                            arabicFontSize: settings.arabicFontSize,
                            otherFontSize: settings.otherFontSize,
                            isPlaying:
                                isCurrentPlaying && audioService.isPlaying,
                            position: isCurrentPlaying
                                ? audioService.position
                                : Duration.zero,
                            duration: isCurrentPlaying
                                ? audioService.duration
                                : Duration.zero,
                            onPlayTap: () =>
                                _togglePlay(context, dua.reference),
                            onSeek: (pos) => isCurrentPlaying
                                ? audioService.seekTo(pos)
                                : null,
                            onFavTap: () => _toggleFav(index),
                            onShare: (cardCtx) => _performShare(cardCtx, dua),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showFontSettings(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FontSettingsSheet(settings: settings),
    );
  }
}

// ─── Dua Detail Card ────────────────────────────────────────────────────────

class _DuaDetailCard extends StatelessWidget {
  final Dua dua;
  final String duaTitle;
  final String arabicFont;
  final double arabicFontSize;
  final double otherFontSize;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayTap;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback onFavTap;
  final ValueChanged<BuildContext> onShare;

  const _DuaDetailCard({
    required this.dua,
    required this.duaTitle,
    required this.arabicFont,
    required this.arabicFontSize,
    required this.otherFontSize,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayTap,
    this.onSeek,
    required this.onFavTap,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedText = theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reference badge
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${dua.reference}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Arabic text
            if (dua.arabic != null && dua.arabic!.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _stripHtml(dua.arabic!),
                  style: AppTheme.getArabicStyle(
                    fontFamily: arabicFont,
                    fontSize: arabicFontSize,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            // Audio player
            const SizedBox(height: 12),
            _AudioBar(
              isPlaying: isPlaying,
              position: position,
              duration: duration,
              onPlayTap: onPlayTap,
              onSeek: onSeek,
            ),

            const Divider(height: 24),

            // Transliteration
            if (dua.transliteration != null && dua.transliteration!.isNotEmpty) ...[
              Text(
                _stripHtml(dua.transliteration!),
                style: TextStyle(
                  fontSize: otherFontSize,
                  fontStyle: FontStyle.italic,
                  color: mutedText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Translation
            if (dua.translation != null && dua.translation!.isNotEmpty)
              Text(
                _stripHtml(dua.translation!),
                style: TextStyle(
                  fontSize: otherFontSize,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),

            // Reference
            if (dua.bookReference != null && dua.bookReference!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _stripHtml(dua.bookReference!),
                style: TextStyle(
                  fontSize: otherFontSize - 1,
                  color: mutedText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _AnimatedIconButton(
                  icon: dua.isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: dua.isFav ? AppTheme.accentGold : mutedText,
                  onTap: onFavTap,
                  tooltip: dua.isFav ? 'Remove bookmark' : 'Bookmark',
                ),
                const SizedBox(width: 8),
                _AnimatedIconButton(
                  icon: Icons.share_rounded,
                  color: AppTheme.primaryRed,
                  onTap: () => onShare(context),
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}

// ─── Audio Bar ──────────────────────────────────────────────────────────────

class _AudioBar extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayTap;
  final ValueChanged<Duration>? onSeek;

  const _AudioBar({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.onPlayTap,
    this.onSeek,
  });

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxVal = duration.inMilliseconds.toDouble();
    final curVal = position.inMilliseconds.toDouble().clamp(0.0, maxVal == 0 ? 1.0 : maxVal);

    return Row(
      children: [
        _AnimatedIconButton(
          icon: isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
          color: AppTheme.primaryRed,
          size: 36,
          onTap: onPlayTap,
          tooltip: isPlaying ? 'Pause' : 'Play',
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: AppTheme.primaryRed,
              thumbColor: AppTheme.primaryRed,
              inactiveTrackColor: theme.colorScheme.outline,
            ),
            child: Slider(
              value: maxVal == 0 ? 0.0 : curVal,
              max: maxVal == 0 ? 1.0 : maxVal,
              onChanged: onSeek == null || maxVal == 0
                  ? null
                  : (val) => onSeek!(Duration(milliseconds: val.toInt())),
            ),
          ),
        ),
        Text(
          _format(position),
          style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ─── Animated Icon Button ───────────────────────────────────────────────────

class _AnimatedIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  const _AnimatedIconButton({
    required this.icon,
    required this.color,
    this.size = 28,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.8,
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

  @override
  Widget build(BuildContext context) {
    // Use InkWell for better compatibility with scrolling containers
    return Tooltip(
      message: widget.tooltip,
      child: InkWell(
        onTapDown: (_) => _ctrl.reverse(),
        onTap: () {
          _ctrl.forward();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.forward(),
        child: ScaleTransition(
          scale: _scale,
          child: Icon(widget.icon, color: widget.color, size: widget.size),
        ),
      ),
    );
  }
}

// ─── Font Settings Sheet ────────────────────────────────────────────────────

class _FontSettingsSheet extends StatelessWidget {
  final SettingsService settings;

  const _FontSettingsSheet({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Font Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Text('Arabic Font Size')),
              Text('${settings.arabicFontSize.toInt()}'),
            ],
          ),
          Slider(
            value: settings.arabicFontSize,
            min: 16,
            max: 36,
            divisions: 10,
            activeColor: AppTheme.primaryRed,
            onChanged: (v) => settings.setArabicFontSize(v),
          ),
          Row(
            children: [
              const Expanded(child: Text('Translation Font Size')),
              Text('${settings.otherFontSize.toInt()}'),
            ],
          ),
          Slider(
            value: settings.otherFontSize,
            min: 10,
            max: 22,
            divisions: 6,
            activeColor: AppTheme.primaryRed,
            onChanged: (v) => settings.setOtherFontSize(v),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
