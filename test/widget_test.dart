import 'package:flutter_test/flutter_test.dart';
import 'package:aiaprtd_admin_dashboard/features/driver/menu/driver_menu_constants.dart';

void main() {
  test('driver menu has matching titles and icons', () {
    expect(DriverMenuConstants.menuTitles, isNotEmpty);
    expect(
      DriverMenuConstants.menuIcons.length,
      DriverMenuConstants.menuTitles.length,
    );
  });
}
