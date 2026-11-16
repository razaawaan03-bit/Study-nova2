import '../models/lab_model.dart';
import 'lab_content/gk_labs.dart';
import 'lab_content/gsc_labs.dart';
import 'lab_content/sst_labs.dart';

/// Bundled starter content for Study Nova Labs.
///
/// This content ships with the app so that Labs work offline / without any
/// AI provider. The service layer may also load Labs from Supabase, but these
/// bundled Labs are always available as a fallback.
class LabContentData {
  const LabContentData._();

  static const String tagline = 'Learn something new every day.';

  /// Builds the complete catalogue of standard (non-custom) Labs.
  static List<LabModel> starterLabs() {
    return <LabModel>[...gscLabs(), ...gkLabs(), ...sstLabs()];
  }
}
