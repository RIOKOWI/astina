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

  // Complaints
  static const String complaints = '/complaints';

  // Finance
  static const String financeSummary = '/finance/summary';
  static const String financeTransactions = '/finance/transactions';
  static const String pendingPayments = '/payments/pending';
  static const String payments = '/payments';

  // Bendahara / Dues & Expenses
  static const String dues = '/dues';
  static const String expenses = '/expenses';
  static const String generateBills = '/dues/generate-bills';
  static String dueBillsByDue(int dueId) => '/dues/$dueId/due-bills';
  static String generateDocument(int letterId) =>
      '/letters/$letterId/document/generate';

  // SOS
  static const String sosAlerts = '/sos/alerts';
  static const String sosActive = '/sos/alerts/active';

  // Letters
  static const String letterTypes = '/letter-types';
  static const String myLetters = '/my/letters';
  static const String letters = '/letters';
  static const String lettersPending = '/letters/pending';

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

  // Device tokens
  static const String deviceTokens = '/device-tokens';

  // Users (RT Admin)
  static const String users = '/users';
  static String residentAccount(int residentId) =>
      '/residents/$residentId/account';
  static String userResetPassword(int userId) =>
      '/users/$userId/reset-password';
}
