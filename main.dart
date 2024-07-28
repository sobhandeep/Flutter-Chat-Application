import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

late Socket socket;

List<User> users = [];

bool connected = false;
String user_id = "";
bool fond_user = false;
bool initiate_change_pass = false;
bool initiate_change_user = false;

Future<void> create_socket(String ip, int port) async {
  if (connected == false) {
    try {
      socket = await Socket.connect(ip, port);
      // print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');
      socket.listen((Uint8List data) {
        // print('Inside listener');
        Map serverResponse = json.decode(String.fromCharCodes(data));
        // print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Server: $serverResponse');

        if (!connected && serverResponse["response"] == "failed") {
          // print("Connection with server failed, restarting");
          socket.close();
          connected = false;
          create_socket(ip, port);
        }

        if (!connected && (serverResponse["response"] == "success")) {
          // print("connected to server successfully");
          connected = true;
        }
        if (serverResponse["response"] == "message") {
          User.sent_message(serverResponse["from"], serverResponse["data"]);
        }

        if (connected &&
            (serverResponse["response"] == "confirmation") &&
            (serverResponse["data"] == "true") &&
            (serverResponse["type"] == "change password")) {
          initiate_change_pass = true;
        }
        if (connected &&
            (serverResponse["response"] == "confirmation") &&
            (serverResponse["data"] == "true") &&
            (serverResponse["type"] == "change username")) {
          initiate_change_user = true;
        }

        if (connected && serverResponse["response"] == "found") {
          fond_user = true;
        } else if (connected && serverResponse["response"] == "not_found") {
          fond_user = false;
        }
      }, onError: (error) {
        // _destroy(ip, port);
        socket.close();
        create_socket(ip, port);
        connected = false;
      }, onDone: () {
        socket.close();
        create_socket(ip, port);
        connected = false;
      });
    } on Exception {
      // print("Exception -> socket");
    }
  }
}

void main() async {
  //show_user();
  // create_socket(ip, port);

  runApp(ChatCraft());
}

class ChatCraft extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
      ),
      home: Scaffold(
        body: SizedBox(
          child: Login_Screen(),
        ),
        bottomSheet: const SizedBox(
          child: Align(
            child: Text("ChatCraft", style: TextStyle(color: Colors.white)),
            alignment: Alignment.center,
          ),
          height: 40,
        ),
      ),
    );
  }
}

class Login_Screen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Login_Screen_Page();
  }
}

class Login_Screen_Page extends State<Login_Screen> {
  late TextEditingController username_controller;
  late TextEditingController password_controller;
  bool _isObscured = true;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    username_controller = TextEditingController();
    password_controller = TextEditingController();
    _isObscured = true;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      key: _formKey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: const <TextSpan>[
                TextSpan(
                    text: 'Chat Craft',
                    style: TextStyle(fontSize: 50, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: username_controller,
              focusNode: passwordFocusNode,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Username',
                prefixIcon: Icon(Icons.person,
                    color: Color.fromRGBO(215, 215, 215, 0.7)),
                //fillColor: Colors.grey.shade100,
                //filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: password_controller,
              textAlign: TextAlign.left,
              obscureText: _isObscured,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Password',
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromRGBO(215, 215, 215, 0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                      color: Color.fromRGBO(215, 215, 215, 0.7),
                      _isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(
                      () {
                        _isObscured = !_isObscured;
                      },
                    );
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 80),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(21, 16, 44, 1)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(21, 16, 44, 1),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _core_fucntion_of_continue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("LOGIN", style: TextStyle(fontSize: 20)),
                SizedBox(width: 30),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                )
              ])),
        ],
      ),
    );
  }

  void _core_fucntion_of_continue() async {
    if (!connected) {
      String user = username_controller.value.text;
      String pass = password_controller.value.text;
      await create_socket("10.0.2.2", 40000);
      Map<String, String> data = Map();
      data["id"] = user;
      data["pass"] = pass;
      socket.write(json.encode(data));
      await Future.delayed(const Duration(seconds: 3));
      if (connected) {
        user_id = user;
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => Indivisual_Chat_Page(id: user)));
      } else {
        Fluttertoast.showToast(
            msg: "Incorrect ID or Password",
            gravity: ToastGravity.BOTTOM,
            webPosition: "center",
            timeInSecForIosWeb: 2,
            backgroundColor: Color.fromRGBO(32, 25, 61, 1),
            textColor: Color.fromRGBO(215, 215, 215, 1),
            fontSize: 15);
      }
    } else {
      Fluttertoast.showToast(
          msg:
              "J.A.R.V.I.S is either offline or check your internet connection",
          gravity: ToastGravity.BOTTOM,
          webPosition: "center",
          timeInSecForIosWeb: 2,
          textColor: Colors.white,
          fontSize: 15);
    }
  }

  @override
  void dispose() {
    username_controller.dispose();
    super.dispose();
  }
}

class Initiate_Change_Password extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
      ),
      home: Scaffold(
        body: SizedBox(
          child: Initiate_Change_password(),
        ),
        bottomSheet: const SizedBox(
          child: Align(
            child: Text("J.A.R.V.I.S", style: TextStyle(color: Colors.white)),
            alignment: Alignment.center,
          ),
          height: 40,
        ),
      ),
    );
  }
}

class Initiate_Change_password extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Initiate_Change_Password_Page();
  }
}

class Initiate_Change_Password_Page extends State<Initiate_Change_password> {
  late TextEditingController username_controller;
  late TextEditingController password_controller;
  bool _isObscured = true;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    username_controller = TextEditingController();
    password_controller = TextEditingController();
    _isObscured = true;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      key: _formKey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: const <TextSpan>[
                TextSpan(
                    text: 'Chat Craft',
                    style: TextStyle(fontSize: 50, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: username_controller,
              focusNode: passwordFocusNode,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Username',
                prefixIcon: Icon(Icons.person,
                    color: Color.fromRGBO(215, 215, 215, 0.7)),
                //fillColor: Colors.grey.shade100,
                //filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: password_controller,
              textAlign: TextAlign.left,
              obscureText: _isObscured,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Password',
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromRGBO(215, 215, 215, 0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                      color: Color.fromRGBO(215, 215, 215, 0.7),
                      _isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(
                      () {
                        _isObscured = !_isObscured;
                      },
                    );
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 80),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(21, 16, 44, 1)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(21, 16, 44, 1),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _core_fucntion_of_continue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("LOGIN", style: TextStyle(fontSize: 20)),
                SizedBox(width: 30),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                )
              ])),
        ],
      ),
    );
  }

  void _core_fucntion_of_continue() async {
    String user = username_controller.value.text;
    String pass = password_controller.value.text;
    User.change_pass_initiate(user, pass);

    await Future.delayed(const Duration(seconds: 2));

    if (initiate_change_pass) {
      user_id = user;
      initiate_change_pass = false;
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Change_Password()));
    } else {
      Fluttertoast.showToast(
          msg: "Incorrect ID or Password",
          gravity: ToastGravity.BOTTOM,
          webPosition: "center",
          timeInSecForIosWeb: 2,
          backgroundColor: Color.fromRGBO(32, 25, 61, 1),
          textColor: Color.fromRGBO(215, 215, 215, 1),
          fontSize: 15);
    }
  }

  @override
  void dispose() {
    username_controller.dispose();
    super.dispose();
  }
}

class Change_Password extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
      ),
      home: Scaffold(
        body: SizedBox(
          child: Change_password(),
        ),
        bottomSheet: const SizedBox(
          child: Align(
            child: Text("J.A.R.V.I.S", style: TextStyle(color: Colors.white)),
            alignment: Alignment.center,
          ),
          height: 40,
        ),
      ),
    );
  }
}

class Change_password extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Change_Password_Page();
  }
}

class Change_Password_Page extends State<Change_password> {
  late TextEditingController confirm_password_controller;
  late TextEditingController password_controller;
  bool _isObscured = true;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    confirm_password_controller = TextEditingController();
    password_controller = TextEditingController();
    _isObscured = true;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      key: _formKey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: const <TextSpan>[
                TextSpan(
                    text: 'Chat Craft',
                    style: TextStyle(fontSize: 50, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: password_controller,
              focusNode: passwordFocusNode,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Enter new password',
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromRGBO(215, 215, 215, 0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                      color: Color.fromRGBO(215, 215, 215, 0.7),
                      _isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(
                      () {
                        _isObscured = !_isObscured;
                      },
                    );
                  },
                ),
                //fillColor: Colors.grey.shade100,
                //filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: confirm_password_controller,
              textAlign: TextAlign.left,
              obscureText: _isObscured,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Confirm new password',
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromRGBO(215, 215, 215, 0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                      color: Color.fromRGBO(215, 215, 215, 0.7),
                      _isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(
                      () {
                        _isObscured = !_isObscured;
                      },
                    );
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 80),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(21, 16, 44, 1)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(21, 16, 44, 1),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _core_fucntion_of_continue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("CONFIRM", style: TextStyle(fontSize: 20)),
                SizedBox(width: 30),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                )
              ])),
        ],
      ),
    );
  }

  void _core_fucntion_of_continue() async {
    String pass = confirm_password_controller.value.text;
    String confirm_pass = password_controller.value.text;

    await Future.delayed(const Duration(seconds: 2));

    if (pass == confirm_pass) {
      User.change_pass(confirm_pass, pass);
      await Future.delayed(const Duration(seconds: 2));
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Indivisual_Chat_Page(id: "chatcraft")));
    } else {
      Fluttertoast.showToast(
          msg: "Password and confirm password should be same",
          gravity: ToastGravity.BOTTOM,
          webPosition: "center",
          timeInSecForIosWeb: 2,
          backgroundColor: Color.fromRGBO(32, 25, 61, 1),
          textColor: Colors.white,
          fontSize: 15);
    }
  }

  @override
  void dispose() {
    confirm_password_controller.dispose();
    super.dispose();
  }
}

class Initiate_Change_Username extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
      ),
      home: Scaffold(
        body: SizedBox(
          child: Initiate_Change_username(),
        ),
        bottomSheet: const SizedBox(
          child: Align(
            child: Text("J.A.R.V.I.S", style: TextStyle(color: Colors.white)),
            alignment: Alignment.center,
          ),
          height: 40,
        ),
      ),
    );
  }
}

class Initiate_Change_username extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Initiate_Change_Username_Page();
  }
}

class Initiate_Change_Username_Page extends State<Initiate_Change_username> {
  late TextEditingController username_controller;
  late TextEditingController password_controller;
  bool _isObscured = true;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    username_controller = TextEditingController();
    password_controller = TextEditingController();
    _isObscured = true;
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      key: _formKey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: const <TextSpan>[
                TextSpan(
                    text: 'Chat Craft',
                    style: TextStyle(fontSize: 50, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: username_controller,
              focusNode: passwordFocusNode,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Username',
                prefixIcon: Icon(Icons.person,
                    color: Color.fromRGBO(215, 215, 215, 0.7)),
                //fillColor: Colors.grey.shade100,
                //filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: password_controller,
              textAlign: TextAlign.left,
              obscureText: _isObscured,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Password',
                prefixIcon:
                    Icon(Icons.lock, color: Color.fromRGBO(215, 215, 215, 0.7)),
                suffixIcon: IconButton(
                  icon: Icon(
                      color: Color.fromRGBO(215, 215, 215, 0.7),
                      _isObscured ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(
                      () {
                        _isObscured = !_isObscured;
                      },
                    );
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 80),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(21, 16, 44, 1)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(21, 16, 44, 1),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _core_fucntion_of_continue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("LOGIN", style: TextStyle(fontSize: 20)),
                SizedBox(width: 30),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                )
              ])),
        ],
      ),
    );
  }

  void _core_fucntion_of_continue() async {
    String user = username_controller.value.text;
    String pass = password_controller.value.text;
    User.change_user_initiate(user, pass);

    await Future.delayed(const Duration(seconds: 2));

    if (initiate_change_user) {
      user_id = user;
      initiate_change_user = false;
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Change_Username()));
    } else {
      Fluttertoast.showToast(
          msg: "Incorrect ID or Password",
          gravity: ToastGravity.BOTTOM,
          webPosition: "center",
          timeInSecForIosWeb: 2,
          backgroundColor: Color.fromRGBO(32, 25, 61, 1),
          textColor: Colors.white,
          fontSize: 15);
    }
  }

  @override
  void dispose() {
    username_controller.dispose();
    super.dispose();
  }
}

class Change_Username extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
        bottomSheetTheme:
            BottomSheetThemeData(backgroundColor: Colors.black.withOpacity(0)),
      ),
      home: Scaffold(
        body: SizedBox(
          child: Change_username(),
        ),
        bottomSheet: const SizedBox(
          child: Align(
            child: Text("J.A.R.V.I.S", style: TextStyle(color: Colors.white)),
            alignment: Alignment.center,
          ),
          height: 40,
        ),
      ),
    );
  }
}

class Change_username extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return Change_Username_Page();
  }
}

class Change_Username_Page extends State<Change_username> {
  late TextEditingController confirm_username_controller;
  late TextEditingController username_controller;
  final _formKey = GlobalKey<FormState>();
  final passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    confirm_username_controller = TextEditingController();
    username_controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return Container(
      key: _formKey,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RichText(
            text: TextSpan(
              children: const <TextSpan>[
                TextSpan(
                    text: 'Chat Craft',
                    style: TextStyle(fontSize: 50, color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 50),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: username_controller,
              focusNode: passwordFocusNode,
              keyboardType: TextInputType.visiblePassword,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Enter new username',
                prefixIcon: Icon(Icons.person,
                    color: Color.fromRGBO(215, 215, 215, 0.7)),
                //fillColor: Colors.grey.shade100,
                //filled: true,
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: 260.w,
            child: TextField(
              controller: confirm_username_controller,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Color.fromRGBO(215, 215, 215, 0.7),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(93, 121, 222, 1),
                hintText: 'Confirm new username',
                prefixIcon: Icon(Icons.person,
                    color: Color.fromRGBO(215, 215, 215, 0.7)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40.0),
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: Color.fromRGBO(93, 121, 222, 1)),
                  borderRadius: BorderRadius.circular(40.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 80),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromRGBO(21, 16, 44, 1)),
                minimumSize: MaterialStateProperty.all(Size(150, 50)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.0),
                    side: const BorderSide(
                      color: Color.fromRGBO(21, 16, 44, 1),
                      width: 3.0,
                    ),
                  ),
                ),
              ),
              onPressed: _core_fucntion_of_continue,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text("CONFIRM", style: TextStyle(fontSize: 20)),
                SizedBox(width: 30),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 30,
                )
              ])),
        ],
      ),
    );
  }

  void _core_fucntion_of_continue() async {
    String user = confirm_username_controller.value.text;
    String confirm_user = username_controller.value.text;

    await Future.delayed(const Duration(seconds: 2));

    if (user == confirm_user) {
      User.change_user(confirm_user, user);
      await Future.delayed(const Duration(seconds: 2));
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Indivisual_Chat_Page(id: "chatcraft")));
    } else {
      Fluttertoast.showToast(
          msg: "Username and confirm username should be same",
          gravity: ToastGravity.BOTTOM,
          webPosition: "center",
          timeInSecForIosWeb: 2,
          backgroundColor: Color.fromRGBO(32, 25, 61, 1),
          textColor: Colors.white,
          fontSize: 15);
    }
  }

  @override
  void dispose() {
    confirm_username_controller.dispose();
    super.dispose();
  }
}

class User {
  late String id;

  List<Message> messages = [];

  User(this.id);

  static void sent_message(String id, String s) {
    User? temp = User.get_user(id);
    if (temp != null) {
      temp.messages.add(Message(s, Message_Type.Send));
    } else {
      User initiated = User(id);
      initiated.messages.add(Message(s, Message_Type.Send));
      users.add(initiated);
    }
  }

  static void received_message(String id, String s) {
    Map<String, String> token = Map();
    token["type"] = "message";
    token["id"] = user_id;
    token["to"] = id;
    token["data"] = s;

    socket.write(json.encode(token));

    User? temp = User.get_user(id);
    if (temp != null) {
      temp.messages.add(Message(s, Message_Type.Received));
    } else {
      User initiated = User(id);
      initiated.messages.add(Message(s, Message_Type.Received));
      users.add(initiated);
    }
  }

  static void change_pass_initiate(String id, String pass) {
    Map<String, String> token = Map();
    token["type"] = "Command";
    token["id"] = id;
    token["to"] = id;
    token["data"] = "change pass";
    token["pass"] = pass;
    socket.write(json.encode(token));
  }

  static void change_user_initiate(String id, String pass) {
    Map<String, String> token = Map();
    token["type"] = "Command";
    token["id"] = id;
    token["to"] = id;
    token["data"] = "change user";
    token["pass"] = pass;
    socket.write(json.encode(token));
  }

  static void change_pass(String conf, String pass) {
    Map<String, String> token = Map();
    token["type"] = "change pass";
    token["data"] = pass;
    socket.write(json.encode(token));
  }

  static void change_user(String conf, String user) {
    Map<String, String> token = Map();
    token["type"] = "change user";
    token["data"] = user;
    socket.write(json.encode(token));
  }

  static void changeTheme() {}

  static User? get_user(String id) {
    for (User i in users) {
      if (i.id == id) {
        return i;
      }
    }

    return null;
  }

  @override
  String toString() {
    return "id $id\n\n" + messages.toString();
  }
}

enum Message_Type { Send, Received }

class Message {
  late String message;
  late Message_Type type;

  Message(this.message, this.type);

  @override
  String toString() {
    return type == Message_Type.Send
        ? "Send : $message"
        : "Received : $message";
  }
}

class NavBar extends StatelessWidget {
  late String id;

  NavBar(String id) {
    this.id = id;
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(21, 16, 44, 1),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(id),
            accountEmail: Text(''),
            currentAccountPicture: CircleAvatar(
              child: Icon(Icons.person, color: Colors.white),
              backgroundColor: Color.fromRGBO(93, 121, 222, 1),
            ),
            decoration: BoxDecoration(
              color: Color.fromRGBO(32, 25, 61, 1),
              border: Border.all(color: Colors.white),
              borderRadius:
                  BorderRadius.only(bottomRight: Radius.circular(100)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.perm_identity_rounded, color: Colors.white),
            title:
                Text('Change Username', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Initiate_Change_Username()));
            },
          ),
          ListTile(
            leading: Icon(Icons.password_rounded, color: Colors.white),
            title:
                Text('Change password', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Initiate_Change_Password()));
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: Colors.white),
            title: Text('Logout', style: TextStyle(color: Colors.white)),
            onTap: () {
              socket.close();
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatCraft()));
            },
          ),
          ListTile(
            title: Text('Exit', style: TextStyle(color: Colors.white)),
            leading: Icon(Icons.exit_to_app_rounded, color: Colors.white),
            onTap: () => exit(0),
          ),
        ],
      ),
    ));
  }
}

//ignore: must_be_immutable
class Indivisual_Chat_Page extends StatefulWidget {
  late String id;

  Indivisual_Chat_Page({Key? key, this.id = "error"}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return Indivisual_Chat_Page_Creator(this.id);
  }
}

class Indivisual_Chat_Page_Creator extends State<Indivisual_Chat_Page> {
  bool alive = true;
  late String id;
  late TextField send_message_input;
  late var drawer;
  late ScrollController scroll_controller;
  var sendMessageInputController = TextEditingController();

  Indivisual_Chat_Page_Creator(String id) {
    this.id = id;
    scroll_controller = ScrollController(keepScrollOffset: true);
  }

  @override
  void initState() {
    drawer = updater();
    super.initState();
    alive = true;

    update_start();
  }

  Future<void> update_start() async {
    while (true) {
      setState(() {
        drawer = updater();
      });

      await Future.delayed(Duration(seconds: 1));
      if (!alive) return;
      scroll_controller.jumpTo(scroll_controller.position.maxScrollExtent);
    }
  }

  dynamic updater() {
    List<Widget> messages = [SizedBox(height: 50)];

    for (User i in users) {
      if (i.id == id) {
        for (Message j in i.messages) {
          messages.add(Padding(
              padding: EdgeInsets.only(left: 15.w, right: 15.h),
              child: Align(
                  alignment: j.type == Message_Type.Received
                      ? Alignment.topRight
                      : Alignment.topLeft,
                  child: Container(
                    padding: EdgeInsets.only(
                        left: 10.w, top: 10.h, bottom: 10.h, right: 20.w),
                    decoration: BoxDecoration(
                        borderRadius: j.type == Message_Type.Received
                            ? BorderRadius.only(
                                topLeft: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20))
                            : BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20)),
                        color: j.type == Message_Type.Received
                            ? Color.fromRGBO(21, 16, 44, 1)
                            : Color.fromRGBO(93, 121, 222, 1)),
                    constraints: BoxConstraints(maxWidth: 300.w),
                    child: Text(
                      j.message,
                      style: TextStyle(fontSize: 17, color: Colors.white),
                    ),
                  ))));
          messages.add(SizedBox(
            height: 24.h,
          ));
        }
      }
    }
    messages.add(SizedBox(height: 50));
    return ListView(
      padding: EdgeInsets.only(left: 5, bottom: 30, right: 5),
      controller: scroll_controller,
      //shrinkWrap: true,
      children: messages,
    );
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context);
    return MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: Color.fromRGBO(52, 40, 103, 1),
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: Colors.black.withOpacity(0)),
          appBarTheme: AppBarTheme(
            backgroundColor: Color.fromRGBO(32, 25, 61, 1),
            surfaceTintColor: Color.fromRGBO(32, 25, 61, 1),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
                iconTheme: IconThemeData(color: Colors.white),
                title:
                    Text("Chat Craft", style: TextStyle(color: Colors.white)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(60),
                  ),
                  side: BorderSide(color: Colors.white),
                )),
            drawer: NavBar(id),
            body: drawer,
            bottomSheet: SizedBox(
              // height: 70.h,
              // width: 300.h,
              child: TextField(
                controller: sendMessageInputController,
                style: const TextStyle(
                  color: Color.fromRGBO(215, 215, 215, 1),
                ),
                decoration: InputDecoration(
                    filled: true,
                    contentPadding: EdgeInsets.only(left: 20),
                    fillColor: Color.fromRGBO(32, 25, 61, 1),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50)),
                        borderSide:
                            const BorderSide(width: 2, color: Colors.white)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50)),
                        borderSide:
                            const BorderSide(width: 2, color: Colors.white)),
                    suffixIcon: IconButton(
                      padding: EdgeInsets.only(right: 20),
                      icon: Icon(Icons.arrow_forward_rounded,
                          color: Colors.white),
                      onPressed: () {
                        User.received_message(
                            id, sendMessageInputController.value.text);
                        sendMessageInputController.clear();
                        scroll_controller
                            .jumpTo(scroll_controller.position.maxScrollExtent);
                      },
                    ),
                    hintText: 'Message',
                    hintStyle:
                        TextStyle(color: Color.fromRGBO(215, 215, 215, 0.7)),
                    border: InputBorder.none),
                // controller: ,
              ),
            )));
  }

  @override
  void dispose() {
    alive = false;
    super.dispose();
  }
}
