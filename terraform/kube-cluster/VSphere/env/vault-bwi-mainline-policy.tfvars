
# Policy Vars
vault_addr               = "https://vault-mainline.infra.bwi:8200"
userdn                   = "dc=infra,dc=bwi"
groupdn                  = "dc=infra,dc=bwi"
ldap_url                 = "ldap://localhost:389"
azure_oidc_discovery_url = "https://login.microsoftonline.com/307de3fa-b846-4fe5-aa44-4fc7df6148b5/v2.0"
azure_oidc_callback_urls = [
  "http://localhost:8250/oidc/callback"
]
duo_api_hostname    = "api-93f1f4ae.duosecurity.com"
duo_secret_key      = "redacted"
duo_integration_key = "redacted"

# Used by nomad clusters, but can be used elsewhere 
vault_cluster_env = "mainline"
