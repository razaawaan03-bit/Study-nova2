/// AI configuration for Study Nova.
///
/// Both AI flows are deliberately server-side. The Flutter app never stores a
/// live Gemini API key at build time, and never sends that key to the browser or
/// the device runtime.
///
/// ## Study From Photo
///
/// The app calls the deployed `study-from-photo` Supabase Edge Function, which
/// reads the key from the server-side secret `STUDY_PHOTO_GEMINI_KEY`.
///
/// ## Course Maker
///
/// The app calls the deployed `course-maker-ai` Supabase Edge Function, which
/// reads the key from the server-side secret `COURSE_MAKER_GEMINI_KEY`.
///
/// Never hard-code a Google key in the repository or in a Flutter build.
/// The only supported app runtime configuration is the Supabase anon key.
const String googleGenerativeAIKey = String.fromEnvironment(
  'GOOGLE_GENERATIVE_AI_KEY',
  defaultValue: '',
);

/// Legacy compatibility model name used by older local tests and older direct
/// client-side paths. The actual server-side Course Maker flow chooses the model
/// in the Edge Function environment and does not require this value.
const String geminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-2.5-flash',
);
