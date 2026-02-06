import express from 'express';
import adminRoutes from './routes/adminRoutes';
import chatRoutes from './routes/chatRoutes';

const app = express();
app.use('/api/admin', adminRoutes);

function printRoutes(stack: any, prefix = '') {
    stack.forEach((layer: any) => {
        if (layer.route) {
            const methods = Object.keys(layer.route.methods).join(',').toUpperCase();
            console.log(`${methods} ${prefix}${layer.route.path}`);
        } else if (layer.name === 'router') {
            printRoutes(layer.handle.stack, prefix + (layer.regexp.source.replace('\\/?(?=\\/|$)', '').replace('^', '').replace('\\/', '/')));
        }
    });
}

console.log('--- REGISTERED ROUTES ---');
printRoutes((adminRoutes as any).stack, '/api/admin');
