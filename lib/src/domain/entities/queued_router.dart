class QueuedRouter {
  QueuedRouter({
    required this.name,
    this.extra,
    this.pathParams,
    this.queryParams,
  });
  final String name;
  final Object? extra;
  final Map<String, String>? pathParams;
  final Map<String, dynamic>? queryParams;
}
