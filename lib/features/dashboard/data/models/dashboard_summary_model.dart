class DashboardSummary {
  const DashboardSummary({
    this.letterPendingCount = 0,
    this.complaintPendingCount = 0,
    this.sosActiveCount = 0,
    this.activityCount = 0,
    this.paymentPendingCount = 0,
    this.cashBalance = 0,
    this.myDueBillAmount = 0,
  });

  final int letterPendingCount;
  final int complaintPendingCount;
  final int sosActiveCount;
  final int activityCount;
  final int paymentPendingCount;
  final int cashBalance;
  final int myDueBillAmount;

  DashboardSummary copyWith({
    int? letterPendingCount,
    int? complaintPendingCount,
    int? sosActiveCount,
    int? activityCount,
    int? paymentPendingCount,
    int? cashBalance,
    int? myDueBillAmount,
  }) {
    return DashboardSummary(
      letterPendingCount: letterPendingCount ?? this.letterPendingCount,
      complaintPendingCount:
          complaintPendingCount ?? this.complaintPendingCount,
      sosActiveCount: sosActiveCount ?? this.sosActiveCount,
      activityCount: activityCount ?? this.activityCount,
      paymentPendingCount: paymentPendingCount ?? this.paymentPendingCount,
      cashBalance: cashBalance ?? this.cashBalance,
      myDueBillAmount: myDueBillAmount ?? this.myDueBillAmount,
    );
  }
}
