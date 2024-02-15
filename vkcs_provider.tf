terraform {
    required_providers {
        vkcs = {
            source = "vk-cs/vkcs"
            version = "~> 0.6.1" 
        }
    }
}

provider "vkcs" {
    username = "Your_login"
    password = "Pass"
    project_id = "ID"
    region = "RegionOne"
    
    auth_url = "https://infra.mail.ru:35357/v3/" 
}
