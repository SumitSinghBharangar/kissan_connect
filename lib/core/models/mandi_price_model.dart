class MandiPriceModel {
  final String id;
  final String commodity;
  final String variety;
  final String mandi;
  final String district;
  final String state;
  final num minPrice;
  final num maxPrice;
  final num modalPrice;
  final DateTime date;

  MandiPriceModel({
    required this.id,
    required this.commodity,
    required this.variety,
    required this.mandi,
    required this.district,
    required this.state,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.date,
  });

  factory MandiPriceModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return MandiPriceModel(
      id: docId ?? (map['id'] as String? ?? ''),
      commodity: map['commodity'] as String? ?? '',
      variety: map['variety'] as String? ?? 'Common',
      mandi: map['mandi'] as String? ?? '',
      district: map['district'] as String? ?? '',
      state: map['state'] as String? ?? '',
      minPrice: map['minPrice'] as num? ?? 0,
      maxPrice: map['maxPrice'] as num? ?? 0,
      modalPrice: map['modalPrice'] as num? ?? 0,
      date: map['date'] != null
          ? (map['date'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commodity': commodity,
      'variety': variety,
      'mandi': mandi,
      'district': district,
      'state': state,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'modalPrice': modalPrice,
      'date': date,
    };
  }
}
