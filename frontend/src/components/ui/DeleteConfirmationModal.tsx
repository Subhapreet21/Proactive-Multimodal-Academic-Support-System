import { Trash2 } from 'lucide-react';

interface DeleteConfirmationModalProps {
    isOpen: boolean;
    onClose: () => void;
    onConfirm: () => void;
    itemName?: string;
    itemType?: string;
}

export const DeleteConfirmationModal = ({
    isOpen,
    onClose,
    onConfirm,
    itemName,
    itemType = "item"
}: DeleteConfirmationModalProps) => {
    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-[60] p-4">
            <div className="bg-gray-900 border border-red-500/30 p-6 rounded-2xl w-full max-w-sm shadow-2xl transform transition-all scale-100">
                <div className="flex flex-col items-center text-center">
                    <div className="bg-red-500/10 p-4 rounded-full mb-4">
                        <Trash2 size={32} className="text-red-500" />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">Delete {itemType.charAt(0).toUpperCase() + itemType.slice(1)}?</h3>
                    <p className="text-gray-400 mb-6">
                        Are you sure you want to delete {itemName ? <span className="text-white font-semibold">"{itemName}"</span> : `this ${itemType}`}? This action cannot be undone.
                    </p>
                    <div className="flex gap-3 w-full">
                        <button
                            onClick={onClose}
                            className="flex-1 bg-gray-800 hover:bg-gray-700 text-white py-3 rounded-xl transition-colors font-medium"
                        >
                            Cancel
                        </button>
                        <button
                            onClick={onConfirm}
                            className="flex-1 bg-red-600 hover:bg-red-700 text-white py-3 rounded-xl transition-colors font-medium shadow-lg shadow-red-500/20"
                        >
                            Delete
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};
