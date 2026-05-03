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

  // notification page strings
  // Inside class AppStrings
  static String getTimeBasedGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning, $name";
    if (hour < 17) return "Good Afternoon, $name";
    return "Good Evening, $name";
  }

  static const String systemCheckTitle = "Guardian System Check";
  static const String systemCheckBody =
      "Flowlytics is awake and watching the clock! Your next reminder is synced.";

  static const String wellnessReportTitle = "Wellness Overview";
  static const String medicalDisclaimer =
      "Medical Disclaimer: Flowlytics is an educational tool. The predictions provided are estimates based on historical data. This report is NOT a substitute for professional medical advice or treatment. It must NOT be used for contraception.";

  static const String legalDisclaimer =
      "Legal Disclaimer: This document was generated locally. Once exported, data security is the sole responsibility of the user. Flowlytics are not liable for unauthorized sharing.";

  // FAQ
  // Detailed FAQ Data for Flowlytics
  static const List<Map<String, String>> faqs = [
    {
      "q": "Is Flowlytics truly private and offline?",
      "a":
          "Yes. Flowlytics operates with zero internet permissions. There are no remote servers, no trackers, and no cloud backups. Your data lives exclusively in the encrypted vault on your physical device. If you lose your phone, your data is gone—this is the price of total privacy.",
    },
    {
      "q": "What happens if I forget my Security Answer?",
      "a":
          "Because we are 100% offline, there is no 'Reset Password' link. Your security answer is the only key to the vault. If you forget it, your data is permanently unrecoverable by design. We have no backdoor to help you.",
    },
    {
      "q": "How accurate is the 'Navigator' vs. Real Biology?",
      "a":
          "The Navigator uses ML to nudge dates based on symptoms like spotting or cramps. However, human biology is not a calculator. Stress, illness, and travel can shift cycles in ways no algorithm can predict. Always listen to your body first.",
    },
    {
      "q": "Is the App Lock and Biometrics secure?",
      "a":
          "We utilize your device's native hardware security for biometrics. While highly secure, no system is impenetrable. Using biometrics is at your own risk; if your device hardware is compromised, your local vault could be at risk.",
    },
    {
      "q": "Who is responsible for my exported PDF reports?",
      "a":
          "Once you export a Wellness Report, it is a standard PDF. If you share it via unencrypted channels like Email or WhatsApp, you are sharing sensitive medical data. Flowlytics is not responsible for the security of your data once it leaves the app's environment.",
    },
    {
      "q": "Why does the app need no permissions?",
      "a":
          "We believe your cycle is your business. By requiring no internet, we ensure that even if our company were sold or hacked, your data remains safely on your own phone, inaccessible to anyone but you.",
    },
  ];

  // Release History
  static const List<Map<String, dynamic>> changelog = [
    {
      "version": "0.1.0",
      // "date": "Month and Year",
      "changes": [
        "Initial release of Flowlytics",
        "Customised ML-algorithm for cycle predictions",
        "Private local encryption vault",
        "Scrollable charts for analytics",
        "Biometric & PIN security lock",
        "Classic pink theme with custom moods",
      ],
    },
  ];

  // Hormone Graph Easter Egg
  static const String hormoneGraphEasterEgg =
      "This wave shows your hidden energy. Estrogen brings creativity and focus, the Testosterone spike brings confidence, and Progesterone acts as your body's natural relaxation signal. Listen to the waves!";
}
