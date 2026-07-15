import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aiaprtd_admin_dashboard/core/providers/admin_trips_provider.dart';

class RideHistoryPanel extends StatefulWidget {
  const RideHistoryPanel({super.key});

  @override
  State<RideHistoryPanel> createState() => _RideHistoryPanelState();
}

class _RideHistoryPanelState extends State<RideHistoryPanel> {
  String _searchQuery = '';
  String _timeFilter = 'Today'; // 'Today', 'This Week', 'This Month', 'Custom'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _filterType = 'All';
  bool _isInit = true;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _fetchTrips();
      _isInit = false;
    }
  }

  Future<void> _fetchTrips() async {
    final tripsProvider = Provider.of<AdminTripsProvider>(
      context,
      listen: false,
    );
    await tripsProvider.fetchTripsForDateRange(_startDate, _endDate);
  }

  void _setTimeFilter(String filter) {
    setState(() {
      _timeFilter = filter;
      final now = DateTime.now();
      if (filter == 'Today') {
        _startDate = now;
        _endDate = now;
      } else if (filter == 'This Week') {
        _startDate = now.subtract(const Duration(days: 6));
        _endDate = now;
      } else if (filter == 'This Month') {
        _startDate = now.subtract(const Duration(days: 29));
        _endDate = now;
      }
      _isInit = true;
    });
    if (filter != 'Custom') {
      _fetchTrips();
    }
  }

  void _showTripDetailsDialog(BuildContext context, AdminTripModel trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Trip Details: ${trip.id}',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow('Status', trip.status.toUpperCase(), context),
                  _detailRow(
                    'Date',
                    DateFormat('yyyy-MMM-dd hh:mm a').format(trip.date),
                    context,
                  ),
                  _detailRow(
                    'Type',
                    trip.type == 'booking' ? 'App Booking' : 'Road Pickup',
                    context,
                  ),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _detailRow('Driver', trip.driverName, context),
                  _detailRow('Driver No.', trip.driverMembershipNo, context),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _detailRow('Passenger', trip.passengerName, context),
                  _detailRow('Passenger Phone', trip.passengerPhone, context),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  if (trip.bookingTime != null)
                    _detailRow(
                      'Booking Time',
                      DateFormat('hh:mm a').format(trip.bookingTime!),
                      context,
                    ),
                  if (trip.driverReachedTime != null)
                    _detailRow(
                      'Driver Reached',
                      DateFormat('hh:mm a').format(trip.driverReachedTime!),
                      context,
                    ),
                  if (trip.tripStartTime != null)
                    _detailRow(
                      'Trip Started',
                      DateFormat('hh:mm a').format(trip.tripStartTime!),
                      context,
                    ),
                  if (trip.tripEndTime != null)
                    _detailRow(
                      'Trip Ended',
                      DateFormat('hh:mm a').format(trip.tripEndTime!),
                      context,
                    ),
                  _detailRow(
                    'Waiting Time',
                    '${trip.waitingTimeSec ~/ 60} min ${trip.waitingTimeSec % 60} sec',
                    context,
                  ),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _detailRow('Pickup', trip.startAddress, context),
                  _detailRow('Drop-off', trip.endAddress, context),
                  _detailRow('Distance', '${trip.distanceKm} km', context),
                  Divider(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  _detailRow(
                    'Est. Fare',
                    'LKR ${trip.estimatedFare.toStringAsFixed(2)}',
                    context,
                  ),
                  _detailRow(
                    'Final Fare',
                    'LKR ${trip.finalFare.toStringAsFixed(2)}',
                    context,
                  ),
                  _detailRow('Payment', trip.paymentMethod, context),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        bool confirm =
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: Text(
                                    'Confirm Deletion',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  content: Text(
                                    'Are you sure you want to completely delete this trip? This action cannot be undone.',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Delete Permanently',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ) ??
                            false;

                        if (confirm && context.mounted) {
                          try {
                            final tripsProvider =
                                Provider.of<AdminTripsProvider>(
                                  context,
                                  listen: false,
                                );
                            await tripsProvider.deleteTrip(trip);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Trip successfully deleted',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete trip: $e',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Permanently Delete Trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSummaryCard(
    String title,
    int count,
    double? revenue,
    Color color,
    String filterValue,
  ) {
    bool isSelected = _filterType == filterValue;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterType = isSelected ? 'All' : filterValue;
          });
        },
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 12, bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? color
                  : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: const Color(0xFF000000).withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (revenue != null) ...[
                const SizedBox(height: 4),
                Text(
                  'LKR ${revenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AdminTripsProvider>(
          builder: (context, tripsProvider, child) {
            final dateTrips = tripsProvider.trips;

            int appBookingsCount = dateTrips
                .where((t) => t.type == 'booking')
                .length;
            int roadPickupsCount = dateTrips
                .where((t) => t.type == 'road_pickup')
                .length;
            int completedCount = dateTrips
                .where((t) => t.status == 'completed')
                .length;
            int cancelledCount = dateTrips
                .where((t) => t.status == 'cancelled')
                .length;

            final filteredTrips = dateTrips.where((trip) {
              if (_filterType == 'booking' && trip.type != 'booking')
                return false;
              if (_filterType == 'road_pickup' && trip.type != 'road_pickup')
                return false;
              if (_filterType == 'completed' && trip.status != 'completed')
                return false;
              if (_filterType == 'cancelled' && trip.status != 'cancelled')
                return false;

              if (_searchQuery.isEmpty) return true;

              final query = _searchQuery.toLowerCase();
              return trip.id.toLowerCase().contains(query) ||
                  trip.driverName.toLowerCase().contains(query) ||
                  trip.driverMembershipNo.toLowerCase().contains(query) ||
                  trip.startAddress.toLowerCase().contains(query) ||
                  trip.endAddress.toLowerCase().contains(query) ||
                  trip.passengerName.toLowerCase().contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ride History Log",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprehensive statistics across all services',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Today', label: Text('Today')),
                            ButtonSegment(
                              value: 'This Week',
                              label: Text('Week'),
                            ),
                            ButtonSegment(
                              value: 'This Month',
                              label: Text('Month'),
                            ),
                            ButtonSegment(
                              value: 'Custom',
                              label: Text('Custom'),
                            ),
                          ],
                          selected: {_timeFilter},
                          onSelectionChanged: (Set<String> newSelection) async {
                            final filter = newSelection.first;
                            if (filter == 'Custom') {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: DateTimeRange(
                                  start: _startDate,
                                  end: _endDate,
                                ),
                              );
                              if (picked != null) {
                                setState(() {
                                  _timeFilter = 'Custom';
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                  _isInit = true;
                                });
                                _fetchTrips();
                              }
                            } else {
                              _setTimeFilter(filter);
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.teal.withValues(alpha: 0.1);
                                  }
                                  return isDark
                                      ? Colors.grey.shade800
                                      : Colors.white;
                                }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.teal;
                                  }
                                  return isDark ? Colors.white : Colors.black87;
                                }),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_timeFilter == 'Custom')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Range: ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    children: [
                      _buildClickableSummaryCard(
                        'App Bookings',
                        appBookingsCount,
                        null,
                        Colors.blue,
                        'booking',
                      ),
                      _buildClickableSummaryCard(
                        'Road Pickups',
                        roadPickupsCount,
                        null,
                        Colors.orange,
                        'road_pickup',
                      ),
                      _buildClickableSummaryCard(
                        'Completed',
                        completedCount,
                        null,
                        Colors.green,
                        'completed',
                      ),
                      _buildClickableSummaryCard(
                        'Cancelled',
                        cancelledCount,
                        null,
                        Colors.red,
                        'cancelled',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_filterType != 'All')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(
                          'Showing $_filterType trips',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => _filterType = 'All'),
                          child: const Text('Clear Filter'),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by Trip ID, Driver, Route, Passenger...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: tripsProvider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        )
                      : filteredTrips.isEmpty
                      ? Center(
                          child: Text(
                            'No trips found for selected range.',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF000000,
                                ).withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade100,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Scrollbar(
                              controller: _horizontalScrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _horizontalScrollController,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minWidth: 1000,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12.0,
                                      ),
                                      child: DataTable(
                                        columnSpacing: 15,
                                        horizontalMargin: 12,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              Colors.teal.withValues(
                                                alpha: 0.02,
                                              ),
                                            ),
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 48,
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              '#',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Trip ID',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Time',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Type',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Driver',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Route Matrix',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Fare',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Status',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Action',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: filteredTrips.asMap().entries.map((
                                          entry,
                                        ) {
                                          int index = entry.key;
                                          var trip = entry.value;
                                          String formattedTime = DateFormat(
                                            'hh:mm a',
                                          ).format(trip.date);

                                          Color statusColor = Colors.grey;
                                          if (trip.status == 'completed')
                                            statusColor = Colors.green;
                                          if (trip.status == 'cancelled')
                                            statusColor = Colors.red;
                                          if (trip.status == 'ongoing')
                                            statusColor = Colors.orange;

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Text(
                                                  '${index + 1}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  trip.id,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 11,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  formattedTime,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        trip.type == 'booking'
                                                        ? Colors.blue
                                                              .withValues(
                                                                alpha: 0.1,
                                                              )
                                                        : Colors.orange
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    trip.type == 'booking'
                                                        ? "APP BOOKING"
                                                        : "ROAD PICKUP",
                                                    style: TextStyle(
                                                      color:
                                                          trip.type == 'booking'
                                                          ? Colors.blue
                                                          : Colors.orange,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      trip.driverName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color,
                                                      ),
                                                    ),
                                                    Text(
                                                      trip.driverMembershipNo,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: isDark
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 150,
                                                  child: Text(
                                                    '${trip.startAddress} ➔ ${trip.endAddress}',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  'LKR ${trip.finalFare.toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge
                                                        ?.color,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    trip.status.toUpperCase(),
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.remove_red_eye,
                                                    color: Colors.teal,
                                                  ),
                                                  tooltip: 'View Details',
                                                  onPressed: () =>
                                                      _showTripDetailsDialog(
                                                        context,
                                                        trip,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
