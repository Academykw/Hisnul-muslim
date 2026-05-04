import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/models/daily_inspiration.dart';
import '../theme/app_theme.dart';

class DailyInspirationCard extends StatelessWidget {
  final DailyInspiration inspiration;
  final bool isLoading;

  DailyInspirationCard({
    super.key, 
    required this.inspiration,
    this.isLoading = false,
  });

  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _shareImage() async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = await _screenshotController.captureAndSave(
      directory.path,
      fileName: "daily_inspiration.png",
    );

    if (imagePath != null) {
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Daily Inspiration from Deen Azkar',
      );
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
            opacity: isLoading ? 0.6 : 1.0,
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
                              inspiration.type.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (isLoading && inspiration.id == 'placeholder')
                            _buildShimmerLine(width: double.infinity)
                          else
                            Text(
                              inspiration.content,
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
                              if (isLoading && inspiration.id == 'placeholder')
                                _buildShimmerLine(width: 100)
                              else
                                Text(
                                  inspiration.source ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              if (!isLoading)
                                GestureDetector(
                                  onTap: _shareImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
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
