import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auto Scroll ListView',
      home: AutoScrollPage(),
    );
  }
}

class AutoScrollPage extends StatefulWidget {
  @override
  _AutoScrollPageState createState() => _AutoScrollPageState();
}

class _AutoScrollPageState extends State<AutoScrollPage> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  List<String> _items = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm gọi API để lấy dữ liệu từ SQL Server
  void _fetchItems() async {
    try {
      final response = await http
          .get(Uri.parse('https://localhost:7170/api/User'))
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _items = data.map((item) => item['name'] as String).toList();
          _loading = false;
        });
        _startAutoScroll(); // Bắt đầu tự động cuộn khi dữ liệu đã được tải
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  // Hàm cuộn tự động
  void _startAutoScroll() {
    _timer = Timer.periodic(Duration(milliseconds: 150), (timer) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        final maxScrollExtent = position.maxScrollExtent;
        final currentPosition = position.pixels;

        if (currentPosition >= maxScrollExtent) {
          // Nếu đã cuộn đến cuối, quay lại đầu
          _scrollController.jumpTo(0.0); // Cuộn ngay lập tức về đầu
        } else {
          // Nếu chưa đến cuối, tiếp tục cuộn xuống
          _scrollController.animateTo(
            currentPosition + 2.0, // Giảm giá trị cuộn để mượt mà hơn
            duration: Duration(milliseconds: 100), // Thời gian cuộn
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Auto Scroll ListView', style: TextStyle(color: Colors.redAccent),),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error
              ? Center(child: Text('Failed to load items'))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_items[index]),
                    );
                  },
                ),
    );
  }
}
