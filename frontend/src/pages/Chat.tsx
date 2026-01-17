import { useState, useRef, useEffect } from 'react';
import { Send, Image as ImageIcon, Mic, X, Loader2 } from 'lucide-react';
import clsx from 'clsx';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

interface Message {
    id: number;
    role: 'user' | 'assistant';
    content: string;
    image?: string;
}

export const Chat = () => {
    const { getToken } = useAuth();
    const navigate = useNavigate();
    const [messages, setMessages] = useState<Message[]>([
        { id: 1, role: 'assistant', content: 'Hello! I am your Campus Assistant. Ask me anything about your schedule, exams, or notices.' }
    ]);
    const [input, setInput] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [selectedImage, setSelectedImage] = useState<File | null>(null);
    const [imagePreview, setImagePreview] = useState<string | null>(null);
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [reminders, setReminders] = useState<any[]>([]);

    useEffect(() => {
        const fetchReminders = async () => {
            if (!getToken) return;
            try {
                const token = await getToken();
                const res = await fetch(`${import.meta.env.VITE_API_URL}/api/reminders`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                const data = await res.json();
                if (!data.error) {
                    // Filter for pending and sort by date
                    const pending = data.filter((r: any) => !r.is_completed).sort((a: any, b: any) => new Date(a.due_at).getTime() - new Date(b.due_at).getTime());
                    setReminders(pending);
                }
            } catch (err) {
                console.error("Failed to fetch reminders for chat context", err);
            }
        };
        fetchReminders();
    }, [getToken]);

    const handleSend = async () => {
        if ((!input.trim() && !selectedImage) || isLoading) return;

        const userMsg: Message = {
            id: Date.now(),
            role: 'user',
            content: input,
            image: imagePreview || undefined
        };

        setMessages(prev => [...prev, userMsg]);
        setInput('');
        setSelectedImage(null);
        setImagePreview(null);
        setIsLoading(true);

        try {
            const token = await getToken();
            // TODO: Handle image upload to Supabase Storage and send URL to backend
            // For now, simpler text chat integration

            let response;
            if (selectedImage) {
                const formData = new FormData();
                // formData.append('userId', user?.id || 'anon'); // Backend extracts from token
                formData.append('prompt', userMsg.content || 'Describe this image');
                formData.append('image', selectedImage);
                // formData.append('conversationId', 'default');

                response = await fetch(`${import.meta.env.VITE_API_URL}/api/chat/image`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${token}`
                        // Content-Type not set for FormData, browser sets boundary
                    },
                    body: formData
                });
            } else {
                response = await fetch(`${import.meta.env.VITE_API_URL}/api/chat/text`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'Authorization': `Bearer ${token}`
                    },
                    body: JSON.stringify({
                        // userId: user?.id, // Backend extracts from token
                        message: userMsg.content,
                        conversationId: 'default'
                    })
                });
            }

            if (!response.ok) throw new Error('Failed to get response');

            const data = await response.json();

            setMessages(prev => [...prev, {
                id: Date.now() + 1,
                role: 'assistant',
                content: data.response || data.message
            }]);

        } catch (error) {
            console.error(error);
            setMessages(prev => [...prev, {
                id: Date.now() + 1,
                role: 'assistant',
                content: "Sorry, I encountered an error connecting to the server."
            }]);
        } finally {
            setIsLoading(false);
        }
    };

    const [isListening, setIsListening] = useState(false);

    const toggleListening = () => {
        const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

        if (!SpeechRecognition) {
            alert("Your browser does not support Speech Recognition. Try Chrome or Edge.");
            return;
        }

        const recognition = new SpeechRecognition();
        recognition.continuous = false;
        recognition.interimResults = false;
        recognition.lang = 'en-US';

        if (isListening) {
            recognition.stop();
            setIsListening(false);
            return;
        }

        setIsListening(true);
        recognition.start();

        recognition.onresult = (event: any) => {
            const transcript = event.results[0][0].transcript;
            setInput(prev => prev + (prev ? ' ' : '') + transcript);
            setIsListening(false);
        };

        recognition.onerror = (event: any) => {
            console.error(event.error);
            setIsListening(false);
        };

        recognition.onend = () => {
            setIsListening(false);
        };
    };

    const handleImageSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            setSelectedImage(file);
            const reader = new FileReader();
            reader.onloadend = () => {
                setImagePreview(reader.result as string);
            };
            reader.readAsDataURL(file);
        }
    };

    return (
        <div className="flex h-[calc(100vh-6rem)] gap-6">
            {/* Main Chat Area */}
            <div className="flex-1 flex flex-col bg-gray-900 rounded-2xl border border-gray-800 overflow-hidden shadow-2xl">
                <div className="flex-1 p-6 overflow-y-auto space-y-6">
                    {messages.map((msg) => (
                        <div key={msg.id} className={clsx("flex", msg.role === 'user' ? "justify-end" : "justify-start")}>
                            <div className={clsx(
                                "max-w-[80%] rounded-2xl p-4 text-sm leading-relaxed",
                                msg.role === 'user'
                                    ? "bg-indigo-600 text-white rounded-br-sm"
                                    : "bg-gray-800 text-gray-200 rounded-bl-sm"
                            )}>
                                {msg.image && (
                                    <img src={msg.image} alt="Upload" className="mb-2 rounded-lg max-h-60 object-cover" />
                                )}
                                {msg.content}
                            </div>
                        </div>
                    ))}
                    {isLoading && (
                        <div className="flex justify-start">
                            <div className="bg-gray-800 text-gray-200 rounded-2xl p-4 rounded-bl-sm flex items-center gap-2">
                                <Loader2 size={16} className="animate-spin text-indigo-400" />
                                <span className="text-xs text-gray-400">Thinking...</span>
                            </div>
                        </div>
                    )}
                </div>

                {/* Input Area */}
                <div className="p-4 bg-gray-950 border-t border-gray-800">
                    {imagePreview && (
                        <div className="mb-2 relative inline-block">
                            <img src={imagePreview} alt="Preview" className="h-20 rounded-lg border border-gray-700" />
                            <button
                                onClick={() => { setSelectedImage(null); setImagePreview(null); }}
                                className="absolute -top-2 -right-2 bg-red-500 rounded-full p-1 text-white hover:bg-red-600"
                            >
                                <X size={12} />
                            </button>
                        </div>
                    )}
                    <div className="flex items-center gap-2 bg-gray-900 p-2 rounded-xl border border-gray-800 focus-within:border-indigo-500/50 transition-colors">
                        <button
                            onClick={() => fileInputRef.current?.click()}
                            className="p-2 text-gray-400 hover:text-indigo-400 hover:bg-gray-800 rounded-lg transition-colors"
                        >
                            <ImageIcon size={20} />
                        </button>
                        <input
                            type="file"
                            ref={fileInputRef}
                            onChange={handleImageSelect}
                            className="hidden"
                            accept="image/*"
                        />
                        <button
                            onClick={toggleListening}
                            className={clsx(
                                "p-2 rounded-lg transition-colors",
                                isListening ? "bg-red-500/20 text-red-400 hover:bg-red-500/30 animate-pulse" : "text-gray-400 hover:text-indigo-400 hover:bg-gray-800"
                            )}>
                            <Mic size={20} />
                        </button>
                        <input
                            type="text"
                            value={input}
                            onChange={(e) => setInput(e.target.value)}
                            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                            placeholder="Ask anything..."
                            className="flex-1 bg-transparent border-none focus:ring-0 text-white placeholder-gray-500 outline-none"
                        />
                        <button onClick={handleSend} disabled={isLoading || (!input && !selectedImage)} className="p-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                            <Send size={18} />
                        </button>
                    </div>
                </div>
            </div>

            {/* Sidebar (Context & Reminders) */}
            <div className="w-80 hidden lg:flex flex-col gap-6">
                {/* Suggested Queries */}
                <div className="flex-1 bg-gray-900 rounded-2xl border border-gray-800 p-6 flex flex-col">
                    <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider mb-4">Suggested</h3>
                    <div className="flex-1 space-y-3 overflow-y-auto custom-scrollbar">
                        {[
                            { label: "What's my next class?", icon: "📅" },
                            { label: "Do I have any exams coming up?", icon: "📝" },
                            { label: "Show my pending assignments", icon: "📌" },
                            { label: "What are the library timings?", icon: "📚" },
                            { label: "Who is the HOD of CSE?", icon: "👥" },
                            { label: "Summarize the latest notice", icon: "📢" },
                        ].map((suggestion, idx) => (
                            <button
                                key={idx}
                                onClick={() => setInput(suggestion.label)}
                                className="w-full text-left p-3 rounded-xl bg-gray-800/50 hover:bg-indigo-600/20 hover:text-indigo-300 border border-gray-700/50 hover:border-indigo-500/30 transition-all group flex items-center gap-3"
                            >
                                <span className="text-lg group-hover:scale-110 transition-transform">{suggestion.icon}</span>
                                <span className="text-sm text-gray-300 group-hover:text-indigo-200">{suggestion.label}</span>
                            </button>
                        ))}
                    </div>
                </div>

                {/* Upcoming Reminders */}
                <div className="h-1/3 bg-gray-900 rounded-2xl border border-gray-800 p-6 overflow-y-auto">
                    <div className="flex items-center justify-between mb-4">
                        <h3 className="text-sm font-semibold text-gray-400 uppercase tracking-wider">Upcoming</h3>
                        <button onClick={() => navigate('/app/reminders')} className="text-xs text-indigo-400 hover:text-indigo-300">View All</button>
                    </div>
                    <div className="space-y-3">
                        {reminders.length === 0 && <p className="text-gray-500 text-xs">No pending tasks.</p>}
                        {reminders.slice(0, 3).map((r: any) => (
                            <div key={r.id} className="flex items-center gap-3 text-sm text-gray-300">
                                <div className={`w-1.5 h-1.5 rounded-full ${r.category === 'Exam' ? 'bg-red-400' : 'bg-emerald-400'}`}></div>
                                <span className="truncate">{r.title}</span>
                                <span className="text-xs text-gray-500 ml-auto">{new Date(r.due_at).toLocaleDateString(undefined, { weekday: 'short', timeZone: 'UTC' })}</span>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};
