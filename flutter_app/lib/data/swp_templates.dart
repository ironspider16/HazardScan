import '../models/swp.dart';

const swpTemplates = <SwpTemplate>[
  SwpTemplate(
    id: 'wah_ladder',
    category: SwpCategory.wah,
    title: 'Work at Height — Ladder',
    checklist: [
      'Inspect ladder condition (no broken steps, cracks, bends)',
      'Ladder footing stable and secured',
      'Correct angle/positioning used',
      'PPE worn (helmet, safety shoes, etc.)',
      'Work area cordoned with signage/barricade if needed',
      'Buddy system in place',
    ],
  ),
  SwpTemplate(
    id: 'wah_vertical_lifter',
    category: SwpCategory.wah,
    title: 'Work at Height — Vertical Lifter',
    checklist: [
      'Pre-use checklist completed',
      'Set up by trained personnel',
      '4 outriggers installed and locked',
      'Work area cordoned with warning signage',
      'Buddy system practiced',
      'Do not step out of guardrail when elevated',
    ],
  ),
  SwpTemplate(
    id: 'wah_scaffold',
    category: SwpCategory.wah,
    title: 'Work at Height — Scaffold',
    checklist: [
      'Scaffold inspected and tagged (if applicable)',
      'Guardrails/toeboards installed',
      'Base plates and bracing secure',
      'Access ladder secured',
      'Area cordoned and signage placed',
      'PPE worn and buddy system in place',
    ],
  ),
  SwpTemplate(
    id: 'chem_ln2_transport',
    category: SwpCategory.ln2,
    title: 'Chemical Handling — LN2 Transportation',
    checklist: [
      'Approved container used and properly labelled',
      'PPE worn (cryogenic gloves/face shield where required)',
      'Transport route confirmed (avoid public/crowded areas)',
      'Spill/emergency plan understood',
      'Area readiness verified at destination',
    ],
  ),
  SwpTemplate(
    id: 'chem_ln2_refill',
    category: SwpCategory.ln2,
    title: 'Chemical Handling — LN2 Refilling (Designated Area)',
    checklist: [
      'Refill only at designated area',
      'PPE worn (cryogenic gloves/face shield where required)',
      'Ventilation adequate and oxygen monitor (if required) checked',
      'Connections/hoses inspected before refilling',
      'Buddy system practiced',
    ],
  ),
  SwpTemplate(
    id: 'confined_space',
    category: SwpCategory.confined,
    title: 'Working in Confined Space',
    checklist: [
      'Entry permit obtained and valid',
      'Atmospheric testing completed',
      'Ventilation set up if required',
      'Rescue plan and standby person in place',
      'Communication method confirmed',
      'PPE worn (as required)',
    ],
  ),
];

List<SwpTemplate> templatesByCategory(SwpCategory c) =>
    swpTemplates.where((t) => t.category == c).toList();
