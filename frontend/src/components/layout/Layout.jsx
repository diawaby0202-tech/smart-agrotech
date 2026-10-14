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
        <div className="pied-de-page-interne">
          <div>
            <div className="pied-marque">
              <span aria-hidden="true">🌱</span> Smart AgroTech Sénégal
            </div>
            <p className="pied-texte">
              La plateforme numérique qui aide les agriculteurs et éleveurs sénégalais à
              mieux suivre leurs activités et à renforcer leur autonomie économique.
            </p>
          </div>
          <div className="pied-colonne">
            <h4>Modules</h4>
            <span>Suivi des cultures</span>
            <span>Gestion de l’élevage</span>
            <span>Alertes météo</span>
            <span>Marché agricole</span>
          </div>
          <div className="pied-colonne">
            <h4>La plateforme</h4>
            <span>Web & Mobile</span>
            <span>Accessible partout</span>
            <span>Données sécurisées</span>
          </div>
        </div>
        <div className="pied-bas">
          Smart AgroTech Sénégal — Projet académique. Conçu pour l’agriculture et l’élevage locaux.
        </div>
      </footer>
    </div>
  )
}

