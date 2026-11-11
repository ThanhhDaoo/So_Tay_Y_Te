class Medicine {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final String? instructions;

  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.instructions,
  });
}
