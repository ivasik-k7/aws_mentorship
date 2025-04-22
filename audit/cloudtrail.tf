resource "aws_cloudtrail" "management_events" {
  name           = "audit-cloudtrail-${var.environment}"
  s3_bucket_name = module.audit_bucket.bucket_id

  include_global_service_events = true
  is_multi_region_trail         = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail_policy]
}
