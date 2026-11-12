import 'objects.dart';

/// Bir meslek ve o mesleği anlatan araç. Görseller
/// `assets/images/jobs/` klasöründedir; uçak, traktör, roket ve astronot
/// oyundaki hazır görsellerden gelir.
class Job {
  const Job(this.key, this.person, this.tool);

  /// Çeviri ve ses kaydı adlarının kökü: adı `job_<key>`, tanıtım cümlesi
  /// `job_<key>_d`.
  final String key;
  final GameObject person;
  final GameObject tool;

  String get nameKey => 'job_$key';
  String get textKey => 'job_${key}_d';
}

const jobs = <Job>[
  Job(
    'firefighter',
    GameObject('job_firefighter', '🧑‍🚒', 0, 'jobs'),
    GameObject('tool_hose', '🧯', 0, 'jobs'),
  ),
  Job(
    'doctor',
    GameObject('job_doctor', '🧑‍⚕️', 0, 'jobs'),
    GameObject('tool_stethoscope', '🩺', 0, 'jobs'),
  ),
  Job(
    'cook',
    GameObject('job_cook', '🧑‍🍳', 0, 'jobs'),
    GameObject('tool_pot', '🍲', 0, 'jobs'),
  ),
  Job(
    'teacher',
    GameObject('job_teacher', '🧑‍🏫', 0, 'jobs'),
    GameObject('tool_book', '📚', 0, 'jobs'),
  ),
  Job(
    'builder',
    GameObject('job_builder', '👷', 0, 'jobs'),
    GameObject('tool_hammer', '🔨', 0, 'jobs'),
  ),
  Job(
    'painter',
    GameObject('job_painter', '🧑‍🎨', 0, 'jobs'),
    GameObject('tool_palette', '🎨', 0, 'jobs'),
  ),
  Job(
    'postman',
    GameObject('job_postman', '🧑‍💼', 0, 'jobs'),
    GameObject('tool_envelope', '✉️', 0, 'jobs'),
  ),
  Job(
    'pilot',
    GameObject('job_pilot', '🧑‍✈️', 0, 'jobs'),
    GameObject('plane', '✈️', 2),
  ),
  Job(
    'farmer',
    GameObject('job_farmer', '🧑‍🌾', 0, 'jobs'),
    GameObject('st_tractor', '🚜', 0, 'stickers'),
  ),
  Job(
    'astronaut',
    GameObject('st_astronaut', '🧑‍🚀', 0, 'stickers'),
    GameObject('st_rocket', '🚀', 0, 'stickers'),
  ),
];
