import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../models/ride_option.dart';
import '../providers/ride_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/primary_button.dart';
import 'ride_confirmation_screen.dart';

class RideOptionsScreen extends StatelessWidget {
  final LocationModel pickup;
  final LocationModel dropoff;

  const RideOptionsScreen(
      {super.key, required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    final ride = context.watch<RideProvider>();
    final options = ride.buildRideOptions();
    final route = ride.lastRoute;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Choose a ride")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Route Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Route Summary",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (route?.isFallback == true)
                            const Chip(
                              label: Text("Demo Route"),
                              backgroundColor: Color(0xFFFFF3CD),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _RouteDetailRow(
                        icon: Icons.location_on,
                        label: "Pickup",
                        value: pickup.label,
                      ),
                      const SizedBox(height: 8),
                      _RouteDetailRow(
                        icon: Icons.location_on,
                        label: "Drop-off",
                        value: dropoff.label,
                      ),
                      const Divider(height: 20),
                      if (route != null)
                        Row(
                          children: [
                            _RouteMetric(
                              icon: Icons.linear_scale,
                              value:
                                  "${route.distanceKm.toStringAsFixed(1)} km",
                              label: "Distance",
                            ),
                            _RouteMetric(
                              icon: Icons.timer,
                              value:
                                  "${route.durationMin.toStringAsFixed(0)} min",
                              label: "Duration",
                            ),
                            _RouteMetric(
                              icon: Icons.attach_money,
                              value:
                                  "PKR ${options.isNotEmpty ? options.first.price.toStringAsFixed(0) : '0'}",
                              label: "From",
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Available Rides",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    final o = options[i];
                    final selected =
                        ride.selectedOption?.category == o.category;

                    // Calculate detailed fare
                    final baseFare = o.category.baseFare;
                    final distanceKm = route?.distanceKm ?? 0;
                    final distanceFare = distanceKm * o.category.perKm;
                    final totalFare = baseFare + distanceFare;

                    return Card(
                      color: selected ? cs.primaryContainer : null,
                      elevation: selected ? 2 : 1,
                      child: InkWell(
                        onTap: () =>
                            context.read<RideProvider>().selectOption(o),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Vehicle Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  o.category.asset,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Ride Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          o.category.label,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (selected)
                                          Icon(Icons.check_circle,
                                              color: cs.primary),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      o.category.isDelivery
                                          ? "Delivery • ${o.estimatedArrivalMinutes.toStringAsFixed(0)} min"
                                          : "${o.category.seats} seats • ${o.estimatedArrivalMinutes.toStringAsFixed(0)} min",
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.linear_scale,
                                            size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${distanceKm.toStringAsFixed(1)} km • ${route?.durationMin.toStringAsFixed(0) ?? '0'} min",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (route != null)
                                      Row(
                                        children: [
                                          Text(
                                            "Base: ${Formatters.money(baseFare)}",
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Distance: ${Formatters.money(distanceFare)}",
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.money(totalFare),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "PKR",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Fare Breakdown (when ride selected)
              if (ride.selectedOption != null && route != null)
                Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Fare Breakdown",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              "Total: ${Formatters.money(ride.selectedOption!.price)}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _FareBreakdownRow(
                          label: "Base fare",
                          value: Formatters.money(
                              ride.selectedOption!.category.baseFare),
                        ),
                        _FareBreakdownRow(
                          label:
                              "Distance (${route.distanceKm.toStringAsFixed(1)} km × ${ride.selectedOption!.category.perKm}/km)",
                          value: Formatters.money(route.distanceKm *
                              ride.selectedOption!.category.perKm),
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Estimated arrival",
                              style: TextStyle(color: cs.onPrimaryContainer),
                            ),
                            Text(
                              "${ride.selectedOption!.estimatedArrivalMinutes.toStringAsFixed(0)} min",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              PrimaryButton(
                label: ride.selectedOption == null
                    ? "Select a Ride"
                    : "Confirm Ride • ${Formatters.money(ride.selectedOption!.price)}",
                icon: Icons.check_circle_outline,
                onPressed: ride.selectedOption == null
                    ? null
                    : () async {
                        await context
                            .read<RideProvider>()
                            .confirmRide(pickup: pickup, dropoff: dropoff);
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RideConfirmationScreen()),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper Widgets

class _RouteDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _RouteDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _RouteMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _FareBreakdownRow extends StatelessWidget {
  final String label;
  final String value;

  const _FareBreakdownRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimaryContainer),
            ),
          ],
        ));
  }
}
