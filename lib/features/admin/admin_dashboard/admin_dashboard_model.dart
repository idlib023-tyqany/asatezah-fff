

class AdminStatisticsModel {
  final int totalUsers;
  final int totalFiles;
  final int pendingFiles;
  final int totalDownloads;
  final int openReports;
  final int openSupportTickets;

  AdminStatisticsModel({
    required this.totalUsers,
    required this.totalFiles,
    required this.pendingFiles,
    required this.totalDownloads,
    required this.openReports,
    required this.openSupportTickets,
  });

  factory AdminStatisticsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminStatisticsModel(
      totalUsers: parseInt(json['total_users'] ?? json['users_count']),
      totalFiles: parseInt(json['total_files'] ?? json['files_count']),
      pendingFiles: parseInt(json['pending_files'] ?? json['pending_files_count']),
      totalDownloads: parseInt(json['total_downloads'] ?? json['downloads_count']),
      openReports: parseInt(json['open_reports'] ?? json['reports_count']),
      openSupportTickets: parseInt(json['open_support_tickets'] ?? json['tickets_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_users': totalUsers,
      'total_files': totalFiles,
      'pending_files': pendingFiles,
      'total_downloads': totalDownloads,
      'open_reports': openReports,
      'open_support_tickets': openSupportTickets,
    };
  }
}
