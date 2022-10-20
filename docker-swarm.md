# workspace on premises installation with portainer
Usually workspace runs on every server able to run docker containers with at at least 8 GB RAM and ~20 GB storage.
Depending on your needs, network and amount of users, we recommend 8 GB RAM per 50 concurrent users and at least 1 GB of storage per project.
For easier installation, configuration and maintanance we recommend to use portainer, even though it is not a requirement. If you have the technical resources in your organisation, you can use any other approach as well.

## Pre-Installation recommendations
* Server: 8 vCPU, 16 GB RAM, 160 GB SSD
* Dedicated Domain (e.g. "your-workspace.com")
* Ubuntu Linux with pre-installed docker in swarm mode
* Running portainer (portainer.io)
* Registered container registry (registry.workspace.pm)

## Workspace Service overview:
* IRIS - Authentification service
* LINNEA - Tenant administration
* MONGO - Database management system (mongodb)
* SERVERSIDE - Workspace Project Management Software
* NGINX - Reverse proxy for request routing (unsupported)
* *Depending on reseller contract*
    * *CRM - Self-Service Shop system (Frontend)*
    * *WEBHOOKS - Self-Service Shop System (Backend with stripe listener)*
    * *WEBHOOKS-DB* - mySQL / MariaDB

## Installation per service
### 1. Global configuration
Switch to portainer, open **Configs**, add a configuration with name *workspace-prod*, modify and apply following configuration:

```
{
    "AUTH_SERVER":"https://auth.example.com",
    "AUTHDOMAIN":"auth.example.com",
    "DOMAIN_PORT":"example.com",
    "DOMAIN":"example.com",
    "SCHEME":"https",
    "DB_CONNECTIONSTRING":"mongodb://dbuser:dbpassword@172.17.0.1:27017",
    "ENCRYPTION_KEY":"6cf5427542f5f5bf424f3a3f4f4d3ac0",
    
    "MASTERPASSWORD":"54C80c01#7E4a-455e!bdf0-e1eP9933a881",
    "StripeApiKey":"sk_live_xxx",
    "StripeEndpointSecret":"whsec_xxx",
    "WebhookBaseURL":"https://webhooks.example.com/",
    "MySQL":"server=db.example.com;port=3306;user=dbusr;password=dbpasswrd;database=tenants",
    "MailJetApiKey":"abc",
    "MailJetSecretKey":"def",
    "LICENSEES":"https://{0}.example.com",
    "lic_key":"key",
    "lic_priv":"private-key",
    "lic_pub":"public-key"
}
```

### Values:
#### Default installation:
* **AUTH_SERVER:** Full URL for IRIS
* **AUTHDOMAIN:** DNS Name for IRIS, IP must point to server running IRIS
* **DOMAIN_PORT:** DNS Name for SERVERSIDE with port, IP must point to server running SERVERSIDE, if port is different than 443 (for scheme https) or 80 (for scheme http) in format: example.com:8443
* **DOMAIN:** DNS Name for SERVERSIDE without port, IP must point to server running SERVERSIDE
* **SCHEME:** http or https (https strongly recommended!)
* **DB_CONNECTIONSTRING:** Formatted mongoDB Connection String
    * IP 172.17.0.1 always points to docker host
    * port 27017 (default port) might be altered on your system
* **ENCRYPTION_KEY:** 32 char hexadecimal key for session encryption (0-9, a-f, lowercase)

#### Multi-Tenant environments with self-service shop only (you might skip this):
* **MASTERPASSWORD:** Alphanummeric, strong password for tenant administration login
* **StripeApiKey** and **StripeEndpointSecret:** Automates payment by stripe (https://dashboard.stripe.com/developers)
* **WebhookBaseURL:** Public available full URL to WEBHOOKS service with trailing slash
* **MySQL:** Formatted mysql connection string
* **MailJetApiKey** and **MailJetSecretKey:** Mailjet API data (https://app.mailjet.com/account/apikeys) for sending account credentials after order
* **LICENSEES:** Public available full URL with placeholder **{0}** where tenant subdomains are generated
* **lic_key** , **lic_priv** and **lic_pub:** Issued PKI Certificates for license issuing

### 2. Installing MONGO as docker service
1. Create two volumes (*db* and *configdb*)
1. Docker Image: *mongo:latest*
1. Environment variables:
    1. **MONGO_INITDB_ROOT_USERNAME**: Select a secure username (must match **DB_CONNECTIONSTRING**)
    1. **MONGO_INITDB_ROOT_PASSWORD**: Select a secure password (must match **DB_CONNECTIONSTRING**)
1. Map volumes:
    1. *db* maps to */data/db*
    1. *configdb* maps to */data/configdb*
1. Publish port: *27017* maps to *27017*

### 3. Installing IRIS as docker service
1. Docker Image: *registry.workspace.pm/workspace/iris:latest*
1. Publish port: *8005* to *80*
1. Add configuration *workspace-prod*, path in container: */app/appsettings.json*

### 4. Installing SERVERSIDE as docker service
1. Create one volume (*tenantdata*)
1. Docker Image: *registry.workspace.pm/workspace/serverside:latest*
1. Map volume: *tenantdata* maps to */app/wwwroot/tenantdata*
1. Publish port: *8001* to *80*
1. Add configuration *workspace-prod*, path in container: */app/appsettings.json*

**-- only multi-tenant environments: --**

### 5. Installing LINNEA as docker service (only multi-tenant environments)
1. Docker Image: *registry.workspace.pm/workspace/linnea:latest*
1. Publish port: *8010* to *80*
1. Add configuration *workspace-prod*, path in container: */app/appsettings.json*

### 5. Installing WEBHOOKS as docker service (only multi-tenant environments with enabled shop)
1. Docker Image: *registry.workspace.pm/workspace/webhooks:latest*
1. Publish port: *8901* to *80*
1. Add configuration *workspace-prod*, path in container: */app/appsettings.json*

### 5. Installing WEBHOOKS-DB as docker service (only multi-tenant environments with enabled shop)
1. Create one volume (*webhooks-db*)
1. Docker Image: *mysql:5.7*
1. Environment variables (must match **MySQL**-Configuration):
    1. **MYSQL_DATABASE**: set to *tenants*
    1. **MYSQL_ROOT_PASSWORD**: Select a secure password
    1. **MYSQL_USER**: Select a secure username
    1. **MYSQL_PASSWORD**: Select a secure password
1. Map volume: *webhooks-db* maps to */var/lib/mysql*
1. Publish port: *8950* to *3306*

### 6. Installing CRM as docker service (only multi-tenant environments with enabled shop)
1. Docker Image: *registry.workspace.pm/workspace/crm:latest*
1. Publish port: *8910* to *80*
1. Add configuration *workspace-prod*, path in container: */app/appsettings.json*

### 7. Installing & configuring NGINX as reverse proxy (unsupported)
Set up an nginx server (https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/) as reverse proxy if needed.
Here is an example configuration section for SERVERSIDE and LINNEA:
```
    server {
        listen                  443 ssl;
	    server_name		        workspace.example.com;

        ssl_certificate         /var/lib/wsdata/nginx/public-wildcard.crt;
        ssl_certificate_key     /var/lib/wsdata/nginx/private-wildcard.key;
        ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers             HIGH:!aNULL:!MD5;

        location / {
            proxy_pass          http://172.17.0.1:8001;
            proxy_http_version  1.1;
            proxy_set_header    Upgrade $http_upgrade;
            proxy_set_header    Connection $connection_upgrade;
            proxy_set_header    Host $host;
            proxy_cache_bypass  $http_upgrade;
            proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header    X-Forwarded-Proto $scheme;
        }
    }

    server {
        listen                  443 ssl;
        server_name             auth.example.com;

        ssl_certificate         /var/lib/wsdata/nginx/public-wildcard.crt;
        ssl_certificate_key     /var/lib/wsdata/nginx/private-wildcard.key;
        ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers             HIGH:!aNULL:!MD5;

        location / {
            proxy_pass          http://172.17.0.1:8005;
            proxy_http_version  1.1;
            proxy_set_header    Upgrade $http_upgrade;
            proxy_set_header    Connection $connection_upgrade;
            proxy_set_header    Host $host;
            proxy_cache_bypass  $http_upgrade;
            proxy_set_header    X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header    X-Forwarded-Proto $scheme;
        }
    }
```

### 8. Booting up your instance
Visit your workspace instance: https://workspace.example.com/setup
