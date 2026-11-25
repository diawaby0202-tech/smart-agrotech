import { createContext, useContext, useEffect, useState } from 'react'
import { clearTokens, getAccessToken } from '../api/axiosClient'
import {
  connexion as connexionApi,
  deconnexion as deconnexionApi,
  obtenirProfil,
  inscription as inscriptionApi,
} from '../api/authService'

const AuthContext = createContext(null)

const ROLES = {
  PRODUCTEUR: 'producteur',
  ACHETEUR: 'acheteur',
  ADMIN: 'admin',
}

export function AuthProvider({ children }) {
  const [utilisateur, setUtilisateur] = useState(null)
  const [chargement, setChargement] = useState(true)

  // Au dÃ©marrage : si un token est prÃ©sent, on rÃ©cupÃ¨re le profil associÃ©.
  useEffect(() => {
    let actif = true

    async function restaurerSession() {
      const token = getAccessToken()
      if (!token) {
        if (actif) setChargement(false)
        return
      }
      try {
        const profil = await obtenirProfil()
        if (actif) setUtilisateur(profil)
      } catch {
        // Token invalide/expirÃ© et refresh impossible : on nettoie la session.
        clearTokens()
        if (actif) setUtilisateur(null)
      } finally {
        if (actif) setChargement(false)
      }
    }

    restaurerSession()
    return () => {
      actif = false
    }
  }, [])

  async function connexion(identifiants) {
    await connexionApi(identifiants)
    const profil = await obtenirProfil()
    setUtilisateur(profil)
    return profil
  }

  async function inscription(donnees) {
    const utilisateurCree = await inscriptionApi(donnees)
    return utilisateurCree
  }

  async function rafraichirProfil() {
    const profil = await obtenirProfil()
    setUtilisateur(profil)
    return profil
  }

  function deconnexion() {
    deconnexionApi()
    setUtilisateur(null)
  }

  function modifierUtilisateurLocal(profil) {
    setUtilisateur(profil)
  }

  const valeur = {
    utilisateur,
    chargement,
    estConnecte: Boolean(utilisateur),
    estAdmin: utilisateur?.role === ROLES.ADMIN,
    roles: ROLES,
    connexion,
    inscription,
    deconnexion,
    rafraichirProfil,
    modifierUtilisateurLocal,
  }

  return <AuthContext.Provider value={valeur}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const contexte = useContext(AuthContext)
  if (!contexte) {
    throw new Error('useAuth doit Ãªtre utilisÃ© Ã  lâ€™intÃ©rieur dâ€™un <AuthProvider>')
  }
  return contexte
}

