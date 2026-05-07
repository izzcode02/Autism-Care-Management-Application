import { Routes, Route } from 'react-router-dom';
import App from '../App';
import Auth from '../auth/auth';

export default function AppRoutes() {
  return (
    <Routes>
      <Route path="/" element={<App />} />
      <Route path="/auth" element={<Auth />} />
    </Routes>
  );
}