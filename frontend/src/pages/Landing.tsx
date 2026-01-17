import { useNavigate } from 'react-router-dom';
import { FadeIn } from '../components/ui/AnimatedComponents';
import { TypingText } from '../components/ui/TypingText';
import { ArrowRight, MessageSquare, Mic, Image as ImageIcon } from 'lucide-react';
import { Canvas } from '@react-three/fiber';
import { CampusModel } from '../components/3d/CampusModel';
import { Suspense } from 'react';

export const Landing = () => {
    const navigate = useNavigate();

    const PHRASES = [
        "Your Intelligent Campus Companion",
        "Navigate Campus Life Effortlessly",
        "Never Miss a Class or a Deadline",
        "Your AI-Powered Academic Guide"
    ];

    return (
        <div className="min-h-screen bg-black text-white selection:bg-indigo-500/30 overflow-x-hidden">
            {/* Nav */}
            <nav className="flex items-center justify-between p-6 px-8 max-w-7xl mx-auto z-50 relative">
                <div className="text-xl font-bold bg-gradient-to-r from-indigo-400 to-purple-400 bg-clip-text text-transparent">
                    Campus Assistant
                </div>
                <div className="flex gap-4">
                    <button onClick={() => navigate('/auth')} className="px-4 py-2 text-sm font-medium hover:text-indigo-400 transition-colors">
                        Login
                    </button>
                    <button onClick={() => navigate('/auth')} className="px-5 py-2 text-sm font-medium bg-white text-black rounded-full hover:bg-gray-200 transition-colors">
                        Get Started
                    </button>
                </div>
            </nav>

            {/* Hero Section */}
            <div className="max-w-7xl mx-auto px-4 mt-8 lg:mt-0 lg:min-h-[600px] grid grid-cols-1 lg:grid-cols-2 gap-12 items-center relative">

                {/* Left: Content */}
                <div className="flex flex-col items-start text-left z-10 pt-10 lg:pt-0">
                    <FadeIn delay={0.2} className="mb-6 inline-flex items-center gap-2 px-3 py-1 rounded-full bg-indigo-900/30 border border-indigo-500/30 text-indigo-300 text-xs font-mono uppercase tracking-wider">
                        <span className="w-2 h-2 rounded-full bg-indigo-400 animate-pulse"></span>
                        AI-Powered Campus OS
                    </FadeIn>

                    <div className="min-h-[160px] lg:min-h-[200px] flex items-center">
                        <TypingText
                            words={PHRASES}
                            className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight leading-[1.1] mb-8 bg-gradient-to-br from-white via-indigo-100 to-gray-500 bg-clip-text text-transparent max-w-3xl"
                            typingSpeed={80}
                            deletingSpeed={40}
                            pauseTime={2500}
                        />
                    </div>

                    <FadeIn delay={0.4} className="max-w-xl text-gray-400 text-lg md:text-xl mb-10 leading-relaxed">
                        Manage your timetable, ask questions, and stay updated with a multimodal AI assistant that understands text, voice, and images.
                    </FadeIn>

                    <FadeIn delay={0.6} className="flex flex-col sm:flex-row gap-4 w-full sm:w-auto">
                        <button
                            onClick={() => navigate('/app/dashboard')}
                            className="px-8 py-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-semibold flex items-center justify-center gap-2 transition-all hover:scale-105 shadow-lg shadow-indigo-600/25"
                        >
                            Launch Assistant <ArrowRight size={20} />
                        </button>
                        <button className="px-8 py-4 bg-gray-900 border border-gray-800 hover:bg-gray-800 text-gray-300 rounded-xl font-semibold transition-all">
                            View Demo
                        </button>
                    </FadeIn>
                </div>

                {/* Right: 3D Model (Hidden on Mobile) */}
                <div className="hidden lg:block h-[600px] w-full relative">
                    <div className="absolute inset-0 bg-gradient-to-tr from-indigo-500/10 to-purple-500/10 rounded-full blur-[100px] -z-10" />
                    <Canvas className="w-full h-full" dpr={[1, 2]}>
                        <Suspense fallback={null}>
                            <CampusModel />
                        </Suspense>
                    </Canvas>
                </div>

                {/* Mobile Fallback Illustration (Visible only on small screens) */}
                <div className="lg:hidden w-full h-64 bg-gradient-to-b from-indigo-900/20 to-transparent rounded-2xl flex items-center justify-center border border-indigo-500/10 mb-10">
                    <div className="text-indigo-400 font-mono text-sm animate-pulse">Initializing 3D Core...</div>
                </div>
            </div>

            {/* Features Grid */}
            <FadeIn delay={0.8} className="max-w-6xl mx-auto mt-20 px-4 grid grid-cols-1 md:grid-cols-3 gap-8 mb-20 relative z-10">
                <div className="p-6 rounded-2xl bg-gray-900/50 border border-gray-800 hover:border-indigo-500/50 transition-colors group backdrop-blur-sm">
                    <div className="w-12 h-12 rounded-lg bg-indigo-500/10 flex items-center justify-center text-indigo-400 mb-4 group-hover:scale-110 transition-transform">
                        <MessageSquare size={24} />
                    </div>
                    <h3 className="text-xl font-semibold mb-2">Contextual Chat</h3>
                    <p className="text-gray-400 text-sm">Ask about exam schedules, locations, or policies. The AI knows your campus.</p>
                </div>
                <div className="p-6 rounded-2xl bg-gray-900/50 border border-gray-800 hover:border-purple-500/50 transition-colors group backdrop-blur-sm">
                    <div className="w-12 h-12 rounded-lg bg-purple-500/10 flex items-center justify-center text-purple-400 mb-4 group-hover:scale-110 transition-transform">
                        <Mic size={24} />
                    </div>
                    <h3 className="text-xl font-semibold mb-2">Voice & Speech</h3>
                    <p className="text-gray-400 text-sm">Speak naturally to your assistant using advanced speech-to-text integration.</p>
                </div>
                <div className="p-6 rounded-2xl bg-gray-900/50 border border-gray-800 hover:border-pink-500/50 transition-colors group backdrop-blur-sm">
                    <div className="w-12 h-12 rounded-lg bg-pink-500/10 flex items-center justify-center text-pink-400 mb-4 group-hover:scale-110 transition-transform">
                        <ImageIcon size={24} />
                    </div>
                    <h3 className="text-xl font-semibold mb-2">Visual Understanding</h3>
                    <p className="text-gray-400 text-sm">Upload photos of notices or timetables to instantly extract and organize details.</p>
                </div>
            </FadeIn>

            {/* Background elements */}
            <div className="fixed top-0 left-0 w-full h-full pointer-events-none -z-20">
                <div className="absolute top-[-10%] left-[-10%] w-[50%] h-[50%] bg-indigo-900/10 rounded-full blur-[120px]" />
                <div className="absolute bottom-[-10%] right-[-10%] w-[50%] h-[50%] bg-purple-900/10 rounded-full blur-[120px]" />
            </div>
        </div>
    );
};
