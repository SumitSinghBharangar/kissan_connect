class AppTranslations {
  static const Map<String, Map<String, String>> values = {
    'en': {
      'app_title': 'Kissan Connect',
      'home': 'Home',
      'rent': 'Rent',
      'chats': 'Chats',
      'profile': 'Profile',
      'welcome': 'Namaste, Farmer',
      'services': 'Quick Services',
      'available_tractors': 'Available Machinery',
      'mandi_rates': 'Mandi Rates',
      'weather': 'Weather',
      'kisan_yojana': 'Kisan Yojana',
      'book_now': 'Book Machine',
      'call_owner': 'Call Owner',
      'whatsapp': 'WhatsApp',
      'my_bookings': 'My Bookings',
      'my_equipment': 'My Listed Machinery',
      'notifications': 'Notifications',
      'change_language': 'Change Language',
      'save': 'Save',
      'rate_per_hour': '₹/hour',
    },
    'hi': {
      'app_title': 'किसान कनेक्ट',
      'home': 'होम',
      'rent': 'किराया',
      'chats': 'संदेश',
      'profile': 'प्रोफ़ाइल',
      'welcome': 'नमस्ते, किसान भाई',
      'services': 'मुख्य सेवाएं',
      'available_tractors': 'उपलब्ध कृषि यंत्र',
      'mandi_rates': 'मंडी भाव',
      'weather': 'मौसम व सलाह',
      'kisan_yojana': 'किसान योजना',
      'book_now': 'मशीन बुक करें',
      'call_owner': 'मालिक को कॉल करें',
      'whatsapp': 'व्हाट्सएप संदेश',
      'my_bookings': 'मेरी बुकिंग्स',
      'my_equipment': 'मेरे कृषि यंत्र',
      'notifications': 'सूचनाएं',
      'change_language': 'भाषा बदलें',
      'save': 'सुरक्षित करें',
      'rate_per_hour': '₹/घंटा',
    },
  };

  static String get(String key, String langCode) {
    return values[langCode]?[key] ?? values['en']?[key] ?? key;
  }
}
