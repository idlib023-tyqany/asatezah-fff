class OtpChallenge {
  const OtpChallenge({
    required this.verificationId,
    required this.purpose,
    required this.channels,
    required this.destinations,
  });

  final String verificationId;
  final String purpose;
  final List<String> channels;
  final Map<String, dynamic> destinations;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) {
    final id = json['verification_id'];
    final rawChannels = json['channels'];
    final rawDestinations = json['destinations'];
    if (id is! String || id.isEmpty || rawChannels is! List) {
      throw const FormatException('بيانات التحقق غير صالحة.');
    }

    return OtpChallenge(
      verificationId: id,
      purpose: json['purpose'] as String? ?? 'login',
      channels: rawChannels.whereType<String>().toList(growable: false),
      destinations: rawDestinations is Map
          ? Map<String, dynamic>.from(rawDestinations)
          : const {},
    );
  }
}
