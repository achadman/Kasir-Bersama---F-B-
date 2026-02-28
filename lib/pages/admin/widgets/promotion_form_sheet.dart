import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../controllers/admin_controller.dart';
import '../../../services/app_database.dart';
import '../../../widgets/asri_dialog.dart';

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
  final _durationController = TextEditingController();

  String _promoType = 'discount'; // discount, buy_x_get_y, bundle
  String _discountUnit = 'percentage'; // percentage, fixed
  List<String> _selectedCategoryIds = [];

  bool _isLoading = false;
  bool _hasDuration = false; // Toggle for duration field

  @override
  void initState() {
    super.initState();
    if (widget.existingPromo != null) {
      final p = widget.existingPromo!;
      _nameController.text = p.name ?? '';
      _descController.text = p.description ?? '';
      _valueController.text = p.value?.toString() ?? '';
      _promoType = p.type;
      _discountUnit = p.discountType;

      // Pre-populate duration if endDate exists
      if (p.endDate != null) {
        _hasDuration = true;
        final daysLeft = p.endDate!.difference(DateTime.now()).inDays;
        _durationController.text = daysLeft > 0 ? daysLeft.toString() : '0';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<AdminController>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
                    hint: 'Contoh: Diskon Ramadhan',
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
                            hint: _discountUnit == 'percentage'
                                ? 'Masukkan jumlah diskon, contoh: 10'
                                : 'Masukkan nominal, contoh: 5000',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icon(
                              _discountUnit == 'percentage'
                                  ? Icons.percent
                                  : Icons.money_off_csred_rounded,
                              size: 18,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nilai diskon wajib diisi';
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null || parsed <= 0) {
                                return 'Masukkan angka yang valid';
                              }
                              if (_discountUnit == 'percentage' &&
                                  parsed > 100) {
                                return 'Max 100%';
                              }
                              return null;
                            },
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

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // --- Duration Section ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Durasi Promosi',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Promosi akan otomatis berakhir',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _hasDuration,
                        onChanged: (v) => setState(() {
                          _hasDuration = v;
                          if (!v) _durationController.clear();
                        }),
                        activeTrackColor: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),

                  if (_hasDuration) ...[
                    const SizedBox(height: 16),
                    _buildDurationField(),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _buildFooter(context, controller),
        ],
      ),
    );
  }

  Widget _buildDurationField() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Berapa hari promosi berlangsung?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: _hasDuration
                    ? (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Masukkan jumlah hari';
                        }
                        final days = int.tryParse(v.trim());
                        if (days == null || days <= 0) {
                          return 'Minimal 1 hari';
                        }
                        return null;
                      }
                    : null,
                decoration: InputDecoration(
                  hintText: 'Contoh: 30',
                  suffixText: 'hari',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Quick duration chips
        Wrap(
          spacing: 8,
          children: [7, 14, 30, 60, 90].map((days) {
            return ActionChip(
              label: Text('$days hari', style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: isDark
                  ? Colors.white10
                  : Theme.of(context).primaryColor.withValues(alpha: 0.08),
              onPressed: () =>
                  setState(() => _durationController.text = '$days'),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (_durationController.text.isNotEmpty) ...[
          Builder(
            builder: (context) {
              final days = int.tryParse(_durationController.text) ?? 0;
              if (days <= 0) return const SizedBox();
              final endDate = DateTime.now().add(Duration(days: days));
              final formatted =
                  '${endDate.day}/${endDate.month}/${endDate.year}';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Berakhir pada: $formatted',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
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
          const SizedBox(width: 60),
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
          onChanged: (_) => setState(() {}), // Refresh end-date preview
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
            return AsriDialog(
              title: 'Pilih Kategori',
              icon: Icons.category_rounded,
              iconColor: Theme.of(context).primaryColor,
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    SizedBox(
                      height: 250,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = _selectedCategoryIds.contains(
                            cat.id,
                          );
                          return CheckboxListTile(
                            title: Text(
                              cat.name ?? 'Tanpa Nama',
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                            value: isSelected,
                            activeColor: Theme.of(context).primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                  ],
                ),
              ),
              primaryActionLabel: 'Selesai',
              onPrimaryAction: () => Navigator.pop(context),
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
      final value = double.tryParse(_valueController.text.trim());

      // Build start/end dates from duration
      DateTime? startDate;
      DateTime? endDate;
      if (_hasDuration) {
        final days = int.tryParse(_durationController.text.trim()) ?? 0;
        if (days > 0) {
          startDate = DateTime.now();
          endDate = startDate.add(Duration(days: days));
        }
      }

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
        startDate: startDate,
        endDate: endDate,
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
