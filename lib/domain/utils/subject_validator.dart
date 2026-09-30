/// Academic Subject Validator
/// Detects whether an entered subject name is a recognized academic subject
/// (school or college level) across STEM, Humanities, Commerce, Languages,
/// Engineering, Medicine, and Law.
class AcademicSubjectValidator {
  static const Set<String> _knownAcademicTerms = {
    // Mathematics
    'math', 'maths', 'mathematics', 'algebra', 'calculus', 'geometry',
    'trigonometry', 'statistics', 'probability', 'discrete math',
    'discrete mathematics', 'linear algebra', 'arithmetic', 'differential equations',
    'real analysis', 'complex analysis', 'number theory', 'topology',
    'applied mathematics', 'engineering maths', 'engineering mathematics',

    // Physics
    'physics', 'mechanics', 'quantum physics', 'quantum mechanics',
    'thermodynamics', 'optics', 'electromagnetism', 'astrophysics',
    'nuclear physics', 'relativity', 'fluid mechanics', 'kinematics',
    'solid state physics', 'classical mechanics', 'particle physics',
    'electrodynamics', 'waves and oscillations',

    // Chemistry
    'chemistry', 'organic chemistry', 'inorganic chemistry', 'physical chemistry',
    'biochemistry', 'analytical chemistry', 'chemical engineering',
    'polymer chemistry', 'electrochemistry', 'environmental chemistry',
    'stoichiometry', 'medicinal chemistry',

    // Biology & Life Sciences
    'biology', 'botany', 'zoology', 'genetics', 'microbiology', 'anatomy',
    'physiology', 'ecology', 'molecular biology', 'cell biology',
    'immunology', 'biotechnology', 'evolutionary biology', 'neuroscience',
    'pathology', 'pharmacology', 'marine biology',

    // Computer Science & IT
    'computer science', 'cs', 'programming', 'coding', 'data structures',
    'algorithms', 'software engineering', 'operating systems', 'os',
    'database', 'databases', 'dbms', 'computer networks', 'networking',
    'artificial intelligence', 'ai', 'machine learning', 'ml', 'deep learning',
    'cybersecurity', 'information security', 'web development', 'web dev',
    'cloud computing', 'computer architecture', 'theory of computation',
    'compiler design', 'data science', 'mobile development', 'devops',
    'python', 'java', 'c++', 'c programming', 'javascript',

    // Engineering Disciplines
    'mechanical engineering', 'civil engineering', 'electrical engineering',
    'electronics', 'electronics engineering', 'aerospace engineering',
    'biomedical engineering', 'robotics', 'mechatronics', 'telecommunication',
    'structural engineering', 'control systems', 'vlsi', 'embedded systems',
    'fluid dynamics', 'digital electronics', 'analog electronics',

    // Social Sciences & Humanities
    'history', 'world history', 'ancient history', 'modern history',
    'geography', 'physical geography', 'human geography', 'civics',
    'political science', 'sociology', 'psychology', 'philosophy',
    'anthropology', 'economics', 'microeconomics', 'macroeconomics',
    'international relations', 'public administration', 'archaeology',
    'linguistics', 'ethics',

    // Business & Commerce
    'business', 'business studies', 'finance', 'accounting', 'accountancy',
    'marketing', 'management', 'business administration', 'commerce',
    'banking', 'entrepreneurship', 'human resource management', 'business law',
    'financial management', 'cost accounting', 'auditing', 'taxation',

    // Languages & Literature
    'english', 'english literature', 'literature', 'grammar', 'reading',
    'writing', 'spanish', 'french', 'german', 'hindi', 'sanskrit',
    'mandarin', 'japanese', 'latin', 'communication skills',
    'kannada', 'tamil', 'telugu', 'malayalam', 'marathi', 'bengali',

    // Law & Legal Studies
    'law', 'constitutional law', 'criminal law', 'corporate law',
    'jurisprudence', 'legal studies', 'international law', 'contract law',

    // Medicine & Health
    'medicine', 'nursing', 'pharmacy', 'dentistry', 'pediatrics',
    'surgery', 'public health', 'forensic medicine', 'epidemiology',

    // Earth & Environmental Sciences
    'environmental science', 'geology', 'astronomy', 'meteorology',
    'oceanography', 'earth science', 'climatology',

    // Arts & Others
    'art', 'music', 'visual arts', 'theatre', 'physical education', 'pe',
    'health education', 'design', 'architecture', 'journalism',
  };

  static const List<String> _academicKeywords = [
    'math', 'physic', 'chem', 'bio', 'eng', 'hist', 'geog', 'scien',
    'econ', 'comput', 'program', 'softw', 'algor', 'struct', 'statist',
    'calcul', 'algeb', 'litera', 'gramm', 'lang', 'electr', 'mechan',
    'thermo', 'optic', 'quant', 'genet', 'cell', 'molecul', 'anatom',
    'physiol', 'medic', 'pharm', 'nurs', 'robot', 'intellig', 'securit',
    'datab', 'netw', 'architec', 'sociol', 'psychol', 'philos', 'politic',
    'law', 'financ', 'account', 'market', 'manage', 'comm', 'theor',
    'analys', 'design', 'fundament', 'principle', 'intro', 'advance',
    'lab', 'practic', 'study', 'studies', 'seminar', 'workshop', 'project',
  ];

  /// Returns true if [name] is identified as an educational / academic subject.
  static bool isAcademicSubject(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.isEmpty) return false;

    // Reject obvious pure gibberish strings (e.g. "asdfghjk", strings with no vowels)
    final lettersOnly = clean.replaceAll(RegExp(r'[^a-z]'), '');
    if (lettersOnly.length >= 4 && !RegExp(r'[aeiouy]').hasMatch(lettersOnly)) {
      return false;
    }

    // Direct match against known academic terms
    if (_knownAcademicTerms.contains(clean)) return true;

    // Check if any known academic term is contained in the name
    for (final term in _knownAcademicTerms) {
      if (clean == term || clean.startsWith('$term ') || clean.endsWith(' $term') || clean.contains(' $term ')) {
        return true;
      }
    }

    // Check academic keyword stems
    for (final keyword in _academicKeywords) {
      if (clean.contains(keyword)) {
        return true;
      }
    }

    // If word ends with common academic suffixes: -ics, -ology, -onomy, -graphy, -try
    if (clean.endsWith('ics') || clean.endsWith('ology') || clean.endsWith('onomy') ||
        clean.endsWith('graphy') || clean.endsWith('metry') || clean.endsWith('try')) {
      return true;
    }

    return false;
  }
}
