import apiClient, { clearTokens, setTokens } from './axiosClient'

/**
 * RF-01 : création de compte (producteur/éleveur ou acheteur).
 */
export async function inscription(donnees) {
  const { data } = await apiClient.post('/auth/register/', donnees)
  return data
}

/**
 * RF-02 : connexion par email / mot de passe, récupération des tokens JWT.
 */
export async function connexion({ email, password }) {
  const { data } = await apiClient.post('/auth/login/', { email, password })
  setTokens({ access: data.access, refresh: data.refresh })
  return data
}

/**
 * RF-04 : déconnexion (purge des tokens côté client).
 */
export function deconnexion() {
  clearTokens()
}

/**
 * RF-05 : consultation du profil de l'utilisateur connecté.
 */
export async function obtenirProfil() {
  const { data } = await apiClient.get('/users/me/')
  return data
}

/**
 * RF-05 : modification du profil de l'utilisateur connecté.
 */
export async function modifierProfil(donnees) {
  const { data } = await apiClient.patch('/users/me/', donnees)
  return data
}
