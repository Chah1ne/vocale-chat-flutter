import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Cette ligne masque le message de débogage
      title: 'Speech to Text Demo',
      theme: ThemeData(
        primaryColor: Color(0xFF075E54), // Couleur accent WhatsApp
        scaffoldBackgroundColor: Color(0xFFECE5DD), // Couleur de fond WhatsApp
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFF128C7E)),
      ),
      home: const SpeechToTextDemo(),
    );
  }
}

class SpeechToTextDemo extends StatefulWidget {
  const SpeechToTextDemo({Key? key}) : super(key: key);

  @override
  _SpeechToTextDemoState createState() => _SpeechToTextDemoState();
}

class _SpeechToTextDemoState extends State<SpeechToTextDemo> with TickerProviderStateMixin {
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _text = 'Press the button and start speaking';

  FlutterTts flutterTts = FlutterTts();
  late AnimationController _controller;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel(); // Assurez-vous d'annuler le timer lors de la fermeture de l'application
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'vocale voicce',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: _listen,
                onTapDown: (_) => _controller.forward(),
                onTapUp: (_) {
                  _controller.reverse();
                  if (!_isListening) _controller.reset();
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: _isListening ? Theme.of(context).colorScheme.secondary : Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 0.9).animate(_controller),
                      child: Icon(
                        Icons.mic,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _text,
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _controller.repeat();
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
              if (val.hasConfidenceRating && val.confidence > 0) {
                _text = '${_text} (Confidence: ${val.confidence * 100}%)';
              }
            });
            // Réinitialise le timer à chaque nouvelle reconnaissance vocale
            _resetTimer();
          },
          onSoundLevelChange: (level) {
            // Vous pouvez utiliser le niveau de son pour des animations supplémentaires si nécessaire
          },
        );

        // Démarrer le timer pour arrêter l'enregistrement après un délai d'inactivité
        _startTimer();
      }
    } else {
      setState(() => _isListening = false);
      _controller.reverse();
      _stopListening();
    }
  }

  void _startTimer() {
    const inactivityDuration = Duration(seconds: 4);
    _timer = Timer(inactivityDuration, () {
      if (_isListening) {
        setState(() => _isListening = false);
        _controller.reverse();
        _stopListening();
      }
    });
  }

  // Réinitialiser le timer
  void _resetTimer() {
    _timer.cancel();
    _startTimer();
  }

  // Arrêter l'enregistrement vocal
  void _stopListening() {
    _speech.stop();
    _sendTextToBackend(_text);
  }

  // Ajoutez cette fonction pour envoyer le texte vers le backend
  Future<void> _sendTextToBackend(String text) async {
    final Uri url = Uri.parse('http://localhost:3000/enregistrer-texte');
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {'texte': text};

    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      print('Texte envoyé avec succès vers le backend');
    } else {
      print('Erreur lors de l\'envoi du texte vers le backend : ${response.statusCode}');
    }
  }

}
