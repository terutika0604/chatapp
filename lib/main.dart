import 'package:flutter/material.dart';

// Firebase系
import 'firebase_options.dart';
// コア プラグイン
import 'package:firebase_core/firebase_core.dart';
// firestore　プラグイン
import 'package:cloud_firestore/cloud_firestore.dart';
// 認証系　プラグイン
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  // Firebase初期化処理
  // 構成ファイルによってエクスポートされた DefaultFirebaseOptions オブジェクトを使用して Firebase を初期化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat App',
      theme: ThemeData(
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,

        // テーマカラー
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

// ログインページ
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

// クラス名の頭に＿を書くと他のクラスからアクセスできないようになる
// LoginPageの処理部分を分けるイメージ
class _LoginPageState extends State<LoginPage> {
  // メッセージ表示用
  String infoText = '';
  // 入力したメールアドレス・パスワード
  String email = '';
  String password = '';
  // String? password = ''; とするとnullを許容する変数になる

  @override
  // Stateが更新されるとBuild関数が再実行される
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // メールアドレス入力
              TextFormField(
                decoration: InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  setState(() {
                    email = value;
                  });
                },
              ),
              // パスワード入力
              TextFormField(
                decoration: InputDecoration(labelText: 'パスワード'),
                obscureText: true,
                onChanged: (String value) {
                  setState(() {
                    password = value;
                  });
                },
              ),
              // メッセージ表示用の箱
              Container(
                padding: EdgeInsets.all(8),
                child: Text(infoText),
              ),
              // ユーザー登録ボタン
              Container(
                width: double.infinity,
                // ユーザー登録ボタンUI
                child: ElevatedButton(
                  child: Text('ユーザー登録'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでユーザー登録
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.createUserWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      // ユーザー登録に成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage(result.user!);
                        }),
                      );
                    } catch (e) {
                      // ユーザー登録に失敗した場合
                      setState(() {
                        infoText = '登録に失敗しました：${e.toString()}';
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              // ログインボタン
              Container(
                width: double.infinity,
                child: OutlinedButton(
                  child: Text('ログイン'),
                  onPressed: () async {
                    try {
                      // メール/パスワードでログイン
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      final result = await auth.signInWithEmailAndPassword(
                        email: email,
                        password: password,
                      );
                      // ログインに成功した場合
                      // チャット画面に遷移＋ログイン画面を破棄
                      await Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) {
                          return ChatPage(result.user!);
                        }),
                      );
                    } catch (e) {
                      // ログインに失敗した場合
                      setState(() {
                        infoText = "ログインに失敗しました：${e.toString()}";
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// チャット一覧ページ
class ChatPage extends StatelessWidget {
  // 引数からユーザー情報を受け取れるようにする(コンストラクタ)
  ChatPage(this.user);
  // ユーザー情報
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () async {
                // ログアウト処理
                // 内部で保持しているログイン情報等が初期化される
                // ログアウト時はこの処理を呼び出せばOKらしい
                await FirebaseAuth.instance.signOut();
                // ログイン画面に遷移＋チャット画面を破棄
                await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      return LoginPage();
                    },
                  ),
                );
              }),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            child: Text('ログイン情報：${user.email}'),
          ),
          Expanded(
            // FutureBuilder
            // 非同期処理の結果を元にWidgetを作れる
            child: FutureBuilder(
              // 投稿メッセージ一覧を取得（非同期処理）
              // 投稿日時でソート
              future: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('date')
                  .get(),
              builder: (context, snapshot) {
                // データが取得できた場合
                if (snapshot.hasData) {
                  final List<DocumentSnapshot> documents = snapshot.data!.docs;
                  // 取得した投稿メッセージ一覧を元にリスト表示
                  return ListView(
                    children: documents.map((document) {
                      return Card(
                        child: ListTile(
                          title: Text(document['text']),
                          subtitle: Text(document['email']),
                        ),
                      );
                    }).toList(),
                  );
                }
                // データが読込中の場合
                return Center(
                  child: Text('読込中...'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return AddPostPage(user);
              },
            ),
          );
        },
      ),
    );
  }
}

// 投稿ページ
class AddPostPage extends StatefulWidget {
  AddPostPage(this.user);
  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('チャット投稿'),
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 投稿メッセージ入力
              TextFormField(
                decoration: InputDecoration(labelText: '投稿メッセージ'),
                // 複数行入力許可
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                onChanged: (String value) {
                  setState(() {
                    messageText = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                // 投稿ボタン
                child: ElevatedButton(
                  child: Text('投稿'),
                  onPressed: () async {
                    // 現在の日付
                    final date = DateTime.now().toLocal().toIso8601String();
                    final email = widget.user.email;

                    // メッセージをFirestoreに保存
                    await FirebaseFirestore.instance
                        .collection('posts') //　コレクションID指定
                        .doc() // ドキュメントID指定
                        .set({
                      'text': messageText,
                      'email': email,
                      'date': date,
                    });
                    // 1つ前の画面に戻る
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
