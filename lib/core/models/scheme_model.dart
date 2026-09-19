class SchemeModel {
  final String id;
  final String title;
  final String category;
  final String benefitSummary;
  final String description;
  final List<String> eligibility;
  final List<String> requiredDocuments;
  final String officialPortalUrl;

  SchemeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.benefitSummary,
    required this.description,
    required this.eligibility,
    required this.requiredDocuments,
    required this.officialPortalUrl,
  });

  factory SchemeModel.fromMap(Map<String, dynamic> map, String docId) {
    return SchemeModel(
      id: docId,
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      benefitSummary: map['benefitSummary'] ?? '',
      description: map['description'] ?? '',
      eligibility: List<String>.from(map['eligibility'] ?? []),
      requiredDocuments: List<String>.from(map['requiredDocuments'] ?? []),
      officialPortalUrl: map['officialPortalUrl'] ?? 'https://agricoop.gov.in',
    );
  }
}
