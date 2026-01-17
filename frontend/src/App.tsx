import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AppShell } from './components/layout/AppShell';
import { Landing } from './pages/Landing';
import { Dashboard } from './pages/Dashboard';
import { Chat } from './pages/Chat';
import { Timetable } from './pages/Timetable';
import { Reminders } from './pages/Reminders';
import { KnowledgeBase } from './pages/KnowledgeBase';
import { Events } from './pages/Events';
import { Profile } from './pages/Profile';
import { AuthProvider } from './contexts/AuthContext';
import { ProtectedRoute } from './components/layout/ProtectedRoute';
import { Auth } from './pages/Auth';
import { Onboarding } from './pages/Onboarding';
import { Toaster } from 'sonner';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Toaster position="top-center" theme="dark" richColors />
        <Routes>
          <Route path="/" element={<Landing />} />
          <Route path="/auth" element={<Auth />} />

          <Route path="/onboarding" element={
            <ProtectedRoute>
              <Onboarding />
            </ProtectedRoute>
          } />

          <Route path="/app" element={
            <ProtectedRoute>
              <AppShell />
            </ProtectedRoute>
          }>
            <Route index element={<Navigate to="dashboard" replace />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="chat" element={<Chat />} />
            <Route path="timetable" element={<Timetable />} />
            <Route path="reminders" element={<Reminders />} />
            <Route path="events-notices" element={<Events />} />
            <Route path="knowledge-base" element={<KnowledgeBase />} />
            <Route path="profile" element={<Profile />} />
          </Route>
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
