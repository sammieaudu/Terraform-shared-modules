output "amplify_frontend_apps" {
    description = "Map of Amplify frontend applications"
    value = {
        for k, v in var.amp_config : k => aws_amplify_app.frontend[k.name].name
    }
}

output "amplify_backend_environments" {
    description = "Map of Amplify backend environments"
    value = {
        for k, v in var.amp_config : k => aws_amplify_backend_environment.backend[k.name].name
    }
}