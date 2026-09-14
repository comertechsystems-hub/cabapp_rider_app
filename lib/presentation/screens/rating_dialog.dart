import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/rating_viewmodel.dart';

class RatingDialog extends StatefulWidget {
  final String rideId;
  final String driverName;
  final RatingViewModel ratingVm;
  final VoidCallback onSubmitted;

  const RatingDialog({
    super.key,
    required this.rideId,
    required this.driverName,
    required this.ratingVm,
    required this.onSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _reviewController = TextEditingController();

  static const List<String> availableTags = [
    'Polite driver',
    'Clean vehicle',
    'Smooth ride',
    'Safe driving',
    'Great conversation',
    'Good music',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ratingVm,
      builder: (context, _) {
        final vm = widget.ratingVm;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.goldSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: AppColors.gold, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rate Your Trip',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How was your trip with ${widget.driverName}?',
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starNum <= vm.score ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                        ),
                        onPressed: () => vm.setScore(starNum),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  // Compliment Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: availableTags.map((tag) {
                      final isSelected = vm.selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.ink)),
                        selected: isSelected,
                        selectedColor: AppColors.navy,
                        backgroundColor: AppColors.paper,
                        checkmarkColor: Colors.white,
                        onSelected: (_) => vm.toggleTag(tag),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  // Review TextField
                  TextField(
                    controller: _reviewController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add an optional note or feedback...',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (val) => vm.setReview(val),
                  ),
                  if (vm.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      vm.errorMessage!,
                      style: const TextStyle(color: AppColors.coral, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: vm.isLoading
                          ? null
                          : () async {
                              final success = await vm.submitRating(widget.rideId);
                              if (success && context.mounted) {
                                Navigator.pop(context);
                                widget.onSubmitted();
                              }
                            },
                      child: vm.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Submit Rating'),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Maybe Later', style: TextStyle(color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
