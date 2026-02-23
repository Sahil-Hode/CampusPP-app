const speech = require('@google-cloud/speech');
const fs = require('fs');

class SpeechToTextService {
  constructor() {
    // Initialize Google Cloud Speech client
    this.client = new speech.SpeechClient({
      keyFilename: process.env.GOOGLE_APPLICATION_CREDENTIALS
    });
  }

  /**
   * Convert audio buffer to text using Google Cloud Speech-to-Text
   * @param {Buffer} audioBuffer - Audio data buffer
   * @param {Object} config - Audio configuration
   * @returns {Promise<string>} - Transcribed text
   */
  async transcribeAudio(audioBuffer, config = {}) {
    try {
      const {
        encoding = 'WEBM_OPUS',
        sampleRateHertz = 48000,
        languageCode = 'en-US',
      } = config;

      const audio = {
        content: audioBuffer.toString('base64'),
      };

      const requestConfig = {
        encoding: encoding,
        sampleRateHertz: sampleRateHertz,
        languageCode: languageCode,
        enableAutomaticPunctuation: true,
      };

      const request = {
        audio: audio,
        config: requestConfig,
      };

      console.log(`[Speech-to-Text] Processing audio (${languageCode})...`);
      
      const [response] = await this.client.recognize(request);
      const transcription = response.results
        .map(result => result.alternatives[0].transcript)
        .join('\n');

      console.log(`[Speech-to-Text] Transcription: ${transcription}`);
      return transcription;
    } catch (error) {
      console.error('[Speech-to-Text] Error:', error.message);
      throw new Error(`Speech-to-Text failed: ${error.message}`);
    }
  }

  /**
   * Stream audio for real-time transcription
   * @param {Object} config - Audio configuration
   * @returns {Stream} - Writable stream for audio chunks
   */
  createStreamingRecognition(config = {}) {
    const {
      encoding = 'WEBM_OPUS',
      sampleRateHertz = 48000,
      languageCode = 'en-US',
    } = config;

    const request = {
      config: {
        encoding: encoding,
        sampleRateHertz: sampleRateHertz,
        languageCode: languageCode,
        enableAutomaticPunctuation: true,
        interimResults: true,
      },
      interimResults: true,
    };

    return this.client.streamingRecognize(request);
  }
}

module.exports = new SpeechToTextService();
