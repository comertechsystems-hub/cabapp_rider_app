import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../viewmodels/trip_history_viewmodel.dart';

class TripHistoryScreen extends StatefulWidget {
  final TripHistoryViewModel historyVm;

  const TripHistoryScreen({super.key, required this.historyVm});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.historyVm.loadTripHistory();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.historyVm,
      builder: (context, _) {
        final vm = widget.historyVm;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          body: Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppColors.paper,
                child: Row(
                  children: [
                    _filterChip('All Trips', HistoryFilter.all, vm),
                    const SizedBox(width: 8),
                    _filterChip('Completed', HistoryFilter.completed, vm),
                    const SizedBox(width: 8),
                    _filterChip('Cancelled', HistoryFilter.cancelled, vm),
                  ],
                ),
              ),
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.filteredTrips.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: AppColors.inkSoft.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No trips found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.ink),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Completed and past trips will appear here.',
                                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: vm.filteredTrips.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final trip = vm.filteredTrips[index];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.paperRaised,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: trip.isCompleted ? AppColors.greenSoft : AppColors.coralSoft,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            trip.status.replaceAll('_', ' '),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: trip.isCompleted ? AppColors.green : AppColors.coral,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₦${trip.fare.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.my_location, size: 16, color: AppColors.navy),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            trip.pickupAddress,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.location_on, size: 16, color: AppColors.coral),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            trip.destinationAddress,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (trip.driverName != null) ...[
                                      const Divider(height: 20, color: AppColors.line),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Driver: ${trip.driverName}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                                          ),
                                          Text(
                                            trip.vehicleCategory,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.navy),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, HistoryFilter filter, TripHistoryViewModel vm) {
    final isSelected = vm.currentFilter == filter;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.ink)),
      selected: isSelected,
      selectedColor: AppColors.navy,
      backgroundColor: AppColors.paperRaised,
      onSelected: (_) => vm.setFilter(filter),
    );
  }
}
