# Erstellung Wildcard SSL-Zertifikat (zum Testen)
```openssl req -subj "/commonName=*.workspace.local/" -x509 -nodes -days 730 -newkey rsa:2048 -keyout ./nginx/private.key -out ./nginx/public.crt```

# Anpassung der Konfiguration
## docker-compose.yml

**Zugangsdaten für Datenbank:**\
Zeile 11 und 12: Benutzername und Passwort
Übernahme in die Zeilen 36, 47, 61

**Ziel-Domain ändern:**\
Zeilen 35, 48-50, 60, 62

**Encryptionkey setzen:**\
Zeile 63

**Wenn Hostsystem Linux und Monitoring gewünscht:**\
Zeilen 14 - 27 einkommentieren

## nginx/nginx.conf
**Ziel-Domain ändern:**\
Zeilen 15, 36, 58, 79

**Wenn Hostsystem Linux und Monitoring gewünscht:**\
Zeilen 77 - 96 einkommentieren

# docker login bei workspace registry
``docker login registry.workspace.pm``\
Benutzername: Siehe Aktivierungsmail\
Kennwort: Siehe Aktivierungsmail

# Start der Umgebung
``docker-compose -p "prod" up -d``\
-p "prod" steht hierbei für den Umgebungsnamen