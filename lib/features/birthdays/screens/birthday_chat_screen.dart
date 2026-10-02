import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/birthday_chat_message_model.dart';
import '../models/student_birthday_model.dart';
import '../services/birthday_chat_service.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:characters/characters.dart';

class BirthdayChatScreen extends StatefulWidget {
  final StudentBirthdayModel student;

  const BirthdayChatScreen({super.key, required this.student});

  @override
  State<BirthdayChatScreen> createState() => _BirthdayChatScreenState();
}

class _BirthdayChatScreenState extends State<BirthdayChatScreen>
    with WidgetsBindingObserver {
  final BirthdayChatService _service = BirthdayChatService();

  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final FocusNode _messageFocusNode = FocusNode();

  final List<String> _availableReactions = const [
    '❤️',
    '👍',
    '😂',
    '😮',
    '😢',
    '👏',
    '🎉',
    '🎂',
  ];

  List<BirthdayChatMessageModel> _messages = [];

  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingUser = true;
  bool _showEmojiPicker = false;

  int? _currentUserId;

  BirthdayChatMessageModel? _replyingTo;
  BirthdayChatMessageModel? _editingMessage;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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
  // CURRENT USER
  // ============================================================

  Future<void> _loadCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        setState(() {
          _isLoadingUser = false;
        });

        return;
      }

      final userId = _extractUserIdFromJwt(token);

      if (!mounted) return;

      setState(() {
        _currentUserId = userId;
        _isLoadingUser = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
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

      final payload = utf8.decode(base64Url.decode(normalized));

      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;

      const possibleKeys = ['userId', 'user_id', 'id', 'uid', 'user', 'sub'];

      for (final key in possibleKeys) {
        final value = data[key];

        if (value is int) {
          return value;
        }

        if (value is num) {
          return value.toInt();
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

  bool _isMyMessage(BirthdayChatMessageModel message) {
    return _currentUserId != null &&
        message.senderId != null &&
        message.senderId == _currentUserId;
  }

  // ============================================================
  // LOAD MESSAGES
  // ============================================================

  Future<void> _loadMessages({bool showLoader = true}) async {
    final studentId = widget.student.studentId;

    if (studentId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Student information is missing.';
      });

      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final messages = await _service.getMessages(studentId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
        _isLoading = false;
        _errorMessage = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(e);
      });
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();

    if (text.startsWith('Exception: ')) {
      return text.substring(11);
    }

    return text;
  }

  // ============================================================
  // SEND / EDIT
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    final studentId = widget.student.studentId;

    if (studentId == null) {
      _showSnackBar('Student information is missing.', isError: true);
      return;
    }

    final editing = _editingMessage;

    setState(() {
      _isSending = true;
    });

    try {
      if (editing != null) {
        final updated = await _service.editMessage(
          messageId: editing.id!,
          message: text,
        );

        if (!mounted) return;

        final index = _messages.indexWhere((item) => item.id == editing.id);

        setState(() {
          if (index != -1) {
            _messages[index] = updated;
          }

          _editingMessage = null;
          _messageController.clear();
          _isSending = false;
        });

        _showSnackBar('Message updated');
      } else {
        final replyId = _replyingTo?.id;

        final newMessage = await _service.sendMessage(
          studentId: studentId,
          message: text,
          replyToMessageId: replyId,
        );

        if (!mounted) return;

        setState(() {
          _messages.add(newMessage);

          _replyingTo = null;
          _messageController.clear();
          _isSending = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      _messageFocusNode.requestFocus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });

      _showSnackBar(_cleanError(e), isError: true);
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteMessage(BirthdayChatMessageModel message) async {
    if (message.id == null || !_isMyMessage(message)) {
      return;
    }

    final confirmed = await _showDeleteConfirmation();

    if (!confirmed) {
      return;
    }

    try {
      await _service.deleteMessage(message.id!);

      if (!mounted) return;

      final index = _messages.indexWhere((item) => item.id == message.id);

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

      _showSnackBar(_cleanError(e), isError: true);
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),

                const SizedBox(height: 20),

                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE53935),
                    size: 28,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Delete message?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171A21),
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'This message will be marked as deleted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF7A8190)),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        style: _outlineButtonStyle(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // REPLY
  // ============================================================

  void _startReply(BirthdayChatMessageModel message) {
    if (message.deleted) {
      return;
    }

    setState(() {
      _editingMessage = null;
      _replyingTo = message;
    });

    _messageFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  // ============================================================
  // EDIT
  // ============================================================

  void _startEdit(BirthdayChatMessageModel message) {
    if (message.deleted || !_isMyMessage(message)) {
      return;
    }

    setState(() {
      _replyingTo = null;
      _editingMessage = message;

      _messageController.text = message.message ?? '';

      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    });

    _messageFocusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
    });
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });

      FocusScope.of(context).requestFocus(_messageFocusNode);
    } else {
      FocusScope.of(context).unfocus();

      setState(() {
        _showEmojiPicker = true;
      });
    }
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> _copyMessage(BirthdayChatMessageModel message) async {
    if (message.deleted ||
        message.message == null ||
        message.message!.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: message.message!));

    if (!mounted) return;

    _showSnackBar('Message copied');
  }

  // ============================================================
  // REACTION
  // ============================================================

  Future<void> _toggleReaction({
    required BirthdayChatMessageModel message,
    required String reaction,
  }) async {
    if (message.id == null || message.deleted) {
      return;
    }

    try {
      final existing = message.reactions.where(
        (item) => item.reaction == reaction,
      );

      final alreadyReacted =
          existing.isNotEmpty && existing.first.reactedByCurrentUser;

      if (alreadyReacted) {
        await _service.removeReaction(
          messageId: message.id!,
          reaction: reaction,
        );
      } else {
        await _service.addReaction(messageId: message.id!, reaction: reaction);
      }

      await _refreshMessagesSilently();
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(_cleanError(e), isError: true);
    }
  }

  Future<void> _refreshMessagesSilently() async {
    final studentId = widget.student.studentId;

    if (studentId == null) {
      return;
    }

    try {
      final messages = await _service.getMessages(studentId);

      if (!mounted) return;

      setState(() {
        _messages = messages;
      });
    } catch (_) {}
  }

  // ============================================================
  // REACTION PICKER
  // ============================================================

  Future<void> _showReactionPicker(BirthdayChatMessageModel message) async {
    if (message.deleted || message.id == null) {
      return;
    }

    final myReactions = message.reactions
        .where((item) => item.reactedByCurrentUser)
        .toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),

                const SizedBox(height: 18),

                const Text(
                  'React to this message',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171A21),
                  ),
                ),

                const SizedBox(height: 18),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableReactions.map((reaction) {
                    final existing = message.reactions.where(
                      (item) => item.reaction == reaction,
                    );

                    final selected =
                        existing.isNotEmpty &&
                        existing.first.reactedByCurrentUser;

                    return InkWell(
                      borderRadius: BorderRadius.circular(17),
                      onTap: () async {
                        Navigator.pop(context);

                        await _toggleReaction(
                          message: message,
                          reaction: reaction,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFEDE9FE)
                              : const Color(0xFFF6F7FA),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFFE4E7EC),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            reaction,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (myReactions.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);

                        for (final reaction in myReactions) {
                          await _service.removeReaction(
                            messageId: message.id!,
                            reaction: reaction.reaction,
                          );
                        }

                        await _refreshMessagesSilently();
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                      label: const Text('Remove my reaction'),
                      style: _outlineButtonStyle(),
                    ),
                  ),
                ],
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

  Future<void> _showMessageOptions(BirthdayChatMessageModel message) async {
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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sheetHandle(),

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

                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (mounted) {
                        _showReactionPicker(message);
                      }
                    });
                  },
                ),

                _messageOption(
                  icon: Icons.copy_rounded,
                  title: 'Copy',
                  onTap: () {
                    Navigator.pop(context);
                    _copyMessage(message);
                  },
                ),

                if (isMine) ...[
                  _messageOption(
                    icon: Icons.edit_rounded,
                    title: 'Edit',
                    onTap: () {
                      Navigator.pop(context);
                      _startEdit(message);
                    },
                  ),

                  _messageOption(
                    icon: Icons.delete_outline_rounded,
                    title: 'Delete',
                    danger: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deleteMessage(message);
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
    bool danger = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: danger ? const Color(0xFFFFF1F1) : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: danger ? const Color(0xFFE53935) : const Color(0xFF424956),
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: danger ? const Color(0xFFE53935) : const Color(0xFF20242C),
        ),
      ),
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position.maxScrollExtent;

    if (animated) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(position);
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: isError
              ? const Color(0xFF32343A)
              : const Color(0xFF20242C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildChatBody()),
          _buildComposer(),
        ],
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    final name = widget.student.studentName?.trim().isNotEmpty == true
        ? widget.student.studentName!.trim()
        : 'Birthday Student';

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
        color: const Color(0xFF242832),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _buildStudentAvatar(size: 42),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF191C23),
                  ),
                ),

                const SizedBox(height: 2),

                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Birthday Chat',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF7C8492),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: _isLoading ? null : () => _loadMessages(),
          icon: const Icon(Icons.refresh_rounded, size: 22),
          color: const Color(0xFF454B57),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildStudentAvatar({double size = 48}) {
    final photoUrl = widget.student.photoUrl;

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE6E8EF)),
        ),
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _avatarFallback(size);
            },
          ),
        ),
      );
    }

    return _avatarFallback(size);
  }

  Widget _avatarFallback(double size) {
    final name = widget.student.studentName ?? 'S';

    final letter = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'S';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * .38,
        ),
      ),
    );
  }

  // ============================================================
  // CHAT BODY
  // ============================================================

  Widget _buildChatBody() {
    if (_isLoading || _isLoadingUser) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_messages.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFF5B5FEF),
      onRefresh: () => _loadMessages(showLoader: false),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];

          final showDate =
              index == 0 ||
              !_isSameDay(_messages[index - 1].createdAt, message.createdAt);

          return Column(
            children: [
              if (showDate) _buildDateSeparator(message.createdAt),

              _buildMessageRow(message),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 24),
      itemCount: 7,
      itemBuilder: (_, index) {
        final isRight = index % 2 == 1;

        return Align(
          alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            width: 150 + (index % 3) * 45,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFE53935),
                size: 32,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20242C),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              _errorMessage ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7B8290)),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () => _loadMessages(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B5FEF),
                foregroundColor: Colors.white,
                elevation: 0,
                minimumSize: const Size(135, 46),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    final name = widget.student.studentName ?? 'student';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF1F8), Color(0xFFF1EDFF)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text('🎂', style: TextStyle(fontSize: 42)),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Start the birthday wishes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20242C),
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'Be the first one to wish $name a happy birthday.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF7A8190),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8EAF0)),
              ),
              child: const Text(
                '🎉  Make it special!',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF555B68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE ROW
  // ============================================================

  Widget _buildMessageRow(BirthdayChatMessageModel message) {
    final isMine = _isMyMessage(message);

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildSmallAvatar(message),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () {
                _showMessageOptions(message);
              },
              onDoubleTap: () {
                if (!message.deleted) {
                  _showReactionPicker(message);
                }
              },
              child: _buildMessageBubble(message, isMine),
            ),
          ),

          if (isMine) ...[const SizedBox(width: 8), _buildMyMessageIndicator()],
        ],
      ),
    );
  }

  Widget _buildSmallAvatar(BirthdayChatMessageModel message) {
    final senderName = message.senderName?.trim();

    final letter = senderName != null && senderName.isNotEmpty
        ? senderName[0].toUpperCase()
        : '?';

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEDEBFF),
        border: Border.all(color: const Color(0xFFE2E3EE)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF5B5FEF),
        ),
      ),
    );
  }

  Widget _buildMyMessageIndicator() {
    return const SizedBox(width: 4, height: 4);
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(BirthdayChatMessageModel message, bool isMine) {
    final deleted = message.deleted;

    final bubbleColor = isMine ? const Color(0xFF5B5FEF) : Colors.white;

    final textColor = isMine ? Colors.white : const Color(0xFF272B34);

    return Column(
      crossAxisAlignment: isMine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (!isMine && !deleted)
          Padding(
            padding: const EdgeInsets.only(left: 5, bottom: 4),
            child: Text(
              message.senderName ?? 'User',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF626A78),
              ),
            ),
          ),

        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .78,
          ),
          padding: const EdgeInsets.fromLTRB(13, 10, 11, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(19),
              topRight: const Radius.circular(19),
              bottomLeft: Radius.circular(isMine ? 19 : 5),
              bottomRight: Radius.circular(isMine ? 5 : 19),
            ),
            border: !isMine ? Border.all(color: const Color(0xFFE8EAF0)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isMine ? .08 : .035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.replyToMessageId != null &&
                  message.replyToMessage != null)
                _buildReplyPreview(message, isMine),

              if (message.replyToMessageId != null &&
                  message.replyToMessage != null)
                const SizedBox(height: 7),

              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      message.message ?? '',
                      style: TextStyle(
                        fontSize: 14.2,
                        height: 1.42,
                        fontStyle: deleted
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: deleted
                            ? (isMine
                                  ? Colors.white.withOpacity(.75)
                                  : const Color(0xFF9298A3))
                            : textColor,
                        fontWeight: deleted ? FontWeight.w400 : FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(width: 9),

                  _buildMessageMeta(message, isMine),
                ],
              ),
            ],
          ),
        ),

        if (message.reactions.isNotEmpty) _buildReactionStrip(message, isMine),
      ],
    );
  }

  // ============================================================
  // REPLY PREVIEW
  // ============================================================

  Widget _buildReplyPreview(BirthdayChatMessageModel message, bool isMine) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withOpacity(.13) : const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: 35,
            decoration: BoxDecoration(
              color: isMine ? Colors.white : const Color(0xFF5B5FEF),
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isMine
                        ? Colors.white.withOpacity(.88)
                        : const Color(0xFF5B5FEF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyToMessage ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isMine
                        ? Colors.white.withOpacity(.78)
                        : const Color(0xFF747B88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MESSAGE META
  // ============================================================

  Widget _buildMessageMeta(BirthdayChatMessageModel message, bool isMine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.edited && !message.deleted)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'edited',
              style: TextStyle(
                fontSize: 8.5,
                color: isMine
                    ? Colors.white.withOpacity(.65)
                    : const Color(0xFF999FAC),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 9.5,
            color: isMine
                ? Colors.white.withOpacity(.68)
                : const Color(0xFF9AA0AB),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REACTIONS
  // ============================================================

  Widget _buildReactionStrip(BirthdayChatMessageModel message, bool isMine) {
    return Transform.translate(
      offset: Offset(isMine ? -8 : 8, -3),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            _showReactionPicker(message);
          },
          child: Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E6EC)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: message.reactions.map((reaction) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        reaction.reaction,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (reaction.count > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Text(
                            '${reaction.count}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: reaction.reactedByCurrentUser
                                  ? const Color(0xFF5B5FEF)
                                  : const Color(0xFF777E8A),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE SEPARATOR
  // ============================================================

  Widget _buildDateSeparator(DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EC))),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E8EE)),
            ),
            child: Text(
              _formatDateLabel(date),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C8390),
              ),
            ),
          ),

          const Expanded(child: Divider(color: Color(0xFFE5E7EC))),
        ],
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isEditing || isReplying) _buildComposerPreview(),

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
                      border: Border.all(color: const Color(0xFFE7E9EE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // ==================================================
                        // EMOJI BUTTON
                        // ==================================================
                        IconButton(
                          onPressed: _toggleEmojiPicker,
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 4,
                            top: 8,
                            bottom: 8,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 42,
                            minHeight: 48,
                          ),
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Icon(
                              _showEmojiPicker
                                  ? Icons.keyboard_rounded
                                  : Icons.emoji_emotions_outlined,
                              key: ValueKey(_showEmojiPicker),
                              size: 23,
                              color: const Color(0xFF6D7280),
                            ),
                          ),
                        ),

                        // ==================================================
                        // TEXT FIELD
                        // ==================================================
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _messageFocusNode,
                            minLines: 1,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            textInputAction: TextInputAction.newline,

                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() {
                                  _showEmojiPicker = false;
                                });
                              }
                            },

                            onChanged: (_) {
                              if (mounted) {
                                setState(() {});
                              }
                            },

                            decoration: const InputDecoration(
                              hintText: 'Write a birthday wish...',
                              hintStyle: TextStyle(
                                color: Color(0xFF969DA9),
                                fontSize: 13.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.only(
                                left: 4,
                                right: 12,
                                top: 13,
                                bottom: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                _buildSendButton(),
              ],
            ),

            // ============================================================
            // EMOJI PICKER
            // ============================================================
            if (_showEmojiPicker)
              SizedBox(
                height: 300,
                child: EmojiPicker(
                  onEmojiSelected: (Category? category, Emoji emoji) {
                    final text = _messageController.text;

                    final selection = _messageController.selection;

                    final start = selection.start < 0
                        ? text.length
                        : selection.start;

                    final end = selection.end < 0 ? text.length : selection.end;

                    final newText = text.replaceRange(start, end, emoji.emoji);

                    _messageController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: start + emoji.emoji.length,
                      ),
                    );

                    setState(() {});
                  },

                  onBackspacePressed: () {
                    _deletePreviousCharacter();
                  },

                  config: Config(
                    height: 300,

                    checkPlatformCompatibility: true,

                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28,
                      columns: 8,
                      backgroundColor: const Color(0xFFF8F9FC),
                    ),

                    categoryViewConfig: const CategoryViewConfig(
                      initCategory: Category.SMILEYS,
                      backgroundColor: Colors.white,
                      indicatorColor: Color(0xFF5B5FEF),
                      iconColor: Color(0xFF9AA0AB),
                      iconColorSelected: Color(0xFF5B5FEF),
                    ),

                    bottomActionBarConfig: const BottomActionBarConfig(
                      backgroundColor: Colors.white,
                      buttonColor: Color(0xFFF3F4F7),
                      buttonIconColor: Color(0xFF5B5FEF),
                    ),

                    searchViewConfig: const SearchViewConfig(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _deletePreviousCharacter() {
    final text = _messageController.text;
    final selection = _messageController.selection;

    if (text.isEmpty) {
      return;
    }

    final start = selection.start;
    final end = selection.end;

    if (start < 0) {
      return;
    }

    // Delete selected text
    if (start != end) {
      final newText = text.replaceRange(start, end, '');

      _messageController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start),
      );

      setState(() {});
      return;
    }

    if (start == 0) {
      return;
    }

    final characters = text.characters.toList();

    if (characters.isEmpty) {
      return;
    }

    characters.removeLast();

    final newText = characters.join();

    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );

    setState(() {});
  }

  Widget _buildComposerPreview() {
    final editing = _editingMessage;

    final replying = _replyingTo;

    final isEditing = editing != null;

    final source = isEditing ? editing : replying;

    if (source == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(11, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E8EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 38,
            decoration: BoxDecoration(
              color: isEditing
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF5B5FEF),
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? 'Editing message'
                      : 'Replying to ${source.senderName ?? 'message'}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isEditing
                        ? const Color(0xFFD97706)
                        : const Color(0xFF5B5FEF),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  source.message ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF737A87),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () {
              if (_showEmojiPicker) {
                setState(() {
                  _showEmojiPicker = false;
                });
              }

              if (isEditing) {
                _cancelEdit();
              } else {
                _cancelReply();
              }
            },
            icon: const Icon(Icons.close_rounded, size: 19),
            color: const Color(0xFF7B818C),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final hasText = _messageController.text.trim().isNotEmpty;

    final enabled = hasText && !_isSending;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              )
            : null,
        color: enabled ? null : const Color(0xFFE8EAF0),
        shape: BoxShape.circle,
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: const Color(0xFF5B5FEF).withOpacity(.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: IconButton(
        onPressed: enabled ? _sendMessage : null,
        icon: _isSending
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_upward_rounded, size: 22),
        color: enabled ? Colors.white : const Color(0xFF9AA0AB),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _sheetHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD9DCE3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  ButtonStyle _outlineButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF555B68),
      side: const BorderSide(color: Color(0xFFE0E3E9)),
      minimumSize: const Size(double.infinity, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  bool _isSameDay(DateTime? first, DateTime? second) {
    if (first == null || second == null) {
      return false;
    }

    final a = first.toLocal();
    final b = second.toLocal();

    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) {
      return '';
    }

    final value = date.toLocal();
    final now = DateTime.now();

    if (_isSameDay(value, now)) {
      return 'Today';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (_isSameDay(value, yesterday)) {
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

    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final value = date.toLocal();

    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;

    final minute = value.minute.toString().padLeft(2, '0');

    final period = value.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
