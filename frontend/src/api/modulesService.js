import apiClient from './axiosClient'

/** Les listes DRF peuvent être paginées ({ results: [] }) ou simples ([]). */
function enListe(data) {
  if (Array.isArray(data)) return data
  return data?.results ?? []
}

/** Transforme une erreur de l'API en message lisible en français. */
export function messageErreur(error, defaut = 'Une erreur est survenue. Réessayez.') {
  const data = error?.response?.data
  if (!error?.response) return 'Serveur injoignable. Vérifiez que le backend est démarré.'
  if (data?.detail) return String(data.detail)
  if (data && typeof data === 'object') {
    const premier = Object.entries(data)
      .map(([champ, valeur]) => {
        const texte = Array.isArray(valeur) ? valeur[0] : valeur
        return champ === 'non_field_errors' ? String(texte) : `${champ} : ${texte}`
      })
      .find(Boolean)
    if (premier) return premier
  }
  return defaut
}

/* --- Cultures (RF-06 à RF-09) -------------------------------------------- */
export const parcelles = {
  lister: async () => enListe((await apiClient.get('/parcelles/')).data),
  creer: async (donnees) => (await apiClient.post('/parcelles/', donnees)).data,
  modifier: async (id, donnees) => (await apiClient.patch(`/parcelles/${id}/`, donnees)).data,
  supprimer: async (id) => apiClient.delete(`/parcelles/${id}/`),
}

/* --- Élevage (RF-10 à RF-12) --------------------------------------------- */
export const animaux = {
  lister: async () => enListe((await apiClient.get('/animaux/')).data),
  creer: async (donnees) => (await apiClient.post('/animaux/', donnees)).data,
  modifier: async (id, donnees) => (await apiClient.patch(`/animaux/${id}/`, donnees)).data,
  supprimer: async (id) => apiClient.delete(`/animaux/${id}/`),
}

export const suivis = {
  lister: async () => enListe((await apiClient.get('/suivis-sanitaires/')).data),
  creer: async (donnees) => (await apiClient.post('/suivis-sanitaires/', donnees)).data,
}

/* --- Météo et alertes (RF-13 à RF-15) ------------------------------------ */
export const meteo = {
  obtenir: async (ville) => (await apiClient.get('/meteo/', { params: { ville } })).data,
}

export const alertes = {
  lister: async () => enListe((await apiClient.get('/alertes/')).data),
  marquerLue: async (id) => (await apiClient.post(`/alertes/${id}/marquer_lue/`)).data,
  toutMarquerLu: async () => (await apiClient.post('/alertes/tout_marquer_lu/')).data,
  generer: async () => (await apiClient.post('/alertes/generer/')).data,
}

/* --- Marché (RF-16 à RF-19) ---------------------------------------------- */
const MULTIPART = { headers: { 'Content-Type': 'multipart/form-data' } }

export const annonces = {
  lister: async ({ q, categorie, mesAnnonces } = {}) => {
    const url = mesAnnonces ? '/annonces/mes_annonces/' : '/annonces/'
    const params = {}
    if (q) params.q = q
    if (categorie) params.categorie = categorie
    const { data } = await apiClient.get(url, { params })
    let liste = enListe(data)
    // mes_annonces ne filtre pas côté serveur : on applique les filtres ici
    if (mesAnnonces) {
      if (categorie) liste = liste.filter((a) => a.categorie === categorie)
      if (q) liste = liste.filter((a) => a.titre.toLowerCase().includes(q.toLowerCase()))
    }
    return liste
  },
  creer: async (formData) => (await apiClient.post('/annonces/', formData, MULTIPART)).data,
  modifier: async (id, donnees) => (await apiClient.patch(`/annonces/${id}/`, donnees)).data,
  supprimer: async (id) => apiClient.delete(`/annonces/${id}/`),
}
