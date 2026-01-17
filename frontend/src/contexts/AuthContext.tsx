import { createContext, useContext, useEffect, useState } from 'react';
import { useUser, useAuth as useClerkAuth } from '@clerk/clerk-react';

interface AuthContextType {
    user: any | null; // Clerk user object
    userRole: string | null;
    isOnboarded: boolean;
    loading: boolean;
    signOut: () => Promise<void>;
    getToken: () => Promise<string | null>;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    userRole: null,
    isOnboarded: false,
    loading: true,
    signOut: async () => { },
    getToken: async () => null,
});

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
    const { user, isLoaded: isUserLoaded } = useUser();
    const { getToken, isLoaded: isAuthLoaded } = useClerkAuth();
    const [userRole, setUserRole] = useState<string | null>(null);

    const loading = !isUserLoaded || !isAuthLoaded;

    // Check if user has completed onboarding (has role in metadata)
    const isOnboarded = !!(user?.publicMetadata as any)?.role;

    useEffect(() => {
        const syncUserWithBackend = async () => {
            if (user && isAuthLoaded) {
                try {
                    const token = await getToken();
                    if (!token) return;

                    const res = await fetch(`${import.meta.env.VITE_API_URL}/api/auth/sync`, {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'Authorization': `Bearer ${token}`
                        },
                        body: JSON.stringify({
                            email: user.primaryEmailAddress?.emailAddress,
                            fullName: user.fullName,
                            avatarUrl: user.imageUrl
                        })
                    });

                    if (res.ok) {
                        const profile = await res.json();
                        // Priority: DB Role -> Clerk Metadata -> null
                        setUserRole(profile.role || (user.publicMetadata as any)?.role || 'student');
                    }
                } catch (error) {
                    console.error("Failed to sync user:", error);
                }
            } else if (!user && isAuthLoaded) {
                setUserRole(null);
            }
        };

        syncUserWithBackend();
    }, [user, isAuthLoaded, getToken]);

    const signOut = async () => {
        // useAuth's signOut is now strictly a local "Force Clear" to guarantee behavior matches the working debug button.
        // We avoid calling clerkSignOut() here because it appears to interfere with the cookie clearing in this specific env.

        console.log("DEBUG: executing force clear signOut");

        // 1. Aggressive Cookie Clearing
        document.cookie.split(";").forEach((c) => {
            document.cookie = c.replace(/^ +/, "").replace(/=.*/, "=;expires=" + new Date().toUTCString() + ";path=/");
        });

        // 2. Clear Storage
        window.localStorage.clear();
        window.sessionStorage.clear();

        // 3. Force Hard Redirect
        window.location.href = '/';
    };

    return (
        <AuthContext.Provider value={{ user, userRole, isOnboarded, loading, signOut, getToken }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);
