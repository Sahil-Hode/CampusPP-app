const { GoogleGenerativeAI } = require('@google/generative-ai');

class GeminiTTSService {
    constructor() {
        this.apiKey = process.env.GEMINI_API_KEY;
        if (!this.apiKey) {
            console.warn('⚠️  GEMINI_API_KEY not found in environment variables');
        }
        this.client = new GoogleGenerativeAI(this.apiKey);
        this.voiceName = process.env.GEMINI_TTS_VOICE || 'Vindemiatrix';
    }

    /**
     * Convert text to speech using Gemini TTS
     * @param {string} text - Text to convert to speech
     * @param {object} options - TTS options
     * @returns {Promise<Buffer>} - WAV audio buffer
     */
    async textToSpeech(text, options = {}) {
        if (!this.apiKey) {
            throw new Error('Gemini API key not configured');
        }

        const voiceName = options.voiceName || this.voiceName;

        try {
            console.log(`[Gemini TTS] Generating speech with voice: ${voiceName}`);

            // Configure the model with audio output
            const model = this.client.getGenerativeModel({
                model: 'gemini-2.5-flash-preview-tts',
                generationConfig: {
                    responseModalities: ['audio'],
                    speechConfig: {
                        voiceConfig: {
                            prebuiltVoiceConfig: {
                                voiceName: voiceName
                            }
                        }
                    }
                }
            });

            // Generate audio
            const result = await model.generateContent({
                contents: [{
                    role: 'user',
                    parts: [{ text: `Say the following text naturally: ${text}` }]
                }]
            });

            // Extract audio data (base64 PCM)
            const audioData = result.response.candidates[0].content.parts[0].inlineData.data;

            // Convert base64 to buffer
            const pcmBuffer = Buffer.from(audioData, 'base64');

            // Convert PCM to WAV by adding RIFF header
            const wavBuffer = this.pcmToWav(pcmBuffer, 24000, 1, 16);

            console.log(`[Gemini TTS] ✓ Generated ${wavBuffer.length} bytes of audio`);
            return wavBuffer;

        } catch (error) {
            console.error('[Gemini TTS] Error:', error.message);
            throw error;
        }
    }

    /**
     * Convert raw PCM to WAV format by adding RIFF header
     * @param {Buffer} pcmBuffer - Raw PCM audio data
     * @param {number} sampleRate - Sample rate in Hz (default: 24000)
     * @param {number} numChannels - Number of channels (default: 1 for mono)
     * @param {number} bitsPerSample - Bits per sample (default: 16)
     * @returns {Buffer} - WAV file buffer
     */
    pcmToWav(pcmBuffer, sampleRate = 24000, numChannels = 1, bitsPerSample = 16) {
        const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
        const blockAlign = numChannels * (bitsPerSample / 8);
        const dataSize = pcmBuffer.length;
        const headerSize = 44;
        const fileSize = headerSize + dataSize - 8;

        const header = Buffer.alloc(headerSize);

        // RIFF chunk descriptor
        header.write('RIFF', 0);
        header.writeUInt32LE(fileSize, 4);
        header.write('WAVE', 8);

        // fmt sub-chunk
        header.write('fmt ', 12);
        header.writeUInt32LE(16, 16); // Subchunk1Size (16 for PCM)
        header.writeUInt16LE(1, 20);  // AudioFormat (1 for PCM)
        header.writeUInt16LE(numChannels, 22);
        header.writeUInt32LE(sampleRate, 24);
        header.writeUInt32LE(byteRate, 28);
        header.writeUInt16LE(blockAlign, 32);
        header.writeUInt16LE(bitsPerSample, 34);

        // data sub-chunk
        header.write('data', 36);
        header.writeUInt32LE(dataSize, 40);

        // Combine header and PCM data
        return Buffer.concat([header, pcmBuffer]);
    }

    /**
     * Test the Gemini TTS service
     */
    async test() {
        try {
            console.log('[Gemini TTS] Testing service...');
            const audio = await this.textToSpeech('Hello! This is a test of the Gemini text to speech service.');
            console.log('[Gemini TTS] ✓ Test successful');
            return true;
        } catch (error) {
            console.error('[Gemini TTS] ✗ Test failed:', error.message);
            return false;
        }
    }
}

module.exports = new GeminiTTSService();
