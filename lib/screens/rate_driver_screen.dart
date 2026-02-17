import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ride_provider.dart';
import '../utils/constants.dart';

class RateDriverScreen extends StatefulWidget {
  final String rideId;

  const RateDriverScreen({super.key, required this.rideId});

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int rating = 5;
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RideProvider>();
    final ride = rp.rideHistory.firstWhere(
      (r) => r.id == widget.rideId,
      orElse: () => rp.activeRide ?? rp.rideHistory.first,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Rate driver")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Constants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("How was your ride with ${ride.driver.name}?",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = star <= rating;
                  return IconButton(
                    onPressed: () => setState(() => rating = star),
                    icon: Icon(filled ? Icons.star : Icons.star_border),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Comment (optional)",
                  alignLabelWithHint: true,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await context.read<RideProvider>().saveRideRating(
                          rideId: widget.rideId,
                          rating: rating,
                          comment: _commentCtrl.text.trim(),
                        );
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text("Save rating"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
