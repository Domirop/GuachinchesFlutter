/// Taxonomía de eventos de producto (nombres estables que alimentan los
/// dashboards de PostHog). Centralizada para no tener strings sueltas.
class AnalyticsEvents {
  AnalyticsEvents._();

  // Onboarding
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStep = 'onboarding_step_completed';
  static const onboardingFinished = 'onboarding_finished';

  // Canarismo del día
  static const canarismoOpened = 'canarismo_opened';
  static const canarismoShared = 'canarismo_shared';

  // Restaurante / descubrimiento
  static const restaurantDirections = 'restaurant_directions_tapped';
  static const favoriteToggled = 'favorite_toggled';
}
