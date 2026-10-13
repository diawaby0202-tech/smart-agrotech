"""Météo (OpenWeatherMap) et génération d'alertes (RF-13, RF-14, RF-12)."""
import json
from collections import defaultdict
from datetime import timedelta
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import urlopen

from django.conf import settings
from django.utils import timezone

from .models import Alerte

URL_PREVISIONS = 'https://api.openweathermap.org/data/2.5/forecast'

SEUIL_PLUIE_MM = 20       # pluie cumulée sur la journée
SEUIL_CHALEUR_ATTENTION = 37
SEUIL_CHALEUR_DANGER = 40
SEUIL_VENT_MS = 15        # ~54 km/h


class MeteoIndisponible(Exception):
    pass


def get_forecast(ville):
    """Appelle l'API météo et renvoie la réponse JSON brute."""
    cle = getattr(settings, 'WEATHER_API_KEY', '')
    if not cle:
        raise MeteoIndisponible("Clé WEATHER_API_KEY non configurée.")
    params = urlencode({'q': f'{ville},SN', 'units': 'metric', 'lang': 'fr', 'appid': cle})
    try:
        with urlopen(f'{URL_PREVISIONS}?{params}', timeout=10) as r:
            return json.loads(r.read().decode())
    except (URLError, ValueError, OSError) as e:
        raise MeteoIndisponible(f'Service météo injoignable : {e}')


def resumer_par_jour(data):
    """Regroupe les prévisions (toutes les 3 h) en un résumé par jour."""
    jours = defaultdict(lambda: {'temps': [], 'pluie': 0.0, 'vent': 0.0, 'descriptions': []})
    for p in data.get('list', []):
        jour = p['dt_txt'][:10]
        j = jours[jour]
        j['temps'].append(p['main']['temp'])
        j['pluie'] += p.get('rain', {}).get('3h', 0.0)
        j['vent'] = max(j['vent'], p.get('wind', {}).get('speed', 0.0))
        if p.get('weather'):
            j['descriptions'].append(p['weather'][0]['description'])
    resume = []
    for jour in sorted(jours):
        j = jours[jour]
        desc = max(set(j['descriptions']), key=j['descriptions'].count) if j['descriptions'] else ''
        resume.append({
            'date': jour,
            'temp_min': round(min(j['temps']), 1),
            'temp_max': round(max(j['temps']), 1),
            'pluie_mm': round(j['pluie'], 1),
            'vent_max_ms': round(j['vent'], 1),
            'description': desc,
        })
    return resume


def detecter_risques(resume):
    """Renvoie une liste de risques (niveau, titre, message) à partir du résumé."""
    risques = []
    for j in resume:
        d = j['date']
        if j['pluie_mm'] >= SEUIL_PLUIE_MM:
            risques.append(('danger', f'Fortes pluies le {d}',
                            f"{j['pluie_mm']} mm de pluie prévus. Risque d'inondation des parcelles."))
        if j['temp_max'] >= SEUIL_CHALEUR_DANGER:
            risques.append(('danger', f'Chaleur extrême le {d}',
                            f"Jusqu'à {j['temp_max']} °C. Protégez cultures et animaux, arrosez tôt."))
        elif j['temp_max'] >= SEUIL_CHALEUR_ATTENTION:
            risques.append(('attention', f'Forte chaleur le {d}',
                            f"Jusqu'à {j['temp_max']} °C prévus."))
        if j['vent_max_ms'] >= SEUIL_VENT_MS:
            risques.append(('attention', f'Vent fort le {d}',
                            f"Rafales jusqu'à {round(j['vent_max_ms'] * 3.6)} km/h."))
    return risques


def _creer_si_absente(user, type_, niveau, titre, message, zone=''):
    """Évite les doublons : même titre, même jour, même utilisateur."""
    aujourd_hui = timezone.localdate()
    existe = Alerte.objects.filter(
        utilisateur=user, titre=titre, date_creation__date=aujourd_hui
    ).exists()
    if existe:
        return None
    return Alerte.objects.create(
        utilisateur=user, type=type_, niveau=niveau, titre=titre, message=message, zone=zone
    )


def generer_alertes(user, jours_vaccination=7):
    """Crée les alertes météo (par zone de parcelle) et vaccination. Renvoie le nb créé."""
    from cultures.models import Parcelle
    from elevage.models import SuiviSanitaire

    crees = 0
    zones = set(
        Parcelle.objects.filter(proprietaire=user).exclude(localisation='')
        .values_list('localisation', flat=True)
    )
    for zone in zones:
        try:
            resume = resumer_par_jour(get_forecast(zone))
        except MeteoIndisponible:
            continue
        for niveau, titre, message in detecter_risques(resume):
            if _creer_si_absente(user, 'meteo', niveau, f'{titre} ({zone})', message, zone):
                crees += 1

    today = timezone.localdate()
    suivis = SuiviSanitaire.objects.filter(
        animal__proprietaire=user,
        prochaine_echeance__gte=today,
        prochaine_echeance__lte=today + timedelta(days=jours_vaccination),
    ).select_related('animal')
    for s in suivis:
        titre = f'{s.get_type_display()} à prévoir le {s.prochaine_echeance}'
        msg = f'{s.animal} : échéance de {s.get_type_display().lower()} le {s.prochaine_echeance}.'
        niveau = 'attention' if (s.prochaine_echeance - today).days <= 2 else 'info'
        if _creer_si_absente(user, 'vaccination', niveau, f'{titre} - {s.animal}', msg):
            crees += 1
    return crees
