# terraform-aws-elb

Módulo Terraform reutilizable para AWS Elastic Load Balancing — soporta **ALB**, **NLB** y **GWLB** desde una sola interfaz.

## Características

| Feature | ALB | NLB | GWLB |
|---|:---:|:---:|:---:|
| Listeners HTTP/HTTPS | ✅ | — | — |
| Listeners TCP/UDP/TLS | — | ✅ | — |
| Listener GENEVE | — | — | ✅ |
| Redirect / Fixed-response | ✅ | — | — |
| Cognito / OIDC auth | ✅ | — | — |
| Listener rules (path/host/header) | ✅ | — | — |
| Weighted target groups | ✅ | — | — |
| mTLS (verify / passthrough) | ✅ | ✅ | — |
| WAF WebACL association | ✅ | — | — |
| Shield Advanced | ✅ | ✅ | ✅ |
| EIP pinning (subnet_mapping) | — | ✅ | — |
| cross-zone LB control | — | ✅ | — |
| Proxy Protocol v2 | — | ✅ | — |
| preserve_client_ip | — | ✅ | — |
| target_failover | — | ✅ | — |
| Access logs | ✅ | ✅ | ✅ |
| Connection logs | ✅ | — | — |

## Requisitos

- Terraform `>= 1.6.0`
- AWS Provider `>= 5.40.0`

## Estructura

```
modules/elb/
├── main.tf        # Recursos principales
├── variables.tf   # Variables tipadas con validación
├── outputs.tf     # Outputs listos para uso
└── versions.tf    # Constraints de versión

examples/
├── alb-http-https/   # ALB con redirect, reglas, WAF, canary
├── nlb-tcp-tls/      # NLB con EIPs, mTLS, cross-zone off
└── gwlb-inline/      # GWLB + VPC Endpoint Service
```

## Uso rápido

### ALB básico

```hcl
module "alb" {
  source = "./modules/elb"

  name        = "mi-alb"
  lb_type     = "application"
  vpc_id      = "vpc-0abc123"
  subnet_ids  = ["subnet-aaa", "subnet-bbb"]
  security_group_ids = ["sg-0abc123"]

  target_groups = {
    app = {
      protocol    = "HTTP"
      port        = 8080
      target_type = "instance"
      health_check = { path = "/health", matcher = "200" }
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = { type = "forward", target_group_key = "app" }
    }
  }
}
```

### NLB con EIPs

```hcl
module "nlb" {
  source  = "./modules/elb"
  name    = "mi-nlb"
  lb_type = "network"
  vpc_id  = "vpc-0abc123"

  subnet_mapping = [
    { subnet_id = "subnet-aaa", allocation_id = "eipalloc-001" },
    { subnet_id = "subnet-bbb", allocation_id = "eipalloc-002" },
  ]

  target_groups = {
    tcp = { protocol = "TCP", port = 443, target_type = "instance",
            health_check = { protocol = "TCP" } }
  }

  listeners = {
    tls = {
      port = 443, protocol = "TLS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = "arn:aws:acm:..."
      default_action  = { type = "forward", target_group_key = "tcp" }
    }
  }
}
```

### GWLB inline

```hcl
module "gwlb" {
  source     = "./modules/elb"
  name       = "mi-gwlb"
  lb_type    = "gateway"
  vpc_id     = "vpc-0abc123"
  subnet_ids = ["subnet-fw-az1", "subnet-fw-az2"]

  target_groups = {
    fw = { protocol = "GENEVE", port = 6081, target_type = "ip",
           health_check = { protocol = "TCP", port = "80" } }
  }

  listeners = {
    geneve = {
      port = 6081, protocol = "GENEVE"
      default_action = { type = "forward", target_group_key = "fw" }
    }
  }
}
```

## Inputs destacados

| Variable | Tipo | Descripción |
|---|---|---|
| `name` | `string` | Prefijo de nombres (regex validado) |
| `lb_type` | `string` | `application` \| `network` \| `gateway` |
| `target_groups` | `map(object)` | TGs con health check, stickiness, failover |
| `listeners` | `map(object)` | Listeners con acciones complejas |
| `listener_rules` | `map(object)` | Reglas ALB con condiciones y acciones múltiples |
| `subnet_mapping` | `list(object)` | EIP pinning por AZ (NLB) |
| `alb` | `object` | Todos los atributos ALB-específicos |
| `nlb` | `object` | Todos los atributos NLB-específicos |
| `waf_web_acl_arn` | `string` | ARN WebACL WAFv2 |

## Outputs destacados

| Output | Descripción |
|---|---|
| `lb_arn` | ARN del load balancer |
| `lb_dns_name` | DNS name para CNAMEs o alias R53 |
| `route53_alias_target` | Objeto listo para `aws_route53_record.alias {}` |
| `target_group_arns` | `map(key → arn)` para ASG attachments externos |
| `listener_arns` | `map(key → arn)` |

## Notas de diseño

- **`lifecycle.precondition`** en `aws_lb` valida en tiempo de plan: ALB ≥ 2 subnets, ALB requiere SG, NLB/GWLB no admiten SGs, GWLB sólo GENEVE.
- Los bloques `dynamic` en listeners permiten exactamente el tipo de acción declarado sin `null` fields en el estado.
- `optional()` con defaults en todos los `object` evita pasar campos innecesarios en cada llamada.
- El módulo **no gestiona ASG attachments**; se expone `target_group_arns` para que el consumidor los adjunte externamente.
