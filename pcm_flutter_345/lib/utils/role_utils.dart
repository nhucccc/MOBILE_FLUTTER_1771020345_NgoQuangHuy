class RoleUtils {
  static const String admin = 'Admin';
  static const String member = 'Member';
  static const String treasurer = 'Treasurer';
  static const String referee = 'Referee';

  static bool isAdmin(String? role) => role == admin;
  static bool isMember(String? role) => role == member;
  static bool isTreasurer(String? role) => role == treasurer;
  static bool isReferee(String? role) => role == referee;

  static bool canManageMembers(String? role) => isAdmin(role);
  static bool canManageCourts(String? role) => isAdmin(role);
  static bool canManageFinances(String? role) => isAdmin(role) || isTreasurer(role);
  static bool canManageTournaments(String? role) => isAdmin(role) || isReferee(role);
  static bool canViewReports(String? role) => isAdmin(role) || isTreasurer(role);
  static bool canExportData(String? role) => isAdmin(role) || isTreasurer(role);

  static String getRoleDisplayName(String? role) {
    switch (role) {
      case admin:
        return 'Quản trị viên';
      case treasurer:
        return 'Kế toán';
      case referee:
        return 'Trọng tài';
      case member:
        return 'Thành viên';
      default:
        return 'Thành viên';
    }
  }

  static String getRoleDescription(String? role) {
    switch (role) {
      case admin:
        return 'Quản lý toàn bộ hệ thống';
      case treasurer:
        return 'Quản lý tài chính và báo cáo';
      case referee:
        return 'Quản lý giải đấu và trọng tài';
      case member:
        return 'Tham gia hoạt động câu lạc bộ';
      default:
        return 'Tham gia hoạt động câu lạc bộ';
    }
  }
}