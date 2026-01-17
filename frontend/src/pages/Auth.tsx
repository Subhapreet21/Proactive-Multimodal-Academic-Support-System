import { SignIn, SignUp } from '@clerk/clerk-react';
import { dark } from '@clerk/themes';
import { FadeIn } from '../components/ui/AnimatedComponents';
import { useState } from 'react';

export const Auth = () => {
    const [isSignUp, setIsSignUp] = useState(false);

    return (
        <div className="min-h-screen bg-black text-white flex items-center justify-center p-4">
            <FadeIn className="w-full max-w-md flex flex-col items-center justify-center">

                <div className="absolute top-8 left-8">
                    <a href="/" className="flex items-center gap-2 text-gray-400 hover:text-white transition-colors group">
                        <span className="group-hover:-translate-x-1 transition-transform">←</span>
                        Back to Home
                    </a>
                </div>

                {isSignUp ? (
                    <SignUp
                        appearance={{
                            baseTheme: dark,
                            elements: {
                                card: "bg-gray-900/50 border border-gray-800 backdrop-blur-sm",
                                headerTitle: "text-indigo-400",
                                headerSubtitle: "text-gray-400",
                                footerAction: "hidden"
                            }
                        }}
                        afterSignUpUrl="/app/dashboard"
                        signInUrl="#"
                    />
                ) : (
                    <SignIn
                        appearance={{
                            baseTheme: dark,
                            elements: {
                                card: "bg-gray-900/50 border border-gray-800 backdrop-blur-sm",
                                headerTitle: "text-indigo-400",
                                headerSubtitle: "text-gray-400",
                                footerAction: "hidden"
                            }
                        }}
                        afterSignInUrl="/app/dashboard"
                        signUpUrl="#"
                    />
                )}

                <div className="mt-6 text-center text-sm text-gray-400">
                    {isSignUp ? "Already have an account?" : "Don't have an account?"}{" "}
                    <button
                        onClick={() => setIsSignUp(!isSignUp)}
                        className="text-indigo-400 hover:text-indigo-300 font-medium ml-1 hover:underline"
                    >
                        {isSignUp ? "Sign In" : "Sign Up"}
                    </button>
                </div>
            </FadeIn>
        </div>
    );
};
