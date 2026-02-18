# Scaling Policies — Guía de uso del módulo ASG

## Tipos de política disponibles

| `policy_type` | Cuándo usarlo |
|---|---|
| `SimpleScaling` | Ajuste fijo con cooldown. Útil para cargas predecibles y simples |
| `StepScaling` | Ajuste por rangos de alarma. Más granular que Simple |
| `TargetTrackingScaling` | AWS gestiona el escalado para mantener una métrica objetivo |
| `PredictiveScaling` | AWS predice el tráfico futuro y aprovisiona capacidad con antelación |

---

## 1. Simple Scaling

El más básico. Añade o quita un número fijo de instancias y espera el `cooldown` antes de volver a actuar.

```hcl
scaling_policies = {
  scale-up = {
    policy_type        = "SimpleScaling"
    adjustment_type    = "ChangeInCapacity"  # ChangeInCapacity | ExactCapacity | PercentChangeInCapacity
    scaling_adjustment = 2
    cooldown           = 300
  }

  scale-down = {
    policy_type        = "SimpleScaling"
    adjustment_type    = "ChangeInCapacity"
    scaling_adjustment = -1
    cooldown           = 300
  }
}
```

> **Nota:** `scaling_adjustment` negativo reduce instancias. Con `ExactCapacity` el valor es absoluto (p. ej. `scaling_adjustment = 3` → fija el ASG en exactamente 3 instancias).

---

## 2. Step Scaling

Permite distintos ajustes según la magnitud de la alarma. Ideal cuando quieres escalar más agresivamente ante picos severos.

```hcl
scaling_policies = {
  step-scale-up = {
    policy_type               = "StepScaling"
    adjustment_type           = "ChangeInCapacity"
    metric_aggregation_type   = "Average"
    estimated_instance_warmup = 120

    step_adjustments = [
      {
        # CPU entre 60% y 75% → +1 instancia
        scaling_adjustment          = 1
        metric_interval_lower_bound = 0
        metric_interval_upper_bound = 15
      },
      {
        # CPU entre 75% y 90% → +2 instancias
        scaling_adjustment          = 2
        metric_interval_lower_bound = 15
        metric_interval_upper_bound = 30
      },
      {
        # CPU > 90% → +4 instancias
        scaling_adjustment          = 4
        metric_interval_lower_bound = 30
      }
    ]
  }

  step-scale-down = {
    policy_type             = "StepScaling"
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustments = [
      {
        # CPU bajó entre 0 y 20 puntos → -1 instancia
        scaling_adjustment          = -1
        metric_interval_upper_bound = 0
        metric_interval_lower_bound = -20
      },
      {
        # CPU bajó más de 20 puntos → -2 instancias
        scaling_adjustment          = -2
        metric_interval_upper_bound = -20
      }
    ]
  }
}
```

> **Nota:** Los `step_adjustments` son relativos al umbral de la alarma de CloudWatch asociada, no a la métrica absoluta. Los bounds inferiores se omiten en el último escalón superior, y los superiores en el último escalón inferior.

---

## 3. Target Tracking Scaling

AWS gestiona automáticamente el número de instancias para mantener la métrica cerca del `target_value`. Es el más sencillo de operar.

```hcl
scaling_policies = {
  target-cpu = {
    policy_type               = "TargetTrackingScaling"
    estimated_instance_warmup = 180

    target_tracking_configuration = {
      predefined_metric_type = "ASGAverageCPUUtilization"
      target_value           = 60.0
    }
  }
}
```

### Métricas predefinidas disponibles para Target Tracking

| Valor | Descripción |
|---|---|
| `ASGAverageCPUUtilization` | CPU media del ASG |
| `ASGAverageNetworkIn` | Bytes de entrada medios |
| `ASGAverageNetworkOut` | Bytes de salida medios |
| `ALBRequestCountPerTarget` | Peticiones por instancia (requiere ALB) |

---

## 4. Predictive Scaling

AWS analiza el historial de tráfico y genera una previsión para aprovisionar capacidad **antes** de que llegue el pico.

### Modos disponibles

| `mode` | Comportamiento |
|---|---|
| `ForecastOnly` | Solo genera predicciones visibles en la consola. No escala. Ideal para validar antes de activar |
| `ForecastAndScale` | Genera predicciones **y** escala automáticamente según ellas |

### 4a. Con par de métricas predefinido (recomendado para empezar)

AWS infiere automáticamente tanto la métrica de carga como la de escalado. Es la opción más sencilla.

```hcl
scaling_policies = {
  predictive-cpu = {
    policy_type = "PredictiveScaling"

    predictive_scaling_configuration = {
      mode                   = "ForecastOnly"   # Empieza aquí para validar
      scheduling_buffer_time = 300              # Aprovisionar 5 min antes del pico

      metric_specification = {
        target_value = 70

        predefined_metric_pair_specification = {
          predefined_metric_type = "ASGCPUUtilization"
        }
      }
    }
  }
}
```

### Métricas de par predefinido disponibles

| Valor | Descripción |
|---|---|
| `ASGCPUUtilization` | CPU del ASG |
| `ASGNetworkIn` | Tráfico de entrada |
| `ASGNetworkOut` | Tráfico de salida |
| `ALBRequestCount` | Peticiones ALB (requiere `resource_label`) |

### 4b. Con métricas separadas de scaling y load (más control)

```hcl
scaling_policies = {
  predictive-alb = {
    policy_type = "PredictiveScaling"

    predictive_scaling_configuration = {
      mode                         = "ForecastAndScale"
      scheduling_buffer_time       = 300
      max_capacity_breach_behavior = "IncreaseMaxCapacity"  # Permite superar max_size
      max_capacity_buffer          = 10                     # Permite +10% sobre la predicción

      metric_specification = {
        target_value = 1000  # Peticiones por instancia objetivo

        predefined_scaling_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "app/my-alb/abc123/targetgroup/my-tg/xyz789"
        }

        predefined_load_metric_specification = {
          predefined_metric_type = "ALBTargetGroupRequestCount"
          resource_label         = "app/my-alb/abc123/targetgroup/my-tg/xyz789"
        }
      }
    }
  }
}
```

> **Cómo obtener el `resource_label`:** Ve a la consola de EC2 → Load Balancers, copia el ARN del ALB y el ARN del Target Group. El `resource_label` es la parte del ARN después de `loadbalancer/` para el ALB, combinada con la parte después de `:targetgroup/` del TG, separadas por `/`.

### 4c. Con métricas customizadas

Útil cuando tienes métricas de negocio propias en CloudWatch (p. ej. órdenes por minuto).

```hcl
scaling_policies = {
  predictive-custom = {
    policy_type = "PredictiveScaling"

    predictive_scaling_configuration = {
      mode                   = "ForecastAndScale"
      scheduling_buffer_time = 600

      metric_specification = {
        target_value = 100

        customized_scaling_metric_specification = {
          metric_data_queries = [
            {
              id          = "scaling_metric"
              return_data = true
              metric_stat = {
                stat = "Average"
                metric = {
                  metric_name = "ActiveConnections"
                  namespace   = "MyApp/Production"
                  dimensions = [
                    {
                      name  = "Environment"
                      value = "production"
                    }
                  ]
                }
              }
            }
          ]
        }

        customized_load_metric_specification = {
          metric_data_queries = [
            {
              id          = "load_metric"
              return_data = true
              metric_stat = {
                stat = "Sum"
                metric = {
                  metric_name = "TotalConnections"
                  namespace   = "MyApp/Production"
                  dimensions = [
                    {
                      name  = "Environment"
                      value = "production"
                    }
                  ]
                }
              }
            }
          ]
        }
      }
    }
  }
}
```

---

## Combinaciones válidas e inválidas

### ✅ Combinaciones válidas

```hcl
# Target Tracking + Predictive: muy habitual en producción
# El predictive aprovisiona capacidad anticipada, el target tracking ajusta en tiempo real
scaling_policies = {
  predictive = {
    policy_type = "PredictiveScaling"
    predictive_scaling_configuration = {
      mode = "ForecastAndScale"
      metric_specification = {
        target_value = 70
        predefined_metric_pair_specification = {
          predefined_metric_type = "ASGCPUUtilization"
        }
      }
    }
  }

  reactive = {
    policy_type = "TargetTrackingScaling"
    estimated_instance_warmup = 120
    target_tracking_configuration = {
      predefined_metric_type = "ASGAverageCPUUtilization"
      target_value           = 70.0
    }
  }
}
```

```hcl
# Step Scaling con Simple Scaling: alarmas distintas para subir y bajar
scaling_policies = {
  scale-up = {
    policy_type             = "StepScaling"
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"
    step_adjustments = [
      { scaling_adjustment = 2, metric_interval_lower_bound = 0 }
    ]
  }

  scale-down = {
    policy_type        = "SimpleScaling"
    adjustment_type    = "ChangeInCapacity"
    scaling_adjustment = -1
    cooldown           = 600
  }
}
```

### ❌ Combinaciones inválidas

```hcl
# ❌ ERROR: predictive_scaling_configuration con policy_type incorrecto
scaling_policies = {
  wrong = {
    policy_type = "TargetTrackingScaling"   # debe ser "PredictiveScaling"
    predictive_scaling_configuration = {    # el módulo lanzará error de validación
      ...
    }
  }
}

# ❌ ERROR: step_adjustments sin policy_type StepScaling (se ignorarán y puede dar error en AWS)
scaling_policies = {
  wrong = {
    policy_type        = "SimpleScaling"
    adjustment_type    = "ChangeInCapacity"
    scaling_adjustment = 2
    step_adjustments   = [...]             # no tiene efecto y confunde
  }
}

# ❌ ERROR: Predictive Scaling con más de una especificación de métrica de par
# Solo puedes usar UNA de las tres opciones: predefined_metric_pair,
# o la combinación predefined_scaling + predefined_load,
# o customized_scaling + customized_load
scaling_policies = {
  wrong = {
    policy_type = "PredictiveScaling"
    predictive_scaling_configuration = {
      metric_specification = {
        target_value = 70
        predefined_metric_pair_specification = {
          predefined_metric_type = "ASGCPUUtilization"
        }
        predefined_scaling_metric_specification = {  # ❌ no mezcles par + individuales
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
      }
    }
  }
}

# ❌ ERROR: cooldown en Target Tracking (solo aplica a SimpleScaling)
scaling_policies = {
  wrong = {
    policy_type  = "TargetTrackingScaling"
    cooldown     = 300                     # se ignora, pero es confuso
    target_tracking_configuration = { ... }
  }
}
```

---

## Campos por tipo de política — referencia rápida

| Campo | SimpleScaling | StepScaling | TargetTracking | PredictiveScaling |
|---|:---:|:---:|:---:|:---:|
| `adjustment_type` | ✅ | ✅ | ❌ | ❌ |
| `scaling_adjustment` | ✅ | ❌ | ❌ | ❌ |
| `cooldown` | ✅ | ❌ | ❌ | ❌ |
| `estimated_instance_warmup` | ❌ | ✅ | ✅ | ❌ |
| `metric_aggregation_type` | ❌ | ✅ | ❌ | ❌ |
| `step_adjustments` | ❌ | ✅ | ❌ | ❌ |
| `target_tracking_configuration` | ❌ | ❌ | ✅ | ❌ |
| `predictive_scaling_configuration` | ❌ | ❌ | ❌ | ✅ |

---

## Consideraciones operativas

**Predictive Scaling necesita historial.** AWS requiere al menos 24 horas de datos para generar la primera predicción y mejora significativamente con 14 días. No tendrá efecto inmediato al activarlo.

**Empieza con `ForecastOnly`.** Antes de activar `ForecastAndScale`, deja la política en `ForecastOnly` durante una semana y revisa las predicciones en la consola (EC2 → Auto Scaling Groups → pestaña *Automatic scaling* → *Predictive scaling policies*). Así validas que el modelo se ajusta a tu patrón de tráfico.

**`max_capacity_breach_behavior`.** Por defecto `HonorMaxCapacity` nunca supera el `max_size` del ASG. Si tus picos pueden requerir más capacidad de la que has definido como máximo, usa `IncreaseMaxCapacity` junto con `max_capacity_buffer` (porcentaje adicional permitido sobre la predicción).

**`scheduling_buffer_time`.** Define cuántos segundos antes del pico predicho se aprovisiona la capacidad. El valor por defecto de 300 segundos (5 minutos) es suficiente para la mayoría de workloads. Auméntalo si tus instancias tardan más en estar listas (AMIs pesadas, bootstrapping largo, etc.).

**Target Tracking y Predictive juntos.** Es el patrón más robusto en producción: el Predictive gestiona los picos predecibles y periódicos, y el Target Tracking actúa como red de seguridad ante variaciones inesperadas. Usa el mismo `target_value` en ambas políticas para que no entren en conflicto.

**Simple y Step Scaling requieren alarmas de CloudWatch externas.** A diferencia de Target Tracking y Predictive, estas políticas no crean sus propias alarmas. Debes crear `aws_cloudwatch_metric_alarm` fuera del módulo y referenciar el ARN de la política en el campo `alarm_actions` de la alarma.
