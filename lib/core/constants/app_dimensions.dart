/// Centralized spacing, sizing, and typography scale tokens.
class AppDimensions {
  AppDimensions._();

  // Layout
  static const double navbarHeight = 72.0;
  static const double sidebarWidth = 380.0;
  static const double railWidth = 84.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;

  // Cards
  static const double cardPadding = 16.0;

  // Border radius (generic)
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  // Clay radii and depth
  static const double radiusClaySm = 16.0; // list rows, inputs, interactive chips
  static const double radiusClay = 24.0; // buttons, tiles, small cards
  static const double radiusClayLg = 32.0; // panels, dialogs, big cards
  static const double radiusClayXl = 40.0; // hero card, navbar
  static const double clayDepth = 6.0; // default inner shadow offset
  static const double clayLift = 18.0; // default outer shadow offset (y)

  // Font Sizes
  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontBody = 13.0;
  static const double fontMd = 14.0;
  static const double fontLg = 15.0;
  static const double fontXl = 20.0;
}
