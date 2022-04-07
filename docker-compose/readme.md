# Erstellung Wildcard SSL-Zertifikat (zum Testen)
```openssl req -subj "/commonName=*.workspace.local/" -x509 -nodes -days 730 -newkey rsa:2048 -keyout ./nginx/private.key -out ./nginx/public.crt```

# Anpassung der Konfiguration
## production.env
Anpassung je nach Bedarf (Ports, Domains, ...), EncryptionKey hat eine feste Länge

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
``docker-compose --env-file production.env -p "prod" up -d``

# Hinweise für parallele Umgebungen
-p "prod" steht hierbei für den Umgebungsnamen\
In der *production.env* werden die Laufzeitvariablen gesetzt. Es ist möglich eine getrennte Konfiguration (z.B. für ein Testsystem: testsystem.env) zu verwenden.
