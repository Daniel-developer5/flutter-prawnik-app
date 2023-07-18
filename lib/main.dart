import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const apiBase = 'https://fanciful-vacherin-e22dc3.netlify.app/.netlify/functions/api';
// const apiBase = 'http://192.168.0.52:3000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: Color.fromRGBO(33, 85, 203, 1),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto',
            ),
            bodySmall: TextStyle(
              color: Color.fromRGBO(61, 97, 110, 1),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            )
          ),
        ),
        home: const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  String category = '';
  bool loading = false;
  String user = '';
  String email = '';
  bool gallery = false;

  void changeCategory(newCategory) {
    category = newCategory;
    notifyListeners();
  }

  void toggleLoading() {
    loading = !loading;
    notifyListeners();
  }

  void setUser(newUser, newEmail) {
    user = newUser;
    email = newEmail;
    notifyListeners();
  }

  void toggleGallery() {
    gallery = !gallery;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var category = appState.category;
    var user = appState.user;
    
    Widget content;
    
    if (user.isNotEmpty) {
      if (!appState.gallery) {
        content = MainView(category: category);
      } else {
        content = const GalleryPage();
      }
    } else {
      content = const AuthForm();
    }

    return Scaffold(
      body: ListView(
        children: [content],
      ),
    );
  }
}

class MainView extends StatelessWidget {
  const MainView({
    super.key,
    required this.category,
  });

  final String category;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Column(
      children: [
        AppHeader(title: 'Hi, ${appState.user}', text: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            children: [
              const WriteIn(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: category.isEmpty ? const CategoriesList() : const WriteForm(),
                  ),
                ],
              ),
              const SizedBox(height: 20,),
              Visibility(
                visible: category.isEmpty,
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => appState.setUser('', ''),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20,),
              Row(
                children: [
                  TextButton(
                    onPressed: () => appState.toggleGallery(),
                    child: const Text('Gallery'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool isLogin = true;

  void toggleIsLogin() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    void sendForm() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final url = Uri.parse('$apiBase/${isLogin ? 'log-in' : 'create-account'}');

      final formData = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
      };

      try {
        appState.toggleLoading();

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(formData),
        );

        var body = jsonDecode(response.body);

        if (response.statusCode == 200 && context.mounted && body['error'] == null) {
          appState.setUser(body['name'], body['email']);
        } else {
          showAlert(context, body['error'] ?? 'Form submission failed');
        }
      } catch (error) {
        showAlert(context, 'Form submission failed' + error.toString());
      }

      appState.toggleLoading();
    }

    RegExp emailRegex = RegExp(r'^(([^<>()[\].,;:\s@"]+(\.[^<>()[\].,;:\s@"]+)*)|(".+"))@(([^<>()[\].,;:\s@"]+\.)+[^<>()[\].,;:\s@"]{2,})$', caseSensitive: false);

    return Column(
      children: [
        const AppHeader(title: 'Prawnik App', text: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            children: [
              const SizedBox(height: 8,),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40,),
                    Row(
                      children: [
                        Text(
                          isLogin ? 'Log in' : 'Create an account',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16,),
                    Visibility(
                      visible: !isLogin,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Name',
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              return (value == null || value.isEmpty) ? 'Field is required' : null;
                            },
                          ),
                          const SizedBox(height: 10,),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Field is required';
                        } else {
                          return emailRegex.hasMatch(value) ? null : 'Email is invalid';
                        }
                      },
                    ),
                    const SizedBox(height: 10,),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Password',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        return (value == null || value.isEmpty) ? 'Field is required' : null;
                      },
                    ),
                    const SizedBox(height: 8,),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: !appState.loading ? sendForm : null,
                          style: ButtonStyle(
                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.primary),
                          ),
                          child: appState.loading ? const Loader() : Text(
                            isLogin ? 'Log in' : 'Create an account',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16,),
                    Row(
                      children: [
                        Text(isLogin ? 'Don\'t have an account?' : 'Have an account?'),
                        TextButton(
                          onPressed: toggleIsLogin,
                          child: Text(isLogin ? 'Create an account' : 'Log in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Future<dynamic> showAlert(BuildContext context, String text) {
  return showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      content: Text(text),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

class WriteForm extends StatefulWidget {
  const WriteForm({super.key});

  @override
  State<WriteForm> createState() => _WriteFormState();
}

class _WriteFormState extends State<WriteForm> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    void sendForm() async {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      final url = Uri.parse('$apiBase/message');

      final formData = {
        'email': appState.email,
        'category': appState.category,
        'message': _messageController.text,
      };

      try {
        appState.toggleLoading();

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(formData),
        );

        if (response.statusCode == 200 && context.mounted) {
          showAlert(context, 'Dziekujemy za zgloszenie sprawy. Prosimy oczekiwać kontaktu naszego pracownika.');
          _messageController.text = '';
        } else {
          showAlert(context, 'Form submission failed');
        }
      } catch (error) {
        showAlert(context, 'Form submission failed');
      }

      appState.toggleLoading();
    }

    return Column(
      children: [
        const SizedBox(height: 8,),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _messageController,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 5,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  return (value == null || value.isEmpty) ? 'Field is required' : null;
                },
              ),
              const SizedBox(height: 8,),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: !appState.loading ? sendForm : null,
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.primary),
                    ),
                    child: appState.loading ? const Loader() : const Text(
                      'Send',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24,),
        ElevatedButton(
          onPressed: !appState.loading ? () => appState.changeCategory('') : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            padding: EdgeInsets.zero,
            elevation: 0,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_circle_left,),
              SizedBox(width: 8,),
              Text('Back to categories'),
            ],
          ),
        ),
      ],
    );
  }
}

class Loader extends StatelessWidget {
  const Loader({
    super.key,
    this.color = Colors.white,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SpinKitCircle(
      color: color,
      size: 20.0,
    );
  }
}

class CategoriesList extends StatelessWidget {
  const CategoriesList({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    final icons = [
      Icons.home, Icons.man, Icons.card_travel, Icons.water_drop_outlined,
      Icons.business, Icons.access_alarm_rounded, Icons.travel_explore, Icons.book,
    ];

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: List.generate(8, (index) {
        return Card(
          margin: const EdgeInsets.all(0),
          clipBehavior: Clip.hardEdge,
          child: InkWell(
            splashColor: Colors.blue.withAlpha(30),
            onTap: () {
              appState.changeCategory('Category ${index + 1}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[index]),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(
                      'Category ${index + 1}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class WriteIn extends StatelessWidget {
  const WriteIn({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var category = appState.category;

    return Row(
      children: [
        const Text(
          'Write in',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: category.isNotEmpty ? 4: 0,),
        Text(
          category.isNotEmpty ? '$category:' : ':',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: category.isNotEmpty ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color.fromRGBO(61, 97, 110, 1),
          ),
        ),
      ],
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.title = '',
    this.text = false,
  });

  final String title;
  final bool text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(141, 210, 226, 1),
            Color.fromRGBO(115, 202, 221, 1),
            Color.fromRGBO(71, 159, 186, 1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
              ],
            ),
            Visibility(
              visible: text,
              child: Row(
                children: [
                  Text(
                    'Welcome back to ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Our App',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      decoration: TextDecoration.underline,
                      decorationColor: const Color.fromRGBO(61, 97, 110, 1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Visibility(
              visible: !text,
              child: const SizedBox(height: 19,),
            ),
          ],
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  var imageFiles = [];

  @override
  void initState() {
    super.initState();
    getImages(context);
  }

  Future<void> getImages(BuildContext context) async {
    final appState = Provider.of<MyAppState>(context, listen: false);

    try {
      final response = await http.get(Uri.parse('$apiBase/get-images/${appState.email}'));

      if (response.statusCode != 200 && context.mounted) {
        showAlert(context, 'Image uploading failed.');
      } else {
        setState(() {
          imageFiles = jsonDecode(response.body)['images'];
        });
      }
    } catch (e) {
      showAlert(context, 'Image uploading failed.');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    void openCamera(ImageSource src) async {
      final pickedFile = await ImagePicker().pickImage(source: src);

      if (pickedFile != null) {
        final newImageFile = File(pickedFile.path);

        try {
          appState.toggleLoading();

          var request = http.MultipartRequest('POST', Uri.parse('$apiBase/image'));
          var uploadImg = await http.MultipartFile.fromPath('image', newImageFile.path);
          request.fields['user'] = appState.email;
          request.files.add(uploadImg);
          var response = await request.send();
          var responseBody = await response.stream.bytesToString();
          var body = jsonDecode(responseBody);
          
          if (response.statusCode != 200 && context.mounted) {
            showAlert(context, 'Image uploading failed.');
          } else {
            setState(() {
              imageFiles.add(body['secureUrl']);
            });
          }
        } catch (error) {
          if (context.mounted) {
            showAlert(context, 'Image uploading failed.');
          }
        }

        appState.toggleLoading();
      }
    }

    return Column(
      children: [
        Row(
          children: [
            TextButton(
              onPressed: appState.loading
                ? null
                : () => appState.toggleGallery(),
              child: const Text('Back'),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: appState.loading
                      ? null
                      : () => openCamera(ImageSource.camera), icon: const Icon(Icons.camera_alt),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, right: 4),
                    child: Text('|'),
                  ),
                  IconButton(
                    onPressed: appState.loading
                      ? null
                      : () => openCamera(ImageSource.gallery), icon: const Icon(Icons.filter),
                  ),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: !appState.loading,
          child: Row(
            children: [
              Expanded(
                child: imageFiles.isEmpty
                ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16,),
                  child: Text('No pictures.'),
                )
                : GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  children: List.generate(imageFiles.length, (index) {
                    return Image.network(imageFiles[index], height: 200, fit: BoxFit.cover,);
                  }),
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: appState.loading,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ Loader(color: Theme.of(context).colorScheme.primary), ],
          ),
        ),
      ],
    );
  }
}
