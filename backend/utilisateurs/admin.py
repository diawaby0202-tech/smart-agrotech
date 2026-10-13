from django.contrib import admin
from django.contrib.auth.admin import UserAdmin

from .models import Utilisateur


@admin.register(Utilisateur)
class UtilisateurAdmin(UserAdmin):
    ordering = ['-date_inscription']
    list_display = ['email', 'nom', 'prenom', 'role', 'statut', 'date_inscription']
    list_filter = ['role', 'statut']
    search_fields = ['email', 'nom', 'prenom']
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Informations', {'fields': ('nom', 'prenom', 'telephone')}),
        ('Compte', {'fields': ('role', 'statut', 'is_staff', 'is_superuser')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'nom', 'prenom', 'role', 'password1', 'password2'),
        }),
    )
