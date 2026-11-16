import '../../models/lab_model.dart';
import 'lab_content_helpers.dart';

/// SST-category Labs: Fundamentals and History.
/// Lessons and quiz questions for each Lab live below.
List<LabModel> sstLabs() {
  return <LabModel>[sstFundamentalsLab(), sstHistoryLab()];
}

LabModel sstFundamentalsLab() {
  return labOf(
    id: 'sst-fundamentals',
    title: 'SST Fundamentals',
    description:
        'A beginner foundation in Social Studies: geography, civics, society and '
        'the basics of how government works.',
    category: LabCategory.sst,
    difficulty: LabDifficulty.beginner,
    lessons: _sstFundamentalsLessons(),
    questions: _sstFundamentalsQuestions(),
  );
}

LabModel sstHistoryLab() {
  return labOf(
    id: 'sst-history',
    title: 'SST History',
    description:
        'Trace the story of India and the world, from ancient civilisations '
        'through the medieval period to the modern era and its key events.',
    category: LabCategory.sst,
    difficulty: LabDifficulty.beginner,
    lessons: _sstHistoryLessons(),
    questions: _sstHistoryQuestions(),
  );
}

List<LabLesson> _sstFundamentalsLessons() {
  return <LabLesson>[
    lessonOf(
      'sstf-1',
      'Geography: Land, Water and Climate',
      'Geography is the study of the Earth, its landforms, its waters, its climate '
          'and the way people live on it. Indian geography divides naturally into '
          'the physical land, the rivers, the climate and the relief.\n\n'
          'The Indian landmass has three major physical divisions. The Northern '
          'Mountains, or the Himalayas, run about 2,400 km across the north and '
          'include the Kashmir or Himadri range, the Himachal range, the Shiwaliks '
          'and, further east, the Purvanchal or Patkai hills. The Northern Plains '
          'are the wide alluvial belt built by the Indus, Ganga and Brahmaputra '
          'systems. The Peninsular Plateau is the older rocky landmass that fills '
          'the south, with the Deccan Plateau at its centre.\n\n'
          'The major rivers are grouped by direction. West-flowing: Indus, '
          'Narmada, Tapi, Sabarmati, Mahi, Periyar, Sharavathi, Mandovi and Zuari, '
          'which drain into the Arabian Sea. East-flowing: Ganga, Brahmaputra, '
          'Godavari, Krishna, Kaveri, Mahanadi and Subarnarekha, which reach the Bay '
          'of Bengal. The Ganga is the longest river in India, about 2,525 km, and '
          'the Godavari is the longest entirely within the peninsula.\n\n'
          'Climate is broadly described as tropical monsoon, with four seasons. '
          'The cold season runs from December to February, the hot season from '
          'March to May, the southwest monsoon from June to September, and the '
          'retreating northeast monsoon from October to November. Rainfall is '
          'highest along the Western Ghats and the northeastern hills, which '
          'receive over 200 cm a year, and lowest in the Thar Desert region, which '
          'gets under 50 cm.',
      <String>[
        'India has three physical divisions: the Northern Mountains, the Northern '
            'Plains and the Peninsular Plateau.',
        'The Ganga is the longest river in India; the Godavari is the longest '
            'river of the peninsula.',
        'India has a tropical monsoon climate with four seasons.',
        'The Western Ghats and the northeastern hills receive the highest rainfall.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'sstf-2',
      'Indian Constitution and the Three Pillars',
      'The Constitution of India is the supreme law of the land. It was adopted on '
          '26 November 1949 and came into force on 26 January 1950, the date now '
          'celebrated as Republic Day.\n\n'
          'It was drafted by a Constituent Assembly of 300 members, chaired by Dr. '
          'Rajendra Prasad, with B. R. Ambedkar as the Chairman of the Drafting '
          'Committee. The source of inspiration was the Government of India Act, '
          '1935, and the Constitution borrowed heavily from the British, American '
          'and Irish constitutions as well.\n\n'
          'The Preamble declares India a Sovereign Socialist Secular Democratic '
          'Republic and sets out the goals of justice, liberty, equality and '
          'fraternity. The fundamental rights are borrowed from the United States '
          'Constitution, the directive principles from the Irish Constitution, '
          'and the parliamentary system and the idea of a single citizenship from '
          'Britain.\n\n'
          'The Indian state rests on three pillars. Legislature: Parliament, which '
          'has the Rajya Sabha and the Lok Sabha, makes laws. Executive: the '
          'President, Prime Minister and Council of Ministers implement the laws. '
          'Judiciary: the Supreme Court, High Courts and subordinate courts '
          'interpret the laws.\n\n'
          'The Lok Sabha has 552 seats and a normal term of five years, the Rajya '
          'Sabha has 250 seats and a permanent character. India follows universal '
          'adult franchise, so any citizen aged 18 and above can vote, and the '
          'President of India is the head of state while the Prime Minister is the '
          'head of government.',
      <String>[
        'The Constitution came into force on 26 January 1950.',
        'Dr. B. R. Ambedkar chaired the Drafting Committee.',
        'Fundamental rights are inspired by the US Constitution; directive '
            'principles by the Irish Constitution.',
        'The Lok Sabha has 552 seats; the Rajya Sabha has 250 and is permanent.',
        'Universal adult franchise applies from the age of 18.',
      ],
      durationMinutes: 11,
    ),
    lessonOf(
      'sstf-3',
      'Society, Rights and Citizenship',
      'Indian society is built on a mix of unity and variety. It has a Hindu '
          'majority alongside large Muslim, Christian, Sikh, Jain, Buddhist and '
          'tribal communities, and hundreds of languages and thousands of '
          'communities.\n\n'
          'Constitutionally, India follows a secular state model. There is no state '
          'religion, and the Constitution aims to ensure equal respect for all '
          'faiths. Indian society is also often described as a unity in '
          'diversity.\n\n'
          'The Constitution guarantees equality before the law, freedom of '
          'religion, equality of opportunity in public employment, and protection '
          'for the weaker sections of society. The reservation system in '
          'education and government jobs for Scheduled Castes, Scheduled Tribes '
          'and Other Backward Classes is a direct response to long historical '
          'inequality.\n\n'
          'A citizen of India holds several duties as well as rights, including the '
          'duty to pay taxes, to respect the national flag and the Constitution, '
          'to protect the natural environment, and to develop the scientific '
          'temper.\n\n'
          'Indian democracy also depends on the rule of law. A law is a rule made '
          'by the legislature that everyone, including those in power, must obey. '
          'Knowing your rights helps a citizen take part in public life, raise '
          'grievances, and hold officeholders accountable.',
      <String>[
        'India is a sovereign socialist secular democratic republic.',
        'Article 15 and Article 16 forbid discrimination and guarantee equality of '
            'opportunity.',
        'The Constitution provides reservations for SC, ST and OBC '
            'categories.',
        'Universal adult franchise means voting age is 18.',
      ],
      durationMinutes: 9,
    ),
  ];
}

List<QuizQuestion> _sstFundamentalsQuestions() {
  return <QuizQuestion>[
    questionOf(
      'sstf-q1',
      'Which is the longest river in India?',
      <String>['Godavari', 'Ganga', 'Narmada', 'Yamuna'],
      'Ganga',
      'The Ganga is about 2,525 km long, rising in the Himalayas and emptying into '
          'the Bay of Bengal.',
    ),
    questionOf(
      'sstf-q2',
      'On which date did the Indian Constitution come into force?',
      <String>[
        '26 November 1949',
        '26 January 1950',
        '15 August 1947',
        '2 October 1949',
      ],
      '26 January 1950',
      'The Constitution was adopted on 26 November 1949 but came into force on '
          '26 January 1950, now Republic Day.',
    ),
    questionOf(
      'sstf-q3',
      'Who was the Chairman of the Drafting Committee of the Constitution?',
      <String>[
        'Dr. Rajendra Prasad',
        'Dr. B. R. Ambedkar',
        'Jawaharlal Nehru',
        'Vallabhbhai Patel',
      ],
      'Dr. B. R. Ambedkar',
      'Dr. B. R. Ambedkar chaired the Drafting Committee and is called the Father '
          'of the Indian Constitution.',
    ),
    questionOf(
      'sstf-q4',
      'How many seats does the Lok Sabha have?',
      <String>['245', '250', '552', '500'],
      '552',
      'The Lok Sabha has 552 seats, of which 530 are elected from the states and 20 '
          'from the union territories.',
    ),
    questionOf(
      'sstf-q5',
      'Which is the largest state of India by area?',
      <String>['Madhya Pradesh', 'Rajasthan', 'Maharashtra', 'Uttar Pradesh'],
      'Rajasthan',
      'Rajasthan is the largest state by area, while Uttar Pradesh is the most '
          'populous.',
    ),
    questionOf(
      'sstf-q6',
      'In which mountain range is Kanchenjunga located?',
      <String>['Himalaya', 'Aravalli', 'Nilgiri', 'Vindhya'],
      'Himalaya',
      'Kanchenjunga, at 8,586 m, is the highest peak in India and lies in the '
          'Himalaya range.',
    ),
    questionOf(
      'sstf-q7',
      'Which branch of the Indian Parliament is permanent and cannot be dissolved?',
      <String>[
        'Lok Sabha',
        'Rajya Sabha',
        'State Assemblies',
        'Both the Lok Sabha and the Rajya Sabha',
      ],
      'Rajya Sabha',
      'The Rajya Sabha is a permanent house of 250 members with a one-third '
          'retirement every two years.',
    ),
    questionOf(
      'sstf-q8',
      'Who is the head of the Indian state?',
      <String>[
        'The Prime Minister',
        'The President',
        'The Chief Justice',
        'The Speaker',
      ],
      'The President',
      'The President is the head of state, while the Prime Minister is the head '
          'of government.',
    ),
    questionOf(
      'sstf-q9',
      'Which of these is a Fundamental Right guaranteed by the Constitution?',
      <String>[
        'Right to property',
        'Right to freedom of religion',
        'Right to employment',
        'Right to travel free of cost',
      ],
      'Right to freedom of religion',
      'Freedom of religion, guaranteed by Article 25, is a Fundamental Right. The '
          'Right to Property was removed as a Fundamental Right in 1978.',
    ),
    questionOf(
      'sstf-q10',
      'Which monsoon brings most of the rainfall to India?',
      <String>[
        'The northwest monsoon',
        'The southwest monsoon',
        'The winter monsoon',
        'The spring monsoon',
      ],
      'The southwest monsoon',
      'The southwest monsoon, blowing from the Arabian Sea and the Bay of Bengal '
          'between June and September, carries most of India\'s rainfall.',
    ),
  ];
}

List<LabLesson> _sstHistoryLessons() {
  return <LabLesson>[
    lessonOf(
      'ssth-1',
      'Ancient India: From the Indus Valley to the Guptas',
      'Indian history is conventionally divided into the ancient, medieval and '
          'modern periods. The ancient period runs roughly from 3000 BCE to the '
          'early centuries of the common era.\n\n'
          'The Indus Valley Civilisation, about 3300 to 1300 BCE, was one of the '
          'largest of the ancient world. Its cities at Mohenjo-daro, Harappa, '
          'Dholavira and Lothal had planned streets, covered drains, granaries and '
          'standardised bricks. Lothal had a dockyard, which shows that these '
          'people traded by sea.\n\n'
          'The Vedic period followed, with the Rigveda composed around 1500 to '
          '1200 BCE, the period of the later Vedic texts, and then the rise of '
          'Magadha. The Mahajanapadas were sixteen large states, most of them in '
          'northern India.\n\n'
          'The Guptas, 320 to 550 CE, are often called the golden age of India. '
          'Under Chandragupta II, Sanskrit literature and mathematics flourished, '
          'Aryabhata calculated the value of pi, and trade with South-East Asia '
          'spread Hindu and Buddhist culture.\n\n'
          'Southern India also had powerful dynasties: the Satavahanas and the '
          'Cholas, with the Chola navy once the most powerful in the Indian Ocean.',
      <String>[
        'The Indus Valley Civilisation, c. 3300 to 1300 BCE, was one of the largest '
            'of the ancient world.',
        'The Rigveda is composed around 1500 to 1200 BCE.',
        'The Guptas, 320 to 550 CE, are called the golden age of India.',
        'The Cholas of South India built a powerful navy in the Indian Ocean.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'ssth-2',
      'The Sultanate and the Mughal Period',
      'The Delhi Sultanate, 1206 to 1526, was founded by Muhammad of Ghor, who '
          'defeated Prithviraj Chauhan at the First Battle of Tarain in 1192. The '
          'five main dynasties were the Slave, Khilji, Tughlaq, Sayyid and Lodi '
          'dynasties. Alauddin Khalji enforced taxes and a standing army, and '
          'Muhammad bin Tughlaq introduced a token currency in 1330 that failed '
          'badly.\n\n'
          'The Mughals arrived in India in 1526. Babur defeated Ibrahim Lodi at the '
          'First Battle of Panipat in 1526 and founded the Mughal Empire. Humayun '
          'lost and regained the empire, Sher Shah Suri briefly took it, and Akbar '
          'consolidated it. Akbar introduced the mansabdari system, abolished '
          'sati, and promoted the Din-i Ilahi and the policy of sulh-i kul, a '
          'spirit of tolerance.\n\n'
          'Jahangir succeeded Akbar, followed by Shah Jahan and then Aurangzeb, '
          'whose long wars in the Deccan drained the treasury and the empire '
          'began to weaken. Important Mughal-era monuments include the Taj Mahal '
          'built by Shah Jahan, the Red Fort and Jama Masjid in Delhi, and Fatehpur '
          'Sikri built by Akbar.\n\n'
          'At the same time the Marathas grew strong under Shivaji, founder of the '
          'Maratha kingdom, and Peshwa Baji Rao I, one of the great military '
          'leaders of the eighteenth century.',
      <String>[
        'The Delhi Sultanate lasted 1206 to 1526, founded by Muhammad of Ghor.',
        'Babur won the First Battle of Panipat in 1526.',
        'Aurangzeb ruled 1658 to 1707 and his Deccan wars weakened the empire.',
        'The Taj Mahal was built by Shah Jahan as a tomb for Mumtaz Mahal.',
      ],
      durationMinutes: 11,
    ),
    lessonOf(
      'ssth-3',
      'The British Period and the Freedom Struggle',
      'The British East India Company won the Battle of Plassey in 1757, and '
          'Robert Clive was Governor of Bengal. The Company ruled until after the '
          'Revolt of 1857, and the British Crown took direct control in 1858, '
          'with the Government of India Act 1858.\n\n'
          'The national movement grew through several stages. Early resistance '
          'came from leaders such as Raja Rammohun Roy, who campaigned against '
          'sati, and the 1857 revolt, which had leaders like Mangal Pandey, '
          'Begum Hazrat Mahal and Kunwar Singh.\n\n'
          'Moderates and Extremists dominated the early struggle. Mahatma '
          'Gandhi, born 2 October 1869, led three movements: the Non-Cooperation '
          'Movement of 1920, the Salt March of 1930 in which he walked from '
          'Sabarmati to Dandi, and the Quit India Movement of 1942. Jawaharlal '
          'Nehru, Subhas Chandra Bose and Sardar Patel were other central figures, '
          'and Bhagat Singh is remembered as a revolutionary.\n\n'
          'India became independent on 15 August 1947, with Partition at the same '
          'moment. Mahatma Gandhi was assassinated on 30 January 1948.\n\n'
          'The Republic Day, 26 January, marks the day in 1950 when the '
          'Constitution came into force and India became a republic.',
      <String>[
        'The Battle of Plassey was fought in 1757.',
        'The East India Company rule ended and the Crown took over in 1858.',
        'The Salt March of 1930 and the Quit India Movement of 1942 were led by '
            'Mahatma Gandhi.',
        'India became independent on 15 August 1947.',
      ],
      durationMinutes: 10,
    ),
  ];
}

List<QuizQuestion> _sstHistoryQuestions() {
  return <QuizQuestion>[
    questionOf(
      'ssth-q1',
      'Which ancient civilisation is known for the cities of Mohenjo-daro and Harappa?',
      <String>[
        'Vedic civilisation',
        'The Indus Valley Civilisation',
        'The Mauryan Empire',
        'The Harappan Gupta period',
      ],
      'The Indus Valley Civilisation',
      'Mohenjo-daro, Harappa, Dholavira and Lothal were major Indus Valley cities, '
          'with planned streets and covered drains.',
    ),
    questionOf(
      'ssth-q2',
      'In which year was the Battle of Plassey fought?',
      <String>['1757', '1764', '1857', '1849'],
      '1757',
      'The Battle of Plassey in 1757 led to Robert Clive becoming Governor of '
          'Bengal and to British ascendancy in India.',
    ),
    questionOf(
      'ssth-q3',
      'Who founded the Mughal Empire in India?',
      <String>['Humayun', 'Akbar', 'Babur', 'Sher Shah Suri'],
      'Babur',
      'Babur defeated Ibrahim Lodi at the First Battle of Panipat in 1526 and '
          'founded the Mughal Empire.',
    ),
    questionOf(
      'ssth-q4',
      'Which dynasty is called the golden age of Indian history?',
      <String>['The Mauryas', 'The Guptas', 'The Cholas', 'The Mughals'],
      'The Guptas',
      'The Guptas, 320 to 550 CE, saw a flourishing of literature, mathematics and '
          'trade.',
    ),
    questionOf(
      'ssth-q5',
      'Which year marked India\'s independence?',
      <String>['1946', '1947', '1950', '1930'],
      '1947',
      'India became independent on 15 August 1947, at the time of Partition.',
    ),
    questionOf(
      'ssth-q6',
      'Who led the Dandi Salt March in 1930?',
      <String>[
        'Mahatma Gandhi',
        'Subhas Chandra Bose',
        'Sardar Vallabhbhai Patel',
        'Bhagat Singh',
      ],
      'Mahatma Gandhi',
      'Mahatma Gandhi walked from Sabarmati Ashram to Dandi in 1930 to protest the '
          'salt tax.',
    ),
    questionOf(
      'ssth-q7',
      'The Revolt of 1857 is also known as which name?',
      <String>[
        'The First War of Indian Independence',
        'The Sepoy Mutiny only',
        'The Indian Rebellion of 1857 and the Sepoy Mutiny',
        'The Vellore Mutiny',
      ],
      'The Indian Rebellion of 1857 and the Sepoy Mutiny',
      'The uprising of 1857 is known both as the Sepoy Mutiny and as the Indian '
          'Rebellion of 1857.',
    ),
    questionOf(
      'ssth-q8',
      'The Taj Mahal was built by which Mughal ruler?',
      <String>['Akbar', 'Jahangir', 'Shah Jahan', 'Aurangzeb'],
      'Shah Jahan',
      'Shah Jahan built the Taj Mahal in memory of his wife Mumtaz Mahal.',
    ),
    questionOf(
      'ssth-q9',
      'Which dynasty ruled at Hampi, the capital of Vijayanagara?',
      <String>['The Cholas', 'The Sangamas', 'The Pandyas', 'The Kadambas'],
      'The Sangamas',
      'Hampi, capital of the Vijayanagara Empire founded in 1336 by Harihara and '
          'Bukka of the Sangama dynasty, is now a UNESCO World Heritage Site.',
    ),
    questionOf(
      'ssth-q10',
      'Who was the founder of the Maratha kingdom?',
      <String>['Shivaji', 'Baji Rao I', 'Shivappiya', 'Balaji Bajirao'],
      'Shivaji',
      'Shivaji founded the Maratha kingdom in the seventeenth century and led it '
          'against the Mughals and Adilshahis.',
    ),
  ];
}
