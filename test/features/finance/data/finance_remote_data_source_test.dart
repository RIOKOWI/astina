import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:astina/core/constants/api_constants.dart';
import 'package:astina/features/finance/data/datasources/finance_remote_data_source.dart';

import '../../../mocks/auth_mocks.mocks.dart';

void main() {
  late MockDioClient mockDioClient;
  late FinanceRemoteDataSource ds;

  setUp(() {
    mockDioClient = MockDioClient();
    ds = FinanceRemoteDataSource(mockDioClient);
  });

  group('FinanceRemoteDataSource', () {
    test('getSummary forwards month and parses cash summary', () async {
      when(
        mockDioClient.get(
          ApiConstants.financeSummary,
          queryParameters: {'month': '2026-09'},
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.financeSummary, {
          'data': {
            'balance': 1500000,
            'total_income': 1750000,
            'total_expense': 250000,
          },
        }),
      );

      final summary = await ds.getSummary(month: '2026-09');

      expect(summary.balance, 1500000);
      expect(summary.totalIncome, 1750000);
      expect(summary.totalExpense, 250000);
    });

    test('getTransactions forwards every documented filter', () async {
      when(
        mockDioClient.get(
          ApiConstants.financeTransactions,
          queryParameters: {
            'type': 'expense',
            'category': 'operational',
            'date_from': '2026-09-01',
            'date_to': '2026-09-30',
            'page': 2,
            'per_page': 20,
          },
        ),
      ).thenAnswer(
        (_) async => _paginatedResponse(ApiConstants.financeTransactions, [
          _transactionJson(),
        ], currentPage: 2),
      );

      final (transactions, meta) = await ds.getTransactions(
        type: 'expense',
        category: 'operational',
        dateFrom: '2026-09-01',
        dateTo: '2026-09-30',
        page: 2,
        perPage: 20,
      );

      expect(transactions.single.category, 'operational');
      expect(meta['current_page'], 2);
    });

    test('createTransaction posts and parses a manual ledger entry', () async {
      when(
        mockDioClient.post(
          ApiConstants.financeTransactions,
          data: {
            'type': 'expense',
            'amount': 150000,
            'category': 'operational',
            'description': 'Lampu jalan',
            'transaction_at': '2026-09-01 09:00:00',
          },
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.financeTransactions, {
          'data': _transactionJson(),
        }),
      );

      final transaction = await ds.createTransaction(
        type: 'expense',
        amount: 150000,
        category: 'operational',
        description: 'Lampu jalan',
        transactionAt: '2026-09-01 09:00:00',
      );

      expect(transaction.isExpense, isTrue);
    });

    test('getDues parses the paginated dues response', () async {
      when(
        mockDioClient.get(
          ApiConstants.dues,
          queryParameters: {
            'include_inactive': true,
            'page': 1,
            'per_page': 15,
          },
        ),
      ).thenAnswer(
        (_) async => _paginatedResponse(ApiConstants.dues, [_dueJson()]),
      );

      final (dues, meta) = await ds.getDues(includeInactive: true);

      expect(dues.single.name, 'Iuran Bulanan RT 005');
      expect(meta['total'], 1);
    });

    test('createDue sends all form fields', () async {
      when(
        mockDioClient.post(
          ApiConstants.dues,
          data: {
            'name': 'Iuran Bulanan RT 005',
            'amount': 50000,
            'description': 'Kas bulanan',
            'frequency': 'monthly',
            'start_date': '2026-01-01',
            'end_date': '2026-12-31',
            'is_active': true,
          },
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.dues, {'data': _dueJson()}),
      );

      final due = await ds.createDue(
        name: 'Iuran Bulanan RT 005',
        amount: 50000,
        description: 'Kas bulanan',
        frequency: 'monthly',
        startDate: '2026-01-01',
        endDate: '2026-12-31',
      );

      expect(due.id, 1);
    });

    test('getDue parses a due detail response', () async {
      when(mockDioClient.get(ApiConstants.dueDetail(1))).thenAnswer(
        (_) async => _response(ApiConstants.dueDetail(1), {'data': _dueJson()}),
      );

      final due = await ds.getDue(1);

      expect(due.frequency, 'monthly');
    });

    test('updateDue can explicitly clear nullable fields', () async {
      when(
        mockDioClient.put(
          ApiConstants.dueDetail(1),
          data: {
            'name': 'Iuran Revisi',
            'description': null,
            'start_date': null,
            'end_date': null,
          },
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.dueDetail(1), {
          'data': _dueJson(name: 'Iuran Revisi'),
        }),
      );

      final due = await ds.updateDue(
        1,
        name: 'Iuran Revisi',
        includeDescription: true,
        includeStartDate: true,
        includeEndDate: true,
      );

      expect(due.name, 'Iuran Revisi');
    });

    test('deleteDue calls the soft-delete endpoint', () async {
      when(
        mockDioClient.delete(ApiConstants.dueDetail(1)),
      ).thenAnswer((_) async => _response(ApiConstants.dueDetail(1), const {}));

      await ds.deleteDue(1);

      verify(mockDioClient.delete(ApiConstants.dueDetail(1))).called(1);
    });

    test('generateBills returns the created bill count', () async {
      when(
        mockDioClient.post(
          ApiConstants.generateBills,
          data: {'year': 2026, 'month': 9},
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.generateBills, {
          'data': {'created': 50},
        }),
      );

      final created = await ds.generateBills(year: 2026, month: 9);

      expect(created, 50);
    });

    test('getDueBills parses resident bill pagination', () async {
      when(
        mockDioClient.get(
          ApiConstants.dueBillsList(1),
          queryParameters: {'page': 1, 'per_page': 15},
        ),
      ).thenAnswer(
        (_) async => _paginatedResponse(ApiConstants.dueBillsList(1), [
          _dueBillJson(status: 'unpaid'),
        ]),
      );

      final (bills, meta) = await ds.getDueBills(1);

      expect(bills.single.residentId, 13);
      expect(bills.single.isUnpaid, isTrue);
      expect(meta['total'], 1);
    });

    test(
      'getMyPayments parses paginated response when due_bill has no due_id',
      () async {
        when(
          mockDioClient.get(
            ApiConstants.myPayments,
            queryParameters: {'page': 1, 'per_page': 15},
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: ApiConstants.myPayments),
            data: {
              'success': true,
              'message': 'Daftar pembayaran berhasil diambil.',
              'data': {
                'data': [_paymentJson()],
              },
              'meta': {
                'current_page': 1,
                'last_page': 1,
                'per_page': 15,
                'total': 1,
              },
            },
          ),
        );

        final (payments, meta) = await ds.getMyPayments();

        expect(payments, hasLength(1));
        expect(payments.first.dueBill?.id, 10);
        expect(payments.first.dueBill?.dueId, 1);
        expect(payments.first.dueBill?.due?.name, 'Iuran Bulanan RT 005');
        expect(meta['total'], 1);
      },
    );

    test('getPendingPayments parses pending approval response', () async {
      when(
        mockDioClient.get(
          ApiConstants.pendingPayments,
          queryParameters: {'page': 1, 'per_page': 15},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.pendingPayments),
          data: {
            'success': true,
            'message': 'Daftar pembayaran pending berhasil diambil.',
            'data': {
              'data': [_paymentJson(status: 'pending', method: 'ewallet')],
            },
            'meta': {
              'current_page': 1,
              'last_page': 1,
              'per_page': 15,
              'total': 1,
            },
          },
        ),
      );

      final (payments, meta) = await ds.getPendingPayments();

      expect(payments, hasLength(1));
      expect(payments.first.isPending, true);
      expect(payments.first.method, 'ewallet');
      expect(payments.first.resident?.fullName, 'Siti Nurhaliza');
      expect(meta['total'], 1);
    });

    test('createPayment posts the selected bill and payment method', () async {
      when(
        mockDioClient.post(
          ApiConstants.payments,
          data: {'due_bill_id': 10, 'amount': 50000, 'method': 'qris'},
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.payments, {
          'data': _paymentJson(status: 'pending', method: 'qris'),
        }),
      );

      final payment = await ds.createPayment(
        dueBillId: 10,
        amount: 50000,
        method: 'qris',
      );

      expect(payment.method, 'qris');
      expect(payment.isPending, isTrue);
    });

    test('getPayment parses payment detail', () async {
      when(mockDioClient.get(ApiConstants.paymentDetail(3))).thenAnswer(
        (_) async =>
            _response(ApiConstants.paymentDetail(3), {'data': _paymentJson()}),
      );

      final payment = await ds.getPayment(3);

      expect(payment.id, 3);
      expect(payment.proofs, hasLength(1));
      expect(payment.resident?.fullName, 'Siti Nurhaliza');
    });

    test(
      'uploadPaymentProof posts multipart data and parses the proof',
      () async {
        when(
          mockDioClient.postFormData(
            ApiConstants.paymentProof(3),
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async =>
              _response(ApiConstants.paymentProof(3), {'data': _proofJson()}),
        );

        final proof = await ds.uploadPaymentProof(3, 'docs/Finance/finance.md');

        expect(proof.paymentId, 3);
        verify(
          mockDioClient.postFormData(
            ApiConstants.paymentProof(3),
            data: anyNamed('data'),
          ),
        ).called(1);
      },
    );

    test('approvePayment parses the approved payment', () async {
      when(mockDioClient.post(ApiConstants.paymentApprove(3))).thenAnswer(
        (_) async =>
            _response(ApiConstants.paymentApprove(3), {'data': _paymentJson()}),
      );

      final payment = await ds.approvePayment(3);

      expect(payment.isApproved, isTrue);
    });

    test('rejectPayment posts the reason and parses rejection', () async {
      when(
        mockDioClient.post(
          ApiConstants.paymentReject(3),
          data: {'reason': 'Bukti tidak jelas'},
        ),
      ).thenAnswer(
        (_) async => _response(ApiConstants.paymentReject(3), {
          'data': _paymentJson(
            status: 'rejected',
            rejectionReason: 'Bukti tidak jelas',
          ),
        }),
      );

      final payment = await ds.rejectPayment(3, 'Bukti tidak jelas');

      expect(payment.isRejected, isTrue);
      expect(payment.rejectionReason, 'Bukti tidak jelas');
    });

    test('getMyDueBills labels paid status as lunas', () async {
      when(
        mockDioClient.get(
          ApiConstants.dueBills,
          queryParameters: {'page': 1, 'per_page': 15},
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiConstants.dueBills),
          data: {
            'success': true,
            'message': 'Daftar tagihan berhasil diambil.',
            'data': {
              'data': [_dueBillJson(status: 'paid')],
            },
            'meta': {'last_page': 1, 'total': 1},
          },
        ),
      );

      final (bills, _) = await ds.getMyDueBills();

      expect(bills, hasLength(1));
      expect(bills.first.status, 'paid');
      expect(bills.first.statusLabel, 'Lunas');
    });
  });
}

Map<String, dynamic> _paymentJson({
  String status = 'approved',
  String method = 'cash',
  String? rejectionReason,
}) {
  return {
    'id': 3,
    'due_bill_id': 10,
    'due_bill': {
      'id': 10,
      'due': {'id': 1, 'name': 'Iuran Bulanan RT 005', 'amount': 50000},
      'amount': 50000,
      'due_date': '2026-08-05',
      'status': 'unpaid',
    },
    'resident_id': 12,
    'resident': {'id': 12, 'full_name': 'Siti Nurhaliza'},
    'amount': 50000,
    'method': method,
    'status': status,
    'paid_at': '2026-09-02T12:34:56+00:00',
    'approved_at': status == 'approved' ? '2026-09-07T12:34:56+00:00' : null,
    'approved_by': status == 'approved' ? 12 : null,
    'approver': status == 'approved' ? {'id': 12, 'name': 'Bendahara'} : null,
    'rejection_reason': rejectionReason,
    'proofs': [_proofJson()],
    'created_at': '2026-09-10T12:34:56+00:00',
  };
}

Map<String, dynamic> _dueJson({String name = 'Iuran Bulanan RT 005'}) {
  return {
    'id': 1,
    'name': name,
    'description': 'Kas bulanan',
    'amount': 50000,
    'frequency': 'monthly',
    'start_date': '2026-01-01',
    'end_date': '2026-12-31',
    'is_active': true,
    'created_at': '2026-01-01T10:00:00+07:00',
  };
}

Map<String, dynamic> _transactionJson() {
  return {
    'id': 3,
    'created_by': 1,
    'payment_id': null,
    'type': 'expense',
    'amount': 150000,
    'category': 'operational',
    'description': 'Lampu jalan',
    'transaction_at': '2026-09-01T09:00:00+07:00',
    'creator': {'id': 1, 'name': 'H. Ahmad Wijaya'},
    'created_at': '2026-09-01T09:30:00+07:00',
  };
}

Map<String, dynamic> _proofJson() {
  return {
    'id': 3,
    'payment_id': 3,
    'url': 'http://localhost/storage/payment-proofs/3/sample.jpg',
    'file_name': 'bukti.jpg',
    'mime_type': 'image/jpeg',
    'file_size': 159841,
    'created_at': '2026-09-10T12:34:56+00:00',
  };
}

Map<String, dynamic> _dueBillJson({required String status}) {
  return {
    'id': 17,
    'due_id': 1,
    'due': {
      'id': 1,
      'name': 'Iuran Bulanan RT 005',
      'amount': 50000,
      'frequency': 'monthly',
      'is_active': true,
    },
    'resident_id': 13,
    'amount': 50000,
    'due_date': '2026-09-05',
    'status': status,
    'created_at': '2026-09-10T12:34:56+00:00',
  };
}

Response<dynamic> _response(String path, Map<String, dynamic> data) {
  return Response<dynamic>(
    requestOptions: RequestOptions(path: path),
    data: data,
  );
}

Response<dynamic> _paginatedResponse(
  String path,
  List<Map<String, dynamic>> items, {
  int currentPage = 1,
}) {
  return _response(path, {
    'success': true,
    'data': {'data': items},
    'meta': {
      'current_page': currentPage,
      'last_page': currentPage,
      'per_page': 15,
      'total': items.length,
    },
  });
}
