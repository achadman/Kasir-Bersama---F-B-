import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../services/app_database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

class CategoryPage extends StatefulWidget {
  final String storeId;
  final VoidCallback? onMenuPressed;
  const CategoryPage({super.key, required this.storeId, this.onMenuPressed});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool _isLoading = true;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final db = Provider.of<AppDatabase>(context, listen: false);
      final data =
          await (db.select(db.categories)
                ..where((t) => t.storeId.equals(widget.storeId))
                ..orderBy([(t) => drift.OrderingTerm.asc(t.name)]))
              .get();

      if (mounted) {
        setState(() {
          _categories = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("CategoryPage: Fetch failed: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCategorySheet({Category? category}) async {
    final isEditing = category != null;
    final controller = TextEditingController(text: category?.name);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isEditing ? "Edit Kategori" : "Tambah Kategori",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.inter(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: "Nama Kategori (Contoh: Makanan)",
                  hintStyle: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white38
                        : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    CupertinoIcons.grid,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;

                    final db = Provider.of<AppDatabase>(context, listen: false);
                    try {
                      if (isEditing) {
                        await (db.update(
                          db.categories,
                        )..where((t) => t.id.equals(category.id))).write(
                          CategoriesCompanion(
                            name: drift.Value(name),
                            lastUpdated: drift.Value(DateTime.now()),
                          ),
                        );
                      } else {
                        final id = const Uuid().v4();
                        await db
                            .into(db.categories)
                            .insert(
                              CategoriesCompanion.insert(
                                id: id,
                                name: drift.Value(name),
                                storeId: drift.Value(widget.storeId),
                                lastUpdated: drift.Value(DateTime.now()),
                              ),
                            );
                      }
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _fetchCategories();
                      }
                    } catch (e) {
                      debugPrint("Error saving category: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA5700),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? "Simpan Perubahan" : "Tambah Kategori",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(String id) async {
    final db = Provider.of<AppDatabase>(context, listen: false);
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text("Hapus Kategori?"),
        content: const Text("Tindakan ini tidak dapat dibatalkan."),
        actions: [
          CupertinoDialogAction(
            child: const Text("Batal"),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await (db.delete(db.categories)..where((t) => t.id.equals(id))).go();
        _fetchCategories();
      } catch (e) {
        debugPrint("Error deleting category: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Manajemen Kategori",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF2D3436),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();

            if (Navigator.canPop(context)) {
              return IconButton(
                icon: Icon(
                  CupertinoIcons.back,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
                onPressed: () => Navigator.pop(context),
              );
            }

            return IconButton(
              icon: Icon(
                CupertinoIcons.bars,
                color: isDark ? Colors.white : const Color(0xFF2D3436),
              ),
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
            );
          },
        ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.grid, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Belum ada kategori",
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.03,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                      child: const Icon(
                        CupertinoIcons.grid,
                        color: Colors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cat.name ?? '',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF2D3436),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.pencil,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showCategorySheet(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.trash,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteCategory(cat.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(),
        backgroundColor: const Color(0xFFEA5700),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Tambah Kategori",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
