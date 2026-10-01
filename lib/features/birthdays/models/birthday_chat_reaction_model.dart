class BirthdayChatReactionModel {
  final String reaction;
  final int count;
  final bool reactedByCurrentUser;

  BirthdayChatReactionModel({
    required this.reaction,
    required this.count,
    required this.reactedByCurrentUser,
  });

  factory BirthdayChatReactionModel.fromJson(Map<String, dynamic> json) {
    return BirthdayChatReactionModel(
      reaction: json['reaction']?.toString() ?? '',
      count: json['count'] ?? 0,
      reactedByCurrentUser:
          json['reactedByCurrentUser'] ??
          json['reacted'] ??
          false,
    );
  }
}