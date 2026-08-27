class ClosePreflightCheck {
  const ClosePreflightCheck({
    required this.checkCode,
    required this.severity,
    required this.blocking,
    required this.issueCount,
    required this.message,
  });

  final String checkCode;
  final String severity;
  final bool blocking;
  final int issueCount;
  final String message;

  factory ClosePreflightCheck.fromJson(Map<String, dynamic> json) {
    return ClosePreflightCheck(
      checkCode: json['check_code']?.toString() ?? '',
      severity: json['severity']?.toString() ?? 'info',
      blocking: json['blocking'] == true,
      issueCount: (json['issue_count'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}
