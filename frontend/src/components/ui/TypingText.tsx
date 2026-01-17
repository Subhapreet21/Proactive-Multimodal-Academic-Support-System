import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

interface TypingTextProps {
    words: string[];
    className?: string;
    typingSpeed?: number;
    deletingSpeed?: number;
    pauseTime?: number;
}

export const TypingText = ({
    words,
    className = "",
    typingSpeed = 150,
    deletingSpeed = 100,
    pauseTime = 2000
}: TypingTextProps) => {
    const [displayedText, setDisplayedText] = useState("");
    const [isDeleting, setIsDeleting] = useState(false);
    const [loopNum, setLoopNum] = useState(0);
    const [speed, setSpeed] = useState(typingSpeed);

    useEffect(() => {
        const handleTyping = () => {
            const i = loopNum % words.length;
            const fullText = words[i];

            setDisplayedText(prev =>
                isDeleting
                    ? fullText.substring(0, prev.length - 1)
                    : fullText.substring(0, prev.length + 1)
            );

            // Determine typing speed
            if (isDeleting) {
                setSpeed(deletingSpeed);
            } else {
                setSpeed(typingSpeed);
            }

            // If finished typing
            if (!isDeleting && displayedText === fullText) {
                setSpeed(pauseTime);
                setIsDeleting(true);
            }
            // If finished deleting
            else if (isDeleting && displayedText === "") {
                setIsDeleting(false);
                setLoopNum(loopNum + 1);
                setSpeed(500); // Pause before starting new word
            }
        };

        const timer = setTimeout(handleTyping, speed);
        return () => clearTimeout(timer);
    }, [displayedText, isDeleting, loopNum, words, speed, typingSpeed, deletingSpeed, pauseTime]);

    return (
        <div className={className}>
            <span>{displayedText}</span>
            <motion.span
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ duration: 0.5, repeat: Infinity, repeatType: "reverse" }}
                className="inline-block w-[3px] h-[1em] bg-indigo-500 ml-1 align-middle"
            />
        </div>
    );
};
