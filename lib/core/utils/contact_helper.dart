import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactHelper {
  static Future<void> makePhoneCall(BuildContext context, String rawPhoneNumber) async {
    final cleanedNumber = rawPhoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanedNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call to $cleanedNumber')),
        );
      }
    }
  }

  static Future<void> openWhatsApp(BuildContext context, String rawPhoneNumber, {String message = ''}) async {
    final cleanedNumber = rawPhoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$cleanedNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp is not installed or number is invalid')),
        );
      }
    }
  }
}