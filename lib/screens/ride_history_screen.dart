import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ride_model.dart';
import '../providers/ride_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/app_drawer.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  final _searchCtrl = TextEditingController();
  RideStatus? _filter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RideProvider>();
    final all = rp.rideHistory;

    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = all.where((r) {
      if (_filter != null && r.status != _filter) return false;
      if (q.isEmpty) return true;
      return r.pickup.label.toLowerCase().contains(q) ||
          r.dropoff.label.toLowerCase().contains(q) ||
          r.driver.name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 1),
      appBar: AppBar(
        title: const Text("Ride History"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: () => context.read<RideProvider>().loadHistory(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: "Search rides (places / driver)…",
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text("All"),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  FilterChip(
                    label: const Text("Completed"),
                    selected: _filter == RideStatus.completed,
                    onSelected: (_) =>
                        setState(() => _filter = RideStatus.completed),
                  ),
                  FilterChip(
                    label: const Text("Cancelled"),
                    selected: _filter == RideStatus.cancelled,
                    onSelected: (_) =>
                        setState(() => _filter = RideStatus.cancelled),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text("No rides yet."))
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final r = filtered[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: const Icon(Icons.person,
                                    color: Colors.white),
                              ),
                              title: Text(
                                "${r.pickup.label} → ${r.dropoff.label}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${Formatters.dateTime(r.createdAt)} • ${r.status.label}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (r.driverRating != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Rated: ${r.driverRating!.toStringAsFixed(1)}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    Formatters.money(r.fare),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  if (r.driverRating != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.star,
                                            size: 14, color: Colors.amber),
                                        const SizedBox(width: 2),
                                        Text(
                                          r.driverRating!.toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    )
                                  else
                                    Text(
                                      "${r.distanceKm.toStringAsFixed(1)} km",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                ],
                              ),
                              onTap: () => _showRideDetails(context, r),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRideDetails(BuildContext context, RideModel r) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Constants.defaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Ride details",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text("Date: ${Formatters.dateTime(r.createdAt)}"),
                Text("Status: ${r.status.label}"),
                const SizedBox(height: 10),
                Text(
                    "Driver: ${r.driver.name} (${r.driver.rating.toStringAsFixed(1)}★)"),
                Text(
                    "Vehicle: ${r.driver.vehicleName} • ${r.driver.plateNumber}"),
                if (r.driverRating != null) ...[
                  const SizedBox(height: 10),
                  Text("Your Rating: ★${r.driverRating!}"),
                  if (r.ratingComment != null && r.ratingComment!.isNotEmpty)
                    Text("Comment: ${r.ratingComment!}"),
                ],
                const SizedBox(height: 10),
                Text("From: ${r.pickup.label}"),
                Text("To: ${r.dropoff.label}"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                        child: Text("${r.distanceKm.toStringAsFixed(1)} km")),
                    Expanded(
                        child: Text("${r.durationMin.toStringAsFixed(0)} min")),
                    Expanded(
                        child: Text(Formatters.money(r.fare),
                            textAlign: TextAlign.end)),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Receipt downloaded."))),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text("Download receipt"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
