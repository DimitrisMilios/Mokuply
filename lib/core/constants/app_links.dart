/// External URLs and in-app route names shared by the home page and the
/// info pages.
class AppLinks {
  AppLinks._();

  static const String hostedApp = 'https://mockuply.web.app';
  static const String repo = 'https://github.com/DimitrisMilios/Mokuply';
  static const String issues = '$repo/issues';
  static const String license = '$repo/blob/main/LICENSE';
  static const String mcpGuide = '$repo/blob/main/docs/MCP_AI_AGENT_GUIDE.md';
  static const String nodeJs = 'https://nodejs.org';

  // In-app routes (hash URLs on the web: mockuply.web.app/#/privacy).
  static const String privacyRoute = '/privacy';
  static const String termsRoute = '/terms';
  static const String connectAiRoute = '/connect-ai';
}
