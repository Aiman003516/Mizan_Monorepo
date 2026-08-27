class CloudPageCursor {
  const CloudPageCursor({required this.updatedAt, required this.id});

  final DateTime updatedAt;
  final String id;

  Map<String, Object?> toRpcParams() => {
    'p_after_updated_at': updatedAt.toUtc().toIso8601String(),
    'p_after_id': id,
  };
}

class CloudPage<T> {
  const CloudPage({
    required this.items,
    required this.pageSize,
    this.nextCursor,
  });

  final List<T> items;
  final int pageSize;
  final CloudPageCursor? nextCursor;

  bool get hasMore => nextCursor != null;
}

abstract final class CloudPageLimits {
  static const defaultSize = 50;
  static const maxSize = 100;

  static int validate(int value) {
    if (value < 1 || value > maxSize) {
      throw ArgumentError.value(
        value,
        'pageSize',
        'Page size must be between 1 and $maxSize',
      );
    }
    return value;
  }
}
