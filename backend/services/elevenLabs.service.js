const axios = require('axios');

class ElevenLabsService {
    constructor() {
        this.apiKey = process.env.ELEVENLABS_API_KEY;
        this.voiceId = process.env.ELEVENLABS_VOICE_ID || 'pNInz6obpgDQGcFmaJgB';
        this.baseUrl = 'https://api.elevenlabs.io/v1';
    }

    /**
     * Convert text to speech using ElevenLabs
     * @param {string} text - Text to convert
     * @param {Object} options - Voice settings
     * @returns {Promise<Buffer>} - Audio buffer
     */
    async textToSpeech(text, options = {}) {
        try {
            const {
                voiceId = this.voiceId,
                modelId = 'eleven_multilingual_v2',
                stability = 0.5,
                similarityBoost = 0.5,
            } = options;

            console.log(`[ElevenLabs] Converting text to speech...`);

            const response = await axios.post(
                `${this.baseUrl}/text-to-speech/${voiceId}`,
                {
                    text: text,
                    model_id: modelId,
                    voice_settings: {
                        stability: stability,
                        similarity_boost: similarityBoost,
                    },
                },
                {
                    headers: {
                        'Content-Type': 'application/json',
                        'xi-api-key': this.apiKey,
                    },
                    responseType: 'arraybuffer',
                }
            );

            console.log(`[ElevenLabs] Audio generated successfully`);
            return Buffer.from(response.data);
        } catch (error) {
            console.error('[ElevenLabs] Error:', error.message);
            throw new Error(`Text-to-Speech failed: ${error.message}`);
        }
    }
}

module.exports = new ElevenLabsService();
