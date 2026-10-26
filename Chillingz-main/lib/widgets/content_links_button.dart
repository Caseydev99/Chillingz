import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/utils/extensions.dart';
import '../core/widgets/custom_button.dart';

class ContentLinksButton extends StatelessWidget {
  const ContentLinksButton({
    super.key,
    required this.websiteLink,
    required this.mapLink,
    required this.ticketLink,
  });

  final String websiteLink;
  final String mapLink;
  final String ticketLink;

  @override
  Widget build(BuildContext context) {
    final links = _availableLinks;
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }

    if (links.length == 1) {
      final link = links.first;
      return CustomButton(
        label: link.label,
        onPressed: () => _openLink(context, link),
      );
    }

    return CustomButton(
      label: AppStrings.seeMore,
      onPressed: () => _showLinksSheet(context, links),
    );
  }

  List<_ContentLink> get _availableLinks {
    return [
      _ContentLink(label: 'Website', url: websiteLink),
      _ContentLink(label: 'Google Map', url: mapLink, isMap: true),
      _ContentLink(label: 'Ticket Link', url: ticketLink),
    ].where((link) => link.url.trim().isNotEmpty).toList();
  }

  Future<void> _showLinksSheet(
    BuildContext context,
    List<_ContentLink> links,
  ) async {
    if (MediaQuery.sizeOf(context).width >= 600) {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Open link'),
          contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          content: SizedBox(
            width: 420,
            child: _ContentLinksList(
              links: links,
              onSelected: (link) {
                Navigator.pop(dialogContext);
                _openLink(context, link);
              },
            ),
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          margin: EdgeInsets.all(context.rs(16, min: 14, max: 20)),
          padding: EdgeInsets.symmetric(
            vertical: context.rs(10, min: 9, max: 12),
          ),
          decoration: BoxDecoration(
            color: AppColors.settingsTileBackground,
            borderRadius: BorderRadius.circular(
              context.rs(18, min: 16, max: 20),
            ),
            border: Border.all(color: AppColors.border),
          ),
          // ListTile paints its ink on the nearest Material ancestor; the
          // decorated Container above would otherwise hide those splashes.
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              top: false,
              child: _ContentLinksList(
                links: links,
                onSelected: (link) {
                  Navigator.pop(sheetContext);
                  _openLink(context, link);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLink(BuildContext context, _ContentLink link) async {
    final uri = link.isMap ? _toGoogleMapsUri(link.url) : _toUri(link.url);
    if (uri == null) {
      _showLinkError(context);
      return;
    }

    try {
      final didLaunch = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!didLaunch && context.mounted) {
        _showLinkError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showLinkError(context);
      }
    }
  }

  void _showLinkError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open this link.')));
  }

  Uri? _toUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final withScheme =
        trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.startsWith('geo:')
        ? trimmed
        : 'https://$trimmed';
    return Uri.tryParse(withScheme);
  }

  /// Converts legacy Google Maps place-id URLs into Google's current
  /// universal Maps URL format. Without `api=1`, Maps mobile ignores the
  /// supplied parameters and can open an unrelated/default map view.
  Uri? _toGoogleMapsUri(String rawUrl) {
    final uri = _toUri(rawUrl);
    if (uri == null) {
      return null;
    }

    final placeId = _extractGooglePlaceId(uri, rawUrl);
    if (placeId == null) {
      // Shared links and address/coordinate links are already valid and
      // should be passed through without changing their meaning.
      return uri;
    }

    return Uri.https('www.google.com', '/maps/search/', <String, String>{
      'api': '1',
      // Search URLs require query. query_place_id remains authoritative and
      // query is used only if Google can no longer resolve that place id.
      'query': placeId,
      'query_place_id': placeId,
    });
  }

  String? _extractGooglePlaceId(Uri uri, String rawUrl) {
    final candidates = <String>[
      uri.queryParameters['query_place_id'] ?? '',
      uri.queryParameters['destination_place_id'] ?? '',
      uri.queryParameters['place_id'] ?? '',
      uri.queryParameters['q'] ?? '',
      rawUrl,
    ];
    final expression = RegExp(r'ChI[A-Za-z0-9_-]+');

    for (final candidate in candidates) {
      final match = expression.firstMatch(candidate);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }
}

class _ContentLink {
  const _ContentLink({
    required this.label,
    required this.url,
    this.isMap = false,
  });

  final String label;
  final String url;
  final bool isMap;
}

class _ContentLinksList extends StatelessWidget {
  const _ContentLinksList({required this.links, required this.onSelected});

  final List<_ContentLink> links;
  final ValueChanged<_ContentLink> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: links.map((link) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            link.label,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Icon(
            Icons.open_in_new_rounded,
            color: AppColors.textSecondary,
          ),
          onTap: () => onSelected(link),
        );
      }).toList(),
    );
  }
}
