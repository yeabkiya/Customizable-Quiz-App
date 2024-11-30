import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(
          secondary: Colors.orange,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
      home: SetupScreen(),
    );
  }
}

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int _numQuestions = 10;
  String? _selectedCategory;
  String _difficulty = 'easy';
  String _type = 'multiple';
  List<dynamic> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response = await http.get(Uri.parse('https://opentdb.com/api_category.php'));
    if (response.statusCode == 200) {
      setState(() {
        _categories = json.decode(response.body)['trivia_categories'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/triviabackground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Quiz Setup'),
          backgroundColor: Colors.blueAccent.withOpacity(0.7),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Number of Questions', style: Theme.of(context).textTheme.displayLarge),
                      Slider(
                        min: 5,
                        max: 20,
                        divisions: 3,
                        value: _numQuestions.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _numQuestions = value.toInt();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                color: Colors.white.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select Category'),
                    value: _selectedCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    items: _categories.map<DropdownMenuItem<String>>((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'].toString(),
                        child: Text(category['name']),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _difficulty,
                          onChanged: (value) {
                            setState(() {
                              _difficulty = value!;
                            });
                          },
                          items: ['easy', 'medium', 'hard'].map((difficulty) {
                            return DropdownMenuItem<String>(
                              value: difficulty,
                              child: Text(difficulty),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      color: Colors.white.withOpacity(0.8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _type,
                          onChanged: (value) {
                            setState(() {
                              _type = value!;
                            });
                          },
                          items: ['multiple', 'boolean'].map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type == 'multiple' ? 'Multiple Choice' : 'True/False'),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Spacer(),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          numQuestions: _numQuestions,
                          category: _selectedCategory,
                          difficulty: _difficulty,
                          type: _type,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start Quiz'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  final int numQuestions;
  final String? category;
  final String difficulty;
  final String type;

  QuizScreen({required this.numQuestions, required this.category, required this.difficulty, required this.type});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    String url =
        'https://opentdb.com/api.php?amount=${widget.numQuestions}&category=${widget.category}&difficulty=${widget.difficulty}&type=${widget.type}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _questions = data['results'];
        _isLoading = false;
      });
    } else {
      throw Exception('Failed to load questions');
    }
  }

  void _answerQuestion(bool isCorrect) {
    setState(() {
      if (isCorrect) _score++;
      _isAnswered = true;
    });
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        if (_currentQuestionIndex < _questions.length - 1) {
          _currentQuestionIndex++;
          _isAnswered = false;
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummaryScreen(score: _score, total: _questions.length),
            ),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('No questions available.'),
        ),
      );
    }

    final question = _questions[_currentQuestionIndex];
    final options = List<String>.from(question['incorrect_answers'])
      ..add(question['correct_answer'])
      ..shuffle();

    return Scaffold(
      appBar: AppBar(title: Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              color: Theme.of(context).colorScheme.secondary,
            ),
            SizedBox(height: 16),
            Card(
              color: const Color.fromARGB(255, 144, 51, 51).withOpacity(0.8),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  question['question'],
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            SizedBox(height: 16),
            ...options.map((option) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isAnswered
                      ? null
                      : () => _answerQuestion(option == question['correct_answer']),
                  child: Text(option),
                ),
              );
            }).toList(),
            Spacer(),
            Text(
              'Score: $_score',
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  final int score;
  final int total;

  SummaryScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quiz Summary')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quiz Complete!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Your Score: $score/$total', style: TextStyle(fontSize: 24, color: Colors.blue)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.restart_alt),
              label: Text('Retake Quiz'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
