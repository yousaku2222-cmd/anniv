import 'package:flutter/foundation.dart';

/// A user-defined category events can be filed under and sorted by.
@immutable
class EventGroup {
  const EventGroup({
    required this.id,
    required this.name,
    required this.order,
  });

  final String id;
  final String name;

  /// Position in the group list / filter bar. Lower comes first.
  final int order;

  EventGroup copyWith({String? name, int? order}) => EventGroup(
        id: id,
        name: name ?? this.name,
        order: order ?? this.order,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'order': order};

  factory EventGroup.fromJson(Map<String, dynamic> json) => EventGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        order: (json['order'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      other is EventGroup &&
      other.id == id &&
      other.name == name &&
      other.order == order;

  @override
  int get hashCode => Object.hash(id, name, order);
}
