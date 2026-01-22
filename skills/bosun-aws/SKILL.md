---
name: bosun-aws
description: AWS security and best practices. Use when reviewing AWS infrastructure, IAM policies, S3 buckets, Lambda functions, or CloudFormation templates. Provides patterns for secure AWS deployments.
tags: [aws, cloud, security, iam, s3, lambda, infrastructure]
---

# Bosun AWS Skill

AWS security patterns and infrastructure best practices for secure cloud deployments.

## When to Use

- Reviewing IAM policies and roles
- Auditing S3 bucket configurations
- Securing Lambda functions
- Reviewing CloudFormation/CDK templates
- Setting up VPC and security groups
- Configuring RDS and database security

## When NOT to Use

- General infrastructure patterns (use bosun-devops)
- GCP-specific (use bosun-gcp)
- Azure-specific (use bosun-azure)
- Kubernetes (use bosun-devops)

## IAM Security

### Principle of Least Privilege

```json
// ❌ BAD: Overly permissive
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}

// ✅ GOOD: Specific permissions
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

### IAM Policy Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `"Action": "*"` | Full access to all services | Specify exact actions needed |
| `"Resource": "*"` | Access to all resources | Scope to specific ARNs |
| `"Effect": "Allow"` on `iam:*` | Can escalate privileges | Limit IAM actions |
| No conditions | Access from anywhere | Add IP/MFA conditions |
| Inline policies | Hard to audit | Use managed policies |

### Secure IAM Patterns

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${BucketName}/*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalAccount": "${AWS::AccountId}"
        }
      }
    }
  ]
}
```

### Cross-Account Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::TRUSTED-ACCOUNT-ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "unique-external-id"
        }
      }
    }
  ]
}
```

## S3 Security

### Bucket Policy Checklist

- [ ] Block public access enabled
- [ ] Server-side encryption enabled
- [ ] Versioning enabled for critical data
- [ ] Access logging enabled
- [ ] No `"Principal": "*"` without conditions

### Secure Bucket Configuration

```yaml
# CloudFormation
SecureBucket:
  Type: AWS::S3::Bucket
  Properties:
    BucketEncryption:
      ServerSideEncryptionConfiguration:
        - ServerSideEncryptionByDefault:
            SSEAlgorithm: aws:kms
            KMSMasterKeyID: !Ref KMSKey
    PublicAccessBlockConfiguration:
      BlockPublicAcls: true
      BlockPublicPolicy: true
      IgnorePublicAcls: true
      RestrictPublicBuckets: true
    VersioningConfiguration:
      Status: Enabled
    LoggingConfiguration:
      DestinationBucketName: !Ref LoggingBucket
      LogFilePrefix: s3-access-logs/
```

### S3 Anti-Patterns

```json
// ❌ BAD: Public read access
{
  "Effect": "Allow",
  "Principal": "*",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}

// ✅ GOOD: CloudFront OAI access only
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity E1234567890"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

## Lambda Security

### Function Configuration

```yaml
# Secure Lambda function
SecureFunction:
  Type: AWS::Lambda::Function
  Properties:
    Runtime: nodejs18.x
    Handler: index.handler
    Role: !GetAtt LambdaRole.Arn
    VpcConfig:  # Run in VPC for network isolation
      SecurityGroupIds:
        - !Ref LambdaSecurityGroup
      SubnetIds:
        - !Ref PrivateSubnet1
        - !Ref PrivateSubnet2
    Environment:
      Variables:
        # Never hardcode secrets!
        DB_SECRET_ARN: !Ref DatabaseSecret
    ReservedConcurrentExecutions: 100  # Limit concurrency
    Timeout: 30
    MemorySize: 256
```

### Lambda Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| Hardcoded secrets in env vars | Secret exposure | Use Secrets Manager/SSM |
| `*` permissions | Over-privileged | Scope to exact resources |
| No VPC | Public network exposure | Deploy in private VPC |
| No timeout | Runaway costs | Set reasonable timeout |
| No concurrency limit | DoS vulnerability | Set reserved concurrency |

### Secrets in Lambda

```javascript
// ❌ BAD: Hardcoded secret
const API_KEY = 'sk-1234567890';

// ✅ GOOD: Fetch from Secrets Manager
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');

const client = new SecretsManagerClient();
const secret = await client.send(new GetSecretValueCommand({
  SecretId: process.env.SECRET_ARN
}));
const apiKey = JSON.parse(secret.SecretString).apiKey;
```

## VPC & Network Security

### Security Group Rules

```yaml
# ❌ BAD: Open to world
SecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0  # SSH from anywhere!

# ✅ GOOD: Restricted access
SecurityGroup:
  Type: AWS::EC2::SecurityGroup
  Properties:
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        SourceSecurityGroupId: !Ref ALBSecurityGroup  # Only from ALB
```

### VPC Best Practices

| Practice | Implementation |
|----------|----------------|
| Private subnets for workloads | No IGW route for private subnets |
| NAT Gateway for outbound | Route 0.0.0.0/0 through NAT |
| VPC Flow Logs | Enable for all traffic |
| No public IPs on EC2 | Use bastion or SSM Session Manager |
| Security groups as allowlists | Deny by default, allow specific |

## RDS Security

### Secure RDS Configuration

```yaml
SecureDatabase:
  Type: AWS::RDS::DBInstance
  Properties:
    Engine: postgres
    EngineVersion: '15'
    DBInstanceClass: db.t3.medium
    StorageEncrypted: true
    KmsKeyId: !Ref KMSKey
    PubliclyAccessible: false  # Never public!
    VPCSecurityGroups:
      - !Ref DatabaseSecurityGroup
    EnableIAMDatabaseAuthentication: true
    DeletionProtection: true
    BackupRetentionPeriod: 7
    MultiAZ: true  # For production
```

### RDS Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| `PubliclyAccessible: true` | Direct internet access | Keep private, use bastion |
| No encryption | Data exposure | Enable `StorageEncrypted` |
| Master password in template | Credentials in code | Use Secrets Manager |
| No backups | Data loss | Set `BackupRetentionPeriod` |
| Single AZ | No failover | Enable `MultiAZ` |

## Secrets Management

### Using Secrets Manager

```yaml
DatabaseSecret:
  Type: AWS::SecretsManager::Secret
  Properties:
    GenerateSecretString:
      SecretStringTemplate: '{"username": "admin"}'
      GenerateStringKey: password
      PasswordLength: 32
      ExcludeCharacters: '"@/\'

# Attach to RDS
Database:
  Type: AWS::RDS::DBInstance
  Properties:
    MasterUsername: !Sub '{{resolve:secretsmanager:${DatabaseSecret}:SecretString:username}}'
    MasterUserPassword: !Sub '{{resolve:secretsmanager:${DatabaseSecret}:SecretString:password}}'
```

### Secrets Anti-Patterns

| Anti-Pattern | Risk | Fix |
|--------------|------|-----|
| Hardcoded in CloudFormation | Secrets in version control | Use Secrets Manager references |
| Environment variables | Visible in console | Fetch at runtime |
| SSM Parameter (String) | Not encrypted | Use SecureString |
| Shared secrets | Blast radius | Per-service secrets |

## Quick Reference

### Security Checklist

**IAM:**
- [ ] No `*` in actions or resources
- [ ] MFA required for sensitive operations
- [ ] Service roles use least privilege
- [ ] No inline policies on users

**S3:**
- [ ] Public access blocked
- [ ] Encryption enabled (SSE-KMS preferred)
- [ ] Versioning enabled
- [ ] Access logging enabled

**Lambda:**
- [ ] No hardcoded secrets
- [ ] In VPC (if accessing private resources)
- [ ] Concurrency limits set
- [ ] Least privilege role

**Network:**
- [ ] Security groups are restrictive
- [ ] No 0.0.0.0/0 ingress (except ALB 443)
- [ ] VPC Flow Logs enabled
- [ ] Private subnets for workloads

**Data:**
- [ ] RDS not publicly accessible
- [ ] Encryption at rest enabled
- [ ] Encryption in transit (TLS)
- [ ] Secrets in Secrets Manager

### AWS Security Tools

| Tool | Purpose | Command |
|------|---------|---------|
| AWS Config | Compliance rules | Console/API |
| Security Hub | Aggregated findings | Console/API |
| GuardDuty | Threat detection | Console/API |
| IAM Access Analyzer | Unused permissions | Console/API |
| Prowler | Security audit | `prowler aws` |
| cfn-lint | CloudFormation linting | `cfn-lint template.yaml` |
| checkov | IaC security | `checkov -f template.yaml` |

## References

See `references/` for detailed documentation:
- `iam-patterns.md` - Advanced IAM patterns
- `network-security.md` - VPC and security group patterns
- `encryption.md` - KMS and encryption patterns
