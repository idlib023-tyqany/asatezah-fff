import 'dart:convert';

class AppInfo {
  final String name;
  final String? logoPath;
  final String version;
  final bool isUpdateRequired;
  final Map<String, String?> links;

  const AppInfo({
    required this.name,
    this.logoPath,
    required this.version,
    this.isUpdateRequired = false,
    required this.links,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    final rawLinks = json['links'];
    final Map<String, String?> linksMap = {};

    if (rawLinks is Map) {
      rawLinks.forEach((key, value) {
        linksMap[key.toString()] = value?.toString();
      });
    }

    return AppInfo(
      name: json['name'] as String? ?? 'أساتذة',
      logoPath: json['logo_path'] as String?,
      version: json['version'] as String? ?? '1.0.0',
      isUpdateRequired:
          json['is_update_required'] as bool? ?? json['force_update'] as bool? ?? false,
      links: linksMap,
    );
  }

  factory AppInfo.fromRawJson(String str) =>
      AppInfo.fromJson(json.decode(str) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
        'name': name,
        'logo_path': logoPath,
        'version': version,
        'is_update_required': isUpdateRequired,
        'links': links,
      };

  String toRawJson() => json.encode(toJson());

  AppInfo copyWith({
    String? name,
    String? logoPath,
    String? version,
    bool? isUpdateRequired,
    Map<String, String?>? links,
  }) {
    return AppInfo(
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      version: version ?? this.version,
      isUpdateRequired: isUpdateRequired ?? this.isUpdateRequired,
      links: links ?? this.links,
    );
  }

  String? get facebookLink => links['facebook'];
  String? get telegramLink => links['telegram'];
  String? get whatsappLink => links['whatsapp'];
  String? get websiteLink => links['website'];
  String? get privacyPolicyLink => links['privacy_policy'];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppInfo &&
        other.name == name &&
        other.logoPath == logoPath &&
        other.version == version &&
        other.isUpdateRequired == isUpdateRequired &&
        _mapEquals(other.links, links);
  }

  @override
  int get hashCode =>
      Object.hash(name, logoPath, version, isUpdateRequired, Object.hashAll(links.entries));

  @override
  String toString() =>
      'AppInfo(name: "$name", version: "$version", logoPath: "$logoPath", linksCount: ${links.length})';

  static bool _mapEquals(Map<String, String?> a, Map<String, String?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
