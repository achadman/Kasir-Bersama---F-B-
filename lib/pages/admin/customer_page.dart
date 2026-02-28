import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/app_database.dart';
import '../../../services/customer_service.dart';
import '../../../controllers/admin_controller.dart';
import 'widgets/pinterest_card.dart';
import 'widgets/stat_card.dart';
import '../../../widgets/asri_dialog.dart';

class CustomerPage extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const CustomerPage({super.key, this.onMenuPressed});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  bool _isLoading = true;
  List<Customer> _customers = [];
  late CustomerService _customerService;

  @override
  void initState() {
    super.initState();
    final db = context.read<AppDatabase>();
    _customerService = CustomerService(db);
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    setState(() => _isLoading = true);
    try {
      final admin = context.read<AdminController>();
      if (admin.storeId != null) {
        final data = await _customerService.getCustomers(admin.storeId!);
        setState(() {
          _customers = data..sort((a, b) => (b.points).compareTo(a.points));
        });
      }
    } catch (e) {
      debugPrint("Error fetching customers: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AsriDialog(
          title: "Tambah Pelanggan Baru",
          icon: CupertinoIcons.person_add_solid,
          iconColor: const Color(0xFFEA5700),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogTextField(
                controller: nameController,
                label: "Nama Lengkap",
                icon: CupertinoIcons.person,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                controller: phoneController,
                label: "No. HP",
                icon: CupertinoIcons.phone,
                isDark: isDark,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildDialogTextField(
                controller: emailController,
                label: "Email",
                icon: CupertinoIcons.mail,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          primaryActionLabel: "Simpan",
          onPrimaryAction: () async {
            if (nameController.text.isNotEmpty) {
              final admin = context.read<AdminController>();
              await _customerService.addCustomer(
                storeId: admin.storeId!,
                name: nameController.text,
                phoneNumber: phoneController.text,
                email: emailController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context);
              _fetchCustomers();
            }
          },
          secondaryActionLabel: "Batal",
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: "Masukkan $label",
            prefixIcon: Icon(icon, color: const Color(0xFFEA5700), size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Manajemen Pelanggan",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddCustomerDialog,
            icon: const Icon(CupertinoIcons.person_add_solid),
            tooltip: "Tambah Pelanggan",
          ),
          const SizedBox(width: 8),
        ],
        leading: Builder(
          builder: (ctx) {
            final isWide = MediaQuery.of(ctx).size.width >= 720;
            if (isWide) return const SizedBox.shrink();
            return IconButton(
              onPressed: () {
                if (widget.onMenuPressed != null) {
                  widget.onMenuPressed!();
                } else {
                  Scaffold.of(context).openDrawer();
                }
              },
              icon: const Icon(CupertinoIcons.bars),
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : RefreshIndicator(
              onRefresh: _fetchCustomers,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildLoyaltyHeader(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: "Total Pelanggan",
                          value: "${_customers.length}",
                          icon: CupertinoIcons.person_2,
                          color: const Color(0xFFEA5700),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: "Total Poin",
                          value:
                              "${_customers.fold(0, (sum, c) => sum + (c.points))}",
                          icon: CupertinoIcons.star_fill,
                          color: const Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Daftar Pelanggan",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_customers.isEmpty)
                    _buildEmptyState()
                  else
                    ..._customers.map((c) => _buildCustomerCard(c, isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildLoyaltyHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEA5700), Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA5700).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Program Loyalitas",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ranking Poin Pelanggan",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                CupertinoIcons.star_circle_fill,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Gunakan poin untuk memberikan diskon khusus kepada pelanggan setia Anda.",
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer c, bool isDark) {
    return PinterestCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEA5700).withValues(alpha: 0.1),
            child: Text(
              c.name?.substring(0, 1).toUpperCase() ?? "P",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEA5700),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name ?? "Tanpa Nama",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  c.phoneNumber ?? "No. HP tidak ada",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    size: 11,
                    color: Color(0xFFEA5700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${c.points}",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEA5700),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                "poin",
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 50),
          Icon(
            CupertinoIcons.person_2_square_stack,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada pelanggan",
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
          ),
          Text(
            "Tambahkan pelanggan untuk memulai program loyalitas",
            style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
