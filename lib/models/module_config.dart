class ModuleConfig {
  final String id;
  final String title;
  final String icon;
  final bool pinned;
  final int order;

  ModuleConfig({
    required this.id,
    required this.title,
    required this.icon,
    required this.pinned,
    required this.order,
  });

  factory ModuleConfig.fromMap(Map<String, dynamic> map) {
    return ModuleConfig(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      icon: map['icon'] ?? '',
      pinned: map['pinned'] ?? false,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'pinned': pinned,
      'order': order,
    };
  }

  ModuleConfig copyWith({
    String? id,
    String? title,
    String? icon,
    bool? pinned,
    int? order,
  }) {
    return ModuleConfig(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      pinned: pinned ?? this.pinned,
      order: order ?? this.order,
    );
  }
}


