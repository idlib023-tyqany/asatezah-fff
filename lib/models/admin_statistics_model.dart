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
    return AdminStatisticsModel(
      totalUsers: json['total_users'] ?? json['users_count'] ?? 0,
      totalFiles: json['total_files'] ?? json['files_count'] ?? 0,
      pendingFiles: json['pending_files'] ?? json['pending_files_count'] ?? 0,
      totalDownloads: json['total_downloads'] ?? json['downloads_count'] ?? 0,
      openReports: json['open_reports'] ?? json['reports_count'] ?? 0,
      openSupportTickets: json['open_support_tickets'] ?? json['tickets_count'] ?? 0,
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
