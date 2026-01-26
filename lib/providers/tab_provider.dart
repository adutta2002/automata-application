import 'package:flutter/material.dart';

enum TabType { dashboard, serviceInvoice, productInvoice, advance, membership, invoiceDetails, invoices }

class TabItem {
  final String id;
  final String title;
  final Widget widget;
  final TabType type;

  TabItem({
    required this.id,
    required this.title,
    required this.widget,
    required this.type,
  });
}

class TabProvider extends ChangeNotifier {
  final List<TabItem> _tabs = [];
  int _activeIndex = 0;

  List<TabItem> get tabs => _tabs;
  int get activeIndex => _activeIndex;

  void addTab(TabItem tab) {
    _tabs.add(tab);
    _activeIndex = _tabs.length - 1;
    notifyListeners();
  }

  void removeTab(String id) {
    final indexToRemove = _tabs.indexWhere((t) => t.id == id);
    if (indexToRemove == -1) return;

    _tabs.removeAt(indexToRemove);
    if (_activeIndex >= _tabs.length) {
      _activeIndex = _tabs.length - 1;
    }
    notifyListeners();
  }

  void setActiveIndex(int index) {
    _activeIndex = index;
    notifyListeners();
  }

  void setActiveTab(String id) {
    final index = _tabs.indexWhere((t) => t.id == id);
    if (index != -1) {
      _activeIndex = index;
      notifyListeners();
    }
  }

  bool hasTab(String id) {
    return _tabs.any((t) => t.id == id);
  }

  void clearTabs() {
    _tabs.clear();
    _activeIndex = 0;
    notifyListeners();
  }
}
