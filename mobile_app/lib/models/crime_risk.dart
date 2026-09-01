class CrimeRisk {
  const CrimeRisk({
    required this.riskLevel, // 'LOW', 'MEDIUM', 'HIGH'
    required this.riskScore, // 0 - 100
    this.probability = 0.0,
    this.recommendation,
    this.factors = const [],
    this.crimeTypeBreakdown = const {},
  });

  final String riskLevel;
  final double riskScore;
  final double probability;
  final String? recommendation;
  final List<String> factors;
  final Map<String, dynamic> crimeTypeBreakdown;

  bool get isHighRisk => riskLevel.toUpperCase() == 'HIGH' || riskScore >= 70;
  bool get isMediumRisk => riskLevel.toUpperCase() == 'MEDIUM' || (riskScore >= 40 && riskScore < 70);
  bool get isLowRisk => !isHighRisk && !isMediumRisk;

  String get defaultRecommendation {
    if (recommendation != null && recommendation!.trim().isNotEmpty) {
      return recommendation!;
    }
    if (isHighRisk) {
      return 'Caution advised: High risk area. Avoid walking alone after dusk, keep contacts on speed-dial, and stay along well-lit main corridors.';
    } else if (isMediumRisk) {
      return 'Stay alert: Moderate activity reported. Keep emergency contacts ready and prefer crowded, illuminated routes.';
    } else {
      return 'Area is currently rated safe. Standard situational awareness recommended.';
    }
  }

  factory CrimeRisk.fromJson(Map<String, dynamic> json) {
    final rawRiskScore = json['risk_score'] ?? json['score'] ?? 0;
    final riskScore = (rawRiskScore is num) ? rawRiskScore.toDouble() : double.tryParse('$rawRiskScore') ?? 0.0;
    final rawProb = json['probability'] ?? (riskScore / 100.0);
    final probability = (rawProb is num) ? rawProb.toDouble() : double.tryParse('$rawProb') ?? 0.0;

    String level = (json['risk_level'] as String? ?? '').toUpperCase();
    if (level.isEmpty) {
      if (riskScore >= 70) {
        level = 'HIGH';
      } else if (riskScore >= 40) {
        level = 'MEDIUM';
      } else {
        level = 'LOW';
      }
    }

    final factorsList = <String>[];
    if (json['factors'] is List) {
      for (final f in json['factors'] as List) {
        if (f != null) factorsList.add(f.toString());
      }
    }

    Map<String, dynamic> breakdown = {};
    if (json['breakdown'] is Map) {
      breakdown = Map<String, dynamic>.from(json['breakdown'] as Map);
    } else if (json['crime_types'] is Map) {
      breakdown = Map<String, dynamic>.from(json['crime_types'] as Map);
    }

    return CrimeRisk(
      riskLevel: level,
      riskScore: riskScore,
      probability: probability,
      recommendation: json['recommendation'] as String? ?? json['safety_tip'] as String?,
      factors: factorsList,
      crimeTypeBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toJson() => {
    'risk_level': riskLevel,
    'risk_score': riskScore,
    'probability': probability,
    'recommendation': recommendation,
    'factors': factors,
    'breakdown': crimeTypeBreakdown,
  };
}

class PredictionResponse {
  const PredictionResponse({
    required this.success,
    required this.risk,
    this.message,
  });

  final bool success;
  final CrimeRisk risk;
  final String? message;

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return PredictionResponse(
      success: json['success'] == true || json['status'] == 'success' || json['risk_level'] != null,
      risk: CrimeRisk.fromJson(data),
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'data': risk.toJson(),
    'message': message,
  };
}
