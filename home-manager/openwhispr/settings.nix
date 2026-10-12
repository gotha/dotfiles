{
  environment = {
    LOCAL_TRANSCRIPTION_PROVIDER = "nvidia";
    PARAKEET_MODEL = "orukeet-v0.1.0";
    DICTATION_LANGUAGE = "auto";
    CLEANUP_PROVIDER = "local";
    LOCAL_CLEANUP_MODEL = "qwen3.5-9b-q4_k_m";
    DICTATION_AGENT_PROVIDER = "local";
    LOCAL_DICTATION_AGENT_MODEL = "qwen3.5-9b-q4_k_m";
    DICTATION_KEY = "RightCommand";
    ACTIVATION_MODE = "push";
    FLOATING_ICON_AUTO_HIDE = "false";
    START_MINIMIZED = "true";
  };

  localStorage = {
    # Keep the 1.10.2 migrations from replacing the selected providers on first launch.
    _agentModeMigrated = "1";
    _dictationAgentSeeded = "1";
    _llmScopeKeysMigrated = "1";
    _providerSettingsMigrated = "1";
    uploadTranscriptionMigrated = true;

    activationMode = "push";
    audioCuesEnabled = true;
    autoLearnCorrections = true;
    autoUpdatesEnabled = true;
    dictationKey = "RightCommand";
    floatingIconAutoHide = false;
    keepTranscriptionInClipboard = true;
    microphoneSelectionMode = "system";
    pauseMediaOnDictation = true;
    startMinimized = true;
    voiceAgentScreenContext = true;

    transcriptionMode = "local";
    useLocalWhisper = true;
    localTranscriptionProvider = "nvidia";
    parakeetModel = "orukeet-v0.1.0";

    meetingFollowsReasoning = false;
    meetingFollowsTranscription = false;
    meetingTranscriptionMode = "local";
    meetingUseLocalWhisper = true;
    meetingLocalTranscriptionProvider = "nvidia";
    meetingCloudTranscriptionMode = "openwhispr";
    meetingCloudTranscriptionModel = "gpt-4o-mini-transcribe";
    meetingCloudTranscriptionProvider = "openai";

    uploadTranscriptionMode = "local";
    uploadUseLocalWhisper = true;
    uploadLocalTranscriptionProvider = "nvidia";
    uploadCloudTranscriptionMode = "openwhispr";
    uploadCloudTranscriptionModel = "gpt-4o-mini-transcribe";
    uploadCloudTranscriptionProvider = "openai";
    uploadDiarizationEnabled = false;
    uploadDiarizationNumSpeakers = "";

    useCleanupModel = true;
    cleanupMode = "local";
    cleanupProvider = "qwen";
    cleanupModel = "qwen3.5-9b-q4_k_m";
    cleanupCloudMode = "byok";
    cleanupCloudBaseUrl = "";
    cleanupRemoteUrl = "";

    useDictationAgent = true;
    dictationAgentMode = "local";
    dictationAgentProvider = "qwen";
    dictationAgentModel = "qwen3.5-9b-q4_k_m";
    dictationAgentCloudBaseUrl = "";
    dictationAgentRemoteUrl = "";

    chatAgentMode = "local";
    chatAgentProvider = "qwen";
    chatAgentModel = "qwen3.5-9b-q4_k_m";
    chatAgentCloudBaseUrl = "";
    chatAgentRemoteUrl = "";

    noteFormattingMode = "local";
    noteFormattingProvider = "qwen";
    noteFormattingModel = "qwen3.5-9b-q4_k_m";
    noteFormattingCloudBaseUrl = "";
    noteFormattingRemoteUrl = "";

    translationMode = "local";
    translationProvider = "qwen";
    translationModel = "qwen3.5-9b-q4_k_m";
    translationCloudBaseUrl = "";
    translationRemoteUrl = "";

    transcriptionModelByProvider = {
      "dictation:openai" = "gpt-4o-mini-transcribe";
      "meeting:openai" = "gpt-4o-mini-transcribe";
      "upload:openai" = "gpt-4o-mini-transcribe";
    };
  };
}
