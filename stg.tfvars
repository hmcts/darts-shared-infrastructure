hub                             = "prod"
address_space                   = "10.24.239.128/28"
postgres_subnet_address_space   = "10.24.239.144/28"
storage_account_contributor_ids = ["87c8cf3d-ff9d-4d8f-8430-ccc737764435"]
defender_enable                 = false
defender_scan                   = false

migration_vms = {}

# virtual_machine_admins = [
#   "675f1c23-3e46-4cf8-867b-747eb60fe89d",
#   "d8b336b1-91fb-4fa6-bbe2-1f197c0d52c8",
#   "14f9cf0e-8327-4f12-9d2c-f7e7eb05629d",
#   "50132661-6997-484e-b0fd-5ec1052afabb",
#   "e7ea2042-4ced-45dd-8ae3-e051c6551789"
# ]
sku_name = "Premium"
family   = "P"
capacity = "1"

palo_networks         = {}
firewall_route_ranges = {}
