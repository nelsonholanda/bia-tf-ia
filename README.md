# 🏗️ BIA Infrastructure as Code

Infraestrutura completa para aplicação BIA usando Terraform com AWS, incluindo backup cross-region, security scanning automatizado e práticas GitOps.

## � Quick Start

```bash
# Desenvolvimento
terraform init -backend-config=backend-dev.hcl
terraform apply -var-file=terraform.tfvars

# Produção  
terraform init -backend-config=backend-prod.hcl
terraform apply -var-file=terraform-prod.tfvars
```

## � Documentação

**� [TECHNICAL_GUIDE.md](TECHNICAL_GUIDE.md)** - Guia técnico completo com tudo que você precisa saber

## 🏗️ Arquitetura

- **VPC** + **ECS** + **RDS** + **ALB** + **WAF**
- **AWS Backup Cross-Region** (us-east-1 → sa-east-1)
- **Security Scanning** (tfsec, Checkov, Gitleaks, Snyk)
- **CI/CD Pipeline** com GitHub Actions

## 🔒 Security & Compliance

- ✅ Automated security scanning
- ✅ Pre-commit hooks
- ✅ Cross-region backups
- ✅ KMS encryption
- ✅ GitOps best practices

## 📊 Estimativa de Custos

| Ambiente | Custo Mensal |
|----------|--------------|
| **Dev**  | ~$50 USD     |
| **Prod** | ~$118 USD    |

## 🛠️ Suporte

- **Repository**: https://github.com/nelsonholanda/bia-tf-ia
- **Documentation**: [TECHNICAL_GUIDE.md](TECHNICAL_GUIDE.md)
- **Issues**: Use GitHub Issues para reportar problemas

---

**Status**: ✅ Production Ready | **Version**: 3.0.0 | **Last Update**: Jan 2025
