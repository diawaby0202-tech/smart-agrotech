import { useEffect } from 'react'
import { Outlet, useLocation } from 'react-router-dom'
import Navbar from './Navbar'

function ScrollEnHaut() {
  const { pathname } = useLocation()
  useEffect(() => {
    window.scrollTo(0, 0)
  }, [pathname])
  return null
}

export default function Layout() {
  return (
    <div className="app-shell">
      <ScrollEnHaut />
      <Navbar />
      <main className="contenu">
        <Outlet />
      </main>
      <footer className="pied-de-page">
        <p>Smart AgroTech Sénégal — Plateforme d’appui à l’agriculture et à l’élevage.</p>
        <p className="pied-de-page-sous">
          Suivi des cultures · Gestion du bétail · Alertes météo · Marché agricole
        </p>
      </footer>
    </div>
  )
}

