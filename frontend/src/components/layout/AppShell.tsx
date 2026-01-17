import { useState } from 'react';
import { Outlet, NavLink } from 'react-router-dom';
import { LayoutDashboard, MessageSquare, Calendar, Bell, Book, FileText, User, LogOut, Menu, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import clsx from 'clsx';
import { useAuth } from '../../contexts/AuthContext';

const SidebarItem = ({ to, icon: Icon, label, onClick }: { to: string, icon: any, label: string, onClick?: () => void }) => (
    <NavLink
        to={to}
        onClick={onClick}
        className={({ isActive }) =>
            clsx(
                "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors",
                isActive ? "bg-indigo-600 text-white" : "text-gray-300 hover:bg-gray-800 hover:text-white"
            )
        }
    >
        <Icon size={20} />
        <span className="font-medium">{label}</span>
    </NavLink>
);

export const AppShell = () => {
    const [isSidebarOpen, setSidebarOpen] = useState(false);
    const { signOut } = useAuth();

    const toggleSidebar = () => setSidebarOpen(!isSidebarOpen);
    const closeSidebar = () => setSidebarOpen(false);

    return (
        <div className="flex h-screen bg-gray-900 text-gray-100 overflow-hidden font-sans">
            {/* Mobile Sidebar Overlay */}
            <AnimatePresence>
                {isSidebarOpen && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 0.5 }}
                        exit={{ opacity: 0 }}
                        onClick={closeSidebar}
                        className="fixed inset-0 bg-black z-20 md:hidden"
                    />
                )}
            </AnimatePresence>

            {/* Sidebar */}
            <motion.aside
                className={clsx(
                    "fixed inset-y-0 left-0 z-30 w-64 bg-gray-950 border-r border-gray-800 transform md:transform-none md:relative transition-transform duration-300 ease-in-out",
                    isSidebarOpen ? "translate-x-0" : "-translate-x-full"
                )}
            >
                <div className="p-6 flex items-center justify-between">
                    <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-400 to-purple-400 bg-clip-text text-transparent">
                        Campus OS
                    </h1>
                    <button onClick={closeSidebar} className="md:hidden text-gray-400 hover:text-white">
                        <X size={24} />
                    </button>
                </div>

                <nav className="px-4 space-y-2 mt-4">
                    <SidebarItem to="/app/dashboard" icon={LayoutDashboard} label="Dashboard" onClick={closeSidebar} />
                    <SidebarItem to="/app/chat" icon={MessageSquare} label="Assistant" onClick={closeSidebar} />
                    <SidebarItem to="/app/timetable" icon={Calendar} label="Timetable" onClick={closeSidebar} />
                    <SidebarItem to="/app/reminders" icon={Bell} label="Reminders" onClick={closeSidebar} />
                    <SidebarItem to="/app/events-notices" icon={FileText} label="Events & Notices" onClick={closeSidebar} />
                    <SidebarItem to="/app/knowledge-base" icon={Book} label="Knowledge Base" onClick={closeSidebar} />
                </nav>

                <div className="absolute bottom-0 w-full p-4 border-t border-gray-800">
                    <SidebarItem to="/app/profile" icon={User} label="Profile" onClick={closeSidebar} />
                    {/* <SidebarItem to="/app/admin" icon={Settings} label="Admin" onClick={closeSidebar} /> */}
                    <button onClick={() => {
                        signOut();
                        closeSidebar();
                    }} className="flex w-full items-center gap-3 px-4 py-3 text-gray-400 hover:text-red-400 transition-colors mt-2">
                        <LogOut size={20} />
                        <span>Log Out</span>
                    </button>
                </div>
            </motion.aside>

            {/* Main Content */}
            <div className="flex-1 flex flex-col h-full overflow-hidden relative">
                {/* Mobile Header */}
                <header className="md:hidden flex items-center justify-between p-4 bg-gray-900 border-b border-gray-800">
                    <div className="text-lg font-bold">Campus Assistant</div>
                    <button onClick={toggleSidebar} className="text-gray-300">
                        <Menu size={24} />
                    </button>
                </header>

                <main className="flex-1 overflow-y-auto p-4 md:p-8 relative">
                    {/* Background Elements could go here */}
                    <Outlet />
                </main>
            </div>
        </div>
    );
};
