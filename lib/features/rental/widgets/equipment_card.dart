import 'package:flutter/material.dart';
import 'package:kissan_connect/core/constants/app_colors.dart';
import 'package:kissan_connect/core/models/equipment_model.dart';

class EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;
  final VoidCallback onTap;

  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vehicle / Machinery Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  equipment.imageUrl,
                  width: 120,
                  height: 95,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 95,
                    color: AppColors.primaryLight,
                    child: const Icon(
                      Icons.agriculture_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      equipment.typeLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${equipment.ratePerHour.toInt()} / per hour',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            equipment.location,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          equipment.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
