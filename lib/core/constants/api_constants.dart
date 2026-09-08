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

  // RT Administration
  static const String residents = '/residents';
  static const String households = '/households';
  static const String users = '/users';

  // RT Household members
  static const String householdMembers = '/households/-/members';
  // RT Resident account
  static String residentAccount(int residentId) =>
      '/residents/$residentId/account';
  // RT User password reset
  static String userResetPassword(int userId) =>
      '/users/$userId/reset-password';

  // Asset / Inventory
  static const String assets = '/assets';

  // Device tokens
  static const String deviceTokens = '/device-tokens';
}
