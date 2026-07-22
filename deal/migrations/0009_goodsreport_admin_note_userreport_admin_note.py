from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('deal', '0008_goodsreport_userreport'),
    ]

    operations = [
        migrations.AddField(
            model_name='goodsreport',
            name='admin_note',
            field=models.TextField(blank=True, verbose_name='반려 사유(관리자 메모)'),
        ),
        migrations.AddField(
            model_name='userreport',
            name='admin_note',
            field=models.TextField(blank=True, verbose_name='반려 사유(관리자 메모)'),
        ),
    ]
