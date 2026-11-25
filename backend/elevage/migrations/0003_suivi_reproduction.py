from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('elevage', '0002_animal_image'),
    ]

    operations = [
        migrations.CreateModel(
            name='SuiviReproduction',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('date_saillie', models.DateField(blank=True, null=True)),
                ('mise_bas_prevue', models.DateField(blank=True, null=True)),
                ('mise_bas_reelle', models.DateField(blank=True, null=True)),
                ('nombre_petits', models.PositiveIntegerField(blank=True, null=True)),
                ('notes', models.TextField(blank=True)),
                ('date_creation', models.DateTimeField(auto_now_add=True)),
                ('animal', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='suivis_reproduction', to='elevage.animal')),
            ],
            options={
                'ordering': ['-date_saillie', '-id'],
            },
        ),
    ]
