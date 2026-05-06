import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import '../../core/services/share_service.dart';
import '../../core/models/daily_inspiration.dart';
import '../theme/app_theme.dart';

class DailyInspirationCard extends StatefulWidget {
  final DailyInspiration inspiration;
  final bool isLoading;

  const DailyInspirationCard({
    super.key, 
    required this.inspiration,
    this.isLoading = false,
  });

  @override
  State<DailyInspirationCard> createState() => _DailyInspirationCardState();
}

class _DailyInspirationCardState extends State<DailyInspirationCard> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _shareImage() async {
    if (_isCapturing) return;
    
    setState(() => _isCapturing = true);
    
    try {
      // Small delay to ensure UI is settled if needed
      await Future.delayed(const Duration(milliseconds: 100));
      
      final directory = await getApplicationDocumentsDirectory();
      // captureAndSave returns the path of the saved image
      final String? imagePath = await _screenshotController.captureAndSave(
        directory.path,
        fileName: "daily_inspiration_${DateTime.now().millisecondsSinceEpoch}.png",
      );

      if (imagePath != null && mounted) {
        await ShareService.shareFiles(
          context,
          paths: [imagePath],
          text: 'Daily Inspiration from Deen Azkar',
        );
      }
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share inspiration image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Daily Inspiration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: widget.isLoading ? 0.6 : 1.0,
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryRed,
                      Color(0xFFB71C1C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.format_quote_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.inspiration.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (widget.isLoading && widget.inspiration.id == 'placeholder')
                            _buildShimmerLine(width: double.infinity)
                          else
                            Text(
                              widget.inspiration.content,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (widget.isLoading && widget.inspiration.id == 'placeholder')
                                _buildShimmerLine(width: 100)
                              else
                                Text(
                                  widget.inspiration.source ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              if (!widget.isLoading)
                                GestureDetector(
                                  onTap: _isCapturing ? null : _shareImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _isCapturing 
                                      ? const SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed)
                                        )
                                      : const Icon(
                                          Icons.share_rounded,
                                          color: AppTheme.primaryRed,
                                          size: 20,
                                        ),
                                  ),
                                ),
                            ],
                          ),
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

  Widget _buildShimmerLine({required double width}) {
    return Container(
      width: width,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
