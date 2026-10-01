import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/birthday_chat_message_model.dart';
import '../models/student_birthday_model.dart';
import '../services/birthday_chat_service.dart';

class BirthdayChatScreen extends StatefulWidget {
  final StudentBirthdayModel student;

  const BirthdayChatScreen({
    super.key,
    required this.student,
  });

  @override
  State<BirthdayChatScreen> createState() => _BirthdayChatScreenState();
}

class _BirthdayChatScreenState extends State<BirthdayChatScreen> {
  final BirthdayChatService _service = BirthdayChatService();

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  List<BirthdayChatMessageModel> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingUser = true;

  int? _currentUserId;

  BirthdayChatMessageModel? _replyingTo;
  BirthdayChatMessageModel? _editingMessage;

  static const List<String> _availableReactions = [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '👏',
    '🎉',
    '🎂',
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    await _loadCurrentUserId();
    await _loadMessages();
  }

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      int? userId;

      if (token != null && token.isNotEmpty) {
        userId = _extractUserIdFromJwt(token);
      }

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentUserId = null;
        _isLoadingUser = false;
      });
    }
  }

  int? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return null;
      }

      final normalized = base64Url.normalize(parts[1]);

      final payload = utf8.decode(
        base64Url.decode(normalized),
      );

      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;

      final possibleKeys = [
        'userId',
        'user_id',
        'id',
        'uid',
        'user',
      ];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value is int) {
          return value;
        }

        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) {
            return parsed;
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // CHECK OWN MESSAGE
  // ============================================================

  bool _isMyMessage(BirthdayChatMessageModel message) {
    if (_currentUserId == null || message.senderId == null) {
      return false;
    }

    return message.senderId == _currentUserId;
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages({
    bool showLoader = true,
  }) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final studentId = widget.student.studentId;

      if (studentId == null) {
        throw Exception('Student ID not found.');
      }

      final messages = await _service.getMessages(studentId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // SEND / UPDATE MESSAGE
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    final studentId = widget.student.studentId;

    if (studentId == null) {
      _showSnackBar(
        'Student ID not found.',
        isError: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      // --------------------------------------------------------
      // EDIT EXISTING MESSAGE
      // --------------------------------------------------------

      if (_editingMessage != null) {
        final messageId = _editingMessage!.id;

        if (messageId == null) {
          throw Exception('Message ID not found.');
        }

        final updatedMessage = await _service.editMessage(
          messageId: messageId,
          message: text,
        );

        if (!mounted) return;

        final index = _messages.indexWhere(
          (message) => message.id == messageId,
        );

        setState(() {
          if (index != -1) {
            _messages[index] = updatedMessage;
          }

          _editingMessage = null;
          _messageController.clear();
          _isSending = false;
        });

        _showSnackBar(
          'Message updated',
        );

        return;
      }

      // --------------------------------------------------------
      // NEW MESSAGE / REPLY
      // --------------------------------------------------------

      final replyMessageId = _replyingTo?.id;

      final newMessage = await _service.sendMessage(
        studentId: studentId,
        message: text,
        replyToMessageId: replyMessageId,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(newMessage);
        _replyingTo = null;
        _messageController.clear();
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // DELETE MESSAGE
  // ============================================================

  Future<void> _deleteMessage(
    BirthdayChatMessageModel message,
  ) async {
    final messageId = message.id;

    if (messageId == null) {
      return;
    }

    if (!_isMyMessage(message)) {
      _showSnackBar(
        'You can delete only your own message.',
        isError: true,
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete message?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'This message will be removed from the chat.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _service.deleteMessage(messageId);

      if (!mounted) return;

      final index = _messages.indexWhere(
        (item) => item.id == messageId,
      );

      if (index != -1) {
        setState(() {
          _messages[index] = message.copyWith(
            deleted: true,
            message: 'This message was deleted',
          );
        });
      }

      _showSnackBar('Message deleted');
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // REPLY
  // ============================================================

  void _startReply(
    BirthdayChatMessageModel message,
  ) {
    if (message.deleted) {
      return;
    }

    setState(() {
      _replyingTo = message;
      _editingMessage = null;
      _messageController.clear();
    });

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!mounted) return;

        _messageFocusNode.requestFocus();
      },
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });

    _messageController.clear();
  }

  // ============================================================
  // EDIT
  // ============================================================

  void _startEdit(
    BirthdayChatMessageModel message,
  ) {
    if (message.deleted) {
      return;
    }

    if (!_isMyMessage(message)) {
      _showSnackBar(
        'You can edit only your own message.',
        isError: true,
      );
      return;
    }

    final text = message.message?.trim() ?? '';

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _editingMessage = message;
      _replyingTo = null;
      _messageController.text = text;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(
          offset: _messageController.text.length,
        ),
      );
    });

    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (!mounted) return;

        _messageFocusNode.requestFocus();
      },
    );
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });

    FocusScope.of(context).unfocus();
  }

  // ============================================================
  // REACTION
  // ============================================================

  Future<void> _toggleReaction({
    required BirthdayChatMessageModel message,
    required String reaction,
  }) async {
    final messageId = message.id;

    if (messageId == null || message.deleted) {
      return;
    }

    try {
      final existingReaction = message.reactions.where(
        (item) => item.reaction == reaction,
      );

      final alreadyReacted = existingReaction.isNotEmpty &&
          existingReaction.first.reactedByCurrentUser;

      if (alreadyReacted) {
        await _service.removeReaction(
          messageId: messageId,
          reaction: reaction,
        );
      } else {
        await _service.addReaction(
          messageId: messageId,
          reaction: reaction,
        );
      }

      if (!mounted) return;

      // Reload only the messages so that reaction counts and
      // reactedByCurrentUser stay in sync with backend.
      final studentId = widget.student.studentId;

      if (studentId == null) {
        return;
      }

      final refreshedMessages = await _service.getMessages(
        studentId,
      );

      if (!mounted) return;

      setState(() {
        _messages = refreshedMessages;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        _cleanError(e),
        isError: true,
      );
    }
  }

  // ============================================================
  // REACTION PICKER
  // ============================================================

  Future<void> _showReactionPicker(
    BirthdayChatMessageModel message,
  ) async {
    if (message.deleted) {
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DCE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'React to this message',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF202531),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableReactions.map(
                    (reaction) {
                      final existing = message.reactions.where(
                        (item) => item.reaction == reaction,
                      );

                      final selected = existing.isNotEmpty &&
                          existing.first.reactedByCurrentUser;

                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          Navigator.pop(context);

                          await _toggleReaction(
                            message: message,
                            reaction: reaction,
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 180,
                          ),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEDE9FE)
                                : const Color(0xFFF5F7FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF7C3AED)
                                  : const Color(0xFFE4E7EC),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              reaction,
                              style: const TextStyle(
                                fontSize: 25,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // MESSAGE OPTIONS
  // ============================================================

  Future<void> _showMessageOptions(
    BirthdayChatMessageModel message,
  ) async {
    if (message.deleted) {
      return;
    }

    final isMine = _isMyMessage(message);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              18,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(26),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DCE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),

                // Message preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.message ?? '',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF353B48),
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                _messageOption(
                  icon: Icons.reply_rounded,
                  title: 'Reply',
                  onTap: () {
                    Navigator.pop(context);
                    _startReply(message);
                  },
                ),

                _messageOption(
                  icon: Icons.emoji_emotions_outlined,
                  title: 'React',
                  onTap: () {
                    Navigator.pop(context);

                    Future.delayed(
                      const Duration(milliseconds: 120),
                      () {
                        if (mounted) {
                          _showReactionPicker(message);
                        }
                      },
                    );
                  },
                ),

                _messageOption(
                  icon: Icons.copy_outlined,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),

                if (isMine) ...[
                  _messageOption(
                    icon: Icons.edit_outlined,
                    title: 'Edit',
                    onTap: () {
                      Navigator.pop(context);
                      _startEdit(message);
                    },
                  ),

                  _messageOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete',
                    destructive: true,
                    onTap: () {
                      Navigator.pop(context);

                      Future.delayed(
                        const Duration(milliseconds: 120),
                        () {
                          if (mounted) {
                            _deleteMessage(message);
                          }
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _messageOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0xFFFFF1F1)
              : const Color(0xFFF3F5F9),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          size: 21,
          color: destructive
              ? const Color(0xFFE53935)
              : const Color(0xFF4B5563),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: destructive
              ? const Color(0xFFE53935)
              : const Color(0xFF252B36),
        ),
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> _copyMessage(
    BirthdayChatMessageModel message,
  ) async {
    final text = message.message?.trim();

    if (text == null || text.isEmpty) {
      return;
    }

    await Clipboard.setData(
      ClipboardData(text: text),
    );

    if (!mounted) return;

    _showSnackBar('Message copied');
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final studentName =
        widget.student.studentName ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: _buildAppBar(studentName),
      body: Column(
        children: [
          Expanded(
            child: _buildChatBody(),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    String studentName,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Color(0xFF252A34),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildHeaderAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF202531),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Birthday Chat',
                  style: TextStyle(
                    color: Color(0xFF8A92A0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () {
            _loadMessages();
          },
          icon: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF555D6D),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildHeaderAvatar() {
    final photoUrl = widget.student.photoUrl;

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: 21,
        backgroundColor: const Color(0xFFFFE4EC),
        backgroundImage: NetworkImage(
          photoUrl,
        ),
      );
    }

    return CircleAvatar(
      radius: 21,
      backgroundColor: const Color(0xFFFFE4EC),
      child: const Icon(
        Icons.cake_rounded,
        color: Color(0xFFE85D8A),
        size: 22,
      ),
    );
  }

  Widget _buildChatBody() {
    if (_isLoading || _isLoadingUser) {
      return _buildLoadingState();
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadMessages(
        showLoader: false,
      ),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          20,
          18,
          20,
        ),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];

          final showDate = index == 0 ||
              !_isSameDay(
                message.createdAt,
                _messages[index - 1].createdAt,
              );

          return Column(
            children: [
              if (showDate) _buildDateDivider(message),
              _buildMessageBubble(message),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(
    BirthdayChatMessageModel message,
  ) {
    final isMine = _isMyMessage(message);
    final isDeleted = message.deleted;

    return GestureDetector(
      onLongPress: () {
        _showMessageOptions(message);
      },
      onDoubleTap: () {
        if (!isDeleted) {
          _showReactionPicker(message);
        }
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        child: Row(
          mainAxisAlignment: isMine
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              _buildSenderAvatar(message),
              const SizedBox(width: 8),
            ],

            Flexible(
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMine &&
                      message.senderName != null &&
                      message.senderName!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: 4,
                      ),
                      child: Text(
                        message.senderName!,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 650,
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      11,
                      14,
                      9,
                    ),
                    decoration: BoxDecoration(
                      color: isDeleted
                          ? const Color(0xFFF0F1F3)
                          : isMine
                              ? const Color(0xFF5B5FEF)
                              : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(
                          isMine ? 18 : 5,
                        ),
                        bottomRight: Radius.circular(
                          isMine ? 5 : 18,
                        ),
                      ),
                      border: !isMine && !isDeleted
                          ? Border.all(
                              color: const Color(0xFFE7E9EE),
                            )
                          : null,
                      boxShadow: !isDeleted
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  isMine ? 0.05 : 0.035,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToMessage != null &&
                            message.replyToMessage!.trim().isNotEmpty)
                          _buildReplyPreview(
                            message,
                            isMine,
                          ),

                        Text(
                          isDeleted
                              ? 'This message was deleted'
                              : (message.message ?? ''),
                          style: TextStyle(
                            color: isDeleted
                                ? const Color(0xFF8B909A)
                                : isMine
                                    ? Colors.white
                                    : const Color(0xFF252A34),
                            fontSize: 14.5,
                            height: 1.4,
                            fontStyle: isDeleted
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (message.edited && !isDeleted)
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: 6,
                                ),
                                child: Text(
                                  'edited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine
                                        ? Colors.white.withOpacity(
                                            0.70,
                                          )
                                        : const Color(0xFF9298A3),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),

                            Text(
                              _formatTime(
                                message.createdAt,
                              ),
                              style: TextStyle(
                                color: isMine
                                    ? Colors.white.withOpacity(
                                        0.70,
                                      )
                                    : const Color(0xFF9298A3),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (message.reactions.isNotEmpty &&
                      !message.deleted)
                    _buildReactions(
                      message,
                      isMine,
                    ),
                ],
              ),
            ),

            if (isMine) ...[
              const SizedBox(width: 8),
              _buildSenderAvatar(message),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSenderAvatar(
    BirthdayChatMessageModel message,
  ) {
    final name = message.senderName ?? 'User';

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE9EAFD),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: Color(0xFF5B5FEF),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REPLY PREVIEW INSIDE MESSAGE
  // ============================================================

  Widget _buildReplyPreview(
    BirthdayChatMessageModel message,
    bool isMine,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      padding: const EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? Colors.white.withOpacity(0.13)
            : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(9),
        border: Border(
          left: BorderSide(
            color: isMine
                ? Colors.white.withOpacity(0.75)
                : const Color(0xFF6366F1),
            width: 3,
          ),
        ),
      ),
      child: Text(
        message.replyToMessage!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isMine
              ? Colors.white.withOpacity(0.82)
              : const Color(0xFF667085),
          fontSize: 11.5,
          height: 1.35,
        ),
      ),
    );
  }

  // ============================================================
  // REACTIONS
  // ============================================================

  Widget _buildReactions(
    BirthdayChatMessageModel message,
    bool isMine,
  ) {
    return Transform.translate(
      offset: Offset(
        isMine ? -8 : 8,
        -6,
      ),
      child: Wrap(
        spacing: 4,
        children: message.reactions.map(
          (reaction) {
            final selected =
                reaction.reactedByCurrentUser;

            return GestureDetector(
              onTap: () {
                _toggleReaction(
                  message: message,
                  reaction: reaction.reaction,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFEDE9FE)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFFE2E5EB),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        0.04,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      reaction.reaction,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    if (reaction.count > 0) ...[
                      const SizedBox(width: 3),
                      Text(
                        reaction.count.toString(),
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF6D28D9)
                              : const Color(0xFF69707D),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _buildComposer() {
    final isEditing = _editingMessage != null;
    final isReplying = _replyingTo != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE8EAF0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isReplying)
              _buildReplyComposerPreview(),

            if (isEditing)
              _buildEditComposerPreview(),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: 48,
                      maxHeight: 130,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6F9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE5E7EC),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      textCapitalization:
                          TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: isEditing
                            ? 'Edit your message...'
                            : isReplying
                                ? 'Write a reply...'
                                : 'Write a birthday wish...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AA1AD),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                GestureDetector(
                  onTap: _isSending
                      ? null
                      : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isSending
                          ? const Color(0xFFB8BBDB)
                          : const Color(0xFF5B5FEF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5B5FEF,
                          ).withOpacity(0.22),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              isEditing
                                  ? Icons.check_rounded
                                  : Icons.send_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyComposerPreview() {
    final message = _replyingTo;

    if (message == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        9,
        8,
        9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(13),
        border: const Border(
          left: BorderSide(
            color: Color(0xFF7C3AED),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.reply_rounded,
            size: 17,
            color: Color(0xFF7C3AED),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.senderName ?? 'User'}',
                  style: const TextStyle(
                    color: Color(0xFF6D28D9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel reply',
            onPressed: _cancelReply,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditComposerPreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        9,
        8,
        9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFF59E0B),
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_outlined,
            size: 17,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Editing message',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Update your message and tap ✓',
                  style: TextStyle(
                    color: Color(0xFF78716C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cancel edit',
            onPressed: _cancelEdit,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: Color(0xFF78716C),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE DIVIDER
  // ============================================================

  Widget _buildDateDivider(
    BirthdayChatMessageModel message,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
        top: 2,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: Color(0xFFE3E6EC),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatDate(message.createdAt),
                style: const TextStyle(
                  color: Color(0xFF7A8190),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              color: Color(0xFFE3E6EC),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF5B5FEF),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9F0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cake_rounded,
                size: 38,
                color: Color(0xFFE85D8A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No birthday wishes yet',
              style: TextStyle(
                color: Color(0xFF252A34),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first person to wish ${widget.student.studentName ?? 'this student'} a happy birthday.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF858C99),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();

    final hour = local.hour == 0
        ? 12
        : local.hour > 12
            ? local.hour - 12
            : local.hour;

    final minute = local.minute
        .toString()
        .padLeft(2, '0');

    final period = local.hour >= 12
        ? 'PM'
        : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();

    if (_isSameDay(local, now)) {
      return 'Today';
    }

    final yesterday = now.subtract(
      const Duration(days: 1),
    );

    if (_isSameDay(local, yesterday)) {
      return 'Yesterday';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  bool _isSameDay(
    DateTime? first,
    DateTime? second,
  ) {
    if (first == null || second == null) {
      return false;
    }

    final a = first.toLocal();
    final b = second.toLocal();

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _initials(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'U';
    }

    final parts = trimmed.split(
      RegExp(r'\s+'),
    );

    if (parts.length == 1) {
      return parts.first.substring(
        0,
        1,
      ).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(
        'Exception: '.length,
      );
    }

    return text;
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? const Color(0xFFD32F2F)
              : const Color(0xFF252A34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
        ),
      );
  }
}