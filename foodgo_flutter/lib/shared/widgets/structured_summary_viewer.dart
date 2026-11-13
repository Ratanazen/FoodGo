import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/glass_theme.dart';
import '../../widgets/glass_container.dart';

/// Represents a structured section inside a document, summary, or receipt.
class SummarySection {
  final String title;
  final String? body;
  final List<String> bulletPoints;
  final Map<String, String> metadata;
  final String? codeOrPayload;
  final IconData? icon;

  const SummarySection({
    required this.title,
    this.body,
    this.bulletPoints = const [],
    this.metadata = const {},
    this.codeOrPayload,
    this.icon,
  });
}

/// Professional, theme-aware TXT and Structured Summary Viewer widget.
///
/// Features:
/// - Bilingual Khmer & English typography with proper line height (`1.58`) and fallback fonts.
/// - Safe plain-text sanitization (strips `<script>`, `<iframe>`, `javascript:` URIs, HTML tags).
/// - Formatted Summary view vs. Plain TXT view toggle.
/// - Real-time Find-in-Text search with match counter.
/// - Copy Full TXT / Summary to clipboard with user feedback.
/// - Handles loading, error, empty, and long-text states without horizontal overflow.
class StructuredSummaryViewer extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? badgeText;
  final List<String> keyPoints;
  final List<SummarySection> sections;
  final String? rawTxtOverride;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool enableSearch;
  final bool enableModeToggle;
  final bool enableCopy;
  final bool initiallyPlainTxt;
  final double maxContentWidth;

  const StructuredSummaryViewer({
    super.key,
    required this.title,
    this.subtitle,
    this.badgeText,
    this.keyPoints = const [],
    this.sections = const [],
    this.rawTxtOverride,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.enableSearch = true,
    this.enableModeToggle = true,
    this.enableCopy = true,
    this.initiallyPlainTxt = false,
    this.maxContentWidth = 820,
  });

  /// Sanitizes untrusted or raw text so it can be safely rendered as plain text
  /// without script injection, unsafe HTML tags, or broken control characters.
  static String sanitizePlainText(String? input) {
    if (input == null || input.isEmpty) return '';
    var text = input;
    // Remove script, style, and iframe blocks completely.
    text = text.replaceAll(
      RegExp(
        r'<\s*(script|style|iframe|object|embed)[^>]*>[\s\S]*?<\s*/\s*\1\s*>',
        caseSensitive: false,
      ),
      '',
    );
    // Remove self-closing or unclosed dangerous tags.
    text = text.replaceAll(
      RegExp(
        r'<\s*/?\s*(script|style|iframe|object|embed)[^>]*>',
        caseSensitive: false,
      ),
      '',
    );
    // Neutralize javascript: and data:text/html URIs.
    text = text.replaceAll(
      RegExp(r'(javascript|vbscript)\s*:', caseSensitive: false),
      'blocked:',
    );
    // Strip remaining HTML tags while preserving line breaks for block tags.
    text = text.replaceAll(
      RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(
      RegExp(r'<\s*/\s*(p|div|li|h[1-6]|tr)\s*>', caseSensitive: false),
      '\n',
    );
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Decode common HTML entities.
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
    // Normalize CRLF to LF and collapse excessive blank lines (3+ -> 2).
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  /// Parses an EMVCo KHQR payload string into structured human-readable TLV fields.
  static Map<String, String> parseEmvcoKhqrSummary(String payload) {
    final clean = sanitizePlainText(payload);
    if (clean.isEmpty || !clean.startsWith('000201')) {
      return {'Raw Payload': clean.isEmpty ? 'N/A' : clean};
    }

    final result = <String, String>{};
    int idx = 0;
    while (idx + 4 <= clean.length) {
      final tag = clean.substring(idx, idx + 2);
      final len = int.tryParse(clean.substring(idx + 2, idx + 4));
      if (len == null || len < 0 || idx + 4 + len > clean.length) {
        break;
      }
      final val = clean.substring(idx + 4, idx + 4 + len);
      switch (tag) {
        case '00':
          result['Payload Format'] = 'EMVCo v$val';
          break;
        case '01':
          result['QR Type'] = val == '12'
              ? 'Dynamic KHQR (12)'
              : (val == '11' ? 'Static KHQR (11)' : val);
          break;
        case '29':
        case '30':
          // Parse sub-tag 00 inside Merchant Account Info
          if (val.length >= 4 && val.startsWith('00')) {
            final subLen = int.tryParse(val.substring(2, 4));
            if (subLen != null && 4 + subLen <= val.length) {
              result['Bakong Account ID'] = val.substring(4, 4 + subLen);
            } else {
              result['Bakong Account ID'] = val;
            }
          } else {
            result['Bakong Account ID'] = val;
          }
          break;
        case '52':
          result['MCC'] = val;
          break;
        case '53':
          result['Currency'] = val == '840'
              ? 'USD (840)'
              : (val == '116' ? 'KHR (116)' : val);
          break;
        case '54':
          result['Amount'] = val;
          break;
        case '58':
          result['Country'] = val;
          break;
        case '59':
          result['Merchant Name'] = val;
          break;
        case '60':
          result['Merchant City'] = val;
          break;
        case '62':
          if (val.length >= 4 && val.startsWith('01')) {
            final subLen = int.tryParse(val.substring(2, 4));
            if (subLen != null && 4 + subLen <= val.length) {
              result['Bill Reference'] = val.substring(4, 4 + subLen);
            }
          }
          break;
        case '99':
          // Parse Tag 99 timestamps (sub-tag 00 created ms, 01 expires ms)
          int subIdx = 0;
          while (subIdx + 4 <= val.length) {
            final subTag = val.substring(subIdx, subIdx + 2);
            final subLen = int.tryParse(val.substring(subIdx + 2, subIdx + 4));
            if (subLen == null || subIdx + 4 + subLen > val.length) break;
            final subVal = val.substring(subIdx + 4, subIdx + 4 + subLen);
            if (subTag == '01') {
              result['Expires Epoch (ms)'] = subVal;
            }
            subIdx += 4 + subLen;
          }
          break;
        case '63':
          result['CRC16 Checksum'] = val;
          break;
      }
      idx += 4 + len;
    }
    return result;
  }

  /// Generates a clean plain-text (TXT) representation of the summary and all sections.
  String buildPlainTextDocument() {
    if (rawTxtOverride != null && rawTxtOverride!.trim().isNotEmpty) {
      return sanitizePlainText(rawTxtOverride);
    }

    final buffer = StringBuffer();
    final safeTitle = sanitizePlainText(title);
    buffer.writeln(
      '============================================================',
    );
    buffer.writeln(safeTitle.toUpperCase());
    if (subtitle != null && subtitle!.trim().isNotEmpty) {
      buffer.writeln(sanitizePlainText(subtitle));
    }
    if (badgeText != null && badgeText!.trim().isNotEmpty) {
      buffer.writeln('[${sanitizePlainText(badgeText)}]');
    }
    buffer.writeln(
      '============================================================',
    );

    if (keyPoints.isNotEmpty) {
      buffer.writeln('\nKEY SUMMARY POINTS:');
      for (final point in keyPoints) {
        buffer.writeln('  * ${sanitizePlainText(point)}');
      }
    }

    for (var i = 0; i < sections.length; i++) {
      final sec = sections[i];
      buffer.writeln(
        '\n------------------------------------------------------------',
      );
      buffer.writeln('${i + 1}. ${sanitizePlainText(sec.title)}');
      buffer.writeln(
        '------------------------------------------------------------',
      );
      if (sec.metadata.isNotEmpty) {
        for (final entry in sec.metadata.entries) {
          final k = sanitizePlainText(entry.key).padRight(20);
          final v = sanitizePlainText(entry.value);
          buffer.writeln('  $k : $v');
        }
      }
      if (sec.body != null && sec.body!.trim().isNotEmpty) {
        buffer.writeln(sanitizePlainText(sec.body));
      }
      if (sec.bulletPoints.isNotEmpty) {
        for (final b in sec.bulletPoints) {
          buffer.writeln('  - ${sanitizePlainText(b)}');
        }
      }
      if (sec.codeOrPayload != null && sec.codeOrPayload!.trim().isNotEmpty) {
        buffer.writeln('\n  [PAYLOAD / DATA]');
        buffer.writeln('  ${sanitizePlainText(sec.codeOrPayload)}');
      }
    }
    return buffer.toString().trim();
  }

  @override
  State<StructuredSummaryViewer> createState() =>
      _StructuredSummaryViewerState();
}

class _StructuredSummaryViewerState extends State<StructuredSummaryViewer> {
  late bool _isPlainTxtMode;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _copiedRecently = false;

  @override
  void initState() {
    super.initState();
    _isPlainTxtMode = widget.initiallyPlainTxt;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _sectionMatches(SummarySection section, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    if (section.title.toLowerCase().contains(q)) return true;
    if ((section.body ?? '').toLowerCase().contains(q)) return true;
    if ((section.codeOrPayload ?? '').toLowerCase().contains(q)) return true;
    for (final b in section.bulletPoints) {
      if (b.toLowerCase().contains(q)) return true;
    }
    for (final entry in section.metadata.entries) {
      if (entry.key.toLowerCase().contains(q) ||
          entry.value.toLowerCase().contains(q)) {
        return true;
      }
    }
    return false;
  }

  int _countOccurrences(String text, String query) {
    if (query.isEmpty || text.isEmpty) return 0;
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int count = 0;
    int index = 0;
    while (true) {
      index = lowerText.indexOf(lowerQuery, index);
      if (index == -1) break;
      count++;
      index += lowerQuery.length;
    }
    return count;
  }

  Future<void> _copyFullTxt() async {
    final txt = widget.buildPlainTextDocument();
    if (txt.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: txt));
    if (!mounted) return;
    setState(() => _copiedRecently = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full TXT summary copied to clipboard!'),
        backgroundColor: GlassTheme.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedRecently = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : GlassTheme.textInverseDark;
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : const Color(0xFF374151);
    final mutedTextColor = isDark
        ? GlassTheme.textMuted
        : const Color(0xFF6B7280);

    if (widget.isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: GlassTheme.primaryGreen),
              const SizedBox(height: 16),
              Text(
                'Loading summary content...',
                style: AppTypography.bodyMedium(color: mutedTextColor),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.errorMessage != null && widget.errorMessage!.trim().isNotEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
          child: GlassContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: GlassTheme.borderRadiusLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: GlassTheme.errorRed,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'Unable to Load Content',
                  style: AppTypography.titleLarge(color: primaryTextColor),
                ),
                const SizedBox(height: 8),
                Text(
                  StructuredSummaryViewer.sanitizePlainText(
                    widget.errorMessage,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: secondaryTextColor),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final fullPlainTxt = widget.buildPlainTextDocument();
    final isEmpty =
        widget.sections.isEmpty &&
        widget.keyPoints.isEmpty &&
        (widget.rawTxtOverride == null ||
            widget.rawTxtOverride!.trim().isEmpty);

    if (isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
          child: GlassContainer(
            padding: const EdgeInsets.all(28),
            borderRadius: GlassTheme.borderRadiusLarge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  color: mutedTextColor,
                  size: 44,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Summary Content Available',
                  style: AppTypography.titleMedium(color: primaryTextColor),
                ),
                const SizedBox(height: 6),
                Text(
                  'There are no text sections or summary records to display yet.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(color: mutedTextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredSections = widget.sections
        .where((s) => _sectionMatches(s, _searchQuery))
        .toList();
    final totalMatches = _searchQuery.isEmpty
        ? 0
        : _countOccurrences(fullPlainTxt, _searchQuery);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxContentWidth),
        child: SelectionArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header & Executive Summary Card
              GlassContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: GlassTheme.borderRadiusLarge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: GlassTheme.primaryGreen.withValues(
                              alpha: 0.14,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.article_outlined,
                            color: GlassTheme.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                StructuredSummaryViewer.sanitizePlainText(
                                  widget.title,
                                ),
                                style: AppTypography.titleLarge(
                                  color: primaryTextColor,
                                ),
                              ),
                              if (widget.subtitle != null &&
                                  widget.subtitle!.trim().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  StructuredSummaryViewer.sanitizePlainText(
                                    widget.subtitle,
                                  ),
                                  style: AppTypography.bodySmall(
                                    color: mutedTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.badgeText != null &&
                            widget.badgeText!.trim().isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: GlassTheme.primaryGreen.withValues(
                                alpha: 0.16,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: GlassTheme.primaryGreen.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            child: Text(
                              StructuredSummaryViewer.sanitizePlainText(
                                widget.badgeText,
                              ),
                              style: AppTypography.labelSmall(
                                color: GlassTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Executive Key Points
                    if (widget.keyPoints.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: GlassTheme.primaryGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'KEY HIGHLIGHTS & SUMMARY',
                                  style: AppTypography.labelSmall(
                                    color: GlassTheme.primaryGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ...widget.keyPoints.map(
                              (point) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 15,
                                        color: GlassTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        StructuredSummaryViewer.sanitizePlainText(
                                          point,
                                        ),
                                        style: AppTypography.bodySmall(
                                          color: secondaryTextColor,
                                        ).copyWith(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Action Toolbar (Mode Toggle + Copy TXT)
                    if (widget.enableModeToggle || widget.enableCopy) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (widget.enableModeToggle)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.25)
                                    : const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildModeButton(
                                    label: 'Formatted Summary',
                                    icon: Icons.view_agenda_outlined,
                                    selected: !_isPlainTxtMode,
                                    isDark: isDark,
                                    onTap: () =>
                                        setState(() => _isPlainTxtMode = false),
                                  ),
                                  const SizedBox(width: 4),
                                  _buildModeButton(
                                    label: 'Plain TXT',
                                    icon: Icons.subject_rounded,
                                    selected: _isPlainTxtMode,
                                    isDark: isDark,
                                    onTap: () =>
                                        setState(() => _isPlainTxtMode = true),
                                  ),
                                ],
                              ),
                            ),
                          if (widget.enableCopy)
                            OutlinedButton.icon(
                              onPressed: _copyFullTxt,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _copiedRecently
                                    ? GlassTheme.primaryGreen
                                    : primaryTextColor,
                                side: BorderSide(
                                  color: _copiedRecently
                                      ? GlassTheme.primaryGreen
                                      : (isDark
                                            ? Colors.white24
                                            : const Color(0xFFD1D5DB)),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                _copiedRecently
                                    ? Icons.check_rounded
                                    : Icons.copy_rounded,
                                size: 15,
                                color: GlassTheme.primaryGreen,
                              ),
                              label: Text(
                                _copiedRecently ? 'Copied TXT!' : 'Copy TXT',
                                style: AppTypography.labelMedium(
                                  color: _copiedRecently
                                      ? GlassTheme.primaryGreen
                                      : primaryTextColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // 2. Find-in-Text Search Bar
              if (widget.enableSearch) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: AppTypography.bodyMedium(color: primaryTextColor),
                  decoration: InputDecoration(
                    hintText: 'Find in text or summary...',
                    hintStyle: AppTypography.bodySmall(color: mutedTextColor),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: GlassTheme.primaryGreen,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: GlassTheme.primaryGreen.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalMatches match${totalMatches == 1 ? '' : 'es'}',
                                  style: AppTypography.labelSmall(
                                    color: GlassTheme.primaryGreen,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: mutedTextColor,
                                ),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              ),
                            ],
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 3. Body: Either Plain TXT Viewer or Structured Sections
              if (_isPlainTxtMode)
                _buildPlainTxtView(
                  fullPlainTxt: fullPlainTxt,
                  isDark: isDark,
                  primaryTextColor: primaryTextColor,
                  mutedTextColor: mutedTextColor,
                )
              else if (filteredSections.isEmpty && _searchQuery.isNotEmpty)
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: GlassTheme.borderRadiusMedium,
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 36,
                        color: mutedTextColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No sections match "$_searchQuery"',
                        style: AppTypography.titleSmall(
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try a different keyword or clear the search filter.',
                        style: AppTypography.bodySmall(color: mutedTextColor),
                      ),
                    ],
                  ),
                )
              else
                ...filteredSections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFormattedSectionCard(
                      section: section,
                      isDark: isDark,
                      primaryTextColor: primaryTextColor,
                      secondaryTextColor: secondaryTextColor,
                      mutedTextColor: mutedTextColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final activeBg = isDark ? GlassTheme.primaryGreen : Colors.white;
    final activeFg = isDark ? Colors.black : GlassTheme.textInverseDark;
    final inactiveFg = isDark ? Colors.white70 : const Color(0xFF4B5563);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? activeFg : inactiveFg),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: selected ? activeFg : inactiveFg,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlainTxtView({
    required String fullPlainTxt,
    required bool isDark,
    required Color primaryTextColor,
    required Color mutedTextColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.terminal_rounded,
                    size: 16,
                    color: GlassTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'PLAIN TXT DOCUMENT VIEW',
                    style: AppTypography.labelSmall(
                      color: GlassTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${fullPlainTxt.split('\n').length} lines',
                style: AppTypography.caption(color: mutedTextColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.32)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: SelectableText(
              fullPlainTxt,
              style: AppTypography.bodySmall(
                color: primaryTextColor,
              ).copyWith(fontFamily: 'monospace', height: 1.58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedSectionCard({
    required SummarySection section,
    required bool isDark,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color mutedTextColor,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: GlassTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                section.icon ?? Icons.bookmark_border_rounded,
                size: 18,
                color: GlassTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  StructuredSummaryViewer.sanitizePlainText(section.title),
                  style: AppTypography.titleSmall(color: primaryTextColor),
                ),
              ),
            ],
          ),
          if (section.metadata.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: section.metadata.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            StructuredSummaryViewer.sanitizePlainText(
                              entry.key,
                            ),
                            style: AppTypography.labelSmall(
                              color: mutedTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Text(
                            StructuredSummaryViewer.sanitizePlainText(
                              entry.value,
                            ),
                            textAlign: TextAlign.right,
                            style: AppTypography.bodySmall(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (section.body != null && section.body!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              StructuredSummaryViewer.sanitizePlainText(section.body),
              style: AppTypography.bodyMedium(
                color: secondaryTextColor,
              ).copyWith(height: 1.62),
            ),
          ],
          if (section.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...section.bulletPoints.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: GlassTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        StructuredSummaryViewer.sanitizePlainText(b),
                        style: AppTypography.bodyMedium(
                          color: secondaryTextColor,
                        ).copyWith(height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (section.codeOrPayload != null &&
              section.codeOrPayload!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: SelectableText(
                StructuredSummaryViewer.sanitizePlainText(
                  section.codeOrPayload,
                ),
                style: AppTypography.caption(
                  color: primaryTextColor,
                ).copyWith(fontFamily: 'monospace', height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
