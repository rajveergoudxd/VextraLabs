import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/screens/chats/chat_detail_screen.dart';
import 'package:acms_app/providers/chat_provider.dart';
import 'package:acms_app/providers/auth_provider.dart';

// Mocks
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  User? get user => User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    fullName: 'Test User',
    isActive: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockChatProvider extends ChangeNotifier implements ChatProvider {
  @override
  int? currentConversationId;
  bool isEntering = false;

  // Data
  @override
  List<ChatMessage> get messages => _messages;
  List<ChatMessage> _messages = [];

  @override
  Map<int, bool> get typingUsers => {};

  @override
  Set<int> get onlineUsers => {};

  @override
  List<Conversation> get conversations => [
    Conversation(
      id: 123,
      participants: [
        ConversationParticipant(id: 1, username: 'testuser'),
        ConversationParticipant(
          id: 2,
          username: 'otheruser',
          fullName: 'Other User',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      unreadCount: 0,
    ),
  ];

  // States
  @override
  bool get isLoadingMessages => false;

  @override
  String? get messagesError => null;

  @override
  ChatMessage? get replyingTo => _replyingTo;
  ChatMessage? _replyingTo;

  @override
  bool get isSending => false;

  // Methods
  @override
  Future<void> enterChat(int conversationId) async {
    currentConversationId = conversationId;
    isEntering = true;
    notifyListeners();
  }

  @override
  Future<void> leaveChat() async {
    currentConversationId = null;
    isEntering = false;
    notifyListeners();
  }

  @override
  void setReplyingTo(ChatMessage? message) {
    _replyingTo = message;
    notifyListeners();
  }

  @override
  void clearReply() {
    _replyingTo = null;
    notifyListeners();
  }

  @override
  void sendTyping(bool isTyping) {}

  @override
  Future<bool> sendMessage(String text) async {
    _messages.add(
      ChatMessage(
        id: _messages.length + 1,
        conversationId: 123,
        senderId: 1,
        content: text,
        messageType: 'text',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    return true;
  }

  @override
  Future<bool> sendReply(String content) async {
    _messages.add(
      ChatMessage(
        id: _messages.length + 1,
        conversationId: 123,
        senderId: 1,
        content: content,
        messageType: 'text',
        createdAt: DateTime.now(),
        replyTo: ReplyPreview(
          id: _replyingTo!.id,
          messageType: _replyingTo!.messageType,
          content: _replyingTo!.content,
          senderId: _replyingTo!.senderId,
          senderName: _replyingTo!.senderFullName,
        ),
        replyToId: _replyingTo!.id,
      ),
    );
    _replyingTo = null;
    notifyListeners();
    return true;
  }

  @override
  Future<void> markMessagesAsRead(List<int> ids) async {
    for (var msg in _messages) {
      if (ids.contains(msg.id)) {
        msg.isRead = true;
      }
    }
    notifyListeners();
  }

  @override
  Future<bool> editMessage(int messageId, String newContent) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    msg.content = newContent;
    msg.editedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  @override
  Future<bool> toggleReaction(int messageId, String emoji) async {
    final msg = _messages.firstWhere((m) => m.id == messageId);
    msg.reactions.add(MessageReaction(emoji: emoji, count: 1, userIds: [1]));
    notifyListeners();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  // Setup helper
  void setMessages(List<ChatMessage> msgs) {
    _messages = msgs;
    notifyListeners();
  }
}

void main() {
  late MockChatProvider mockChatProvider;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockChatProvider = MockChatProvider();
    mockAuthProvider = MockAuthProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>.value(value: mockChatProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: const MaterialApp(home: ChatDetailScreen(conversationId: 123)),
    );
  }

  testWidgets('Renders chat screen with messages', (WidgetTester tester) async {
    mockChatProvider.setMessages([
      ChatMessage(
        id: 1,
        conversationId: 123,
        senderId: 2, // Other user
        content: 'Hello there',
        messageType: 'text',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      ChatMessage(
        id: 2,
        conversationId: 123,
        senderId: 1, // Me
        content: 'Hi back',
        messageType: 'text',
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Other User'), findsOneWidget); // Header
    expect(find.text('Hello there'), findsOneWidget);
    expect(find.text('Hi back'), findsOneWidget);
  });

  testWidgets('Swipe to reply shows reply bar', (WidgetTester tester) async {
    final message = ChatMessage(
      id: 1,
      conversationId: 123,
      senderId: 2,
      senderFullName: 'Other User',
      content: 'Swipe me',
      messageType: 'text',
      createdAt: DateTime.now(),
    );
    mockChatProvider.setMessages([message]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find the message bubble
    final messageFinder = find.text('Swipe me');

    // Swipe it
    await tester.drag(messageFinder, const Offset(500, 0));
    await tester.pumpAndSettle();

    // Verify setReplyingTo was called (by checking render of reply bar)
    expect(find.text('Replying to Other User'), findsOneWidget);
    expect(find.text('Swipe me'), findsNWidgets(2));

    // Close reply bar
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Replying to Other User'), findsNothing);
  });

  testWidgets('Long press shows options menu', (WidgetTester tester) async {
    mockChatProvider.setMessages([
      ChatMessage(
        id: 1,
        conversationId: 123,
        senderId: 1, // Me
        content: 'Long press me',
        messageType: 'text',
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Long press me'));
    await tester.pumpAndSettle();

    // Verify menu items
    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget); // Should show for me
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('❤️'), findsOneWidget); // Reaction emoji
  });

  testWidgets('Edit flow works', (WidgetTester tester) async {
    mockChatProvider.setMessages([
      ChatMessage(
        id: 1,
        conversationId: 123,
        senderId: 1, // Me
        content: 'Original text',
        messageType: 'text',
        createdAt: DateTime.now(),
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Open menu
    await tester.longPress(find.text('Original text'));
    await tester.pumpAndSettle();

    // Tap edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Dialog should show
    expect(find.text('Edit Message'), findsOneWidget);

    // Enter new text
    await tester.enterText(
      find.widgetWithText(TextField, 'Original text'),
      'Edited text',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify message updated in provider (mock updates it immediately)
    expect(find.text('Edited text'), findsOneWidget);
    expect(find.text('edited'), findsOneWidget); // Indicator
  });
}
