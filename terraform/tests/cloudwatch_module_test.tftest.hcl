run "cloudwatch_alarm_created" {
  module {
    source = "./modules/cloudwatch"
  }

  variables {
    app_name         = "test-app"
    environment      = "test"
    ecs_cluster_name = "test-cluster"
    ecs_service_name = "test-service"
    log_group_name   = "/ecs/test-app-test"
    alert_email      = "test@example.com"
  }

  assert {
    condition     = length(module.cloudwatch.alarm_names) == 2
    error_message = "Expected 2 CloudWatch alarms to be created"
  }
}

