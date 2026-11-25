import django.utils.timezone
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('cultures', '0002_parcelle_image'),
    ]

    operations = [
        migrations.CreateModel(
            name='Recolte',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date', models.DateField(default=django.utils.timezone.localdate)),
                ('quantite', models.DecimalField(decimal_places=2, max_digits=12)),
                ('unite', models.CharField(choices=[('kg', 'Kilogrammes'), ('tonne', 'Tonnes'), ('sac', 'Sacs'), ('caisse', 'Caisses')], default='kg', max_length=10)),
                ('notes', models.TextField(blank=True)),
                ('date_creation', models.DateTimeField(auto_now_add=True)),
                ('parcelle', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='recoltes', to='cultures.parcelle')),
            ],
            options={
                'ordering': ['-date', '-id'],
            },
        ),
    ]
