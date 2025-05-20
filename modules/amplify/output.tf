output "amplify_frontend" {
    value = {
        for k, v in var.amp_config : k => aws_amplify_app.frontend[v.name].name
    }
}

output "aws_amplify_backend" {
    value = {
        for k, v in var.amp_config : k => aws_amplify_backend_environment.backend[v.name].name
    }
}