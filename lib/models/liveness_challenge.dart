enum ChallengeType {
  blink,
  turnRight,
  turnLeft,
  smile,
}

/// Represents an active liveness challenge presented to the user.
class LivenessChallenge {
  final ChallengeType type;
  final String title;
  final String instruction;
  final String prompt;

  const LivenessChallenge({
    required this.type,
    required this.title,
    required this.instruction,
    required this.prompt,
  });

  static List<LivenessChallenge> standardChallenges() {
    return const [
      LivenessChallenge(
        type: ChallengeType.blink,
        title: 'Blink Challenge',
        instruction: 'Look straight at the camera and blink both eyes naturally.',
        prompt: 'Blink your eyes',
      ),
      LivenessChallenge(
        type: ChallengeType.turnRight,
        title: 'Head Rotation Challenge',
        instruction: 'Slowly turn your head slightly to the right.',
        prompt: 'Turn head to the right',
      ),
      LivenessChallenge(
        type: ChallengeType.turnLeft,
        title: 'Head Rotation Challenge',
        instruction: 'Slowly turn your head slightly to the left.',
        prompt: 'Turn head to the left',
      ),
    ];
  }
}
