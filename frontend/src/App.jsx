import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { AuthProvider } from './context/AuthContext'
import { RouteProtegee, RoutePublique } from './routes/RouteProtegee'
import Layout from './components/layout/Layout'
import Accueil from './pages/Accueil'
import Connexion from './pages/Connexion'
import Inscription from './pages/Inscription'
import Profil from './pages/Profil'
import TableauDeBord from './pages/TableauDeBord'
import Cultures from './pages/Cultures'
import Elevage from './pages/Elevage'
import Alertes from './pages/Alertes'
import Marche from './pages/Marche'
import NonTrouve from './pages/NonTrouve'
import Administration from './pages/admin/Administration'
import GestionUtilisateurs from './pages/admin/GestionUtilisateurs'
import Statistiques from './pages/admin/Statistiques'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route element={<Layout />}>
            {/* Pages publiques */}
            <Route index element={<Accueil />} />
            <Route path="/cultures" element={<Cultures />} />
            <Route path="/elevage" element={<Elevage />} />
            <Route path="/alertes" element={<Alertes />} />
            <Route path="/marche" element={<Marche />} />

            {/* Authentification (reserve aux visiteurs) */}
            <Route
              path="/connexion"
              element={
                <RoutePublique>
                  <Connexion />
                </RoutePublique>
              }
            />
            <Route
              path="/inscription"
              element={
                <RoutePublique>
                  <Inscription />
                </RoutePublique>
              }
            />

            {/* Espace connecte */}
            <Route
              path="/tableau-de-bord"
              element={
                <RouteProtegee>
                  <TableauDeBord />
                </RouteProtegee>
              }
            />
            <Route
              path="/profil"
              element={
                <RouteProtegee>
                  <Profil />
                </RouteProtegee>
              }
            />

            {/* Administration (reserve au role admin) */}
            <Route
              path="/administration"
              element={
                <RouteProtegee roles={['admin']}>
                  <Administration />
                </RouteProtegee>
              }
            />
            <Route
              path="/administration/utilisateurs"
              element={
                <RouteProtegee roles={['admin']}>
                  <GestionUtilisateurs />
                </RouteProtegee>
              }
            />
            <Route
              path="/administration/statistiques"
              element={
                <RouteProtegee roles={['admin']}>
                  <Statistiques />
                </RouteProtegee>
              }
            />

            {/* Divers */}
            <Route path="/accueil" element={<Navigate to="/" replace />} />
            <Route path="*" element={<NonTrouve />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
