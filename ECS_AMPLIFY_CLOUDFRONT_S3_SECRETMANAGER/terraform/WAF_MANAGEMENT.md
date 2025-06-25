# AWS WAF Management for demo API

## Overview

The demo API is protected by AWS WAF (Web Application Firewall) attached to the CloudFront distribution. This provides comprehensive protection against common web attacks and malicious traffic.

## WAF Rules Configuration

### 1. Domain Protection
- **Purpose**: Only allows traffic to legitimate demo API domains
- **Allowed Domains**: 
  - `api.livedemo.com` (production)
  - `api-dev.livedemo.com` (development)
  - Any subdomain matching pattern: `api-*.livedemo.com`

### 2. IP Management
- **Allowed IPs**: IP set for whitelisting trusted IPs (currently empty)
- **Blocked IPs**: IP set for blacklisting malicious IPs (currently empty)

### 3. AWS Managed Rule Sets

#### Common Rule Set (Count Mode)
- Protects against common web attacks
- Currently in **count mode** to avoid false positives
- Excludes:
  - `SizeRestrictions_BODY`: Allows larger request bodies for content uploads
  - `GenericRFI_BODY`: Counts instead of blocks for API requests

#### SQL Injection Protection (Block Mode)
- Blocks SQL injection attempts
- Uses AWS managed SQL injection detection rules

#### Known Bad Inputs (Block Mode)
- Blocks requests with known malicious patterns
- Uses AWS managed known bad inputs rules

#### Bot Control (Count Mode)
- Monitors bot traffic without blocking
- Uses common inspection level for cost efficiency
- Currently in **count mode** for monitoring

### 4. Rate Limiting
- **Limit**: 2000 requests per 5-minute window per IP
- **Scope**: Applies to all IPs except those in the allowed IP set
- **Action**: Blocks excessive requests

### 5. Attack Tool Detection (Block Mode)
- Blocks common penetration testing and attack tools:
  - sqlmap
  - nikto
  - nessus

## Management Tasks

### Adding IPs to Allow/Block Lists

To add IPs to the allow or block lists, update the Terraform configuration:

```hcl
# In ECS_AMPLIFY_CLOUDFRONT_S3_SECRETMANAGER/terraform/modules/ecs/main.tf

# To allow specific IPs
resource "aws_wafv2_ip_set" "allowed_ips" {
  # ... existing config ...
  addresses = [
    "203.0.113.0/24",  # Example: Allow office network
    "198.51.100.15/32" # Example: Allow specific IP
  ]
}

# To block specific IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  # ... existing config ...
  addresses = [
    "192.0.2.44/32",   # Example: Block malicious IP
    "203.0.113.0/28"   # Example: Block IP range
  ]
}
```

### Adjusting Rate Limits

To modify the rate limit, update the `RateBasedRule`:

```hcl
rate_based_statement {
  limit              = 1000  # Change this value (requests per 5-minute window)
  aggregate_key_type = "IP"
  # ... rest of config
}
```

### Switching Rules from Count to Block Mode

To make rules more restrictive, change `count {}` to `none {}` in the override_action:

```hcl
# Example: Enable blocking for Common Rule Set
rule {
  name     = "AWSManagedRulesCommonRuleSet"
  priority = 3
  
  override_action {
    none {}  # Changed from count {} to none {} to enable blocking
  }
  # ... rest of config
}
```

## Monitoring and Logging

### CloudWatch Metrics

WAF metrics are available in CloudWatch under the `AWS/WAFV2` namespace:

- `AllowedRequests`: Requests allowed by rules
- `BlockedRequests`: Requests blocked by rules
- `CountedRequests`: Requests counted by rules
- `SampledRequests`: Sample of requests for analysis

### Key Metrics to Monitor

1. **demoAPIWAF**: Overall WAF metrics
2. **AllowdemoAPIDomains**: Legitimate domain access
3. **BlockMaliciousIPs**: Blocked malicious IPs
4. **RateBasedRule**: Rate limiting actions
5. **AWSManagedRulesSQLiRuleSet**: SQL injection attempts

### Setting Up Alerts

Create CloudWatch alarms for:

```bash
# High number of blocked requests (potential attack)
aws cloudwatch put-metric-alarm \
  --alarm-name "WAF-High-Blocked-Requests" \
  --alarm-description "High number of requests blocked by WAF" \
  --metric-name BlockedRequests \
  --namespace AWS/WAFV2 \
  --statistic Sum \
  --period 300 \
  --threshold 100 \
  --comparison-operator GreaterThanThreshold

# Rate limiting triggered frequently
aws cloudwatch put-metric-alarm \
  --alarm-name "WAF-Rate-Limiting-Active" \
  --alarm-description "Rate limiting is frequently triggered" \
  --metric-name BlockedRequests \
  --namespace AWS/WAFV2 \
  --statistic Sum \
  --period 300 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold
```

## Deployment

Apply the WAF configuration:

```bash
cd ECS_AMPLIFY_CLOUDFRONT_S3_SECRETMANAGER/terraform/environments/dev  # or prod
terraform plan
terraform apply
```

## Cost Considerations

- **WAF Web ACL**: $1.00 per month
- **Rule evaluations**: $0.60 per million requests
- **Bot Control**: Additional cost based on requests analyzed
- **CloudWatch logs**: Additional cost for log storage and analysis

## Best Practices

1. **Start in Count Mode**: Begin with rules in count mode to observe traffic patterns
2. **Gradual Enforcement**: Move to block mode gradually after analyzing metrics
3. **Regular Monitoring**: Review WAF metrics weekly for unusual patterns
4. **IP Management**: Regularly update IP allow/block lists based on traffic analysis
5. **Rate Limit Tuning**: Adjust rate limits based on legitimate traffic patterns

## Troubleshooting

### Common Issues

1. **Legitimate Traffic Blocked**: Check WAF metrics and adjust rules in count mode
2. **High False Positives**: Review rule exclusions and add necessary overrides
3. **Rate Limiting Too Aggressive**: Increase rate limit threshold or add IPs to allow list

### Viewing Blocked Requests

Access WAF logs through:
1. CloudWatch Logs (if configured)
2. WAF console → Web ACLs → Sampled requests
3. CloudWatch metrics for detailed analysis

## Security Recommendations

1. **Enable WAF Logging**: Configure detailed logging for security analysis
2. **Regular Rule Updates**: AWS managed rules are automatically updated
3. **Custom Rule Development**: Add custom rules based on application-specific threats
4. **Integration with SIEM**: Forward WAF logs to security monitoring systems 