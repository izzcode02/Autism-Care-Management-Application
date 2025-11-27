import 'package:flutter/material.dart';

class LargeListTile extends StatelessWidget {
  LargeListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.bottom,
    this.leading,
    this.trailing,
    this.overline,
    this.onTap,
    this.extraLarge = false,
    this.backgroundColor,
    this.titleColor,
    this.alignLeadingOnTop = false,
    this.border, // New optional border parameter
    this.disableChevron = false,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? bottom;
  final Widget? leading;
  final Widget? trailing;
  final Widget? overline;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool extraLarge;
  final bool alignLeadingOnTop;
  final Color? backgroundColor;
  final Border? border; // New border property
  final bool disableChevron;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final textualContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overline != null) ...[
          DefaultTextStyle(
            style: textTheme.labelSmall!.copyWith(color: Colors.blue[900]),
            child: overline!,
          ),
          const SizedBox(height: 8),
        ],
        DefaultTextStyle(
          style: textTheme.titleSmall!.copyWith(color: titleColor),
          child: title,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: textTheme.labelSmall!.copyWith(color: Colors.blue[900]),
            child: subtitle!,
          ),
        ],
        if (bottom != null) ...[
          const SizedBox(height: 12),
          bottom!,
        ]
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: backgroundColor ?? Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: border, // Apply the border here
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: extraLarge ? 32 : 20,
                horizontal: extraLarge ? 32 : 20,
              ),
              child: extraLarge
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(height: 24),
                        ],
                        textualContent,
                        if (trailing != null) ...[
                          const SizedBox(height: 24),
                          trailing!,
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: alignLeadingOnTop
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 24),
                        ],
                        Expanded(child: textualContent),
                        if (trailing != null) ...[
                          const SizedBox(width: 24),
                          trailing!,
                        ] else if (onTap != null) ...[
                          const SizedBox(height: 24),
                          disableChevron ? SizedBox(height: 0) : Icon(Icons.chevron_right, color: Colors.black54) ,
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}