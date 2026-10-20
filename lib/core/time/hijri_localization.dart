import 'package:hijri/hijri_calendar.dart';

/// Menginisialisasi lokalisasi Bahasa Indonesia untuk HijriCalendar
void initializeHijriLocale() {
  HijriCalendar.addLocale('id', {
    'long': {
      1: 'Muharram',
      2: 'Safar',
      3: "Rabi'ul Awwal",
      4: "Rabi'ul Akhir",
      5: 'Jumadil Awal',
      6: 'Jumadil Akhir',
      7: 'Rajab',
      8: "Sya'ban",
      9: 'Ramadhan',
      10: 'Syawwal',
      11: "Dzulqa'dah",
      12: 'Dzulhijjah',
    },
    'short': {
      1: 'Muh',
      2: 'Saf',
      3: 'Rab-1',
      4: 'Rab-2',
      5: 'Jum-1',
      6: 'Jum-2',
      7: 'Raj',
      8: 'Sya',
      9: 'Ram',
      10: 'Syaw',
      11: 'Dzul-Q',
      12: 'Dzul-H',
    },
    'days': {
      1: 'Senin',
      2: 'Selasa',
      3: 'Rabu',
      4: 'Kamis',
      5: 'Jumat',
      6: 'Sabtu',
      7: 'Ahad',
    },
    'short_days': {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Ahd',
    },
  });
  HijriCalendar.setLocal('id');
}
