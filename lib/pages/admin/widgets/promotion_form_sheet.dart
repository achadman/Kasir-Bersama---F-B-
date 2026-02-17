import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/app_database.dart';

class PromotionFormSheet extends StatefulWidget {
  final Promotion? existingPromo;
  const PromotionFormSheet({super.key, this.existingPromo});

  @override
  State<PromotionFormSheet> createState() => _PromotionFormSheetState();
}

class _PromotionFormSheetState extends State<PromotionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _valueController = TextEditingController();

  String _promoType = 'discount'; // discount, buy_x_get_y, bundle
  String _discountUnit = 'percentage'; // percentage, fixed
  List<String> _selectedCategoryIds = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPromo != null) {
      _nameController.text = widget.existingPromo!.name ?? '';
      _descController.text = widget.existingPromo!.description ?? '';
      _valueController.text = widget.existingPromo!.value?.toString() ?? '';
      _promoType = widget.existingPromo!.type;
      _discountUnit = widget.existingPromo!.discountType;
      // Loading items would require another query
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nama Promosi',
                    hint: 'Contoh: Diskon Kemerdekaan',
                    validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _descController,
                    label: 'Deskripsi (Opsional)',
                    hint: 'Keterangan lengkap promosi...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tipe Promosi',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTypeSelector(),
                  const SizedBox(height: 24),

                  if (_promoType == 'discount') ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _valueController,
                            label: 'Nilai Diskon',
                            hint: _discountUnit == 'percentage' ? '10' : '5000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(
                              _discountUnit == 'percentage'
                                  ? Icons.percent
                                  : Icons.money_off_csred_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    _buildUnitBtn('%', 'percentage'),
                                    _buildUnitBtn('Rp', 'fixed'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildTargetSelector(controller),
                  ],

                  if (_promoType == 'buy_x_get_y') ...[
                    _buildInfoBox(
                      'Fitur Beli X Gratis Y akan segera hadir dalam update berikutnya.',
                    ),
                  ],

                  if (_promoType == 'bundle') ...[
                    _buildInfoBox(
                      'Fitur Paket (Bundling) akan segera hadir dalam update berikutnya.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildFooter(context, controller),
        ],
      ),
    );
  }

  Widget _buildUnitBtn(String label, String unit) {
    final isSelected = _discountUnit == unit;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _discountUnit = unit),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          Text(
            widget.existingPromo == null ? 'Tambah Promosi' : 'Edit Promosi',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 60), // Spacer
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        _typeItem('discount', Icons.percent, 'Diskon'),
        const SizedBox(width: 12),
        _typeItem('buy_x_get_y', Icons.repeat, 'B1G1'),
        const SizedBox(width: 12),
        _typeItem('bundle', Icons.inventory_2, 'Paket'),
      ],
    );
  }

  Widget _typeItem(String type, IconData icon, String label) {
    final isSelected = _promoType == type;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _promoType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(color: isSelected ? color : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(AdminController controller) {
    final hasCategories = controller.categories.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terapkan Pada',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSelectionChip(
              'Semua Produk',
              _selectedCategoryIds.isEmpty,
              () {
                setState(() {
                  _selectedCategoryIds = [];
                });
              },
            ),
            if (hasCategories) ...[
              const SizedBox(width: 12),
              _buildSelectionChip(
                'Kategori',
                _selectedCategoryIds.isNotEmpty,
                () => _showCategoryPicker(controller),
              ),
            ],
          ],
        ),
        if (_selectedCategoryIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSelectedTags(
            _selectedCategoryIds,
            (id) => setState(() => _selectedCategoryIds.remove(id)),
            true,
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  final Map<String, String> _categoryNames = {};

  Widget _buildSelectedTags(
    List<String> ids,
    Function(String) onRemove,
    bool isCategory,
  ) {
    if (ids.isEmpty) return const SizedBox();
    return Wrap(
      spacing: 8,
      children: ids.map((id) {
        final name = _categoryNames[id];
        return Chip(
          label: Text(
            name ?? id.substring(0, 8),
            style: const TextStyle(fontSize: 10),
          ),
          onDeleted: () => onRemove(id),
          deleteIcon: const Icon(Icons.close, size: 14),
          backgroundColor: Theme.of(
            context,
          ).primaryColor.withValues(alpha: 0.1),
        );
      }).toList(),
    );
  }

  void _showCategoryPicker(AdminController controller) async {
    final categories = controller.categories;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Pilih Kategori'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = _selectedCategoryIds.contains(cat.id);
                    return CheckboxListTile(
                      title: Text(cat.name ?? 'Tanpa Nama'),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedCategoryIds.add(cat.id);
                            _categoryNames[cat.id] = cat.name ?? 'Cat';
                          } else {
                            _selectedCategoryIds.remove(cat.id);
                          }
                        });
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Selesai'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFooter(BuildContext context, AdminController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleSave(controller),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Simpan Promosi',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  Future<void> _handleSave(AdminController controller) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final value = double.tryParse(_valueController.text);

      List<Map<String, dynamic>> items = [];
      for (var id in _selectedCategoryIds) {
        items.add({'categoryId': id, 'role': 'TARGET'});
      }

      await controller.promotionService.createPromotion(
        name: _nameController.text,
        type: _promoType,
        discountType: _discountUnit,
        description: _descController.text,
        value: value,
        storeId: controller.storeId!,
        items: items,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promosi berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
