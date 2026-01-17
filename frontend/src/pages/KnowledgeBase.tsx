import { useState, useEffect } from 'react';
import { toast } from 'sonner';
import { useAuth } from '../contexts/AuthContext';
import { Loader2, Plus, Search, BookOpen, ChevronRight, X, Edit2, Trash2, Save } from 'lucide-react';
import { motion } from 'framer-motion';
import { DeleteConfirmationModal } from '../components/ui/DeleteConfirmationModal';

interface Article {
    id: string;
    title: string;
    content: string;
    category: string;
}

export const KnowledgeBase = () => {
    const { getToken, userRole } = useAuth();
    const [articles, setArticles] = useState<Article[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showForm, setShowForm] = useState(false);

    const [selectedArticle, setSelectedArticle] = useState<Article | null>(null);
    const [isEditing, setIsEditing] = useState(false);
    const [editForm, setEditForm] = useState<Article | null>(null);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

    const [newArticle, setNewArticle] = useState({
        title: '',
        content: '',
        category: 'General'
    });

    useEffect(() => {
        fetchArticles();
    }, []);

    const fetchArticles = async () => {
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/kb`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (!data.error) setArticles(data);
        } catch (error) {
            console.error("Error fetching articles:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!searchQuery.trim()) {
            fetchArticles();
            return;
        }
        setLoading(true);
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/kb/search?query=${encodeURIComponent(searchQuery)}`, {
                headers: { 'Authorization': `Bearer ${token}` }
            });
            const data = await res.json();
            if (!data.error) setArticles(data);
        } catch (error) {
            console.error("Error searching:", error);
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/kb`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(newArticle)
            });
            if (res.ok) {
                fetchArticles();
                setShowForm(false);
                setNewArticle({ title: '', content: '', category: 'General' });
            }
        } catch (error) {
            console.error("Error adding article:", error);
        }
    };
    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!editForm) return;
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/kb/${editForm.id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify(editForm)
            });

            if (res.ok) {
                toast.success("Article updated successfully");
                fetchArticles();
                setIsEditing(false);
                setSelectedArticle(editForm); // Update the view
            } else {
                toast.error("Failed to update article");
            }
        } catch (error) {
            console.error("Error updating article:", error);
            toast.error("An error occurred while updating");
        }
    };

    const confirmDelete = () => {
        setShowDeleteConfirm(true);
    };

    const handleDelete = async () => {
        if (!selectedArticle) return;
        try {
            const token = await getToken();
            const res = await fetch(`${import.meta.env.VITE_API_URL}/api/kb/${selectedArticle.id}`, {
                method: 'DELETE',
                headers: { 'Authorization': `Bearer ${token}` }
            });

            if (res.ok) {
                toast.success("Article deleted");
                fetchArticles();
                setSelectedArticle(null);
                setShowDeleteConfirm(false);
            } else {
                toast.error("Failed to delete article");
            }
        } catch (error) {
            console.error("Error deleting article:", error);
            toast.error("An error occurred while deleting");
        }
    };

    const openArticle = (article: Article) => {
        setSelectedArticle(article);
        setEditForm(article);
        setIsEditing(false);
    };

    if (loading && !searchQuery) return <div className="p-8 text-white flex justify-center"><Loader2 className="animate-spin" /></div>;

    return (
        <div className="p-8 h-full overflow-y-auto">
            <div className="flex justify-between items-center mb-8">
                <div>
                    <h1 className="text-3xl font-bold text-white mb-2">Knowledge Base</h1>
                    <p className="text-gray-400">Campus Information & FAQs</p>
                </div>
                {['admin', 'faculty'].includes(userRole || '') && (
                    <button
                        onClick={() => setShowForm(true)}
                        className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors"
                    >
                        <Plus size={20} /> Add Article
                    </button>
                )}
            </div>

            {/* Search Bar */}
            <form onSubmit={handleSearch} className="mb-8 relative max-w-2xl">
                <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                <input
                    type="text"
                    placeholder="Search for policies, locations, or guides..."
                    className="w-full bg-gray-900 border border-gray-800 rounded-xl py-4 pl-12 pr-4 text-white focus:border-indigo-500/50 outline-none transition-colors"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                />
            </form>

            {/* Recents Section */}
            {!searchQuery && articles.length > 0 && (
                <div className="mb-10">
                    <h2 className="text-lg font-semibold text-gray-400 mb-4 flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-indigo-500"></span> Recently Added
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                        {articles.slice(0, 3).map(article => (
                            <motion.div
                                key={article.id}
                                initial={{ opacity: 0, scale: 0.95 }}
                                animate={{ opacity: 1, scale: 1 }}
                                onClick={() => openArticle(article)}
                                className="bg-gradient-to-br from-gray-900 to-gray-800 border border-gray-700 p-5 rounded-xl hover:shadow-lg hover:shadow-indigo-500/10 transition-all cursor-pointer"
                            >
                                <div className="flex justify-between items-start mb-3">
                                    <span className="text-xs font-medium text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded-md">{article.category}</span>
                                    <BookOpen size={16} className="text-gray-500" />
                                </div>
                                <h3 className="text-white font-semibold mb-2 line-clamp-1">{article.title}</h3>
                                <p className="text-gray-400 text-xs line-clamp-2">{article.content}</p>
                            </motion.div>
                        ))}
                    </div>
                </div>
            )}

            {/* Enlarged View / Edit Modal */}
            {selectedArticle && (
                <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                    <div className="bg-gray-900 border border-gray-800 p-6 rounded-2xl w-full max-w-4xl shadow-2xl max-h-[90vh] overflow-y-auto relative">
                        <button
                            onClick={() => setSelectedArticle(null)}
                            className="absolute top-4 right-4 text-gray-400 hover:text-white p-2"
                        >
                            <X size={24} />
                        </button>

                        {!isEditing ? (
                            // View Mode
                            <div>
                                <div className="flex items-center gap-3 mb-6">
                                    <span className="text-xs font-medium text-emerald-400 bg-emerald-400/10 px-2 py-1 rounded-md">
                                        {selectedArticle.category}
                                    </span>
                                    {['admin', 'faculty'].includes(userRole || '') && (
                                        <div className="flex gap-2">
                                            <button onClick={() => setIsEditing(true)} className="text-gray-400 hover:text-indigo-400 p-1">
                                                <Edit2 size={18} />
                                            </button>
                                            <button onClick={confirmDelete} className="text-gray-400 hover:text-red-400 p-1">
                                                <Trash2 size={18} />
                                            </button>
                                        </div>
                                    )}
                                </div>
                                <h2 className="text-3xl font-bold text-white mb-6">{selectedArticle.title}</h2>
                                <div className="prose prose-invert max-w-none text-gray-300 whitespace-pre-wrap">
                                    {selectedArticle.content}
                                </div>
                            </div>
                        ) : (
                            // Edit Mode
                            <form onSubmit={handleUpdate} className="space-y-4 pt-4">
                                <div className="flex justify-between items-center mb-4">
                                    <h2 className="text-xl font-bold text-white">Edit Article</h2>
                                    <button type="button" onClick={() => setIsEditing(false)} className="text-gray-400 hover:text-white px-3 py-1 text-sm">Cancel Editing</button>
                                </div>
                                <input
                                    placeholder="Title"
                                    className="w-full bg-gray-800 rounded-lg p-3 text-white font-bold text-lg"
                                    value={editForm?.title}
                                    onChange={e => setEditForm(prev => prev ? { ...prev, title: e.target.value } : null)}
                                    required
                                />
                                <div className="grid grid-cols-2 gap-4">
                                    <input
                                        placeholder="Category"
                                        className="w-full bg-gray-800 rounded-lg p-3 text-white"
                                        value={editForm?.category}
                                        onChange={e => setEditForm(prev => prev ? { ...prev, category: e.target.value } : null)}
                                    />
                                </div>
                                <textarea
                                    placeholder="Content"
                                    className="w-full bg-gray-800 rounded-lg p-4 text-white h-96 font-mono text-sm leading-relaxed"
                                    value={editForm?.content}
                                    onChange={e => setEditForm(prev => prev ? { ...prev, content: e.target.value } : null)}
                                    required
                                />
                                <div className="flex justify-end pt-4">
                                    <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-2 rounded-lg flex items-center gap-2">
                                        <Save size={18} /> Save Changes
                                    </button>
                                </div>
                            </form>
                        )}
                    </div>
                </div>
            )}



            {/* Delete Confirmation Modal */}
            <DeleteConfirmationModal
                isOpen={showDeleteConfirm}
                onClose={() => setShowDeleteConfirm(false)}
                onConfirm={handleDelete}
                itemName={selectedArticle?.title}
                itemType="article"
            />

            {/* Add Modal */}
            {
                showForm && (
                    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                        <div className="bg-gray-900 border border-gray-800 p-6 rounded-2xl w-full max-w-2xl shadow-2xl">
                            <h2 className="text-xl font-bold text-white mb-4">New Knowledge Article</h2>
                            <form onSubmit={handleAdd} className="space-y-4">
                                <input placeholder="Title" className="w-full bg-gray-800 rounded-lg p-2 text-white" value={newArticle.title} onChange={e => setNewArticle({ ...newArticle, title: e.target.value })} required />
                                <textarea placeholder="Content (Markdown supported)" className="w-full bg-gray-800 rounded-lg p-2 text-white h-60 font-mono text-sm" value={newArticle.content} onChange={e => setNewArticle({ ...newArticle, content: e.target.value })} required />
                                <input placeholder="Category" className="w-full bg-gray-800 rounded-lg p-2 text-white" value={newArticle.category} onChange={e => setNewArticle({ ...newArticle, category: e.target.value })} />

                                <div className="flex justify-end gap-3 mt-4">
                                    <button type="button" onClick={() => setShowForm(false)} className="text-gray-400 hover:text-white px-3 py-2">Cancel</button>
                                    <button type="submit" className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg">Publish Article</button>
                                </div>
                            </form>
                        </div>
                    </div>
                )
            }

            {/* Articles List */}
            <div>
                <h2 className="text-lg font-semibold text-gray-400 mb-4">All Articles</h2>
                <div className="grid grid-cols-1 gap-4">
                    {articles.length === 0 && (
                        <div className="text-gray-500 text-center py-10">No articles found. Add one to get started!</div>
                    )}
                    {articles.map(article => (
                        <motion.div
                            key={article.id}
                            initial={{ opacity: 0, y: 10 }}
                            animate={{ opacity: 1, y: 0 }}
                            onClick={() => openArticle(article)}
                            className="bg-gray-900 border border-gray-800 p-6 rounded-xl hover:border-gray-700 transition-colors cursor-pointer group"
                        >
                            <div className="flex items-start justify-between">
                                <div className="flex items-center gap-3 mb-2">
                                    <div className="p-2 bg-indigo-500/10 rounded-lg">
                                        <BookOpen size={20} className="text-indigo-400" />
                                    </div>
                                    <div>
                                        <h3 className="font-semibold text-white group-hover:text-indigo-400 transition-colors">{article.title}</h3>
                                        <span className="text-xs text-gray-500 bg-gray-800 px-2 py-0.5 rounded-full">{article.category}</span>
                                    </div>
                                </div>
                                <ChevronRight className="text-gray-600 group-hover:text-gray-400" />
                            </div>
                            <p className="text-gray-400 text-sm mt-2 line-clamp-2">{article.content}</p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </div >
    );
};
