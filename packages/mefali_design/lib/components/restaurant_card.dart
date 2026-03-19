import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import '../mefali_colors.dart';
import 'vendor_status_indicator.dart';

/// Carte restaurant pour la grille de découverte B2C (UX-DR3).
/// Affiche : photo, nom, note ★, ETA, frais de livraison, statut.
class RestaurantCard extends StatelessWidget {
  const RestaurantCard({
    required this.restaurant,
    required this.onTap,
    super.key,
  });

  final RestaurantSummary restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isClosed = restaurant.status == VendorStatus.closed ||
        restaurant.status == VendorStatus.autoPaused;

    return AbsorbPointer(
      absorbing: isClosed,
      child: Opacity(
        opacity: isClosed ? 0.5 : 1.0,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _RestaurantPhoto(photoUrl: restaurant.photoUrl),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (restaurant.avgRating > 0)
                        _RatingRow(
                          avgRating: restaurant.avgRating,
                          totalRatings: restaurant.totalRatings,
                        ),
                      const SizedBox(height: 2),
                      Text(
                        '~30 min • ${formatFcfa(restaurant.deliveryFee)} livraison',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      VendorStatusIndicator(status: restaurant.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestaurantPhoto extends StatelessWidget {
  const _RestaurantPhoto({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return SizedBox(
        height: 120,
        width: double.infinity,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => const _Placeholder(),
          errorWidget: (context, url, error) => const _Placeholder(),
        ),
      );
    }
    return const _Placeholder();
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      width: double.infinity,
      child: ColoredBox(
        color: MefaliColors.primaryContainerLight,
        child: Icon(
          Icons.restaurant,
          color: Colors.white54,
          size: 40,
        ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.avgRating, required this.totalRatings});

  final double avgRating;
  final int totalRatings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
        const SizedBox(width: 2),
        Text(
          '${avgRating.toStringAsFixed(1)} ($totalRatings)',
          style: textTheme.labelSmall,
        ),
      ],
    );
  }
}

/// Squelette animé pour RestaurantCard — affiché pendant le chargement (UX-DR14).
/// Utilise ColorTween pour le shimmer, sans package externe.
class RestaurantCardSkeleton extends StatefulWidget {
  const RestaurantCardSkeleton({super.key});

  @override
  State<RestaurantCardSkeleton> createState() => _RestaurantCardSkeletonState();
}

class _RestaurantCardSkeletonState extends State<RestaurantCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _colorAnim = ColorTween(
      begin: MefaliColors.primaryContainerLight,
      end: const Color(0xFFEFEBE9),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder: (context, _) {
        final color = _colorAnim.value ?? MefaliColors.primaryContainerLight;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo placeholder
              SizedBox(height: 120, width: double.infinity, child: ColoredBox(color: color)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBox(width: double.infinity, height: 14, color: color),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 100, height: 12, color: color),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 80, height: 12, color: color),
                    const SizedBox(height: 6),
                    _SkeletonBox(width: 130, height: 12, color: color),
                    const SizedBox(height: 6),
                    _SkeletonBox(
                      width: 80,
                      height: 28,
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.color,
    this.borderRadius,
  });

  final double width;
  final double height;
  final Color color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}
