import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.campusassistant.app',
  appName: 'Campus Assistant',
  webDir: 'dist',
  server: {
    androidScheme: 'http',
    allowNavigation: [
      '*.clerk.com',
      '*.clerk.accounts.dev',
      '*.google.com',
      'accounts.google.com'
    ]
  }
};

export default config;
