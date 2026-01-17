
import { useState } from 'react';

import { useAuth } from '../contexts/AuthContext';
import { useUser } from '@clerk/clerk-react';
import { Shield, GraduationCap, School, Loader2 } from 'lucide-react';

import { toast } from 'sonner';

export const Onboarding = () => {
    const { getToken } = useAuth();
    const { user } = useUser();
    // const navigate = useNavigate(); // Not using navigate directly, sticking to window.location for full reload
    const [step, setStep] = useState(1);
    const [selectedRole, setSelectedRole] = useState<'student' | 'faculty' | 'admin' | null>(null);
    const [accessCode, setAccessCode] = useState('');
    const [loading, setLoading] = useState(false);

    // Profile Details State
    const [details, setDetails] = useState({
        department: '',
        year: '',
        section: ''
    });

    const handleRoleSelect = (roleId: 'student' | 'faculty' | 'admin') => {
        setSelectedRole(roleId);
        // If Role is Admin, they might not need Dept/Year/Sec, but they need Code.
        // If Student, they need Dept/Year/Sec.
        // If Faculty, they need Dept + Code.
        // Move to Step 2
        setStep(2);
    };

    const handleBack = () => {
        setStep(1);
        setSelectedRole(null);
        setAccessCode('');
        setDetails({ department: '', year: '', section: '' });
    };

    const handleSubmit = async () => {
        if (!selectedRole) return;

        // Validation
        if (selectedRole === 'student') {
            if (!details.department || !details.year || !details.section) {
                toast.error("Please fill in all details (Department, Year, Section)");
                return;
            }
        }
        if (selectedRole === 'faculty') {
            if (!accessCode) {
                toast.error("Please enter the Faculty Access Code");
                return;
            }
            if (!details.department) {
                toast.error("Please select your Department");
                return;
            }
        }
        if (selectedRole === 'admin') {
            if (!accessCode) {
                toast.error("Please enter the Admin Access Code");
                return;
            }
        }

        setLoading(true);
        try {
            const token = await getToken();
            const payload = {
                role: selectedRole,
                code: accessCode,
                ...details
            };

            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/role`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(payload)
            });

            const data = await res.json();

            if (res.ok) {
                toast.success("Welcome to Campus OS!");
                await user?.reload();
                window.location.href = '/app/dashboard';
            } else {
                alert("Error setting role: " + (data.error || JSON.stringify(data)));
                toast.error(data.error || "Failed to set role");
            }
        } catch (error: any) {
            console.error(error);
            alert("Network/System Error: " + error.message);
            toast.error("Something went wrong");
        } finally {
            setLoading(false);
        }
    };

    const roles = [
        {
            id: 'student',
            title: 'Student',
            icon: GraduationCap,
            desc: 'View schedules, reminders, and notices.',
            color: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/50'
        },
        {
            id: 'faculty',
            title: 'Faculty',
            icon: School,
            desc: 'Manage timetables and verify specific data.',
            color: 'bg-blue-500/10 text-blue-400 border-blue-500/50'
        },
        {
            id: 'admin',
            title: 'Admin',
            icon: Shield,
            desc: 'Full system control and management.',
            color: 'bg-indigo-500/10 text-indigo-400 border-indigo-500/50'
        }
    ];

    return (
        <div className="min-h-screen bg-gray-950 flex flex-col items-center justify-center p-4">
            <div className="max-w-4xl w-full">
                <div className="text-center mb-8 relative">
                    <button
                        onClick={() => {
                            // Force logout
                            window.localStorage.clear();
                            window.sessionStorage.clear();
                            window.location.href = '/auth';
                        }}
                        className="absolute top-0 right-0 text-xs text-red-400 hover:text-red-300 border border-red-500/30 px-3 py-1 rounded-full"
                    >
                        Sign Out
                    </button>
                    <h1 className="text-4xl font-bold text-white mb-4">Welcome to Campus OS</h1>
                    <p className="text-gray-400 text-lg">
                        {step === 1 ? "Choose your role to get started." : "Tell us a bit more about you."}
                    </p>
                </div>

                {step === 1 && (
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6 animate-in fade-in zoom-in duration-300">
                        {roles.map((role) => (
                            <button
                                key={role.id}
                                onClick={() => handleRoleSelect(role.id as any)}
                                className="bg-gray-900 border-2 border-gray-800 p-6 rounded-2xl text-left hover:border-gray-600 hover:bg-gray-800 transition-all duration-300 group"
                            >
                                <role.icon size={48} className={`mb-6 ${role.color.split(' ')[1]}`} />
                                <h3 className="text-xl font-bold text-white mb-2">{role.title}</h3>
                                <p className="text-sm text-gray-400 group-hover:text-gray-300">{role.desc}</p>
                            </button>
                        ))}
                    </div>
                )}

                {step === 2 && (
                    <div className="max-w-md mx-auto bg-gray-900 border border-gray-800 p-8 rounded-2xl animate-in slide-in-from-right-8 fade-in duration-300">
                        <div className="space-y-6">

                            {/* Role Badge */}
                            <div className="flex items-center gap-2 mb-6">
                                <span className="text-gray-400 text-sm">Selected Role:</span>
                                <span className="bg-indigo-500/20 text-indigo-400 px-3 py-1 rounded-full text-sm font-medium capitalize border border-indigo-500/30">
                                    {selectedRole}
                                </span>
                            </div>

                            {/* Access Code (Admin/Faculty) */}
                            {(selectedRole === 'admin' || selectedRole === 'faculty') && (
                                <div>
                                    <label className="block text-sm text-gray-400 mb-1">
                                        {selectedRole === 'admin' ? 'Admin' : 'Faculty'} Access Code
                                    </label>
                                    <input
                                        type="password"
                                        value={accessCode}
                                        onChange={(e) => setAccessCode(e.target.value)}
                                        className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
                                        placeholder="Enter secure code"
                                    />
                                </div>
                            )}

                            {/* Department (Student/Faculty) */}
                            {(selectedRole === 'student' || selectedRole === 'faculty') && (
                                <div>
                                    <label className="block text-sm text-gray-400 mb-1">Department</label>
                                    <select
                                        value={details.department}
                                        onChange={(e) => setDetails({ ...details, department: e.target.value })}
                                        className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
                                    >
                                        <option value="">Select Department</option>
                                        <option value="CSE">CSE</option>
                                        <option value="ECE">ECE</option>
                                        <option value="MECH">MECH</option>
                                    </select>
                                </div>
                            )}

                            {/* Year/Section (Student Only) */}
                            {selectedRole === 'student' && (
                                <div className="grid grid-cols-2 gap-4">
                                    <div>
                                        <label className="block text-sm text-gray-400 mb-1">Year</label>
                                        <select
                                            value={details.year}
                                            onChange={(e) => setDetails({ ...details, year: e.target.value })}
                                            className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
                                        >
                                            <option value="">Select Year</option>
                                            <option value="1">1st Year</option>
                                            <option value="2">2nd Year</option>
                                            <option value="3">3rd Year</option>
                                            <option value="4">4th Year</option>
                                        </select>
                                    </div>
                                    <div>
                                        <label className="block text-sm text-gray-400 mb-1">Section</label>
                                        <select
                                            value={details.section}
                                            onChange={(e) => setDetails({ ...details, section: e.target.value })}
                                            className="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-indigo-500"
                                        >
                                            <option value="">Select Section</option>
                                            <option value="A">Section A</option>
                                            <option value="B">Section B</option>
                                            <option value="C">Section C</option>
                                        </select>
                                    </div>
                                </div>
                            )}

                            <div className="flex gap-4 pt-4">
                                <button
                                    onClick={handleBack}
                                    className="flex-1 text-gray-400 hover:text-white py-3 transition-colors"
                                >
                                    Back
                                </button>
                                <button
                                    onClick={handleSubmit}
                                    disabled={loading}
                                    className="flex-[2] bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl font-bold py-3 disabled:opacity-50 flex items-center justify-center gap-2"
                                >
                                    {loading ? <Loader2 className="animate-spin" /> : 'Complete Setup'}
                                </button>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </div>
    );
};
