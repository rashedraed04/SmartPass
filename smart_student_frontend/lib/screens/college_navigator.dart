import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class CollegeNavigatorScreen extends StatefulWidget {
  const CollegeNavigatorScreen({super.key});

  @override
  State<CollegeNavigatorScreen> createState() => _CollegeNavigatorScreenState();
}

class _CollegeNavigatorScreenState extends State<CollegeNavigatorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _departments = ['CS', 'CIS', 'BIT'];

  static const List<Map<String, String>> _professors = [
    {"name": "أ.د. عبداللطيف أبودلهوم", "email": "a.latif@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. أحمد الشرايعة", "email": "sharieh@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. عزام سليط", "email": "azzam.sleit@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. باسل محافظة", "email": "b.mahafzah@ju.edu.jo", "department": "CS"},
    {"name": "أ.د. حازم الحياري", "email": "hazemh@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. عماد صلاح", "email": "isalah@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. محمد الشريدة", "email": "mshridah@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. محمد القطاونة", "email": "mohd.qat@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. محمد عبيدات", "email": "Obaidat@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. صالح الشرايعة", "email": "ssharaeh@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. سامي السرحان", "email": "samiserh@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. وسام المبيضين", "email": "almobaideen@inf.ju.edu.jo", "department": "CS"},
    {"name": "السيدة أنصار خوري", "email": "ansar@ju.edu.jo", "department": "CS"},
    {"name": "دة. باسمة أحمد الشقيرات", "email": "b.shoqurat@ju.edu.jo", "department": "CS"},
    {"name": "د. بلال أبوصالح", "email": "b.AbuSalih@ju.edu.jo", "department": "CS"},
    {"name": "دة. هبه سعاده", "email": "heba.saadeh@ju.edu.jo", "department": "CS"},
    {"name": "أد. إيمان المومني", "email": "i.momani@ju.edu.jo", "department": "CS"},
    {"name": "د. جمال محمد السكران", "email": "j.alsakran@ju.edu.jo", "department": "CS"},
    {"name": "أ.د. خير الدين صبري", "email": "k.sabri@ju.edu.jo", "department": "CS"},
    {"name": "السيدة لبنى ناصر الدين", "email": "lubna@ju.edu.jo", "department": "CS"},
    {"name": "د. معن العساف", "email": "m_alassaf@ju.edu.jo", "department": "CS"},
    {"name": "السيد نبيل العساف", "email": "n.alassaf@ju.edu.jo", "department": "CS"},
    {"name": "د. ساهر المناصير", "email": "saher@ju.edu.jo", "department": "CS"},
    {"name": "دة. شريناز بدّار", "email": "s.baddar@ju.edu.jo", "department": "CS"},
    {"name": "أ. د. محمد بلال الزعبي", "email": "mba@ju.edu.jo", "department": "CIS"},
    {"name": "أ.د. عمار الحنيطي", "email": "a.huneiti@ju.edu.jo", "department": "CIS"},
    {"name": "أ. د. بسام حمو", "email": "b.hammo@ju.edu.jo", "department": "CIS"},
    {"name": "د. لؤي النمر", "email": "l.nemer@ju.edu.jo", "department": "CIS"},
    {"name": "د. محمد عبد الرحمن أبو شريعة", "email": "m.abushariah@ju.edu.jo", "department": "CIS"},
    {"name": "د. محمد سالم العتوم", "email": "m.atoum@ju.edu.jo", "department": "CS"},
    {"name": "د. موسى الأخرس", "email": "mousa.akhras@ju.edu.jo", "department": "CIS"},
    {"name": "أ.د. عمر العدوان", "email": "adwanoy@ju.edu.jo", "department": "CIS"},
    {"name": "د. عريب أبو الغنم", "email": "O.Abualganam@ju.edu.jo", "department": "CS"},
    {"name": "دة. رنا يوسف", "email": "rana.yousef@ju.edu.jo", "department": "CIS"},
    {"name": "أ. د. أمجد هديب", "email": "ahudaib@ju.edu.jo", "department": "CIS"},
    {"name": "أ. د. فواز الزغول", "email": "fawaz@ju.edu.jo", "department": "CIS"},
    {"name": "السيدة أصيل العناني", "email": "a.anani@ju.edu.jo", "department": "CIS"},
    {"name": "دة. إسراء الزغول", "email": "e.zaghoul@ju.edu.jo", "department": "CIS"},
    {"name": "د. حمد عقاب السوالقة", "email": "h.sawalqah@ju.edu.jo", "department": "CIS"},
    {"name": "السيدة هبة خضراوي", "email": "h.Khadrawi@ju.edu.jo", "department": "CIS"},
    {"name": "دة. هدى كراجه", "email": "h.karajeh@ju.edu.jo", "department": "CIS"},
    {"name": "السيدة لما رجب", "email": "lama.rajab@ju.edu.jo", "department": "CIS"},
    {"name": "د. مروان الطويل", "email": "m.alTawil@ju.edu.jo", "department": "CIS"},
    {"name": "دة. ريم علي الفايز", "email": "r.alfayez@ju.edu.jo", "department": "CIS"},
    {"name": "الآنسة رولا الخالد", "email": "r.khalid@ju.edu.jo", "department": "CIS"},
    {"name": "دة. سلسبيل فايز الفلاح", "email": "s.alfalah@ju.edu.jo", "department": "CIS"},
    {"name": "السيدة تهاني الخطيب", "email": "tahani.khatib@ju.edu.jo", "department": "CIS"},
    {"name": "السيدة تمارا المراعبة", "email": "t.almaraabeh@ju.edu.jo", "department": "CIS"},
    {"name": "د. علي عبدالله الروضان", "email": "a.rodan@ju.edu.jo", "department": "BIT"},
    {"name": "د. بشار عوض الشبول", "email": "b.shboul@ju.edu.jo", "department": "BIT"},
    {"name": "دة. دانه القضاة", "email": "d.qudah@ju.edu.jo", "department": "BIT"},
    {"name": "أ. د. حامد صقر البدور", "email": "h.bdour@ju.edu.jo", "department": "BIT"},
    {"name": "أ.د. حسام فارس", "email": "Hossam.faris@ju.edu.jo", "department": "BIT"},
    {"name": "دة. ملاك ونس الحسن", "email": "M_Alhassan@ju.edu.jo", "department": "BIT"},
    {"name": "أ.د. أسامة حرفوشي", "email": "o.harfoushi@ju.edu.jo", "department": "BIT"},
    {"name": "أ.د. رزق السيد", "email": "r.alsayyed@ju.edu.jo", "department": "BIT"},
    {"name": "دة. ربى عبيدات", "email": "r.obiedat@ju.edu.jo", "department": "BIT"},
    {"name": "د. يزن ياسين الشمايلة", "email": "y.shamaileh@ju.edu.jo", "department": "BIT"},
    {"name": "السيدة ولاء قطيشات", "email": "walaa_qutechate@yahoo.com", "department": "CIS"},
    {"name": "السيد يوسف مجدلاوي", "email": "ymajdal@ju.edu.jo", "department": "CIS"}
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String email) {
    Clipboard.setData(ClipboardData(text: email)).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ البريد الإلكتروني'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearching = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF001600) : const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          'college_guide'.tr(),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003B00)),
        ),
        backgroundColor: isDark ? const Color(0xFF001600) : const Color(0xFFF4F6FB),
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF003B00)),
      ),
      body: Column(
        children: [
          // Search Bar Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003B00)),
              decoration: InputDecoration(
                hintText: 'search_prof_major'.tr(),
                hintStyle: TextStyle(color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00A650)),
                filled: true,
                fillColor: isDark ? const Color(0xFF003300) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: isDark ? BorderSide.none : const BorderSide(color: Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00A650), width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Departments List
          Expanded(
            child: ListView.builder(
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final department = _departments[index];
                
                String depName;
                IconData depIcon;
                switch (department) {
                  case 'CS':
                    depName = 'dept_cs'.tr();
                    depIcon = Icons.computer;
                    break;
                  case 'CIS':
                    depName = 'dept_cis'.tr();
                    depIcon = Icons.dns;
                    break;
                  case 'BIT':
                    depName = 'dept_bit'.tr();
                    depIcon = Icons.business_center;
                    break;
                  default:
                    depName = department;
                    depIcon = Icons.domain;
                }

                final departmentProfs = _professors.where((p) {
                   final matchesDep = p['department'] == department;
                   final query = _searchQuery.toLowerCase();
                   final matchesSearch = query.isEmpty || 
                       p['name']!.toLowerCase().contains(query) || 
                       p['email']!.toLowerCase().contains(query);
                   return matchesDep && matchesSearch;
                }).toList();

                if (departmentProfs.isEmpty) {
                  return const SizedBox.shrink(); // Hide if searching and no matches
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: isDark ? 0 : 2,
                  color: isDark ? const Color(0xFF003300) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isDark ? BorderSide.none : const BorderSide(color: Colors.black12, width: 0.5),
                  ),
                  child: ExpansionTile(
                    key: PageStorageKey<String>(department),
                    initiallyExpanded: isSearching,
                    leading: Icon(depIcon, color: const Color(0xFF00A650)),
                    iconColor: const Color(0xFF00A650),
                    textColor: isDark ? Colors.white : const Color(0xFF003B00),
                    collapsedIconColor: const Color(0xFF00A650),
                    collapsedTextColor: isDark ? Colors.white : const Color(0xFF003B00),
                    title: Text(
                      depName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF003B00),
                      ),
                    ),
                    children: departmentProfs.map((prof) {
                      final name = prof['name'] ?? '';
                      final email = prof['email'] ?? '';
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF00A650).withValues(alpha: 0.1),
                          child: Icon(Icons.person, color: const Color(0xFF00A650)),
                        ),
                        title: Text(
                          name,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF003B00)),
                        ),
                        subtitle: Text(
                          email,
                          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF00A650)),
                          onPressed: () => _copyToClipboard(email),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
