output "amplify_frontend_apps" {
    description = "Map of Amplify frontend applications"
    value = {
        for app in var.amp_config : app.name => aws_amplify_app.frontend[app.name].name
    }
}

output "amplify_backend_environments" {
    description = "Map of Amplify backend environments"
    value = {
        for app in var.amp_config : app.name => aws_amplify_backend_environment.backend[app.name].name if app.backend
    }
}