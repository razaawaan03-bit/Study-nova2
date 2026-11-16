import '../../models/lab_model.dart';
import 'lab_content_helpers.dart';

/// GSC-category Labs.
List<LabModel> gscLabs() {
  return <LabModel>[circulatorySystemLab(), gscFundamentalsLab()];
}

LabModel circulatorySystemLab() {
  return labOf(
    id: 'gsc-circulatory-system',
    title: 'Circulatory System',
    description:
        'Understand how your heart, blood and blood vessels work together to '
        'deliver oxygen and nutrients to every single cell in your body.',
    category: LabCategory.gsc,
    difficulty: LabDifficulty.beginner,
    lessons: _circulatoryLessons(),
    questions: _circulatoryQuestions(),
  );
}

LabModel gscFundamentalsLab() {
  return labOf(
    id: 'gsc-fundamentals',
    title: 'GSC Fundamentals',
    description:
        'Build a strong science base. Learn about living things, cells, the human '
        'body systems, food, digestion, respiration and the environment.',
    category: LabCategory.gsc,
    difficulty: LabDifficulty.beginner,
    lessons: _gscFundamentalsLessons(),
    questions: _gscFundamentalsQuestions(),
  );
}

List<LabLesson> _circulatoryLessons() {
  return <LabLesson>[
    lessonOf(
      'circ-1',
      'Introduction to the Circulatory System',
      'The circulatory system, also called the cardiovascular system, is the '
          'body\'s transport network. Its job is to move substances around the body '
          'that are needed to survive, and to remove wastes that must not build up.\n\n'
          'It carries three essential things:\n\n'
          '1. Oxygen, needed by every cell to release energy from food.\n'
          '2. Nutrients, obtained from digested food and needed for growth and '
          'repair.\n'
          '3. Hormones and other chemical messengers that control distant organs.\n\n'
          'It also removes carbon dioxide and other wastes to the lungs, kidneys '
          'and skin for removal.\n\n'
          'The main components of the system are the heart (the pump), the blood '
          '(the transport fluid), and the blood vessels (the pipelines): arteries '
          'that carry blood away from the heart, veins that bring it back, and '
          'capillaries that connect them.\n\n'
          'This system is essential. In a human, if the circulation stops, brain '
          'cells begin to die within minutes because they cannot survive without a '
          'constant supply of oxygen. The human heart is roughly the size of a '
          'closed fist, beats about 100,000 times a day, and pumps around 7,500 '
          'litres of blood daily.\n\n'
          'Blood completes one full round trip of the body in roughly one minute, '
          'which is why the circulatory system is a good example of a transport '
          'system with a closed loop.',
      <String>[
        'The circulatory system transports oxygen, nutrients and hormones.',
        'It removes carbon dioxide and other wastes from the body.',
        'Its main parts are the heart, blood and blood vessels.',
        'Blood completes a full circuit in about one minute.',
      ],
      durationMinutes: 8,
    ),
    lessonOf(
      'circ-2',
      'The Human Heart',
      'The heart is a muscular pump about the size of a closed fist, located in '
          'the chest slightly left of the centre behind the breastbone.\n\n'
          'It is divided into four chambers. The right side handles blood that has '
          'given away its oxygen and needs to go to the lungs. The left side '
          'handles blood that has collected oxygen and needs to go to the body.\n\n'
          'The four chambers are:\n\n'
          '1. Right atrium - receives oxygen-poor blood from the body.\n'
          '2. Right ventricle - pumps that blood to the lungs.\n'
          '3. Left atrium - receives oxygen-rich blood from the lungs.\n'
          '4. Left ventricle - the strongest chamber, pumps blood to the whole '
          'body.\n\n'
          'The heart has its own electrical system. A natural pacemaker called the '
          'sinoatrial node generates an electrical signal that triggers each beat, '
          'so the heart does not rely on nerves from the brain to keep beating. A '
          'typical adult heart beats around 60 to 100 times a minute, and a '
          'trained athlete may have a much lower resting rate.\n\n'
          'Four valves sit between the chambers and at the exits to the lungs and '
          'body. They open and close automatically with each beat, so blood can '
          'only flow in one direction and can never flow backwards.\n\n'
          'The wall of the heart is made of strong cardiac muscle. The left '
          'ventricle has the thickest wall because it must pump blood through the '
          'entire body, while the right ventricle only pumps to the nearby lungs.',
      <String>[
        'The heart has four chambers: right atrium, right ventricle, left atrium, '
            'left ventricle.',
        'The right side of the heart pumps blood to the lungs; the left side pumps '
            'to the body.',
        'Valves ensure blood flows in one direction only.',
        'The sinoatrial node is the natural pacemaker that starts each heartbeat.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'circ-3',
      'Blood',
      'Blood is a fluid connective tissue that transports everything around the '
          'body. It is made up of a liquid part and a solid part.\n\n'
          'The liquid part is plasma, which is about 90 percent water. Plasma '
          'carries dissolved food, salts, hormones and waste products, and it '
          'carries the blood cells suspended in it.\n\n'
          'The solid part is made of three kinds of blood cell:\n\n'
          '1. Red blood cells (erythrocytes) contain haemoglobin, the red pigment '
          'that binds oxygen. They give blood its red colour.\n'
          '2. White blood cells (leucocytes) fight germs and protect the body from '
          'infection.\n'
          '3. Platelets are small fragments that help blood to clot and stop '
          'bleeding when a blood vessel is cut.\n\n'
          'The main job of blood is transport. Red blood cells carry oxygen from '
          'the lungs to the tissues and bring back some carbon dioxide. Plasma '
          'carries digested nutrients from the intestine to every cell. White '
          'blood cells and platelets provide defence and repair.\n\n'
          'An average adult has about five litres of blood, which circulates '
          'through the body roughly every minute. Blood is about five times denser '
          'than water, and the body can lose a significant amount of it before '
          'serious problems appear.',
      <String>[
        'Blood is a fluid connective tissue made of plasma and blood cells.',
        'Red blood cells carry oxygen using haemoglobin.',
        'White blood cells fight infection, and platelets help blood to clot.',
        'An adult has about five litres of blood in the body.',
      ],
      durationMinutes: 9,
    ),
    lessonOf(
      'circ-4',
      'Blood Vessels',
      'Blood vessels are the tubes that carry blood around the body. There are '
          'three main types, and together they form one continuous, closed network.\n\n'
          '1. Arteries carry blood away from the heart. Their walls are thick, '
          'strong and elastic, because they must withstand the strong pumping '
          'pressure of the heart.\n\n'
          '2. Veins carry blood back towards the heart. Their walls are thinner and '
          'they contain valves that stop blood from flowing backwards, since the '
          'pressure is much lower on the return journey.\n\n'
          '3. Capillaries are the tiny, thin-walled vessels that connect arteries '
          'to veins. Their walls are only one cell thick, which lets oxygen and '
          'nutrients pass out into the tissues and lets wastes pass in.\n\n'
          'The capillaries are where the actual work of circulation happens. Oxygen '
          'and nutrients leave the blood here to reach the cells, and carbon '
          'dioxide and other wastes enter the blood here to be carried away.\n\n'
          'If you look at a cut finger, you see many tiny red openings. Each one is '
          'the opening of a capillary. Their combined surface area is enormous, '
          'which is exactly why the exchange of gases and nutrients is so '
          'efficient.',
      <String>[
        'Arteries carry blood away from the heart and have thick, elastic walls.',
        'Veins carry blood back to the heart and contain valves.',
        'Capillaries connect arteries to veins and have walls one cell thick.',
        'Exchange of oxygen, nutrients and wastes happens in the capillaries.',
      ],
      durationMinutes: 9,
    ),
    lessonOf(
      'circ-5',
      'Arteries and Veins',
      'Arteries and veins both carry blood, but they are built very differently '
          'because they work under very different pressures.\n\n'
          'Arteries receive blood at high pressure, straight from the heart\'s '
          'strong pumping. Their walls are thick, muscular and elastic so they can '
          'stretch and spring back with each beat, which helps smooth the blood '
          'flow. Because of this thickness, arteries always stay open even when cut, '
          'which is why arterial bleeding is severe and bright red.\n\n'
          'Veins receive blood at much lower pressure, after the pressure has been '
          'used up on the way around the body. Their walls are thinner and contain '
          'valves to stop blood from flowing backwards and pooling. Muscular '
          'contractions when you move help push blood along. Because their walls '
          'are thin, a cut vein bleeds steadily and the dark red blood can be '
          'pushed out more easily.\n\n'
          'A useful memory trick: artery is "away from" the heart, vein is "back '
          'to" the heart. The letters A and V match the first letter of the '
          'direction.\n\n'
          'Remember that arteries and veins are named by the direction of blood '
          'flow, not by the type of blood they carry. Both carry the same blood; '
          'the oxygen content changes as the blood travels.',
      <String>[
        'Arteries carry blood away from the heart; veins carry blood back to it.',
        'Artery walls are thick and elastic; vein walls are thin and contain '
            'valves.',
        'A is for artery / away; V is for vein / towards.',
        'Both carry the same blood - the name refers to direction, not oxygen '
            'content.',
      ],
      durationMinutes: 8,
    ),
    lessonOf(
      'circ-6',
      'Blood Circulation',
      'The circulation of blood follows a double circuit, which means blood '
          'travels through the heart twice during one complete journey around the '
          'body.\n\n'
          'The Pulmonary Circulation connects the heart with the lungs. Oxygen-poor '
          'blood from the body enters the right atrium, moves into the right '
          'ventricle, and is pumped through the pulmonary artery to the lungs. In '
          'the lungs it picks up oxygen and releases carbon dioxide. It then '
          'returns through the pulmonary vein to the left atrium. This circuit is '
          'short and low in pressure.\n\n'
          'The Systemic Circulation connects the heart with the rest of the body. '
          'Oxygen-rich blood leaves the left ventricle through the aorta, the '
          'largest artery in the body. It travels to the organs and tissues, gives '
          'up its oxygen and nutrients in the capillaries, collects wastes, and '
          'returns through the vena cava to the right atrium. This circuit is long '
          'and high in pressure.\n\n'
          'Because the blood passes through the heart twice, it keeps its pressure '
          'high throughout the body instead of dropping as it moves away.\n\n'
          'It is worth noting that the pulmonary artery is the only artery in the '
          'body that carries oxygen-poor blood, and the pulmonary vein is the only '
          'vein that carries oxygen-rich blood.',
      <String>[
        'Blood passes through the heart twice in a complete journey (double '
            'circulation).',
        'Pulmonary circulation connects the heart to the lungs.',
        'Systemic circulation connects the heart to the rest of the body.',
        'The pulmonary artery carries oxygen-poor blood; the pulmonary vein carries '
            'oxygen-rich blood.',
      ],
      durationMinutes: 11,
    ),
    lessonOf(
      'circ-7',
      'Major Components',
      'Let us bring together everything that makes up the circulatory system and '
          'check what each part contributes.\n\n'
          'The Heart is the pump. Its four chambers and valves keep blood moving '
          'in one direction and at the right pressure.\n\n'
          'Blood is the transport medium. Plasma carries dissolved nutrients and '
          'wastes, red blood cells carry oxygen, white blood cells defend against '
          'infection, and platelets repair damage.\n\n'
          'Arteries carry blood away from the heart under high pressure, and their '
          'thick elastic walls withstand the pumping force.\n\n'
          'Veins return blood to the heart at low pressure, aided by valves and by '
          'the movement of surrounding muscles.\n\n'
          'Capillaries are the exchange points. Their one-cell-thick walls let '
          'oxygen, nutrients, carbon dioxide and wastes pass between the blood and '
          'the body tissues.\n\n'
          'You can remember the five by the letters A-V-C plus the heart and blood: '
          'the heart pumps, blood carries, arteries and veins conduct, and '
          'capillaries connect and exchange. All five are needed for the system to '
          'work.',
      <String>[
        'The heart is the pump, blood is the transport medium.',
        'Arteries and veins are the conducting vessels.',
        'Capillaries are the sites of exchange.',
        'All five parts are needed for the system to function.',
      ],
      durationMinutes: 7,
    ),
    lessonOf(
      'circ-8',
      'Review',
      'This review brings the whole circulatory system together. Read it through, '
          'then try to explain each idea in your own words before taking the quiz.\n\n'
          'The circulatory system is a closed, double transport system. Blood is '
          'pumped by the heart through a continuous network of vessels, never '
          'leaving them.\n\n'
          'Remember the two circuits. In pulmonary circulation the right side of '
          'the heart sends blood to the lungs to collect oxygen. In systemic '
          'circulation the left side sends that oxygenated blood around the whole '
          'body and brings it back. Blood therefore passes through the heart twice '
          'per full circuit.\n\n'
          'Remember the pressure rule. Arteries work at high pressure and so are '
          'thick and elastic. Veins work at low pressure and so are thin, with '
          'valves to prevent backflow. Capillaries sit between them and are the '
          'site of all exchange.\n\n'
          'Remember the jobs. Red blood cells with haemoglobin carry oxygen. White '
          'blood cells fight infection. Platelets help clotting. Plasma carries '
          'nutrients, hormones and wastes.\n\n'
          'Finally, remember why it matters. Every cell in the body depends on this '
          'system. Without a steady supply of oxygen and nutrients and without '
          'waste removal, cells begin to fail within minutes. Keeping the system '
          'healthy through exercise, a balanced diet and avoiding smoking protects '
          'the heart and the vessels for life.',
      <String>[
        'It is a closed, double circulation system.',
        'Arteries are thick for high pressure; veins are thin with valves for low '
            'pressure.',
        'Capillaries are where all exchange happens.',
        'Healthy habits such as exercise and a balanced diet protect the system.',
      ],
      durationMinutes: 6,
    ),
  ];
}

List<QuizQuestion> _circulatoryQuestions() {
  return <QuizQuestion>[
    questionOf(
      'circ-q1',
      'What is the main function of the circulatory system?',
      <String>[
        'To digest food',
        'To transport oxygen, nutrients and wastes around the body',
        'To control body temperature only',
        'To produce hormones',
      ],
      'To transport oxygen, nutrients and wastes around the body',
      'The circulatory system is the body\'s transport network, moving oxygen, '
          'nutrients, hormones and wastes.',
    ),
    questionOf(
      'circ-q2',
      'How many chambers does the human heart have?',
      <String>['Two', 'Three', 'Four', 'Six'],
      'Four',
      'The heart has two atria and two ventricles - four chambers in total.',
    ),
    questionOf(
      'circ-q3',
      'Which chamber pumps blood to the whole body?',
      <String>[
        'Right atrium',
        'Right ventricle',
        'Left atrium',
        'Left ventricle',
      ],
      'Left ventricle',
      'The left ventricle has the thickest wall because it must pump blood through '
          'the entire body.',
    ),
    questionOf(
      'circ-q4',
      'What pigment in red blood cells binds oxygen?',
      <String>['Haemoglobin', 'Melanin', 'Keratin', 'Insulin'],
      'Haemoglobin',
      'Haemoglobin is the red iron-containing pigment that carries oxygen in red '
          'blood cells.',
    ),
    questionOf(
      'circ-q5',
      'Which blood vessels have the thinnest walls, only one cell thick?',
      <String>['Arteries', 'Veins', 'Capillaries', 'Aorta'],
      'Capillaries',
      'Capillary walls are one cell thick so substances can pass between blood and '
          'tissues.',
    ),
    questionOf(
      'circ-q6',
      'Which vessels contain valves to prevent backflow of blood?',
      <String>['Arteries', 'Veins', 'Both', 'Neither'],
      'Veins',
      'Veins carry blood at low pressure, so they need valves to keep blood moving '
          'towards the heart.',
    ),
    questionOf(
      'circ-q7',
      'What is the name of the double circuit that connects the heart to the lungs?',
      <String>[
        'Systemic circulation',
        'Pulmonary circulation',
        'Portal circulation',
        'Lymph circulation',
      ],
      'Pulmonary circulation',
      'Pulmonary circulation carries blood between the heart and the lungs to '
          'collect oxygen.',
    ),
    questionOf(
      'circ-q8',
      'Which is the only artery that carries oxygen-poor blood?',
      <String>[
        'The aorta',
        'The pulmonary artery',
        'The carotid artery',
        'The renal artery',
      ],
      'The pulmonary artery',
      'The pulmonary artery carries blood from the right ventricle to the lungs '
          'before it has picked up oxygen.',
    ),
    questionOf(
      'circ-q9',
      'Which blood cells are responsible for fighting infection?',
      <String>[
        'Red blood cells',
        'White blood cells',
        'Platelets',
        'Plasma cells only',
      ],
      'White blood cells',
      'White blood cells (leucocytes) defend the body against germs and disease.',
    ),
    questionOf(
      'circ-q10',
      'What is the liquid part of blood called?',
      <String>['Haemoglobin', 'Serum', 'Plasma', 'Lymph'],
      'Plasma',
      'Plasma is the water-based liquid that carries the blood cells, nutrients, '
          'hormones and wastes.',
    ),
  ];
}

List<LabLesson> _gscFundamentalsLessons() {
  return <LabLesson>[
    lessonOf(
      'gscf-1',
      'Living Things and Their Characteristics',
      'Science begins by asking what is alive. Living things share a set of '
          'characteristics that non-living things do not have.\n\n'
          '1. Nutrition - taking in food or nutrients for energy and growth. '
          'Plants make their own food; animals eat other organisms.\n\n'
          '2. Respiration - releasing energy from food, usually with oxygen.\n\n'
          '3. Growth - increasing in size and developing new parts. Unlike crystals, '
          'living things grow from within.\n\n'
          '4. Reproduction - producing new living things of the same kind.\n\n'
          '5. Response to stimuli - reacting to changes such as light, sound, heat '
          'or touch. A plant turning towards light is a response.\n\n'
          '6. Excretion - removing metabolic waste.\n\n'
          '7. Movement - the organism moves its parts or travels.\n\n'
          'All of these occur within a single cell in organisms such as bacteria, '
          'and are distributed across specialised cells in large organisms like '
          'humans.\n\n'
          'Movement in plants is slower but still real - the shoot bends towards '
          'light and roots grow downwards in response to gravity. This response is '
          'called tropism.',
      <String>[
        'Living things show nutrition, respiration, growth, reproduction, response, '
            'excretion and movement.',
        'Plants make their own food; animals obtain food by eating.',
        'Growth in living things comes from within, not by adding to the outside.',
        'Responding to a stimulus, such as light, is a sign of life.',
      ],
      durationMinutes: 9,
    ),
    lessonOf(
      'gscf-2',
      'Cells: The Basic Unit of Life',
      'The cell is the smallest unit that can carry out all the activities of life. '
          'Everything alive is made of cells, and in multicellular organisms cells '
          'specialise and work together.\n\n'
          'A typical plant cell has a cell wall made of cellulose for support, a '
          'cell membrane, a large permanent vacuole that stores water and keeps '
          'the cell firm, and large chloroplasts containing chlorophyll for '
          'photosynthesis.\n\n'
          'An animal cell has no cell wall, no chloroplasts and only small '
          'temporary vacuoles. This is why animal cells are usually more rounded.\n\n'
          'Both have a cell membrane that controls what enters and leaves, '
          'cytoplasm where the chemical reactions happen, and a nucleus containing '
          'DNA, the instructions for building and running the cell.\n\n'
          'Mitochondria are the organelles that release energy from food. They have '
          'folded inner membranes that increase the surface area for reactions, '
          'and are found in nearly all living cells.\n\n'
          'Some single-celled organisms such as Amoeba are made of just one cell, '
          'yet they move, feed, respond and reproduce - all inside that one cell.',
      <String>[
        'The cell is the smallest unit of life.',
        'Plant cells have a cell wall, large vacuole and chloroplasts; animal cells '
            'do not.',
        'The nucleus holds DNA, and mitochondria release energy from food.',
        'In multicellular organisms, specialised cells work together.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gscf-3',
      'The Human Body Systems',
      'The human body is made of several organ systems, each with a specific job. '
          'They work as one coordinated machine.\n\n'
          'The digestive system breaks food into small molecules that can be '
          'absorbed. Food travels down the oesophagus into the stomach, then the '
          'small intestine, where most digestion and absorption happens. The large '
          'intestine absorbs water.\n\n'
          'The respiratory system takes in oxygen and removes carbon dioxide. Air '
          'enters through the nose, travels down the trachea to the lungs, where '
          'gas exchange happens in the alveoli.\n\n'
          'The circulatory system transports oxygen, nutrients and wastes around '
          'the body using the heart, blood and vessels.\n\n'
          'The skeletal system gives the body shape and support and protects '
          'delicate organs. The muscular system moves the bones. Bone is living '
          'tissue that is constantly renewed.\n\n'
          'The nervous system, made of the brain, spinal cord and nerves, receives '
          'information and coordinates the response of all the other systems.\n\n'
          'The excretory system filters waste from the blood and removes it as '
          'urine through the kidneys, ureters, bladder and urethra.',
      <String>[
        'Each organ system has a specific job and they must work together.',
        'The digestive system breaks food down and absorbs nutrients in the small '
            'intestine.',
        'The respiratory system exchanges gases in the alveoli of the lungs.',
        'The nervous system coordinates and controls all other systems.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gscf-4',
      'Food, Nutrition and Balanced Diet',
      'Food is what we eat. Nutrition is the process of taking in and using food '
          'for growth, repair and energy. A diet is balanced when it contains the '
          'right amounts of every kind of nutrient.\n\n'
          'Carbohydrates are the main energy source. They include sugars, starches '
          'and fibres, and are found in rice, bread, potatoes and fruits.\n\n'
          'Proteins are the body\'s building materials, used to make muscles, '
          'enzymes and hormones. They come from eggs, milk, meat, fish, pulses and '
          'nuts.\n\n'
          'Fats and oils provide concentrated energy, protect organs and help absorb '
          'vitamins A, D, E and K. They come from oils, ghee, butter and nuts.\n\n'
          'Vitamins and minerals are needed in small amounts. They include iron '
          'for healthy blood, calcium for bones and teeth, iodine for the thyroid '
          'gland, and vitamin C for healthy skin and healing.\n\n'
          'Water makes up about two thirds of the body. It transports nutrients, '
          'regulates temperature and removes wastes. Dehydration causes tiredness, '
          'headache and poor concentration, so drinking water regularly matters.\n\n'
          'A rough daily balance is about six to eight portions of fruit and '
          'vegetables, some starchy food, protein, a little fat, and plenty of '
          'water, while limiting sugar and salt.',
      <String>[
        'Carbohydrates give energy, proteins build and repair the body.',
        'Fats are concentrated energy and help absorb vitamins A, D, E and K.',
        'Vitamins and minerals are needed in small amounts for normal working.',
        'About two thirds of the body is water, so regular water intake is '
            'essential.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gscf-5',
      'Digestion and Absorption',
      'Digestion breaks large pieces of food into small molecules that can pass '
          'into the blood. It happens both mechanically and chemically.\n\n'
          'In the mouth, teeth chew the food and saliva begins chemical digestion '
          'of starch by an enzyme called amylase. The tongue rolls the food into '
          'a bolus.\n\n'
          'The oesophagus carries food to the stomach by muscle contractions called '
          'peristalsis, not by gravity.\n\n'
          'The stomach mixes food with acid and the enzyme pepsin, which breaks '
          'protein into smaller pieces. The thick lining of the stomach protects '
          'it from its own acid. Food is released into the small intestine as a '
          'semi-liquid called chyme.\n\n'
          'Most digestion happens in the small intestine. Bile from the liver and '
          'pancreatic juice are added here. Folds and tiny projections called villi '
          'give this organ a very large surface area.\n\n'
          'Absorption happens mainly through the villi into the blood and lymph, '
          'and the blood carries the nutrients to every cell. The large intestine '
          'absorbs water and helps form faeces.',
      <String>[
        'Mechanical digestion breaks food physically; chemical digestion uses '
            'enzymes.',
        'Peristalsis moves food along the oesophagus, not gravity.',
        'Most digestion and absorption happen in the small intestine.',
        'Villi increase the surface area for absorption into the blood.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gscf-6',
      'Breathing and Respiration',
      'Breathing is the physical movement of air in and out. Respiration is the '
          'chemical process inside cells that releases energy from glucose.\n\n'
          'The respiratory system carries out breathing. Air enters through the '
          'nose and mouth, passes down the trachea, and reaches the lungs, which '
          'are spongy organs protected by the rib cage.\n\n'
          'In the lungs, branching airways end in tiny air sacs called alveoli. '
          'Their walls are one cell thick and surrounded by a dense network of '
          'capillaries, so oxygen diffuses into the blood and carbon dioxide '
          'diffuses out. The diaphragm, a dome-shaped muscle under the lungs, '
          'contracts to draw air in and relaxes to push it out.\n\n'
          'Respiration happens in every living cell. During aerobic respiration, '
          'glucose combines with oxygen to release energy, producing carbon dioxide '
          'and water. The chemical equation is: glucose plus oxygen gives carbon '
          'dioxide plus water, with energy released.\n\n'
          'If oxygen is unavailable, cells can respire without it, but they release '
          'much less energy. This is why deep breathing matters, and why air supply '
          'is important in any activity involving the lungs or the blood.',
      <String>[
        'Breathing moves air; respiration releases energy from glucose inside '
            'cells.',
        'Gas exchange happens in the alveoli of the lungs.',
        'The diaphragm controls the movement of air in and out.',
        'Aerobic respiration needs oxygen and releases carbon dioxide and water.',
      ],
      durationMinutes: 10,
    ),
    lessonOf(
      'gscf-7',
      'Skeletal and Muscular Systems',
      'The skeletal system gives the body its shape, supports it, protects '
          'delicate organs, stores minerals and produces blood cells.\n\n'
          'Bones meet at joints, which allow movement. Some joints are fixed, as '
          'in the skull, while others are freely movable, as at the shoulder and '
          'knee. Cartilage at the ends of bones gives a smooth surface and '
          'absorbs shock.\n\n'
          'The adult human skeleton has 206 bones. The longest is the femur in the '
          'thigh, and the smallest are in the ear. Bone marrow inside certain bones '
          'produces red blood cells.\n\n'
          'The muscular system works with the skeleton to produce movement. '
          'Muscles can only pull, never push, so they work in pairs: when one '
          'contracts it shortens, and its opposing partner lengthens.\n\n'
          'Skeletal muscles are attached to bones by tendons. They use stored '
          'energy from respiration, and they grow and become stronger with regular '
          'exercise, while lack of use makes them weak.\n\n'
          'Skeletal and muscular systems also work together in the chest to move '
          'air during breathing.',
      <String>[
        'The skeleton supports, protects and produces blood cells.',
        'Joints allow movement; some joints, like the skull, are fixed.',
        'An adult skeleton has 206 bones.',
        'Muscles work in opposing pairs because they can only pull, not push.',
      ],
      durationMinutes: 9,
    ),
    lessonOf(
      'gscf-8',
      'Environment and Its Components',
      'The environment is everything living and non-living that surrounds us, and '
          'it can be divided into two major components.\n\n'
          'The natural environment includes all living things and the non-living '
          'things around them. The non-living parts are air, water, soil, rock and '
          'sunlight, which together provide the conditions for life. Biotic means '
          'living and abiotic means non-living, and every ecosystem contains '
          'both.\n\n'
          'The man-made environment is everything humans have built, from roads and '
          'buildings to vehicles and machinery.\n\n'
          'A healthy environment is one in which living things can survive, grow '
          'and reproduce, and in which the air, water and soil are not polluted. '
          'Keeping it healthy depends on conserving natural resources, reducing '
          'waste, and not overusing anything faster than it can be renewed.\n\n'
          'Examples of interdependence are everywhere: bees pollinate crops, and '
          'plants provide food and shelter for animals. When one part of a '
          'ecosystem is damaged, the effects spread through the whole system.\n\n'
          'Simple daily actions such as saving water, reducing plastic, planting '
          'trees and disposing of waste correctly all contribute to protecting the '
          'environment.',
      <String>[
        'Biotic means living; abiotic means non-living.',
        'The natural environment contains both living and non-living components.',
        'A healthy environment is one where organisms can live, grow and reproduce.',
        'Saving resources and reducing waste helps protect the environment.',
      ],
      durationMinutes: 9,
    ),
  ];
}

List<QuizQuestion> _gscFundamentalsQuestions() {
  return <QuizQuestion>[
    questionOf(
      'gscf-q1',
      'What is the basic unit of life?',
      <String>['Atom', 'Cell', 'Organ', 'Tissue'],
      'Cell',
      'The cell is the smallest unit that can carry out all the activities of life.',
    ),
    questionOf(
      'gscf-q2',
      'Which organelle releases energy from food inside the cell?',
      <String>['Nucleus', 'Mitochondria', 'Chloroplast', 'Vacuole'],
      'Mitochondria',
      'Mitochondria carry out aerobic respiration and release energy from glucose.',
    ),
    questionOf(
      'gscf-q3',
      'Which of the following is present in a plant cell but not in an animal cell?',
      <String>['Cell membrane', 'Cell wall', 'Nucleus', 'Mitochondria'],
      'Cell wall',
      'A plant cell has a cellulose cell wall, a large permanent vacuole and '
          'chloroplasts; animal cells do not.',
    ),
    questionOf(
      'gscf-q4',
      'Where does most digestion and absorption take place?',
      <String>[
        'The mouth',
        'The stomach',
        'The small intestine',
        'The large intestine',
      ],
      'The small intestine',
      'Most digestion and absorption happens in the small intestine, whose villi '
          'give a huge surface area.',
    ),
    questionOf(
      'gscf-q5',
      'What is the name for the wave of muscle contractions that moves food along '
          'the oesophagus?',
      <String>['Diffusion', 'Peristalsis', 'Osmosis', 'Filtration'],
      'Peristalsis',
      'Peristalsis is the rhythmic muscular contraction that pushes food along, '
          'not gravity.',
    ),
    questionOf(
      'gscf-q6',
      'In which part of the lungs does gas exchange take place?',
      <String>['Bronchi', 'Trachea', 'Alveoli', 'Diaphragm'],
      'Alveoli',
      'The alveoli are tiny air sacs with one-cell-thick walls surrounded by '
          'capillaries.',
    ),
    questionOf(
      'gscf-q7',
      'Which muscle controls the movement of air in and out of the lungs?',
      <String>['Diaphragm', 'Biceps', 'Quadriceps', 'Tongue'],
      'Diaphragm',
      'The diaphragm contracts to draw air in and relaxes to push air out.',
    ),
    questionOf(
      'gscf-q8',
      'How many bones are there in the adult human skeleton?',
      <String>['156', '186', '206', '306'],
      '206',
      'The adult human skeleton has 206 bones; babies are born with more that fuse '
          'during growth.',
    ),
    questionOf(
      'gscf-q9',
      'Which nutrients does the body need in small amounts for normal working?',
      <String>['Carbohydrates', 'Vitamins and minerals', 'Proteins', 'Fats'],
      'Vitamins and minerals',
      'Vitamins and minerals are needed in small amounts, for example iron for '
          'blood and calcium for bones.',
    ),
    questionOf(
      'gscf-q10',
      'In a food chain, what does the term biotic refer to?',
      <String>['Non-living things', 'Living things', 'Water only', 'Sunlight'],
      'Living things',
      'Biotic means living, such as plants and animals; abiotic means non-living, '
          'such as air, water and soil.',
    ),
  ];
}
