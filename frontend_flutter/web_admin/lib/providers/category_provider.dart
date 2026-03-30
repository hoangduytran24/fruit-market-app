import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/category_service.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLoaded => _categories.isNotEmpty;

  Future<void> fetchCategories() async {
    if (_isLoading) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> createCategory({
    required String categoryName,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final newCategory = await _categoryService.createCategory(
        categoryName: categoryName,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      
      if (newCategory != null) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> updateCategory({
    required String categoryId,
    required String categoryName,
    String? description,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedCategory = await _categoryService.updateCategory(
        categoryId: categoryId,
        categoryName: categoryName,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      
      if (updatedCategory != null) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> deleteCategory(String categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _categoryService.deleteCategory(categoryId);
      if (success) {
        await fetchCategories();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}