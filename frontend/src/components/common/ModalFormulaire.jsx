import { useEffect, useState } from 'react'
import '../../styles-modules.css'
import Message from './Message'
import Spinner from './Spinner'

/**
 * Fenêtre de formulaire générique pilotée par une liste de champs.
 * champs : [{ nom, label, type, options, requis, pleineLargeur, aide }]
 * valeursInitiales : objet { nom: valeur }
 * onSubmit(valeurs) doit lever une erreur (message déjà lisible) pour l'afficher.
 */
export default function ModalFormulaire({
  titre,
  champs,
  valeursInitiales = {},
  libelleBouton = 'Enregistrer',
  onSubmit,
  onFermer,
}) {
  const [valeurs, setValeurs] = useState(valeursInitiales)
  const [erreur, setErreur] = useState('')
  const [envoi, setEnvoi] = useState(false)

  useEffect(() => {
    function surTouche(evenement) {
      if (evenement.key === 'Escape') onFermer()
    }
    window.addEventListener('keydown', surTouche)
    return () => window.removeEventListener('keydown', surTouche)
  }, [onFermer])

  function changer(champ, evenement) {
    const valeur = champ.type === 'file' ? evenement.target.files[0] || null : evenement.target.value
    setValeurs((precedent) => ({ ...precedent, [champ.nom]: valeur }))
  }

  async function soumettre(evenement) {
    evenement.preventDefault()
    setErreur('')
    setEnvoi(true)
    try {
      await onSubmit(valeurs)
    } catch (e) {
      setErreur(e.message || 'Une erreur est survenue.')
      setEnvoi(false)
    }
  }

  return (
    <div className="modal-fond" onMouseDown={(e) => e.target === e.currentTarget && onFermer()}>
      <div className="modal-boite" role="dialog" aria-modal="true" aria-label={titre}>
        <div className="modal-entete">
          <h2>{titre}</h2>
          <button type="button" className="modal-fermer" onClick={onFermer} aria-label="Fermer">×</button>
        </div>

        {erreur && <Message type="erreur">{erreur}</Message>}

        <form onSubmit={soumettre} className="formulaire" noValidate>
          <div className="formulaire-grille">
            {champs.map((champ) => (
              <div key={champ.nom} className={`champ ${champ.pleineLargeur ? 'champ-plein' : ''}`}>
                <label htmlFor={`champ-${champ.nom}`}>{champ.label}</label>
                {champ.type === 'select' ? (
                  <select
                    id={`champ-${champ.nom}`}
                    value={valeurs[champ.nom] ?? ''}
                    onChange={(e) => changer(champ, e)}
                    required={champ.requis}
                  >
                    {champ.options.map((option) => (
                      <option key={option.valeur} value={option.valeur}>{option.libelle}</option>
                    ))}
                  </select>
                ) : champ.type === 'textarea' ? (
                  <textarea
                    id={`champ-${champ.nom}`}
                    value={valeurs[champ.nom] ?? ''}
                    onChange={(e) => changer(champ, e)}
                  />
                ) : champ.type === 'file' ? (
                  <input
                    id={`champ-${champ.nom}`}
                    type="file"
                    accept="image/*"
                    onChange={(e) => changer(champ, e)}
                  />
                ) : (
                  <input
                    id={`champ-${champ.nom}`}
                    type={champ.type || 'text'}
                    value={valeurs[champ.nom] ?? ''}
                    onChange={(e) => changer(champ, e)}
                    required={champ.requis}
                    step={champ.type === 'number' ? 'any' : undefined}
                    min={champ.min}
                  />
                )}
                {champ.aide && <small>{champ.aide}</small>}
              </div>
            ))}
          </div>

          <div className="modal-actions">
            <button type="button" className="btn btn-fantome" onClick={onFermer}>Annuler</button>
            <button type="submit" className="btn btn-primaire" disabled={envoi}>
              {envoi ? <Spinner /> : libelleBouton}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
