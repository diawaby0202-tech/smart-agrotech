import PageEnConstruction from '../components/common/PageEnConstruction'

export default function Marche() {
  return (
    <PageEnConstruction
      icone="🛒"
      titre="Marché agricole"
      accroche="L’offre et la demande, réunies sur une seule place de marché."
      description="Publiez vos récoltes et votre bétail à la vente, ou trouvez des produits frais et locaux proposés par les producteurs de votre région."
      fonctionnalites={[
        'Publier une annonce avec photo, prix et description',
        'Rechercher par catégorie, zone géographique ou budget',
        'Contacter directement un vendeur',
        'Gérer, modifier ou retirer vos propres annonces',
      ]}
    />
  )
}
