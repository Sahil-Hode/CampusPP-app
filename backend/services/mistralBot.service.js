const Mistral = require('@mistralai/mistralai');
const fs = require('fs');
const path = require('path');

class MistralBotService {
    constructor() {
        this.client = new Mistral({
            apiKey: process.env.MISTRAL_API_KEY
        });

        // Store conversation history per session
        this.sessions = new Map();

        // History file path
        this.historyFile = path.join(__dirname, '../data/mistral_history.json');
        this.loadHistory();
    }

    /**
     * Load conversation history from file
     */
    loadHistory() {
        try {
            if (fs.existsSync(this.historyFile)) {
                const data = fs.readFileSync(this.historyFile, 'utf8');
                const history = JSON.parse(data);
                this.sessions = new Map(Object.entries(history));
                console.log('[Mistral] History loaded');
            }
        } catch (error) {
            console.error('[Mistral] Error loading history:', error.message);
        }
    }

    /**
     * Save conversation history to file
     */
    saveHistory() {
        try {
            const dir = path.dirname(this.historyFile);
            if (!fs.existsSync(dir)) {
                fs.mkdirSync(dir, { recursive: true });
            }

            const history = Object.fromEntries(this.sessions);
            fs.writeFileSync(this.historyFile, JSON.stringify(history, null, 2));
        } catch (error) {
            console.error('[Mistral] Error saving history:', error.message);
        }
    }

    /**
     * Get or create session history
     * @param {string} sessionId - Session identifier
     * @returns {Array} - Message history
     */
    getSessionHistory(sessionId) {
        if (!this.sessions.has(sessionId)) {
            this.sessions.set(sessionId, []);
        }
        return this.sessions.get(sessionId);
    }

    /**
     * Clear session history
     * @param {string} sessionId - Session identifier
     */
    clearSession(sessionId) {
        this.sessions.delete(sessionId);
        this.saveHistory();
        console.log(`[Mistral] Session ${sessionId} cleared`);
    }

    /**
     * Generate AI response using Mistral
     * @param {string} userMessage - User's message
     * @param {string} sessionId - Session identifier
     * @param {Object} options - Additional options
     * @returns {Promise<string>} - AI response
     */
    async generateResponse(userMessage, sessionId, options = {}) {
        try {
            const {
                systemPrompt = 'You are a helpful and knowledgeable teacher named Deepak. You are mentoring a student.',
                language = 'English',
                studentContext = null,
                maxTokens = 200,
            } = options;

            // Build system prompt
            let fullSystemPrompt = `${systemPrompt}\n\nCRITICAL INSTRUCTIONS:\n1. ALWAYS reply in ${language}. Use perfect grammar and natural phrasing.\n2. If the user asks a general knowledge or academic question, answer it accurately and concisely.\n3. Use the provided STUDENT DATA ONLY if the user asks something personal about themselves.\n4. Keep answers under 3 sentences.`;

            if (studentContext) {
                fullSystemPrompt += `\n\nSTUDENT DATA (Use only if relevant to the question):\n${studentContext}`;
            }

            // Get session history
            const history = this.getSessionHistory(sessionId);

            // Build messages array
            const messages = [
                { role: 'system', content: fullSystemPrompt },
                ...history.slice(-20), // Keep last 20 messages for context
                { role: 'user', content: userMessage }
            ];

            console.log(`[Mistral] Generating response for session ${sessionId}...`);

            // Call Mistral API
            const response = await this.client.chat.complete({
                model: 'mistral-small-latest',
                messages: messages,
                maxTokens: maxTokens,
                temperature: 0.7,
            });

            const aiResponse = response.choices[0].message.content;

            // Update history
            history.push({ role: 'user', content: userMessage });
            history.push({ role: 'assistant', content: aiResponse });

            // Keep only last 20 messages
            if (history.length > 20) {
                this.sessions.set(sessionId, history.slice(-20));
            }

            this.saveHistory();

            console.log(`[Mistral] Response generated: ${aiResponse.substring(0, 50)}...`);
            return aiResponse;
        } catch (error) {
            console.error('[Mistral] Error:', error.message);
            throw new Error(`Mistral AI failed: ${error.message}`);
        }
    }

    /**
     * Send text message (for testing without speech)
     * @param {string} message - Text message
     * @param {string} sessionId - Session identifier
     * @param {Object} options - Additional options
     * @returns {Promise<string>} - AI response
     */
    async sendTextMessage(message, sessionId, options = {}) {
        return this.generateResponse(message, sessionId, options);
    }
}

module.exports = new MistralBotService();
