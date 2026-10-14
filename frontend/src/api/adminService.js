import apiClient from './axiosClient'

/**
 * RF-20 : liste de tous les utilisateurs inscrits (filtrable par rôle/statut).
 */
export async function listerUtilisateurs({ role, statut } = {}) {
  const { data } = await apiClient.get('/admin/users/', {
    params: { role, statut },
  })
  return data
}

/**
 * RF-21 : modifier un compte utilisateur (ex. valider, changer un champ).
 */
export async function modifierUtilisateur(id, donnees) {
  const { data } = await apiClient.patch(`/admin/users/${id}/`, donnees)
  return data
}

/**
 * RF-21 : suspendre un compte utilisateur.
 */
export async function suspendreUtilisateur(id) {
  const { data } = await apiClient.patch(`/admin/users/${id}/`, { statut: 'suspendu' })
  return data
}

/**
 * RF-03 : valider un compte en attente.
 */
export async function validerUtilisateur(id) {
  const { data } = await apiClient.patch(`/admin/users/${id}/`, { statut: 'valide' })
  return data
}

/**
 * RF-03 : refuser un compte en attente.
 */
export async function refuserUtilisateur(id) {
  const { data } = await apiClient.patch(`/admin/users/${id}/`, { statut: 'refuse' })
  return data
}

/**
 * RF-21 : supprimer un compte utilisateur.
 */
export async function supprimerUtilisateur(id) {
  await apiClient.delete(`/admin/users/${id}/`)
}

/**
 * RF-23 : statistiques globales d'utilisation de la plateforme.
 */
export async function obtenirStatistiques() {
  const { data } = await apiClient.get('/admin/stats/')
  return data
}
