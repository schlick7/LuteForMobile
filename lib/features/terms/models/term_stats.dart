class TermStats {
  final int status1;
  final int status2;
  final int status3;
  final int status4;
  final int status5;
  final int status99;
  final int total;

  const TermStats({
    required this.status1,
    required this.status2,
    required this.status3,
    required this.status4,
    required this.status5,
    required this.status99,
    required this.total,
  });

  static const TermStats empty = TermStats(
    status1: 0,
    status2: 0,
    status3: 0,
    status4: 0,
    status5: 0,
    status99: 0,
    total: 0,
  );
}
