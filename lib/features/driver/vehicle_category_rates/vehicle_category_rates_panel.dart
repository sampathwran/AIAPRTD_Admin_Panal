import 'package:flutter/material.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/rate_calculator_view.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/vehicle_category_rates/active_system_rates_view.dart';

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
      length: 2,
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
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 📊 1 වන කොටස: Rate Calculator View
            RateCalculatorView(),

            // 🌐 2 වන කොටස: Active System Rates View
            ActiveSystemRatesView(),
          ],
        ),
      ),
    );
  }
}
