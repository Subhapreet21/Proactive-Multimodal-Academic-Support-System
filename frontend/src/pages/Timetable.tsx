
import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { Loader2, Plus, MapPin, BookOpen, Trash2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { DeleteConfirmationModal } from '../components/ui/DeleteConfirmationModal';

const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

interface TimetableEntry {
    id: string;
    day_of_week: string;
    start_time: string;
    end_time: string;
    course_code: string;
    course_name: string;
    location: string;
}

export const Timetable = () => {
    const { user, getToken, userRole } = useAuth();
    const [entries, setEntries] = useState<TimetableEntry[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);

    // Edit State
    const [editingEntry, setEditingEntry] = useState<TimetableEntry | null>(null);

    // Delete Confirmation State
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [classToDelete, setClassToDelete] = useState<{ id: string, name: string } | null>(null);

    // Form State
    const [newClass, setNewClass] = useState({
        day_of_week: 'Monday',
        start_time: '09:00',
        end_time: '10:00',
        course_code: '',
        course_name: '',
        location: '',
        department: 'CSE',
        year: '4',
        section: 'A'
    });


    // Filter State (for Admin/Faculty)
    const [filters, setFilters] = useState({
        department: 'CSE',
        year: '4',
        section: 'A'
    });

    const isPowerUser = userRole === 'admin' || userRole === 'faculty';

    useEffect(() => {
        if (user) fetchTimetable();
    }, [user, filters]); // Refetch when filters change

    const fetchTimetable = async () => {
        try {
            if (!user) return;
            const token = await getToken();
            const queryParams = new URLSearchParams(filters).toString();
            // Students ignore query params in backend, so always safe to send
            const url = `${import.meta.env.VITE_API_URL}/api/timetable?${queryParams}`;

            const res = await fetch(url, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (!data.error) setEntries(data);
        } catch (error) {
            console.error("Error fetching timetable:", error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (editingEntry) {
            setNewClass({
                day_of_week: editingEntry.day_of_week,
                start_time: editingEntry.start_time,
                end_time: editingEntry.end_time,
                course_code: editingEntry.course_code,
                course_name: editingEntry.course_name,
                location: editingEntry.location,
                department: (editingEntry as any).department || filters.department,
                year: (editingEntry as any).year || filters.year,
                section: (editingEntry as any).section || filters.section
            });
            setShowForm(true);
        }
    }, [editingEntry]);

    const handleCloseForm = () => {
        setShowForm(false);
        setEditingEntry(null);
        setNewClass({
            day_of_week: 'Monday',
            start_time: '09:00',
            end_time: '10:00',
            course_code: '',
            course_name: '',
            location: '',
            department: filters.department,
            year: filters.year,
            section: filters.section
        });
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const token = await getToken();
            const url = editingEntry
                ? `${import.meta.env.VITE_API_URL}/api/timetable/${editingEntry.id}`
                : `${import.meta.env.VITE_API_URL}/api/timetable`;

            const method = editingEntry ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(newClass)
            });

            if (res.ok) {
                toast.success(editingEntry ? "Class updated successfully" : "Class added successfully");
                fetchTimetable();
                handleCloseForm();
            } else {
                toast.error(editingEntry ? "Failed to update class" : "Failed to add class");
            }
        } catch (error) {
            console.error("Error saving class:", error);
            toast.error("An error occurred while saving class");
        }
    };

    const confirmDelete = (id: string, name: string) => {
        setClassToDelete({ id, name });
        setShowDeleteConfirm(true);
    };

    const handleDelete = async () => {
        if (!classToDelete) return;

        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/timetable/${classToDelete.id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (res.ok) {
                fetchTimetable();
                toast.success("Class deleted");
                setShowDeleteConfirm(false);
                setClassToDelete(null);
            } else {
                toast.error("Failed to delete class");
            }
        } catch (error) {
            console.error("Error deleting class:", error);
            toast.error("Error deleting class");
        }
    };

    if (loading) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    return (
        <div className="p-8 h-full overflow-y-auto">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-white mb-2">Weekly Timetable</h1>
                    {isPowerUser ? (
                        <div className="flex gap-4 items-center">
                            {userRole === 'admin' && (
                                <select value={filters.department} onChange={(e) => setFilters({ ...filters, department: e.target.value })} className="bg-gray-800 text-white text-sm rounded-lg p-2 border-none">
                                    <option value="CSE">CSE</option>
                                    <option value="ECE">ECE</option>
                                    <option value="MECH">MECH</option>
                                </select>
                            )}
                            <select value={filters.year} onChange={(e) => setFilters({ ...filters, year: e.target.value })} className="bg-gray-800 text-white text-sm rounded-lg p-2 border-none">
                                <option value="1">1st Year</option>
                                <option value="2">2nd Year</option>
                                <option value="3">3rd Year</option>
                                <option value="4">4th Year</option>
                            </select>
                            <select value={filters.section} onChange={(e) => setFilters({ ...filters, section: e.target.value })} className="bg-gray-800 text-white text-sm rounded-lg p-2 border-none">
                                <option value="A">Sec A</option>
                                <option value="B">Sec B</option>
                                <option value="C">Sec C</option>
                            </select>
                        </div>
                    ) : (
                        <p className="text-gray-400">Your scheduled classes</p>
                    )}
                </div>
                {isPowerUser && (
                    <button
                        onClick={() => setShowForm(true)}
                        className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors"
                    >
                        <Plus size={20} /> Add Class
                    </button>
                )}
            </div>

            {/* Add/Edit Form Modal */}
            {showForm && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 border border-gray-800 p-6 rounded-2xl w-full max-w-lg shadow-2xl">
                        <h2 className="text-xl font-bold text-white mb-4">{editingEntry ? 'Edit Class' : 'Add New Class'}</h2>
                        <form onSubmit={handleSave} className="space-y-4">
                            {/* Group Selectors in Form */}
                            <div className="grid grid-cols-3 gap-2 bg-gray-800/50 p-3 rounded-xl mb-2">
                                <select value={newClass.department} onChange={e => setNewClass({ ...newClass, department: e.target.value })} className="bg-gray-800 text-white text-xs rounded-lg p-2">
                                    <option value="CSE">CSE</option>
                                    <option value="ECE">ECE</option>
                                    <option value="MECH">MECH</option>
                                </select>
                                <select value={newClass.year} onChange={e => setNewClass({ ...newClass, year: e.target.value })} className="bg-gray-800 text-white text-xs rounded-lg p-2">
                                    <option value="1">Year 1</option>
                                    <option value="2">Year 2</option>
                                    <option value="3">Year 3</option>
                                    <option value="4">Year 4</option>
                                </select>
                                <select value={newClass.section} onChange={e => setNewClass({ ...newClass, section: e.target.value })} className="bg-gray-800 text-white text-xs rounded-lg p-2">
                                    <option value="A">Sec A</option>
                                    <option value="B">Sec B</option>
                                    <option value="C">Sec C</option>
                                </select>
                            </div>

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs text-gray-500 mb-1">Day</label>
                                    <select
                                        className="w-full bg-gray-800 border-none rounded-lg p-2 text-white"
                                        value={newClass.day_of_week}
                                        onChange={e => setNewClass({ ...newClass, day_of_week: e.target.value })}
                                    >
                                        {DAYS.map(d => <option key={d} value={d}>{d}</option>)}
                                    </select>
                                </div>
                                <div className="grid grid-cols-2 gap-2">
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">Start</label>
                                        <input type="time" className="w-full bg-gray-800 border-none rounded-lg p-2 text-white"
                                            value={newClass.start_time} onChange={e => setNewClass({ ...newClass, start_time: e.target.value })} required />
                                    </div>
                                    <div>
                                        <label className="block text-xs text-gray-500 mb-1">End</label>
                                        <input type="time" className="w-full bg-gray-800 border-none rounded-lg p-2 text-white"
                                            value={newClass.end_time} onChange={e => setNewClass({ ...newClass, end_time: e.target.value })} required />
                                    </div>
                                </div>
                            </div>
                            <div className="grid grid-cols-2 gap-4">
                                <input placeholder="Course Code (e.g. CS101)" className="bg-gray-800 rounded-lg p-2 text-white" value={newClass.course_code} onChange={e => setNewClass({ ...newClass, course_code: e.target.value })} required />
                                <input placeholder="Location (e.g. Room 304)" className="bg-gray-800 rounded-lg p-2 text-white" value={newClass.location} onChange={e => setNewClass({ ...newClass, location: e.target.value })} />
                            </div>
                            <input placeholder="Course Name" className="w-full bg-gray-800 rounded-lg p-2 text-white" value={newClass.course_name} onChange={e => setNewClass({ ...newClass, course_name: e.target.value })} required />

                            <div className="flex justify-end gap-3 mt-4">
                                <button type="button" onClick={handleCloseForm} className="text-gray-400 hover:text-white px-3 py-2">Cancel</button>
                                <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg">
                                    {editingEntry ? 'Update Class' : 'Save Class'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* Timetable Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-6">
                {DAYS.map(day => (
                    <div key={day} className="space-y-4">
                        <h3 className="text-gray-500 font-medium uppercase text-sm tracking-wider border-b border-gray-800 pb-2">{day.substring(0, 3)}</h3>
                        <div className="space-y-3">
                            {entries.filter(e => e.day_of_week === day).length === 0 && (
                                <div className="text-gray-700 text-xs italic text-center py-4">No classes</div>
                            )}
                            {entries
                                .filter(e => e.day_of_week === day)
                                .map(entry => (
                                    <motion.div
                                        key={entry.id}
                                        initial={{ opacity: 0, y: 10 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        className="bg-gray-900 border border-gray-800 p-4 rounded-xl hover:border-indigo-500/50 transition-colors group relative"
                                    >
                                        <div className="flex justify-between items-start mb-2">
                                            <span className="text-indigo-400 font-bold text-xs">{entry.course_code}</span>
                                            {isPowerUser && (
                                                <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                                                    <button
                                                        onClick={() => setEditingEntry(entry)}
                                                        className="text-gray-500 hover:text-indigo-400 p-1"
                                                    >
                                                        <BookOpen size={16} />
                                                        {/* Reusing BookOpen as Edit icon for now, or import Edit2 */}
                                                    </button>
                                                    <button
                                                        onClick={() => confirmDelete(entry.id, entry.course_name)}
                                                        className="text-gray-500 hover:text-red-400 p-1"
                                                    >
                                                        <Trash2 size={16} />
                                                    </button>
                                                </div>
                                            )}
                                        </div>
                                        <h4 className="text-white font-medium text-sm mb-1">{entry.course_name}</h4>
                                        <div className="flex items-center gap-2 text-xs text-gray-500">
                                            <span>{entry.start_time.substring(0, 5)} - {entry.end_time.substring(0, 5)}</span>
                                        </div>
                                        {entry.location && (
                                            <div className="mt-2 flex items-center gap-1 text-xs text-gray-400">
                                                <MapPin size={10} /> {entry.location}
                                            </div>
                                        )}
                                    </motion.div>
                                ))}
                        </div>
                    </div>
                ))}
            </div>
            {/* Delete Confirmation Modal */}
            <DeleteConfirmationModal
                isOpen={showDeleteConfirm}
                onClose={() => setShowDeleteConfirm(false)}
                onConfirm={handleDelete}
                itemName={classToDelete?.name}
                itemType="class"
            />
        </div>
    );
};
