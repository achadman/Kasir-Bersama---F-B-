import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../services/app_database.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column;
import '../../services/platform/file_manager.dart';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _newToppingController = TextEditingController();

  XFile? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  String _selectedCategory = "Makanan"; // Changed default to existing

  // Data ini bisa kamu kembangkan untuk masuk ke tabel product_option_values nantinya
  List<Map<String, dynamic>> toppingList = [
    {"name": "Keju", "isSelected": false},
    {"name": "Telur", "isSelected": false},
    {"name": "Susu", "isSelected": false},
    {"name": "Extra Pedas", "isSelected": false},
  ];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
  }

  void _addNewTopping() {
    if (_newToppingController.text.isNotEmpty) {
      setState(() {
        toppingList.add({
          "name": _newToppingController.text.trim(),
          "isSelected": true,
        });
        _newToppingController.clear();
      });
    }
  }

  // LOGIKA SIMPAN KE SQLITE
  void _saveToDatabase() async {
    if (_imageFile == null) {
      _showSnackBar("Silahkan pilih gambar terlebih dahulu");
      return;
    }

    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      _showSnackBar("Nama dan Harga tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = context.read<AppDatabase>();

      // 1. Get Store ID
      final stores = await (db.select(db.stores)..limit(1)).get();
      if (stores.isEmpty) throw "Store not found";
      final String storeId = stores.first.id;

      // 2. Save Image Locally
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}${p.extension(_imageFile!.path)}';
      String imageUrl = await FileManager().saveFile(_imageFile!, fileName);

      // 3. Get or Create Category ID
      final existingCategories =
          await (db.select(db.categories)
                ..where(
                  (t) =>
                      t.storeId.equals(storeId) &
                      t.name.equals(_selectedCategory),
                )
                ..limit(1))
              .get();

      String categoryId;
      if (existingCategories.isEmpty) {
        categoryId = const Uuid().v4();
        await db
            .into(db.categories)
            .insert(
              CategoriesCompanion.insert(
                id: categoryId,
                storeId: Value(storeId),
                name: Value(_selectedCategory),
                lastUpdated: Value(DateTime.now()),
                createdAt: Value(DateTime.now()),
              ),
            );
      } else {
        categoryId = existingCategories.first.id;
      }

      // 4. Save to Products
      await db
          .into(db.products)
          .insert(
            ProductsCompanion.insert(
              id: const Uuid().v4(),
              storeId: Value(storeId),
              categoryId: Value(categoryId),
              name: Value(_nameController.text.trim()),
              description: const Value(''),
              salePrice: Value(double.parse(_priceController.text)),
              basePrice: const Value(0.0),
              stockQuantity: Value(int.parse(_stockController.text)),
              imageUrl: Value(imageUrl),
              isAvailable: const Value(true),
              lastUpdated: Value(DateTime.now()),
              createdAt: Value(DateTime.now()),
            ),
          );

      if (!mounted) return;
      Navigator.pop(context);
      _showSnackBar("Menu Berhasil Disimpan", isError: false);
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // UI tetap sama dengan desain kamu yang sudah bagus
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Menu"),
        backgroundColor: const Color(0xFF001D3D),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 25),
                  _buildTextField(
                    _nameController,
                    "Nama Menu",
                    Icons.fastfood_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _priceController,
                          "Harga",
                          null,
                          isNumber: true,
                          prefix: "Rp ",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _stockController,
                          "Stok",
                          null,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  _buildToppingSection(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image(
                  image: FileManager().getImageProvider(_imageFile!.path),
                  fit: BoxFit.cover,
                ),
              )
            : const Center(
                child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData? icon, {
    bool isNumber = false,
    String? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: "Kategori",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      items: [
        "Makanan",
        "Minuman",
        "Cemilan",
        "Nasi",
      ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildToppingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kelola Pilihan / Topping:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _newToppingController,
                "Tambah pilihan...",
                null,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addNewTopping,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 15),
        // List Topping UI... (sama seperti kode lama kamu)
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _saveToDatabase,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "SIMPAN KE DATABASE",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
