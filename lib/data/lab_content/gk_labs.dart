import '../../models/lab_model.dart';
import 'lab_content_helpers.dart';

/// GK-category Labs: Fundamentals and Current Affairs.
List<LabModel> gkLabs() {
  return <LabModel>[gkFundamentalsLab(), gkCurrentAffairsLab()];
}

LabModel gkFundamentalsLab() {
  return labOf(
    id: 'gk-fundamentals',
    title: 'GK Fundamentals',
    description:
        'Build durable general knowledge: countries and capitals, continents, '
        'important organisations, world landmarks and basic geography.',
    category: LabCategory.gk,
    difficulty: LabDifficulty.beginner,
    lessons: _gkFundamentalsLessons(),
    questions: _gkFundamentalsQuestions(),
  );
}

LabModel gkCurrentAffairsLab() {
  return labOf(
    id: 'gk-current-affairs',
    title: 'Current Affairs',
    description:
        'A structured space for up-to-date general knowledge. Because current '
        'affairs change constantly, this Lab ships with the method for staying '
        'current and refreshable content rather than dated facts.',
    category: LabCategory.gk,
    difficulty: LabDifficulty.intermediate,
    lessons: _gkCurrentAffairsLessons(),
    questions: const <QuizQuestion>[],
  );
}

List<LabLesson> _gkFundamentalsLessons() {
  return <LabLesson>[
    lessonOf(
      'gkf-1',
      'Countries and Capitals',
      'A capital city is the seat of a country\'s government. Knowing the capitals '
          'of the world is one of the most frequently tested areas of general '
          'knowledge.\n\n'
          'Here is a solid core set worth memorising.\n\n'
          'Asia: India - New Delhi. China - Beijing. Japan - Tokyo. Indonesia - '
          'Jakarta. Pakistan - Islamabad. Bangladesh - Dhaka. Sri Lanka - Sri '
          'Jayawardenepura Kotte, with Colombo as the commercial capital. Nepal - '
          'Kathmandu. Saudi Arabia - Riyadh. Israel - Jerusalem, the disputed '
          'capital.\n\n'
          'Europe: France - Paris. Germany - Berlin. Italy - Rome. Spain - Madrid. '
          'United Kingdom - London. Russia - Moscow.\n\n'
          'Africa: Egypt - Cairo. Kenya - Nairobi. Nigeria - Abuja. South Africa - '
          'Pretoria, with Cape Town as the legislative capital. Ghana - Accra. '
          'Ethiopia - Addis Ababa. Tanzania - Dodoma, with Dar es Salaam as the '
          'commercial centre.\n\n'
          'Americas: United States - Washington D.C. Canada - Ottawa. Brazil - '
          'Brasilia. Mexico - Mexico City. Argentina - Buenos Aires.\n\n'
          'Oceania: Australia - Canberra. New Zealand - Wellington.\n\n'
          'A good memory method is to learn capitals in groups of five linked to a '
          'region, rather than as one long list. Regular short revision of a few '
          'at a time is far more effective than a single long session.',
      <String>[
        'Know the capital of every country you study, and learn them in regional '
            'groups.',
        'India is New Delhi, China is Beijing, Japan is Tokyo.',
        'The United States is Washington D.C., not New York.',
        'Some countries have more than one capital, such as South Africa.',
      ],
      durationMinutes: 12,
    ),
    lessonOf(
      'gkf-2',
      'Continents and Oceans',
      'The Earth\'s surface is divided into seven continents and five oceans. The '
          'continents, largest to smallest, are Asia, Africa, North America, South '
          'America, Antarctica, Europe and Australia.\n\n'
          'Asia is the largest continent, home to China, India, Japan and Russia, '
          'and it holds the largest population.\n\n'
          'Africa is the second largest continent and has the most countries - 54 '
          'of them. It is crossed by the Equator and the Prime Meridian.\n\n'
          'Europe is small but densely populated, and is the only continent with no '
          'coastline on the Arctic Ocean.\n\n'
          'North America includes Canada, the United States, Mexico, Greenland and '
          'Central America. South America is linked to North America by the '
          'Isthmus of Panama, which has the Panama Canal.\n\n'
          'Antarctica is the coldest and largest desert, and has no permanent '
          'population or national ownership.\n\n'
          'The five oceans, from largest to smallest, are the Pacific, Atlantic, '
          'Indian, Southern and Arctic.\n\n'
          'Roughly 71 percent of the Earth is covered by water and only 29 percent '
          'is land, which is why the oceans dominate the world map.',
      <String>[
        'The seven continents in size order: Asia, Africa, North America, South '
            'America, Antarctica, Europe, Australia.',
        'Africa has the most countries, about 54.',
        'The five oceans: Pacific, Atlantic, Indian, Southern, Arctic.',
        'About 71 percent of the Earth is covered by water.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-3',
      'Important Countries and Their Facts',
      'Alongside capitals, it helps to know a few defining facts about each major '
          'country.\n\n'
          'India is the largest democracy in the world, and its national animal is '
          'the Bengal tiger. Its national flower is the lotus. It became '
          'independent on 15 August 1947.\n\n'
          'China has the largest population and the largest economy in Asia. The '
          'Great Wall is the best known monument. National day is 1 October.\n\n'
          'Japan is an island nation, known for Mount Fuji and for Shinkansen '
          'high-speed trains. The national flower is the cherry blossom.\n\n'
          'The United States of America has 50 states, with Washington D.C. as its '
          'capital. The Statue of Liberty and the Grand Canyon are famous '
          'landmarks.\n\n'
          'Russia is the largest country in the world by area, and spans eleven '
          'time zones. Moscow is its capital.\n\n'
          'Brazil is the largest country in South America and the home of the Amazon '
          'rainforest, which produces a large share of the world\'s oxygen. Its '
          'national sport is football. Rio de Janeiro hosted the 2016 Olympics.\n\n'
          'Australia is both a country and a continent, and is famous for its '
          'outback and unique wildlife such as the koala and the kangaroo.',
      <String>[
        'India is the largest democracy and became independent on 15 August 1947.',
        'Russia is the largest country in the world by area.',
        'Brazil contains the Amazon rainforest and hosted the 2016 Olympics.',
        'Australia is both a country and a continent.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-4',
      'World Landmarks and Natural Wonders',
      'Landmarks are widely asked about in general knowledge questions, and they '
          'are easy to remember because they are visually distinctive.\n\n'
          'The Great Pyramid of Giza in Egypt is the largest of the pyramids and '
          'the only surviving Wonder of the Ancient World. It stands in the Sahara '
          'Desert region.\n\n'
          'The Taj Mahal in India is a white marble mausoleum in Agra, built by '
          'the Mughal emperor Shah Jahan for his wife Mumtaz Mahal. It is a UNESCO '
          'World Heritage Site.\n\n'
          'The Great Wall of China is a network of fortifications built over many '
          'centuries to protect the northern borders. It is visible from space with '
          'the naked eye in some low-orbit photographs.\n\n'
          'The Eiffel Tower in Paris was built for the 1889 World\'s Fair and was '
          'initially criticised by many artists as ugly.\n\n'
          'Mount Everest is the highest mountain above sea level, in the Himalayas '
          'on the border of Nepal and Tibet.\n\n'
          'The Amazon Rainforest is the largest rainforest, and the Sahara is the '
          'largest hot desert.\n\n'
          'The Great Barrier Reef off Australia is the largest coral reef system, '
          'and Lake Baikal in Russia is the deepest lake in the world.',
      <String>[
        'The Great Pyramid of Giza is the only surviving Ancient Wonder of the '
            'World.',
        'The Taj Mahal is a white marble mausoleum in Agra, India.',
        'Mount Everest is the highest mountain above sea level.',
        'The Great Barrier Reef is the largest coral reef system.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-5',
      'Important International Organisations',
      'International organisations bring countries together to cooperate on issues '
          'that no country can handle alone.\n\n'
          'The United Nations was founded on 24 October 1945 and has its '
          'headquarters in New York. It has 193 member states and aims to keep '
          'peace, promote human rights and cooperate internationally. Its '
          'General Assembly is where all members meet.\n\n'
          'The World Health Organization, also based in Geneva, is responsible for '
          'world public health, disease control and vaccination programmes such as '
          'the global smallpox eradication campaign.\n\n'
          'The International Monetary Fund was established at the Bretton Woods '
          'conference in 1944. It promotes international monetary cooperation and '
          'provides financial assistance to countries facing balance of payments '
          'problems.\n\n'
          'The World Bank provides long-term loans and grants for development '
          'projects such as roads, health and education systems.\n\n'
          'UNICEF, the United Nations Children\'s Fund, works to protect children\'s '
          'rights and improve their health, nutrition and education.\n\n'
          'NATO is a military alliance founded in 1949 for collective defence. Its '
          'membership is different from the United Nations.\n\n'
          'The World Trade Organization, established in 1995, deals with rules of '
          'trade between nations.',
      <String>[
        'The United Nations was founded in 1945 and has 193 member states.',
        'The WHO is the United Nations agency responsible for world public health.',
        'The IMF and World Bank were created to support economic development.',
        'UNICEF protects children\'s rights and welfare.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-6',
      'First Ladies, Presidents and National Symbols',
      'Questions about leaders and national symbols are common in general '
          'knowledge exams.\n\n'
          'Dr. Rajendra Prasad was the first President of independent India, and '
          'was also its first President. Dr. Sarvepalli Radhakrishnan was the '
          'first Indian to be awarded the Nobel Prize, in Literature in 1950.\n\n'
          'The first woman Prime Minister of India was Indira Gandhi, who took '
          'office in 1966.\n\n'
          'The national animal of India is the Bengal tiger, the national bird is '
          'the Indian peafowl, the national flower is the lotus, and the national '
          'tree is the Indian banyan. The national animal of Australia is the '
          'red kangaroo, and the national emblem of the United States is the bald '
          'eagle.\n\n'
          'The currency of India is the rupee, of the United States the dollar, of '
          'the United Kingdom the pound sterling, of Japan the yen, and of '
          'European Union countries the euro.\n\n'
          'Learning these facts in a themed way - first leaders, then symbols, then '
          'currencies - makes them much easier to hold on to than a random list.',
      <String>[
        'Dr. Rajendra Prasad was the first President of India.',
        'Indira Gandhi was the first woman Prime Minister of India, in office from '
            '1966.',
        'India\'s national animal is the Bengal tiger and its national flower is '
            'the lotus.',
        'Learn symbols and currencies in themed groups for better recall.',
      ],
      durationMinutes: 9,
    ),
    lessonOf(
      'gkf-7',
      'Sports, Awards and Literature',
      'General knowledge includes achievements in sport, awards and literature.\n\n'
          'The Olympic Games are held every four years, with both Summer and '
          'Winter Games. They were first held in modern form in Athens in 1896, '
          'and the first Winter Games were in Chamonix in 1924.\n\n'
          'The FIFA World Cup is football\'s biggest tournament, held every four '
          'years. Brazil has won it more times than any other country. The Cricket '
          'World Cup is held every four years, and the ICC Champions Trophy was '
          'renamed from the Champions Trophy in 2021.\n\n'
          'The Nobel Prize, established in 1895, is awarded annually for physics, '
          'chemistry, physiology or medicine, literature, peace and later the '
          'economic sciences. Mother Teresa received the Peace Prize in 1979.\n\n'
          'The Bharat Ratna is India\'s highest civilian award. In literature, '
          'Rabindranath Tagore was the first non-European to win the Nobel Prize '
          'for Literature, in 1913, for Gitanjali.\n\n'
          'Shakespeare is often called the greatest English playwright, with works '
          'such as Hamlet, Macbeth and Romeo and Juliet.',
      <String>[
        'The Olympic Games are held every four years.',
        'The FIFA World Cup is the biggest international football tournament.',
        'The Nobel Prize was established in 1895.',
        'Rabindranath Tagore won the Nobel Prize for Literature in 1913.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-8',
      'Indian States, Rivers and Facts',
      'India is a land of great diversity, and knowledge of its states, rivers and '
          'borders is frequently asked.\n\n'
          'India currently has 28 states and 8 union territories. Major states '
          'include Uttar Pradesh, Maharashtra, Rajasthan, Madhya Pradesh, West '
          'Bengal, Tamil Nadu, Karnataka, Gujarat and Andhra Pradesh. The national '
          'capital, New Delhi, is a union territory.\n\n'
          'The Ganga is the longest river in India and rises in the Himalayas, '
          'flowing through Varanasi, Prayagraj and Patna before reaching the Bay of '
          'Bengal. Other major rivers include the Yamuna, Brahmaputra, Godavari, '
          'Narmada, Kaveri and Krishna.\n\n'
          'The Himalaya is the highest mountain range, and Kanchenjunga is the '
          'highest peak in India. The Thar Desert lies mainly in Rajasthan, and the '
          'Deccan Plateau is in peninsular India.\n\n'
          'Mawsynram in Meghalaya is one of the wettest places on Earth. The '
          'Sundarbans of West Bengal is the largest mangrove forest in the world.\n\n'
          'Studying India state by state, with the main river, the main city and the '
          'main fact for each, is a reliable revision method.',
      <String>[
        'India has 28 states and 8 union territories.',
        'The Ganga is the longest river in India.',
        'Kanchenjunga is the highest peak in India; the Himalaya is the highest '
            'range.',
        'Mawsynram in Meghalaya is one of the wettest places on Earth.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-9',
      'Science and Technology GK',
      'General knowledge regularly includes basic science and current technology '
          'milestones.\n\n'
          'Water boils at 100 degrees Celsius at sea level. The speed of light is '
          'about 300,000 kilometres per second, and the speed of sound is around '
          '343 metres per second in air.\n\n'
          'The SI unit of force is the newton, of energy the joule, of power the '
          'watt and of pressure the pascal.\n\n'
          'Penicillin was discovered by Alexander Fleming in 1928, and it began '
          'modern antibiotics. Vaccination was pioneered by Edward Jenner in 1796 '
          'with smallpox.\n\n'
          'In technology, the first artificial satellite was Sputnik 1, launched by '
          'the Soviet Union in 1957. The first human in space was Yuri Gagarin in '
          '1961. The first person to walk on the Moon was Neil Armstrong in 1969.\n\n'
          'The first computer was built by Charles Babbage, and the World Wide Web '
          'was proposed by Tim Berners-Lee in 1989, with the first website going '
          'live in 1991.\n\n'
          'DNA was discovered by Watson and Crick, with crucial work by Rosalind '
          'Franklin and Maurice Wilkins.',
      <String>[
        'Penicillin was discovered by Alexander Fleming in 1928.',
        'The first artificial satellite was Sputnik 1, launched in 1957.',
        'Neil Armstrong was the first person to walk on the Moon, in 1969.',
        'The World Wide Web was proposed by Tim Berners-Lee in 1989.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gkf-10',
      'World War History, First Dates and Quick Facts',
      'Key dates and famous figures form the backbone of many general knowledge '
          'examinations.\n\n'
          'World War I began in 1914 and ended in 1918, and World War II began in '
          '1939 and ended in 1945. The Second World War is the deadliest conflict '
          'in recorded history, with an estimated 70 to 85 million deaths, the '
          'majority of them civilians.\n\n'
          'India\'s independence movement included the Non-Cooperation Movement of '
          '1920, the Dandi Salt March of 1930, and the Quit India Movement of 1942. '
          'Mahatma Gandhi was born on 2 October 1869.\n\n'
          'The United Nations was formed in 1945, and the Indian Constitution came '
          'into force on 26 January 1950, making India a republic.\n\n'
          'Some quick useful facts: the largest desert in the world is Antarctica, '
          'the largest hot desert is the Sahara, the smallest country is Vatican '
          'City, and the most spoken native language in the world is Mandarin '
          'Chinese.\n\n'
          'The human body has 206 bones, the largest organ is the skin, and the '
          'smallest bone is in the ear.',
      <String>[
        'World War I: 1914 to 1918. World War II: 1939 to 1945.',
        'The Indian Constitution came into force on 26 January 1950.',
        'The largest desert is Antarctica; the largest hot desert is the Sahara.',
        'The largest organ in the human body is the skin.',
      ],
      durationMinutes: 11,
    ),
  ];
}

List<QuizQuestion> _gkFundamentalsQuestions() {
  return <QuizQuestion>[
    questionOf(
      'gkf-q1',
      'What is the capital of Japan?',
      <String>['Seoul', 'Tokyo', 'Kyoto', 'Osaka'],
      'Tokyo',
      'Tokyo is the capital of Japan.',
    ),
    questionOf(
      'gkf-q2',
      'What is the capital of Australia?',
      <String>['Sydney', 'Melbourne', 'Canberra', 'Perth'],
      'Canberra',
      'Canberra is the capital of Australia, chosen because it sits between Sydney '
          'and Melbourne.',
    ),
    questionOf(
      'gkf-q3',
      'Which is the largest continent by area?',
      <String>['Africa', 'Asia', 'Europe', 'Australia'],
      'Asia',
      'Asia is the largest continent and also has the largest population.',
    ),
    questionOf(
      'gkf-q4',
      'Which continent has the most countries?',
      <String>['Asia', 'Europe', 'Africa', 'South America'],
      'Africa',
      'Africa has about 54 countries, more than any other continent.',
    ),
    questionOf(
      'gkf-q5',
      'What is the largest ocean on Earth?',
      <String>['Atlantic', 'Indian', 'Pacific', 'Arctic'],
      'Pacific',
      'The Pacific Ocean is the largest and deepest of the five oceans.',
    ),
    questionOf(
      'gkf-q6',
      'When was the United Nations founded?',
      <String>['1919', '1945', '1950', '1947'],
      '1945',
      'The United Nations came into existence on 24 October 1945.',
    ),
    questionOf(
      'gkf-q7',
      'Which organisation is responsible for world public health?',
      <String>['UNESCO', 'The World Health Organization', 'The IMF', 'NATO'],
      'The World Health Organization',
      'The WHO leads international public health, including disease control and '
          'vaccination campaigns.',
    ),
    questionOf(
      'gkf-q8',
      'Who was the first President of India?',
      <String>[
        'Dr. Sarvepalli Radhakrishnan',
        'Dr. Rajendra Prasad',
        'Jawaharlal Nehru',
        'Indira Gandhi',
      ],
      'Dr. Rajendra Prasad',
      'Dr. Rajendra Prasad was the first President of independent India.',
    ),
    questionOf(
      'gkf-q9',
      'Which is the only surviving Wonder of the Ancient World?',
      <String>[
        'The Hanging Gardens of Babylon',
        'The Great Pyramid of Giza',
        'The Colossus of Rhodes',
        'The Lighthouse of Alexandria',
      ],
      'The Great Pyramid of Giza',
      'The Great Pyramid of Giza in Egypt is the only Ancient Wonder still standing.',
    ),
    questionOf(
      'gkf-q10',
      'Which is the longest river in India?',
      <String>['Godavari', 'Ganga', 'Narmada', 'Kaveri'],
      'Ganga',
      'The Ganga is the longest river in India, rising in the Himalayas.',
    ),
  ];
}

List<LabLesson> _gkCurrentAffairsLessons() {
  return <LabLesson>[
    lessonOf(
      'gca-1',
      'How to Stay Current Without Guessing',
      'Current affairs is the one area of general knowledge where facts go out of '
          'date quickly. This Lab therefore teaches the method rather than freezing '
          'a set of dated facts in the app.\n\n'
          'The first rule is simple: never trust an old answer about something '
          'recent. Details such as who currently holds an office, which team won a '
          'tournament, or the latest policy change can all change within months, '
          'and an old figure presented confidently is worse than no answer.\n\n'
          'A workable daily method has three habits:\n\n'
          '1. Daily scan - spend ten minutes reading a reputable news summary. '
          'Consistency matters more than length.\n\n'
          '2. One-topic focus - each week, pick a single subject such as science, '
          'sport, politics or awards and follow it properly. Depth in one area is '
          'more useful than shallow coverage of everything.\n\n'
          '3. Write it down - record a fact only when you can also record where it '
          'came from and roughly when. A fact with a source is trustworthy; a fact '
          'remembered vaguely is not.\n\n'
          'When you revise, check the date of what you are reading. If the source '
          'is more than a few months old for a fast-moving topic, treat it as '
          'background rather than as the present position.',
      <String>[
        'Never present an old fact as current - check the date of the source.',
        'Ten minutes of daily reading beats long, infrequent sessions.',
        'Focus one subject at a time each week for real depth.',
        'Always record where a fact came from and roughly when.',
      ],
      durationMinutes: 8,
    ),
    lessonOf(
      'gca-2',
      'Where to Find Reliable Sources',
      'Not all sources are equally trustworthy, and knowing which to trust saves a '
          'lot of confusion later.\n\n'
          'Reliable sources usually have these features: a named author or '
          'responsible organisation, a visible publication or updated date, links '
          'to original documents, and corrections made openly when something is '
          'wrong.\n\n'
          'Be cautious with social media posts that state a fact confidently with '
          'no source, with sites that simply copy each other, and with anything '
          'that is designed to make you angry, because sensational content spreads '
          'faster and is edited less carefully.\n\n'
          'A useful habit is to check whether two independent reliable sources '
          'agree before believing something surprising. If a claim appears in only '
          'one place and that place is anonymous, treat it as unconfirmed.\n\n'
          'It is also worth knowing the difference between news and opinion, and '
          'between a report of an event and a prediction about what will happen '
          'next. Predictions are opinions, and should be labelled as such in your '
          'notes.',
      <String>[
        'Look for a named source, a visible date and links to original documents.',
        'Check whether two independent reliable sources agree.',
        'Be careful with unsourced social media posts and sensational headlines.',
        'Distinguish news reports of events from predictions about the future.',
      ],
      durationMinutes: 8,
    ),
    lessonOf(
      'gca-3',
      'How to Take Notes That Last',
      'Current affairs is only useful if you can recall it later, and the way you '
          'write notes determines how well you remember them.\n\n'
          'Write each fact as a complete short sentence that answers who, what, '
          'where and when. Fragments such as "PM - G20" are almost useless later, '
          'while "The G20 Summit was held in the specified city with the stated '
          'theme" survives revision.\n\n'
          'Link new facts to what you already know. A new fact attached to a '
          'strong existing memory is far easier to recall than one stored on its '
          'own.\n\n'
          'Use categories that match how questions are actually asked - national, '
          'international, science, sport, awards, geography - rather than a single '
          'undated list.\n\n'
          'Revise on a spaced schedule: review again after one day, one week and '
          'one month. Each spaced repetition takes only a minute but dramatically '
          'improves long-term retention.',
      <String>[
        'Write complete sentences including who, what, where and when.',
        'Connect each new fact to something you already know.',
        'Group notes by question type: national, international, science, sport.',
        'Revise after one day, one week and one month for long-term recall.',
      ],
      durationMinutes: 8,
    ),
    lessonOf(
      'gca-4',
      'How This Lab Is Kept Up To Date',
      'This Lab is designed so that new current-affairs content can be added later '
          'without changing the way the app works.\n\n'
          'Content for a Lab is stored in the standard Labs tables in Supabase: a '
          'lesson row in lab_lessons and question rows in lab_quizzes. Adding or '
          'updating a lesson is therefore a data change, not a code change.\n\n'
          'Because the content is date-sensitive, lessons carry the source and the '
          'date the content was last verified, so you can always see how fresh the '
          'information is. If a lesson is older than you consider acceptable, '
          'treat it as background rather than as today\'s position.\n\n'
          'This design is also what makes an AI-assisted option possible later. '
          'The Labs feature as it stands works entirely from bundled and stored '
          'content and does not depend on any AI provider being available. When '
          'content is refreshed, existing progress records stay valid because they '
          'reference the Lab, not the wording of a particular lesson.',
      <String>[
        'Current-affairs content lives in the standard labs, lab_lessons and '
            'lab_quizzes tables.',
        'New or revised content is a data update, not a code change.',
        'Always note the date a fact was last verified.',
        'The Labs feature does not depend on an AI provider being available.',
      ],
      durationMinutes: 7,
    ),
  ];
}
