import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/rate_calculator_view.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/active_system_rates_view.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/flat_rate_minimums_view.dart';

class VehicleCategoryRatesPanel extends StatefulWidget {
  const VehicleCategoryRatesPanel({super.key});

  @override
  State<VehicleCategoryRatesPanel> createState() =>
      _VehicleCategoryRatesPanelState();
}

class _VehicleCategoryRatesPanelState extends State<VehicleCategoryRatesPanel> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text(
            "Fleet Rate & Cost Manager",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(icon: Icon(Icons.calculate_rounded), text: "Rate Calculator"),
              Tab(
                icon: Icon(Icons.local_taxi_rounded),
                text: "Active System Rates",
              ),
              Tab(
                icon: Icon(Icons.price_check_rounded),
                text: "Flat Rate Minimums",
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 1 වැනි කොටස: Rate Calculator View
            RateCalculatorView(),

            // 2 වැනි කොටස: Active System Rates View
            ActiveSystemRatesView(),

            // 3 වැනි කොටස: Flat Rate Minimums View
            FlatRateMinimumsView(),
          ],
        ),
      ),
    );
  }
}
