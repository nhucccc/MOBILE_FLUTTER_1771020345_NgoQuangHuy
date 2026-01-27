import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class MemberProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<dynamic> _members = [];
  Map<int, dynamic> _memberProfiles = {};
  bool _isLoading = false;
  String? _error;

  MemberProvider(this._apiService);

  // Getters
  List<dynamic> get members => _members;
  Map<int, dynamic> get memberProfiles => _memberProfiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMembers({String? search, int page = 1, int pageSize = 20}) async {
    if (page == 1) _setLoading(true);
    
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
      };
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '/api/members',
        queryParameters: queryParams,
      );
      
      final data = response.data!;
      final newMembers = data['data'] as List;
      
      if (page == 1) {
        _members = newMembers;
      } else {
        _members.addAll(newMembers);
      }
      
      _clearError();
    } catch (e) {
      _setError('Lỗi tải danh sách thành viên: ${e.toString()}');
    } finally {
      if (page == 1) _setLoading(false);
    }
  }

  Future<dynamic> loadMemberProfile(int memberId) async {
    _setLoading(true);
    try {
      final response = await _apiService.get<Map<String, dynamic>>('/api/members/$memberId/profile');
      final profile = response.data!;
      _memberProfiles[memberId] = profile;
      _clearError();
      return profile;
    } catch (e) {
      _setError('Lỗi tải thông tin thành viên: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(String fullName, String? phoneNumber, String? avatarUrl) async {
    _setLoading(true);
    try {
      await _apiService.put<Map<String, dynamic>>(
        '/api/members/profile',
        data: {
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'avatarUrl': avatarUrl,
        },
      );
      
      _clearError();
      return true;
    } catch (e) {
      _setError('Lỗi cập nhật thông tin: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  dynamic getMemberProfile(int memberId) {
    return _memberProfiles[memberId];
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}