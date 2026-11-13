enum DocumentCategory {
  all('all', 'Tất cả', 24),
  prescriptions('prescriptions', 'Toa thuốc', 8),
  bloodTests('blood_tests', 'Xét nghiệm máu', 5),
  endoscopy('endoscopy', 'Siêu âm / Nội soi', 6),
  xray('xray', 'X-Quang / CT', 3),
  discharge('discharge', 'Giấy ra viện', 2);

  const DocumentCategory(this.id, this.label, this.count);

  final String id;
  final String label;
  final int count;
}

class ExtractedDrugItem {
  const ExtractedDrugItem({
    required this.name,
    required this.dosage,
  });

  final String name;
  final String dosage;
}

class DocumentsState {
  const DocumentsState({
    required this.selectedCategory,
    this.showViewerTip = true,
    this.usedStorageMb = 142,
    this.savedStorageMb = 480,
    this.totalStorageGb = '1.8 GB',
    this.totalDocCount = 24,
  });

  final DocumentCategory selectedCategory;
  final bool showViewerTip;
  final int usedStorageMb;
  final int savedStorageMb;
  final String totalStorageGb;
  final int totalDocCount;

  DocumentsState copyWith({
    DocumentCategory? selectedCategory,
    bool? showViewerTip,
    int? usedStorageMb,
    int? savedStorageMb,
    String? totalStorageGb,
    int? totalDocCount,
  }) {
    return DocumentsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      showViewerTip: showViewerTip ?? this.showViewerTip,
      usedStorageMb: usedStorageMb ?? this.usedStorageMb,
      savedStorageMb: savedStorageMb ?? this.savedStorageMb,
      totalStorageGb: totalStorageGb ?? this.totalStorageGb,
      totalDocCount: totalDocCount ?? this.totalDocCount,
    );
  }
}

