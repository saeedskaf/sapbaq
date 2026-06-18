import 'package:flutter/material.dart';
import 'package:sapbaq/core/theme/theme_colors.dart';
import 'package:sapbaq/core/widgets/custom_text.dart';
import 'package:sapbaq/features/mosques/data/models/mosque.dart';

class MosqueCard extends StatelessWidget {
  final Mosque mosque;
  final VoidCallback onTap;

  /// Optional trailing widget (e.g. a favorite heart). Defaults to a chevron.
  final Widget? trailing;

  const MosqueCard({
    super.key,
    required this.mosque,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.colors.border, width: 0.5),
          ),
          child: Row(
            children: [
              _Thumb(url: mosque.image),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextCustom(
                      text: mosque.name,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mosque.area.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      TextCustom(
                        text: mosque.area,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.colors.primary,
                      ),
                    ],
                    if (mosque.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      TextCustom(
                        text: mosque.address,
                        fontSize: 12,
                        color: context.colors.textSecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textHint,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  const _Thumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: (url == null || url!.isEmpty)
            ? ColoredBox(
                color: context.colors.surfaceVariant,
                child: Icon(Icons.mosque_outlined, color: context.colors.primary),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: context.colors.surfaceVariant,
                  child: Icon(
                    Icons.mosque_outlined,
                    color: context.colors.primary,
                  ),
                ),
              ),
      ),
    );
  }
}
