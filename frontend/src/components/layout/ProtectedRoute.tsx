import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Loader2 } from 'lucide-react';
export const ProtectedRoute = ({ children, allowedRoles }: { children: React.ReactNode, allowedRoles?: string[] }) => {
    const { user, userRole, isOnboarded, loading } = useAuth();
    const location = useLocation();

    if (loading) {
        return <div className="h-screen w-full flex items-center justify-center bg-black text-indigo-500"><Loader2 className="animate-spin" size={40} /></div>;
    }

    if (!user) {
        return <Navigate to="/auth" state={{ from: location }} replace />;
    }

    // New User -> Onboarding
    if (!isOnboarded && location.pathname !== '/onboarding') {
        return <Navigate to="/onboarding" replace />;
    }

    // Existing User -> Block Onboarding
    if (isOnboarded && location.pathname === '/onboarding') {
        return <Navigate to="/app/dashboard" replace />;
    }

    if (allowedRoles && userRole && !allowedRoles.includes(userRole)) {
        return <Navigate to="/app/dashboard" replace />;
    }

    return <>{children}</>;
};
