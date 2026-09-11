import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String password = '/auth/password';

  // Profile / Me
  static const String resident = '/me/resident';
  static const String household = '/me/household';
  static const String documents = '/me/documents';
  static const String dueBills = '/my/due-bills';
  static const String myPayments = '/my/payments';

  // Activities
  static const String activities = '/activities';
  static String activityDetail(int id) => '/activities/$id';
  static String activityRead(int id) => '/activities/$id/read';
  static String activityAttachments(int id) => '/activities/$id/attachments';
  static String activityAttachment(int activityId, int attachmentId) =>
      '/activities/$activityId/attachments/$attachmentId';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(int id) => '/notifications/$id/read';
  static const String notificationMarkAllRead = '/notifications/read-all';

  // Device Tokens
  static const String deviceTokens = '/device-tokens';
  static String deviceToken(String token) => '/device-tokens/$token';

  // Complaints
  static const String complaints = '/complaints';
  static String complaintDetail(int id) => '/complaints/$id';
  static String complaintStatus(int id) => '/complaints/$id/status';
  static String complaintAttachments(int id) => '/complaints/$id/attachments';
  static String complaintAttachment(int complaintId, int attachmentId) =>
      '/complaints/$complaintId/attachments/$attachmentId';
  static String complaintComments(int id) => '/complaints/$id/comments';

  // Finance
  static const String financeSummary = '/finance/summary';
  static const String financeTransactions = '/finance/transactions';
  static const String pendingPayments = '/payments/pending';
  static const String payments = '/payments';
  static String paymentDetail(int id) => '/payments/$id';
  static String paymentProof(int id) => '/payments/$id/proof';
  static String paymentApprove(int id) => '/payments/$id/approve';
  static String paymentReject(int id) => '/payments/$id/reject';

  // Bendahara / Dues & Expenses
  static const String dues = '/dues';
  static const String generateBills = '/dues/generate-bills';
  static String dueDetail(int id) => '/dues/$id';
  static String dueBillsList(int id) => '/dues/$id/due-bills';

  // SOS
  static const String sosAlerts = '/sos/alerts';
  static const String sosActive = '/sos/alerts/active';

  // Letters
  static const String letterTypes = '/letter-types';
  static String letterType(int id) => '/letter-types/$id';
  static const String myLetters = '/my/letters';
  static const String letters = '/letters';
  static String letterDetail(int id) => '/letters/$id';
  static const String lettersPending = '/letters/pending';
  static String letterApprove(int id) => '/letters/$id/approve';
  static String letterReject(int id) => '/letters/$id/reject';
  static String letterDocument(int id) => '/letters/$id/document';
  static String letterGenerateDoc(int id) => '/letters/$id/document/generate';

  // Me endpoints (warga)
  static const String meKtp = '/me/documents/ktp';
  static const String meKtpFile = '/me/documents/ktp/file';
  static const String meKk = '/me/documents/kk';
  static const String meKkFile = '/me/documents/kk/file';

  // Residents (RT Admin)
  static const String residents = '/residents';
  static String residentDetail(int id) => '/residents/$id';
  static String residentKtpFile(int id) => '/residents/$id/documents/ktp/file';
  static String residentKkFile(int id) => '/residents/$id/documents/kk/file';

  // Households (RT Admin)
  static const String households = '/households';
  static String householdDetail(int id) => '/households/$id';
  static String householdMembers(int id) => '/households/$id/members';
  static String householdMember(int id, int residentId) =>
      '/households/$id/members/$residentId';

  // Asset / Inventory
  static const String assets = '/assets';
  static String assetDetail(int id) => '/assets/$id';
  static String assetMovements(int id) => '/assets/$id/movements';
  static String assetMovement(int assetId, int movementId) =>
      '/assets/$assetId/movements/$movementId';

  // Users (RT Admin)
  static const String users = '/users';
  static String residentAccount(int residentId) =>
      '/residents/$residentId/account';
  static String userResetPassword(int userId) =>
      '/users/$userId/reset-password';
}
