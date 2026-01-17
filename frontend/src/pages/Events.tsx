
import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { Loader2, Plus, Calendar, MapPin, Trash2 } from 'lucide-react';
import { motion } from 'framer-motion';
import { DeleteConfirmationModal } from '../components/ui/DeleteConfirmationModal';

interface Event {
    id: string;
    title: string;
    description: string;
    event_date: string;
    category: string;
    location?: string;
}

export const Events = () => {
    const { getToken, userRole, user } = useAuth();
    const [events, setEvents] = useState<Event[]>([]);
    const [loading, setLoading] = useState(true);
    const [showForm, setShowForm] = useState(false);

    // Edit State
    const [editingEvent, setEditingEvent] = useState<Event | null>(null);

    // Delete Confirmation State
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [eventToDelete, setEventToDelete] = useState<{ id: string, title: string } | null>(null);

    const [newEvent, setNewEvent] = useState({
        title: '',
        description: '',
        event_date: '',
        category: 'General',
        location: ''
    });

    const isAdmin = userRole === 'admin';

    useEffect(() => {
        if (user) {
            fetchEvents();
        }
    }, [user]);

    useEffect(() => {
        if (editingEvent) {
            setNewEvent({
                title: editingEvent.title,
                description: editingEvent.description,
                event_date: editingEvent.event_date.substring(0, 16), // Format for datetime-local
                category: editingEvent.category,
                location: editingEvent.location || ''
            });
            setShowForm(true);
        }
    }, [editingEvent]);

    const fetchEvents = async () => {
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/events`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (!data.error) setEvents(data);
        } catch (error) {
            console.error("Error fetching events:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleCloseForm = () => {
        setShowForm(false);
        setEditingEvent(null);
        setNewEvent({ title: '', description: '', event_date: '', category: 'General', location: '' });
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const token = await getToken();
            const url = editingEvent
                ? `${import.meta.env.VITE_API_URL}/api/events/${editingEvent.id}`
                : `${import.meta.env.VITE_API_URL}/api/events`;

            const method = editingEvent ? 'PUT' : 'POST';

            const res = await fetch(url, {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(newEvent)
            });

            if (res.ok) {
                toast.success(editingEvent ? "Event updated successfully" : "Event created successfully");
                fetchEvents();
                handleCloseForm();
            } else {
                toast.error(editingEvent ? "Failed to update event" : "Failed to create event");
            }
        } catch (error) {
            console.error("Error saving event:", error);
            toast.error("An error occurred");
        }
    };

    const confirmDelete = (id: string, title: string) => {
        setEventToDelete({ id, title });
        setShowDeleteConfirm(true);
    };

    const handleDelete = async () => {
        if (!eventToDelete) return;

        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/events/${eventToDelete.id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (res.ok) {
                fetchEvents();
                toast.success("Event deleted");
                setShowDeleteConfirm(false);
                setEventToDelete(null);
            } else {
                toast.error("Failed to delete event");
            }
        } catch (error) {
            console.error("Error deleting event:", error);
            toast.error("An error occurred");
        }
    };

    if (loading) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    return (
        <div className="p-8 h-full overflow-y-auto">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-white mb-2">Events & Notices</h1>
                    <p className="text-gray-400">Whatever's happening on campus</p>
                </div>
                {isAdmin && (
                    <button
                        onClick={() => setShowForm(true)}
                        className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors"
                    >
                        <Plus size={20} /> Add Event
                    </button>
                )}
            </div>

            {showForm && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 border border-gray-800 p-6 rounded-2xl w-full max-w-xl shadow-2xl">
                        <h2 className="text-xl font-bold text-white mb-4">{editingEvent ? 'Edit Event' : 'Add New Event'}</h2>
                        <form onSubmit={handleSave} className="space-y-4">
                            <input placeholder="Event Title" className="w-full bg-gray-800 rounded-lg p-3 text-white" value={newEvent.title} onChange={e => setNewEvent({ ...newEvent, title: e.target.value })} required />
                            <textarea placeholder="Description" className="w-full bg-gray-800 rounded-lg p-3 text-white h-32" value={newEvent.description} onChange={e => setNewEvent({ ...newEvent, description: e.target.value })} required />
                            <div className="grid grid-cols-2 gap-4">
                                <input type="datetime-local" className="w-full bg-gray-800 rounded-lg p-3 text-white" value={newEvent.event_date} onChange={e => setNewEvent({ ...newEvent, event_date: e.target.value })} required />
                                <input placeholder="Location (Optional)" className="w-full bg-gray-800 rounded-lg p-3 text-white" value={newEvent.location} onChange={e => setNewEvent({ ...newEvent, location: e.target.value })} />
                            </div>
                            <div className="flex justify-end gap-3 mt-4">
                                <button type="button" onClick={handleCloseForm} className="text-gray-400 hover:text-white px-3 py-2">Cancel</button>
                                <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg">
                                    {editingEvent ? 'Update Event' : 'Post Event'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {events.length === 0 && <div className="text-gray-500 col-span-3 text-center py-10">No upcoming events.</div>}

                {events.map(event => (
                    <motion.div
                        key={event.id}
                        initial={{ opacity: 0, scale: 0.95 }}
                        animate={{ opacity: 1, scale: 1 }}
                        className="bg-gray-900 border border-gray-800 rounded-xl overflow-hidden hover:border-indigo-500/50 transition-all group"
                    >
                        <div className="h-2 bg-indigo-500 w-full" />

                        <div className="p-4">
                            <div className="flex justify-between items-start mb-2">
                                <h3 className="text-white font-bold text-lg">{event.title}</h3>
                                {isAdmin && (
                                    <div className="flex gap-2">
                                        <button
                                            onClick={() => setEditingEvent(event)}
                                            className="text-gray-400 hover:text-indigo-400 p-2 transition-colors"
                                        >
                                            <Calendar size={18} />
                                            {/* Reuse Calendar icon for edit or map to pencil if available later */}
                                        </button>
                                        <button
                                            onClick={() => confirmDelete(event.id, event.title)}
                                            className="text-gray-400 hover:text-red-400 p-2 transition-colors"
                                        >
                                            <Trash2 size={18} />
                                        </button>
                                    </div>
                                )}
                            </div>

                            <div className="flex items-center gap-2 text-sm text-indigo-400 mb-3">
                                <Calendar size={14} />
                                <span>
                                    {new Date(event.event_date).toLocaleDateString(undefined, {
                                        weekday: 'short',
                                        year: 'numeric',
                                        month: 'short',
                                        day: 'numeric',
                                        timeZone: 'UTC'
                                    })}
                                    <span className="mx-2">•</span>
                                    {new Date(event.event_date).toLocaleTimeString(undefined, {
                                        hour: '2-digit',
                                        minute: '2-digit',
                                        timeZone: 'UTC'
                                    })}
                                </span>
                            </div>

                            <p className="text-gray-400 text-sm line-clamp-3 mb-4">{event.description}</p>

                            {event.location && (
                                <div className="flex items-center gap-2 text-xs text-gray-500 border-t border-gray-800 pt-3">
                                    <MapPin size={12} /> {event.location}
                                </div>
                            )}
                        </div>
                    </motion.div>
                ))}
            </div>
            {/* Delete Confirmation Modal */}
            <DeleteConfirmationModal
                isOpen={showDeleteConfirm}
                onClose={() => setShowDeleteConfirm(false)}
                onConfirm={handleDelete}
                itemName={eventToDelete?.title}
                itemType="event"
            />
        </div>
    );
};
