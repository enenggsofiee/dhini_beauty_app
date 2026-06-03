import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/glassmorphism.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> treatment;
  
  const BookingScreen({super.key, required this.treatment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  String? _selectedJam;
  final _catatanController = TextEditingController();
  String _selectedPaymentMethod = 'Cash (Di Tempat)';
  bool _isLoading = false;
  String? _selectedVariasi;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Constants.primaryColor,
            colorScheme: const ColorScheme.light(primary: Constants.primaryColor),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Constants.primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedJam = null;
      });
    }
  }

  void _showPaymentInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Constants.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Text(
              _selectedPaymentMethod == 'Transfer Bank' ? 'Instruksi Transfer Bank' : 'Scan QRIS',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Constants.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Selesaikan pembayaran untuk booking Anda',
              style: const TextStyle(color: Constants.textLight, fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            if (_selectedPaymentMethod == 'Transfer Bank') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Constants.textLight.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    _buildBankItem('BCA', '1234 5678 90', 'Dhini Beauty Care'),
                    const Divider(height: 24, color: Colors.black12),
                    _buildBankItem('Mandiri', '0987 6543 21', 'Dhini Beauty Care'),
                    const Divider(height: 24, color: Colors.black12),
                    _buildBankItem('BRI', '1122 3344 55', 'Dhini Beauty Care'),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 120, color: Constants.textDark),
                    const SizedBox(height: 8),
                    const Text('QRIS Dummy', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Scan barcode ini menggunakan aplikasi e-Wallet atau M-Banking Anda.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Constants.textLight)),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _processBookingAPI(); // Process to DB
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Constants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Saya Sudah Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Constants.textLight),
                child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBankItem(String bankName, String accountNo, String accountName) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: Constants.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(bankName[0], style: const TextStyle(color: Constants.primaryColor, fontWeight: FontWeight.bold, fontSize: 18))),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(bankName, style: const TextStyle(fontWeight: FontWeight.w700, color: Constants.textDark)),
              const SizedBox(height: 4),
              Text(accountNo, style: const TextStyle(fontWeight: FontWeight.w600, color: Constants.primaryColor, letterSpacing: 1.2)),
              Text('a/n $accountName', style: const TextStyle(fontSize: 12, color: Constants.textLight)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20, color: Constants.textLight),
          onPressed: () => _showSnackBar('Nomor rekening disalin!'),
        ),
      ],
    );
  }

  Future<void> _bookTreatment() async {
    if (_selectedJam == null) {
      _showSnackBar('Please select a time first!', isError: true);
      return;
    }

    if (_selectedPaymentMethod != 'Cash (Di Tempat)') {
      _showPaymentInstructions();
    } else {
      _processBookingAPI();
    }
  }

  Future<void> _processBookingAPI() async {
    if (_selectedJam == null) {
      _showSnackBar('Please select a time first!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String catatanFinal = '';
    if (_selectedVariasi != null && _selectedVariasi!.isNotEmpty) {
      catatanFinal += 'Variasi: $_selectedVariasi\n\n';
    }
    catatanFinal += _catatanController.text.trim();

    final user = await _apiService.getUserSession();
    final result = await _apiService.createBooking({
      'user_id': user['id'],
      'treatment_id': widget.treatment['id'],
      'tanggal': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'jam_mulai': _selectedJam,
      'catatan': catatanFinal.trim(),
      'metode_pembayaran': _selectedPaymentMethod,
    });

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          builder: (context) => GlassContainer(
            padding: const EdgeInsets.all(32),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.green, size: 50),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Constants.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result['message'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Constants.textLight, fontSize: 16),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.textDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    } else {
      _showSnackBar(result['message'] ?? 'Failed to create booking', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final dayName = days[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    
    return '$dayName, $month $day, $year';
  }

  List<Widget> _getTreatmentDetailWidgets(String treatmentName) {
    String name = treatmentName.toLowerCase();
    List<Widget> items = [];

    Widget buildItem(String title, String desc) {
      bool isChecked = _selectedVariasi == title;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: InkWell(
          onTap: () {
            setState(() {
              if (isChecked) {
                _selectedVariasi = null;
              } else {
                _selectedVariasi = title;
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isChecked ? Constants.primaryColor.withOpacity(0.08) : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isChecked ? Constants.primaryColor : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: isChecked ? Constants.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked ? Constants.primaryColor : Constants.textLight.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isChecked ? Constants.primaryColor : Constants.textDark,
                          fontSize: 15,
                        ),
                      ),
                      if (desc.isNotEmpty) const SizedBox(height: 4),
                      if (desc.isNotEmpty)
                        Text(
                          desc,
                          style: const TextStyle(color: Constants.textLight, fontSize: 13),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (name.contains('eyelash')) {
      items = [
        const Text('Berdasarkan Ketebalan & Volume:', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
        const SizedBox(height: 8),
        buildItem('Classic', '1 bulu mata palsu pada 1 bulu asli. Hasil paling natural.'),
        buildItem('Hybrid', 'Campuran Classic & Volume. Berisi tapi natural.'),
        buildItem('Volume (2D - 6D)', '2-6 bulu mata palsu per 1 bulu asli. Hasil tebal & fluffy.'),
        buildItem('Mega Volume', 'Lebih dari 6 bulu mata per satu bulu asli. Hasil sangat dramatis pekat.'),
        const SizedBox(height: 8),
        const Text('Berdasarkan Gaya/Desain:', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
        const SizedBox(height: 8),
        buildItem('Natural / Open Eye', 'Lebih panjang di bagian tengah, mata terlihat bulat.'),
        buildItem('Cat Eye', 'Semakin panjang ke arah sudut luar mata.'),
        buildItem('Doll Eye', 'Terlihat mirip open eye dengan helaian lebih tebal lentik.'),
        buildItem('Wispy / Kim K Style', 'Panjang berbeda secara selang-seling untuk efek tekstur modern.'),
      ];
    } else if (name.contains('alis')) {
      items = [
        buildItem('Natural Black / Jet Black', 'Hitam pekat/natural, biasa dicampur agar tidak terlalu galak.'),
        buildItem('Dark Brown', 'Cokelat tua, paling populer untuk rambut gelap.'),
        buildItem('Medium Brown', 'Cokelat sedang, cocok untuk rambut cokelat tua/lembut.'),
        buildItem('Light Brown / Ash Brown', 'Cokelat muda keabu-abuan, untuk rambut pirang/cool tone.'),
        buildItem('Chocolate / Auburn', 'Cokelat dengan sentuhan hangat/kemerahan.'),
      ];
    } else if (name.contains('lip blush') || name.contains('bibir')) {
      items = [
        buildItem('Nude & Pink Series', 'Baby Pink, Rose Pink, Dusty Pink, Nude Peach. Tampilan sehari-hari alami.'),
        buildItem('Coral & Orange Series', 'Peach, Coral, Bright Orange. Bagus menetralkan bibir gelap.'),
        buildItem('Red Series', 'Cherry Red, Ruby Red, Wine, Strawberry. Efek bibir merona sehat.'),
      ];
    } else if (name.contains('whitening') || name.contains('suntik')) {
      items = [
        buildItem('Paket Basic (Standard Brightening)', 'Vitamin C & Kolagen. Mencerahkan secara perlahan & daya tahan tubuh.'),
        buildItem('Paket Premium / Platinum', 'Vit C, Kolagen, & Glutathione. Glowing dan menekan pigmen gelap.'),
        buildItem('Paket Super Whitening / Chromosome', 'Bahan aktif premium cepat meresap. Memutihkan merata dari dalam.'),
      ];
    } else if (name.contains('tindik') || name.contains('piercing')) {
      items = [
        const Text('Telinga (Paling Populer):', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
        const SizedBox(height: 8),
        buildItem('Lobe', 'Cuping telinga bawah (tindik standar).'),
        buildItem('Helix', 'Tulang rawan telinga bagian atas/luar.'),
        buildItem('Tragus', 'Tonjolan kecil tulang rawan di depan lubang telinga.'),
        buildItem('Conch, Rook, Daith', 'Area tulang rawan bagian dalam telinga.'),
        const SizedBox(height: 8),
        const Text('Wajah:', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
        const SizedBox(height: 8),
        buildItem('Nostril / Septum', 'Cuping hidung atau sekat tengah hidung.'),
        buildItem('Lip / Labret', 'Di bawah atau di sekitar bibir.'),
        buildItem('Eyebrow', 'Di area tulang alis.'),
        const SizedBox(height: 8),
        const Text('Tubuh Lainnya:', style: TextStyle(fontWeight: FontWeight.w700, color: Constants.primaryColor)),
        const SizedBox(height: 8),
        buildItem('Navel', 'Tindik pusar (sering dipilih untuk estetika perut).'),
        buildItem('Tongue', 'Tindik lidah.'),
      ];
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book Appointment'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Constants.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _animationController.value,
                child: Transform.translate(
                  offset: Offset(0, 30 * (1 - _animationController.value)),
                  child: child,
                ),
              );
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Treatment Card
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    borderRadius: BorderRadius.circular(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: widget.treatment['gambar'] != null && widget.treatment['gambar'].toString().isNotEmpty
                                    ? Image.network(
                                        '${Constants.baseUrl}/../uploads/treatments/${widget.treatment['gambar']}',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.spa_rounded, color: Constants.primaryColor, size: 35),
                                      )
                                    : const Icon(Icons.spa_rounded, color: Constants.primaryColor, size: 35),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.treatment['nama_treatment'],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Constants.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${widget.treatment['durasi']} min session',
                                    style: const TextStyle(color: Constants.textLight, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Constants.primaryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sell_rounded, size: 16, color: Constants.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Mulai dari Rp ${widget.treatment['harga']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Constants.primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_getTreatmentDetailWidgets(widget.treatment['nama_treatment'].toString()).isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pilih Variasi Treatment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark)),
                        if (_selectedVariasi != null && _selectedVariasi!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Constants.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Terpilih',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _getTreatmentDetailWidgets(widget.treatment['nama_treatment'].toString()),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark)),
                  const SizedBox(height: 12),
                  
                  GestureDetector(
                    onTap: _selectDate,
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.calendar_month_rounded, color: Constants.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Constants.textDark),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Constants.textLight),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Available Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark)),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: Constants.jamTersedia.map((jam) {
                      bool isSelected = _selectedJam == jam;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedJam = isSelected ? null : jam),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Constants.primaryColor : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Constants.primaryColor : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Constants.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                : null,
                          ),
                          child: Text(
                            jam,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Constants.textDark,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  const Text('Notes for Therapist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark)),
                  const SizedBox(height: 12),
                  
                  GlassContainer(
                    borderRadius: BorderRadius.circular(20),
                    child: TextField(
                      controller: _catatanController,
                      maxLines: 4,
                      style: const TextStyle(color: Constants.textDark, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Any special requests?',
                        hintStyle: const TextStyle(color: Constants.textLight),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text('Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Constants.textDark)),
                  const SizedBox(height: 16),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: ['Cash (Di Tempat)', 'Transfer Bank', 'Qris / E-Wallet'].map((method) {
                      bool isSelected = _selectedPaymentMethod == method;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedPaymentMethod = method),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Constants.primaryColor : Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Constants.primaryColor : Colors.white.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                method.contains('Cash') ? Icons.payments_rounded : method.contains('Transfer') ? Icons.account_balance_rounded : Icons.qr_code_scanner_rounded,
                                size: 18,
                                color: isSelected ? Colors.white : Constants.textDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                method,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Constants.textDark,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _bookTreatment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.textDark, // Apple style: black prominent button
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirm Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}