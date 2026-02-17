import 'package:flutter/material.dart';
import '../models/driver_model.dart';
import '../utils/constants.dart';

class DriverCard extends StatelessWidget {
  final DriverModel driver;

  const DriverCard({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundImage: AssetImage(driver.avatarAsset),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text("${driver.vehicleName} • ${driver.plateNumber}",
                      style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.star, color: const Color(Constants.secondaryGreen)),
                Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
