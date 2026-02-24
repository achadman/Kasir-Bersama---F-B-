import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_controller.dart';
import '../../widgets/kasir_drawer.dart';
import 'widgets/kasir_side_navigation.dart';
import 'kasir_page.dart';
import '../attendance/attendance_page.dart';
import 'user_profile_page.dart';
import '../other/printer_settings_page.dart';
import '../admin/inventory_page.dart';
import '../admin/category_page.dart';
import '../admin/history/history_page.dart';
import '../admin/promotion_page.dart';
import '../admin/report/profit_loss_page.dart';
import '../admin/customer_page.dart';

class KasirMainPage extends StatefulWidget {
  const KasirMainPage({super.key});

  @override
  State<KasirMainPage> createState() => _KasirMainPageState();
}

class _KasirMainPageState extends State<KasirMainPage> {
  int _selectedIndex = 3; // Default to POS for employees
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final adminCtrl = context.watch<AdminController>();
    final isWide = MediaQuery.of(context).size.width >= 720;

    if (adminCtrl.isInitializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: KasirDrawer(
        currentRoute: _getCurrentRoute(),
        onIndexSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
      body: Row(
        children: [
          if (isWide)
            KasirSideNavigation(
              selectedIndex: _selectedIndex,
              onIndexSelected: (index) {
                setState(() => _selectedIndex = index);
              },
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _getSelectedPage(adminCtrl),
          ),
        ],
      ),
    );
  }

  String _getCurrentRoute() {
    switch (_selectedIndex) {
      case 1: return '/inventory';
      case 2: return '/categories';
      case 3: return '/kasir';
      case 4: return '/order-history';
      case 7: return '/printer-settings';
      case 8: return '/profile';
      case 9: return '/promotions';
      case 11: return '/profit-loss';
      case 12: return '/customers';
      case 13: return '/attendance';
      default: return '/kasir';
    }
  }

  Widget _getSelectedPage(AdminController ctrl) {
    final sId = ctrl.storeId;
    void onMenuPressed() => _scaffoldKey.currentState?.openDrawer();

    switch (_selectedIndex) {
      case 1:
        return InventoryPage(onMenuPressed: onMenuPressed);
      case 2:
        return CategoryPage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 3:
        return KasirPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
        );
      case 4:
        return HistoryPage(
          storeId: sId!,
          showSidebar: false,
          onMenuPressed: onMenuPressed,
        );
      case 7:
        return PrinterSettingsPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
        );
      case 8:
        return UserProfilePage(
          onMenuPressed: onMenuPressed,
          showSidebar: false,
        );
      case 9:
        return PromotionPage(onMenuPressed: onMenuPressed);
      case 11:
        return ProfitLossPage(storeId: sId!, onMenuPressed: onMenuPressed);
      case 12:
        return CustomerPage(onMenuPressed: onMenuPressed);
      case 13:
        return AttendancePage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
        );
      default:
        return KasirPage(
          showSidebar: false,
          onMenuPressed: onMenuPressed,
        );
    }
  }
}
