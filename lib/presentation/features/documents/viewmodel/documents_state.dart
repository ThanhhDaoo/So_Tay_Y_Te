enum DocumentCategory {
  all('all', 'Tất cả', 0),
  prescriptions('prescriptions', 'Toa thuốc', 0),
  bloodTests('blood_tests', 'Xét nghiệm máu', 0),
  endoscopy('endoscopy', 'Siêu âm / Nội soi', 0),
  xray('xray', 'X-Quang / CT', 0),
  discharge('discharge', 'Giấy ra viện', 0);

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

class MedicalDocumentItem {
  final String id;
  final String title;
  final DocumentCategory category;
  final String date;
  final String hospital;
  final String imagePath;
  final List<Map<String, String>> keyFindings;

  const MedicalDocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.hospital,
    required this.imagePath,
    this.keyFindings = const [],
  });
}

class DocumentsState {
  const DocumentsState({
    required this.selectedCategory,
    this.showViewerTip = true,
    this.usedStorageMb = 0,
    this.savedStorageMb = 0,
    this.totalStorageGb = '0 MB',
    this.totalDocCount = 0,
    this.documents = const [],
  });

  final DocumentCategory selectedCategory;
  final bool showViewerTip;
  final int usedStorageMb;
  final int savedStorageMb;
  final String totalStorageGb;
  final int totalDocCount;
  final List<MedicalDocumentItem> documents;

  DocumentsState copyWith({
    DocumentCategory? selectedCategory,
    bool? showViewerTip,
    int? usedStorageMb,
    int? savedStorageMb,
    String? totalStorageGb,
    int? totalDocCount,
    List<MedicalDocumentItem>? documents,
  }) {
    return DocumentsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      showViewerTip: showViewerTip ?? this.showViewerTip,
      usedStorageMb: usedStorageMb ?? this.usedStorageMb,
      savedStorageMb: savedStorageMb ?? this.savedStorageMb,
      totalStorageGb: totalStorageGb ?? this.totalStorageGb,
      totalDocCount: totalDocCount ?? this.totalDocCount,
      documents: documents ?? this.documents,
    );
  }
}

