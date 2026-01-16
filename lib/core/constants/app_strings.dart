class AppStrings {
  // a secret easter egg message
  static const String secretNote = "Crafted with love, just for you. Always!";

  // Detailed biological insights for the Easter Egg overlay
  static String getPhaseDetailedInfo(String phase) {
    switch (phase) {
      case "Menstrual Phase":
        return "During this time, your progesterone and estrogen levels are at their lowest. Your body is shedding the uterine lining. It's completely normal to feel tired or have lower energy. Focus on iron-rich foods, stay hydrated, and give yourself permission to rest deeply. You are incredibly strong.";
      case "Follicular Phase":
        return "Your body is preparing for the next chapter. Estrogen is beginning to rise, which often brings a boost in energy, creativity, and a more positive outlook. It's a great time to start new projects, exercise, and socialize. Your brain is at its most resilient right now!";
      case "Ovulatory Phase":
        return "This is your 'glow' phase. Estrogen peaks and testosterone rises, often making you feel more confident, communicative, and energetic. Your skin might look clearer and your social battery is at its highest. You are literally radiating energy today.";
      case "Luteal Phase":
        return "Progesterone is now the dominant hormone, preparing your body for rest. You might find yourself wanting more 'me-time' or feeling more sensitive. It's the perfect time for grounding activities like yoga, journaling, or cozying up with a book. Listen to your body's need for peace.";
      default:
        return "Your body is a complex and beautiful system, always working to keep you healthy and balanced.";
    }
  }

  // Mood Categories
  static const List<String> moods = [
    "Energetic",
    "Happy",
    "Calm",
    "Sensitive",
    "Anxious",
    "Tired",
  ];

  // Physical Symptoms
  static const List<String> physical = [
    "Cramps",
    "Bloating",
    "Headache",
    "Backache",
    "Tender",
    "Normal",
  ];

  // Skin States
  static const List<String> skin = [
    "Clear",
    "Glowing",
    "Oily",
    "Dry",
    "Breakouts",
  ];

  // Discharge or Flow
  static const List<String> flow = [
    "None",
    "Light",
    "Medium",
    "Heavy",
    "Spotting",
  ];

  // Sleep Quality
  static const List<String> sleep = [
    "Deep Sleep",
    "Restless",
    "Insomnia",
    "Vivid Dreams",
  ];
}
