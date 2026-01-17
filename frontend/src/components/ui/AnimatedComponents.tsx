import { motion } from 'framer-motion';

export const FadeIn = ({ children, delay = 0, className = '' }: { children: React.ReactNode, delay?: number, className?: string }) => (
    <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.5, delay }}
        className={className}
    >
        {children}
    </motion.div>
);

export const AnimatedText = ({ text, className = '' }: { text: string, className?: string }) => {
    // Split text into words
    const words = text.split(" ");

    const container = {
        hidden: { opacity: 0 },
        visible: (i = 1) => ({
            opacity: 1,
            transition: { staggerChildren: 0.12, delayChildren: 0.04 * i },
        }),
        exit: {
            opacity: 0,
            transition: { staggerChildren: 0.05, staggerDirection: -1 }
        }
    };

    const child = {
        visible: {
            opacity: 1,
            y: 0,
            transition: {
                type: "spring",
                damping: 12,
                stiffness: 100,
            } as any,
        },
        hidden: {
            opacity: 0,
            y: 20,
            transition: {
                type: "spring",
                damping: 12,
                stiffness: 100,
            } as any,
        },
        exit: {
            opacity: 0,
            y: -20,
            transition: { duration: 0.2 }
        }
    };

    return (
        <motion.div
            style={{ overflow: "hidden", display: "flex", flexWrap: "wrap" }}
            variants={container}
            initial="hidden"
            animate="visible"
            exit="exit"
            className={className}
        >
            {words.map((word, index) => (
                <div key={index} style={{ display: 'flex', marginRight: '0.25em', whiteSpace: 'nowrap' }}>
                    {Array.from(word).map((letter, letterIndex) => (
                        <motion.span variants={child} key={letterIndex}>
                            {letter}
                        </motion.span>
                    ))}
                </div>
            ))}
        </motion.div>
    );
};
