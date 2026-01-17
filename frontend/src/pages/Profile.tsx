import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { Loader2, User, Mail, School, BookOpen, Hash, Save } from 'lucide-react';
import { motion } from 'framer-motion';

export const Profile = () => {
    const { user, getToken, userRole } = useAuth();
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    const [profile, setProfile] = useState({
        full_name: '',
        email: '',
        avatar_url: '',
        department: '',
        year: '',
        section: ''
    });

    useEffect(() => {
        if (user) {
            fetchProfile();
            setProfile(prev => ({ ...prev, email: user.emailAddresses[0]?.emailAddress || '' }));
        }
    }, [user]);

    const fetchProfile = async () => {
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/profile`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (data && !data.error && !data.message) {
                setProfile(prev => ({ ...prev, ...data }));
            } else if (user?.fullName) {
                // Fallback to metadata if profile doesn't exist yet
                setProfile(prev => ({ ...prev, full_name: user.fullName }));
            }
        } catch (error) {
            console.error("Error fetching profile:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault();
        setSaving(true);
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/profile`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(profile)
            });

            if (res.ok) {
                toast.success("Profile Updated Successfully!");
            } else {
                toast.error("Failed to update profile.");
            }
        } catch (error) {
            console.error("Error updating profile:", error);
        } finally {
            setSaving(false);
        }
    };

    if (loading) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    const isStudent = userRole === 'student';
    const isFaculty = userRole === 'faculty';
    const isAdmin = userRole === 'admin';

    const getRoleTitle = () => {
        if (isAdmin) return 'Admin Profile';
        if (isFaculty) return 'Faculty Profile';
        return 'Student Profile';
    };

    return (
        <div className="p-8 h-full overflow-y-auto">
            <h1 className="text-3xl font-bold text-white mb-2">{getRoleTitle()}</h1>
            <p className="text-gray-400 mb-8">Manage your personal information</p>

            <div className="max-w-2xl">
                {/* ID Card Style */}
                <motion.div
                    initial={{ scale: 0.95, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="bg-gradient-to-r from-indigo-900 to-purple-900 border border-indigo-500/30 p-6 rounded-2xl mb-8 flex items-center gap-6 shadow-xl"
                >
                    <div className="w-24 h-24 rounded-full overflow-hidden shadow-lg border-4 border-indigo-400/30 bg-gray-800">
                        {user.imageUrl ? (
                            <img src={user.imageUrl} alt="Profile" className="w-full h-full object-cover" />
                        ) : profile.avatar_url ? (
                            <img src={profile.avatar_url} alt="Profile" className="w-full h-full object-cover" />
                        ) : (
                            <div className="w-full h-full bg-indigo-500 flex items-center justify-center text-3xl font-bold text-white">
                                {profile.full_name?.charAt(0) || 'U'}
                            </div>
                        )}
                    </div>
                    <div>
                        <h2 className="text-2xl font-bold text-white">{profile.full_name || 'User'}</h2>
                        <p className="text-indigo-200">{profile.email}</p>
                        <div className="flex gap-2 mt-2 flex-wrap">
                            <span className="bg-black/30 px-2 py-1 rounded text-xs text-white border border-white/10 capitalize">{userRole || 'User'}</span>

                            {(isStudent || isFaculty) && (
                                <span className="bg-black/30 px-2 py-1 rounded text-xs text-white border border-white/10">{profile.department || 'No Dept'}</span>
                            )}

                            {isStudent && (
                                <span className="bg-black/30 px-2 py-1 rounded text-xs text-white border border-white/10">{profile.year || 'No Year'} - {profile.section || 'No Sec'}</span>
                            )}
                        </div>
                    </div>
                </motion.div>

                {/* Edit Form */}
                <form onSubmit={handleUpdate} className="bg-gray-900 border border-gray-800 p-8 rounded-2xl space-y-6">
                    <h3 className="text-xl font-semibold text-white border-b border-gray-800 pb-4 mb-4">Edit Details</h3>

                    <div className="space-y-4">
                        <div>
                            <label className="block text-sm text-gray-400 mb-1 flex items-center gap-2"><User size={14} /> Full Name</label>
                            <input
                                className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-white focus:border-indigo-500 outline-none"
                                value={profile.full_name}
                                onChange={e => setProfile({ ...profile, full_name: e.target.value })}
                            />
                        </div>

                        <div>
                            <label className="block text-sm text-gray-400 mb-1 flex items-center gap-2"><Mail size={14} /> Email (Read Only)</label>
                            <input
                                className="w-full bg-gray-800/50 border border-gray-700 rounded-lg p-3 text-gray-400 cursor-not-allowed"
                                value={profile.email}
                                readOnly
                            />
                        </div>

                        {(isStudent || isFaculty) && (
                            <div>
                                <label className="block text-sm text-gray-400 mb-1 flex items-center gap-2"><School size={14} /> Department</label>
                                <select
                                    className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-white focus:border-indigo-500 outline-none"
                                    value={profile.department}
                                    onChange={e => setProfile({ ...profile, department: e.target.value })}
                                >
                                    <option value="">Select Department</option>
                                    <option value="CSE">Computer Science (CSE)</option>
                                    <option value="ECE">Electronics (ECE)</option>
                                    <option value="ME">Mechanical (ME)</option>
                                    <option value="CE">Civil (CE)</option>
                                </select>
                            </div>
                        )}

                        {isStudent && (
                            <div className="grid grid-cols-2 gap-6">
                                <div>
                                    <label className="block text-sm text-gray-400 mb-1 flex items-center gap-2"><BookOpen size={14} /> Year</label>
                                    <select
                                        className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-white focus:border-indigo-500 outline-none"
                                        value={profile.year}
                                        onChange={e => setProfile({ ...profile, year: e.target.value })}
                                    >
                                        <option value="">Select Year</option>
                                        <option value="1">1st Year</option>
                                        <option value="2">2nd Year</option>
                                        <option value="3">3rd Year</option>
                                        <option value="4">4th Year</option>
                                    </select>
                                </div>
                                <div>
                                    <label className="block text-sm text-gray-400 mb-1 flex items-center gap-2"><Hash size={14} /> Section</label>
                                    <input
                                        className="w-full bg-gray-800 border border-gray-700 rounded-lg p-3 text-white focus:border-indigo-500 outline-none"
                                        value={profile.section}
                                        onChange={e => setProfile({ ...profile, section: e.target.value })}
                                        placeholder="e.g. A, B"
                                    />
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="pt-6 border-t border-gray-800 flex justify-end">
                        <button
                            type="submit"
                            disabled={saving}
                            className="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-3 rounded-xl flex items-center gap-2 transition-all font-medium disabled:opacity-50"
                        >
                            {saving ? <Loader2 className="animate-spin" /> : <Save size={18} />}
                            Save Changes
                        </button>
                    </div>
                </form>

            </div>
        </div>
    );
};
