class DirectorySection {
  final int id;
  final String code;
  final String name;
  final String description;

  const DirectorySection({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
  });

  factory DirectorySection.fromJson(Map<String, dynamic> json) {
    return DirectorySection(
      id: json['id'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class DirectoryEntry {
  final int id;
  final int section;
  final String code;
  final String name;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const DirectoryEntry({
    required this.id,
    required this.section,
    required this.code,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    this.metadata = const <String, dynamic>{},
  });

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    final metadataMap = metadataRaw is Map<String, dynamic>
        ? metadataRaw
        : const <String, dynamic>{};

    return DirectoryEntry(
      id: json['id'] as int,
      section: json['section'] as int,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sortOrder: json['sort_order'] as int? ?? 100,
      isActive: json['is_active'] as bool? ?? true,
      metadata: metadataMap,
    );
  }
}
