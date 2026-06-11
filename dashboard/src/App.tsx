import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider, useAuth } from './context/AuthContext';
import { I18nProvider } from './lib/i18n';
import Layout from './components/Layout';
import Login from './pages/Login';
import Overview from './pages/Overview';
import Orders from './pages/Orders';
import Rides from './pages/Rides';
import Parcels from './pages/Parcels';
import Bookings from './pages/Bookings';
import Stores from './pages/Stores';
import Drivers from './pages/Drivers';
import Users from './pages/Users';
import Marketing from './pages/Marketing';
import Finance from './pages/Finance';
import Jobs from './pages/Jobs';
import Support from './pages/Support';
import Team from './pages/Team';
import Cities from './pages/Cities';
import Notes from './pages/Notes';
import Logs from './pages/Logs';
import Training from './pages/Training';
import CitySettings from './pages/CitySettings';
import Banners from './pages/Banners';
import Marketplace from './pages/Marketplace';
import Settings from './pages/Settings';
import { Spinner } from './components/ui';

const queryClient = new QueryClient();

function Guarded() {
  const { user, loading } = useAuth();
  if (loading) return <div className="min-h-screen grid place-items-center"><Spinner /></div>;
  if (!user) return <Login />;
  return <Layout />;
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <I18nProvider>
        <AuthProvider>
          <BrowserRouter>
            <Routes>
              <Route element={<Guarded />}>
                <Route path="/" element={<Overview />} />
                <Route path="/orders" element={<Orders />} />
                <Route path="/rides" element={<Rides />} />
                <Route path="/parcels" element={<Parcels />} />
                <Route path="/bookings" element={<Bookings />} />
                <Route path="/stores" element={<Stores />} />
                <Route path="/drivers" element={<Drivers />} />
                <Route path="/users" element={<Users />} />
                <Route path="/marketing" element={<Marketing />} />
                <Route path="/finance" element={<Finance />} />
                <Route path="/jobs" element={<Jobs />} />
                <Route path="/support" element={<Support />} />
                <Route path="/team" element={<Team />} />
                <Route path="/cities" element={<Cities />} />
                <Route path="/cities/:id" element={<CitySettings />} />
                <Route path="/banners" element={<Banners />} />
                <Route path="/marketplace" element={<Marketplace />} />
                <Route path="/notes" element={<Notes />} />
                <Route path="/logs" element={<Logs />} />
                <Route path="/training" element={<Training />} />
                <Route path="/settings" element={<Settings />} />
                <Route path="*" element={<Navigate to="/" replace />} />
              </Route>
            </Routes>
          </BrowserRouter>
        </AuthProvider>
      </I18nProvider>
    </QueryClientProvider>
  );
}
