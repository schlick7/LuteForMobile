class DataTablesResponse<T> {
  final int draw;
  final int recordsTotal;
  final int recordsFiltered;
  final List<T> data;

  DataTablesResponse({
    required this.draw,
    required this.recordsTotal,
    required this.recordsFiltered,
    required this.data,
  });

  factory DataTablesResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return DataTablesResponse(
      draw: json['draw'] as int? ?? 1,
      recordsTotal: json['recordsTotal'] as int,
      recordsFiltered: json['recordsFiltered'] as int,
      data: (json['data'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
