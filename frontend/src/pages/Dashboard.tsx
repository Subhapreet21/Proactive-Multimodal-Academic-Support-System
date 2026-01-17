import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';
import { Loader2, BookOpen, Clock, Calendar, Bell, MessageSquare } from 'lucide-react';
import { motion } from 'framer-motion';

export const Dashboard = () => {
    const { user, getToken } = useAuth();
    const navigate = useNavigate();
    const [stats, setStats] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchStats();
    }, [user]);

    const fetchStats = async () => {
        try {
            if (!user) return;
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/dashboard`, {
                headers: {
                    Authorization: `Bearer ${token}`
                }
            });
            const data = await res.json();
            if (!data.error) setStats(data);
        } catch (error) {
            console.error("Error fetching dashboard:", error);
        } finally {
            setLoading(false);
        }
    };

    if (loading) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    const userName = user?.firstName || user?.fullName?.split(' ')[0] || 'Student';

    return (
        <div className="p-8 h-full overflow-y-auto">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-white mb-2">Welcome back, {userName} 👋</h1>
                <p className="text-gray-400">Here's what's happening today.</p>
            </div>

            {/* Quick Stats / Widgets */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">

                {/* Next Class Widget */}
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="bg-gradient-to-br from-indigo-900/50 to-purple-900/50 border border-indigo-500/30 p-6 rounded-2xl relative overflow-hidden"
                >
                    <div className="relative z-10">
                        <div className="flex justify-between items-start mb-4">
                            <span className="bg-indigo-500/20 text-indigo-300 text-xs font-bold px-2 py-1 rounded-md">
                                {stats?.nextClass ? (stats.nextClass.isToday ? 'NEXT CLASS' : `NEXT CLASS (${stats.nextClass.nextDay?.toUpperCase()})`) : 'SCHEDULE'}
                            </span>
                            <BookOpen className="text-indigo-400" size={24} />
                        </div>
                        {stats?.nextClass ? (
                            <>
                                <h2 className="text-2xl font-bold text-white mb-1">{stats.nextClass.course_code}</h2>
                                <p className="text-indigo-200 text-sm mb-4 line-clamp-1">{stats.nextClass.course_name}</p>
                                <div className="flex items-center gap-3 text-sm text-gray-300">
                                    <span className="flex items-center gap-1"><Clock size={14} /> {stats.nextClass.start_time.substring(0, 5)}</span>
                                    <span className="w-1 h-1 bg-gray-500 rounded-full"></span>
                                    <span>{stats.nextClass.location}</span>
                                </div>
                            </>
                        ) : (
                            <div className="text-gray-400 py-4">No more classes today! 🎉</div>
                        )}
                    </div>
                </motion.div>

                {/* Quick Actions */}
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.1 }}
                    className="bg-gray-900 border border-gray-800 p-6 rounded-2xl flex flex-col justify-between"
                >
                    <h3 className="text-white font-semibold mb-4">Quick Actions</h3>
                    <div className="grid grid-cols-2 gap-3">
                        <button onClick={() => navigate('/app/chat')} className="bg-gray-800 hover:bg-gray-700 p-3 rounded-xl flex flex-col items-center gap-2 text-gray-300 hover:text-white transition-colors">
                            <MessageSquare size={20} />
                            <span className="text-s">Chat Assistant</span>
                        </button>
                        <button onClick={() => navigate('/app/timetable')} className="bg-gray-800 hover:bg-gray-700 p-3 rounded-xl flex flex-col items-center gap-2 text-gray-300 hover:text-white transition-colors">
                            <Calendar size={20} />
                            <span className="text-s">Schedule</span>
                        </button>
                    </div>
                </motion.div>

                {/* Upcoming Reminders */}
                <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 }}
                    className="bg-gray-900 border border-gray-800 p-6 rounded-2xl"
                >
                    <div className="flex justify-between items-center mb-4">
                        <h3 className="text-white font-semibold">Tasks Due</h3>
                        <span className="text-xs text-gray-500">{stats?.reminders?.length || 0} Pending</span>
                    </div>
                    <div className="space-y-3">
                        {stats?.reminders?.length === 0 && <p className="text-gray-500 text-xs">No pending tasks.</p>}
                        {stats?.reminders?.map((r: any) => (
                            <div key={r.id} className="flex items-center gap-3 text-sm">
                                <div className={`w-2 h-2 rounded-full ${r.category === 'Exam' ? 'bg-red-500' : 'bg-emerald-500'}`}></div>
                                <span className="text-gray-300 flex-1 truncate">{r.title}</span>
                                <span className="text-gray-500 text-xs whitespace-nowrap">{new Date(r.due_at).toLocaleDateString()}</span>
                            </div>
                        ))}
                    </div>
                    <button onClick={() => navigate('/app/reminders')} className="w-full mt-4 text-xs text-indigo-400 hover:text-indigo-300 text-center">View All</button>
                </motion.div>
            </div>

            {/* Recent Events / Notices */}
            <div>
                <h3 className="text-xl font-bold text-white mb-4">Campus Notices</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {stats?.events?.length === 0 && <p className="text-gray-500">No recent notices.</p>}
                    {stats?.events?.map((e: any) => (
                        <div key={e.id} className="bg-gray-900 border border-gray-800 p-4 rounded-xl flex items-start gap-4 hover:border-gray-700 transition-colors">
                            <div className="bg-indigo-500/10 p-3 rounded-lg text-indigo-400">
                                <Bell size={20} />
                            </div>
                            <div className="flex-1">
                                <h4 className="text-white font-medium mb-1">{e.title}</h4>
                                <p className="text-gray-400 text-sm line-clamp-2">{e.description}</p>
                                <div className="mt-2 text-xs text-gray-500 flex justify-between">
                                    <span>{e.category}</span>
                                    <span>{new Date(e.created_at).toLocaleDateString()}</span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        </div>
    );
};
