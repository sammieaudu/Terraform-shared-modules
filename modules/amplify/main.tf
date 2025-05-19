data "aws_ssm_parameter" "github_pat" {
    for_each = {for amplify in var.amp_config : amplify.name => amplify}
    name            = each.value.github_pat_path
    with_decryption = true
}

################################################
# Amplify Application
################################################
resource "aws_amplify_app" "frontend" {
    for_each = {for amplify in var.amp_config : amplify.name => amplify}
  name       = "${local.name}-${each.value.name}"
  repository = each.value.repo
  # GitHub personal access token
  access_token = data.aws_ssm_parameter.github_pat[each.value.name].value

  # The default build_spec added by the Amplify Console for React.
  build_spec = templatefile("${path.module}/build_specs/${each.value.framework}.yaml", {})

  dynamic "custom_rule" {
    for_each = length(var.custom_rules) > 0 ? var.custom_rules : []
    content {
      source = custom_rule.value.source
      status = custom_rule.value.status
      target = custom_rule.value.target
    }
  }

  tags = local.tags
}

resource "aws_amplify_backend_environment" "backend" {
  for_each = {for amplify in var.amp_config : amplify.name => amplify if amplify.backend}
  app_id           = aws_amplify_app.frontend[each.value.name].id
  environment_name = substr(each.value.name, 0, 10)

  depends_on = [ aws_amplify_app.frontend ]
}

resource "aws_amplify_branch" "main_branch" {
    for_each = {for amplify in var.amp_config : amplify.name => amplify}
    app_id      = aws_amplify_app.frontend[each.value.name].id
    branch_name = each.value.branch_name
    framework = each.value.framework

    tags = local.tags
    depends_on = [ aws_amplify_app.frontend ]
}

resource "aws_amplify_webhook" "main" {
  for_each = {for amplify in var.amp_config : amplify.name => amplify}
  app_id      = aws_amplify_app.frontend[each.key].id
  branch_name = aws_amplify_branch.main_branch[each.key].branch_name
  description = "triggermaster"

  depends_on = [ aws_amplify_branch.main_branch ]
}