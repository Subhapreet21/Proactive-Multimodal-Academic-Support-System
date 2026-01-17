import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { Loader2, Plus, Trash2, CheckCircle2, Circle, Calendar, Tag, Edit2 } from 'lucide-react';
import clsx from 'clsx';
import { motion, AnimatePresence } from 'framer-motion';
import { DeleteConfirmationModal } from '../components/ui/DeleteConfirmationModal';

interface Reminder {
    id: string;
    title: string;
    description: string;
    due_at: string;
    category: string;
    is_completed: boolean;
}

const CATEGORIES = ['Class', 'Exam', 'Assignment', 'Event', 'Personal'];

export const Reminders = () => {
    const { user, getToken } = useAuth();
    const [reminders, setReminders] = useState<Reminder[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);

    // Delete Confirmation State
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [reminderToDelete, setReminderToDelete] = useState<string | null>(null);

    const [newReminder, setNewReminder] = useState({
        title: '',
        description: '',
        due_at: '',
        category: 'Class'
    });

    useEffect(() => {
        fetchReminders();
    }, [user]);

    const fetchReminders = async () => {
        try {
            if (!user) return;
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/reminders`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (!data.error) setReminders(data);
        } catch (error) {
            console.error("Error fetching reminders:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const token = await getToken();
            // Ensure ISO string for timestamp
            const dueAtISO = new Date(newReminder.due_at).toISOString();

            const url = editingId
                ? `${import.meta.env.VITE_API_URL}/api/reminders/${editingId}`
                : `${import.meta.env.VITE_API_URL}/api/reminders`;

            const method = editingId ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ ...newReminder, due_at: dueAtISO })
            });
            if (res.ok) {
                toast.success(editingId ? "Reminder updated successfully" : "Reminder created successfully");
                fetchReminders();
                closeForm();
            } else {
                toast.error("Failed to save reminder");
            }
        } catch (error) {
            console.error("Error saving reminder:", error);
            toast.error("An error occurred while saving");
        }
    };

    const closeForm = () => {
        setShowForm(false);
        setEditingId(null);
        setNewReminder({ title: '', description: '', due_at: '', category: 'Class' });
    }

    const openEdit = (reminder: Reminder) => {
        setEditingId(reminder.id);
        // Format date for datetime-local input (YYYY-MM-DDTHH:mm)
        const dateStr = new Date(reminder.due_at).toISOString().slice(0, 16);
        setNewReminder({
            title: reminder.title,
            description: reminder.description || '',
            due_at: dateStr,
            category: reminder.category || 'Class'
        });
        setShowForm(true);
    };

    const toggleStatus = async (id: string, currentStatus: boolean) => {
        try {
            const token = await getToken();
            await fetch(`${import.meta.env.VITE_API_URL}/api/reminders/${id}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ is_completed: !currentStatus })
            });
            // Optimistic update
            setReminders(prev => prev.map(r => r.id === id ? { ...r, is_completed: !currentStatus } : r));
            toast.success(`Reminder marked as ${!currentStatus ? 'completed' : 'incomplete'}`);
        } catch (error) {
            console.error("Error updating status:", error);
            toast.error("Failed to update status");
        }
    };

    const confirmDelete = (id: string) => {
        setReminderToDelete(id);
        setShowDeleteConfirm(true);
    };

    const handleDelete = async () => {
        if (!reminderToDelete) return;

        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/reminders/${reminderToDelete}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (res.ok) {
                fetchReminders();
                toast.success("Reminder deleted");
                setShowDeleteConfirm(false);
                setReminderToDelete(null);
            } else {
                toast.error("Failed to delete reminder");
            }
        } catch (error) {
            console.error("Error deleting reminder:", error);
            toast.error("Error deleting reminder");
        }
    };

    if (loading) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    return (
        <div className="p-8 h-full overflow-y-auto">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-white mb-2">Reminders</h1>
                    <p className="text-gray-400">Stay on top of your tasks</p>
                </div>
                <button
                    onClick={() => setShowForm(true)}
                    className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors"
                >
                    <Plus size={20} /> New Reminder
                </button>
            </div>

            {/* Delete Confirmation Modal */}
            <DeleteConfirmationModal
                isOpen={showDeleteConfirm}
                onClose={() => setShowDeleteConfirm(false)}
                onConfirm={handleDelete}
                itemName="this reminder"
                itemType="reminder"
            />

            {/* Add/Edit Modal */}
            {showForm && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 border border-gray-800 p-6 rounded-2xl w-full max-w-md shadow-2xl">
                        <h2 className="text-xl font-bold text-white mb-4">{editingId ? 'Edit Reminder' : 'Add Reminder'}</h2>
                        <form onSubmit={handleSave} className="space-y-4">
                            <input placeholder="Title" className="w-full bg-gray-800 rounded-lg p-2 text-white" value={newReminder.title} onChange={e => setNewReminder({ ...newReminder, title: e.target.value })} required />
                            <textarea placeholder="Description (Optional)" className="w-full bg-gray-800 rounded-lg p-2 text-white h-20" value={newReminder.description} onChange={e => setNewReminder({ ...newReminder, description: e.target.value })} />

                            <div className="grid grid-cols-2 gap-4">
                                <div>
                                    <label className="block text-xs text-gray-500 mb-1">Due Date</label>
                                    <input type="datetime-local" className="w-full bg-gray-800 border-none rounded-lg p-2 text-white"
                                        value={newReminder.due_at} onChange={e => setNewReminder({ ...newReminder, due_at: e.target.value })} required />
                                </div>
                                <div>
                                    <label className="block text-xs text-gray-500 mb-1">Category</label>
                                    <select
                                        className="w-full bg-gray-800 border-none rounded-lg p-2 text-white"
                                        value={newReminder.category}
                                        onChange={e => setNewReminder({ ...newReminder, category: e.target.value })}
                                    >
                                        {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                                    </select>
                                </div>
                            </div>

                            <div className="flex justify-end gap-3 mt-4">
                                <button type="button" onClick={closeForm} className="text-gray-400 hover:text-white px-3 py-2">Cancel</button>
                                <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg">{editingId ? 'Update' : 'Add'}</button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            {/* List */}
            <div className="max-w-4xl space-y-3">
                {reminders.length === 0 && (
                    <div className="text-gray-500 text-center py-10">No reminders yet. Great job!</div>
                )}
                <AnimatePresence>
                    {reminders.map(reminder => (
                        <motion.div
                            key={reminder.id}
                            initial={{ opacity: 0, x: -20 }}
                            animate={{ opacity: 1, x: 0 }}
                            exit={{ opacity: 0, x: 20 }}
                            className={clsx(
                                "flex items-center gap-4 p-4 rounded-xl border transition-colors group",
                                reminder.is_completed ? "bg-gray-900/50 border-gray-800 opacity-60" : "bg-gray-900 border-gray-800 hover:border-indigo-500/50"
                            )}
                        >
                            <button onClick={() => toggleStatus(reminder.id, reminder.is_completed)} className="text-gray-400 hover:text-indigo-400 transition-colors">
                                {reminder.is_completed ? <CheckCircle2 size={24} className="text-green-500" /> : <Circle size={24} />}
                            </button>

                            <div className="flex-1">
                                <h3 className={clsx("font-medium", reminder.is_completed ? "text-gray-500 line-through" : "text-white")}>{reminder.title}</h3>
                                {reminder.description && <p className="text-sm text-gray-500">{reminder.description}</p>}
                                <div className="flex items-center gap-4 mt-1 text-xs text-gray-400">
                                    <span className="flex items-center gap-1"><Calendar size={12} /> {new Date(reminder.due_at).toLocaleString(undefined, { timeZone: 'UTC' })}</span>
                                    <span className="flex items-center gap-1"><Tag size={12} /> {reminder.category}</span>
                                </div>
                            </div>

                            <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                                <button onClick={() => openEdit(reminder)} className="text-gray-600 hover:text-indigo-400 p-2">
                                    <Edit2 size={18} />
                                </button>
                                <button
                                    onClick={() => confirmDelete(reminder.id)}
                                    className="text-gray-500 hover:text-red-400 transition-colors p-2"
                                >
                                    <Trash2 size={20} />
                                </button>
                            </div>
                        </motion.div>
                    ))}
                </AnimatePresence>
            </div>
        </div>
    );
};
