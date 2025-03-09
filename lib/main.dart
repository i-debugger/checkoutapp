import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Checkout',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainScreen(),
    );
  }
}

class CartProvider extends ChangeNotifier {
  final List<String> _cartItems = [];

  List<String> get cartItems => _cartItems;

  void addItem(String item) {
    _cartItems.add(item);
    notifyListeners();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BarcodeScannerScreen(),
    const CartScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Checkout")),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: "Scanner"),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: "Cart"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Scaffold(
          body: cart.cartItems.isEmpty
              ? const Center(child: Text("Your cart is empty"))
              : ListView.builder(
                  itemCount: cart.cartItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(cart.cartItems[index]),
                    );
                  },
                ),
        );
      },
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String scannedBarcode = "Scan a barcode";
  String productImageUrl = "";
  String productName = "";
  bool isScanning = false;
  final MobileScannerController scannerController = MobileScannerController();

  Future<void> fetchProductImage(String barcode) async {
    final url = Uri.parse('https://mocki.io/v1/$barcode');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        productImageUrl = data['product']['image_url'] ?? "";
        productName = data['name'] ?? "Unknown Product";
      });
      if (productImageUrl.isNotEmpty) {
        showProductBottomSheet();
      }
    }
  }

  void showProductBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Product Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Image.network(productImageUrl, height: 200),
              const SizedBox(height: 10),
              Text(
                productName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false)
                      .addItem(productName);
                  Navigator.pop(context);
                },
                child: const Text("Add to Cart"),
              ),
            ],
          ),
        );
      },
    );
  }

  void startScanning() {
    setState(() {
      isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: isScanning
              ? MobileScanner(
                  controller: scannerController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty) {
                      String detectedBarcode =
                          barcodes.first.rawValue ?? "Unknown barcode";
                      if (detectedBarcode != scannedBarcode) {
                        setState(() {
                          scannedBarcode = detectedBarcode;
                          fetchProductImage(scannedBarcode);
                          isScanning = false;
                        });
                      }
                    }
                  },
                )
              : Center(
                  child: ElevatedButton(
                    onPressed: startScanning,
                    child: const Text("Scan a barcode"),
                  ),
                ),
        ),
      ],
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Welcome to Home Screen"));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Welcome to Profile Screen"));
  }
}
