import 'birthday_chat_reaction_model.dart';

class BirthdayChatMessageModel {
  final int? id;
  final int? studentId;
  final int? senderId;
  final String? senderName;
  final String? message;
  final bool edited;
  final bool deleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? replyToMessageId;
  final String? replyToMessage;
  final List<BirthdayChatReactionModel> reactions;

  BirthdayChatMessageModel({
    this.id,
    this.studentId,
    this.senderId,
    this.senderName,
    this.message,
    this.edited = false,
    this.deleted = false,
    this.createdAt,
    this.updatedAt,
    this.replyToMessageId,
    this.replyToMessage,
    this.reactions = const [],
  });

  factory BirthdayChatMessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsJson = json['reactions'];

    return BirthdayChatMessageModel(
      id: json['id'],
      studentId: json['studentId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
      edited: json['edited'] ?? false,
      deleted: json['deleted'] ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      replyToMessageId: json['replyToMessageId'],
      replyToMessage: json['replyToMessage'],
      reactions: reactionsJson is List
          ? reactionsJson
              .map(
                (item) => BirthdayChatReactionModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : [],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  BirthdayChatMessageModel copyWith({
    int? id,
    int? studentId,
    int? senderId,
    String? senderName,
    String? message,
    bool? edited,
    bool? deleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? replyToMessageId,
    String? replyToMessage,
    List<BirthdayChatReactionModel>? reactions,
  }) {
    return BirthdayChatMessageModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      edited: edited ?? this.edited,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      reactions: reactions ?? this.reactions,
    );
  }
}