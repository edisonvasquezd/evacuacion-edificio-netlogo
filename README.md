# 🏢 Simulación de Evacuación de Edificio Multinivel

Modelo de simulación basado en agentes (ABM) desarrollado en NetLogo para analizar y optimizar procesos de evacuación en edificios de múltiples pisos durante situaciones de emergencia.

## 📋 Descripción

Este proyecto implementa un modelo computacional que simula la evacuación de un edificio de 5 pisos con arquitectura compleja. El sistema permite:

- **Analizar comportamientos de evacuación** en escenarios realistas
- **Identificar cuellos de botella** en el diseño arquitectónico
- **Evaluar el impacto del pánico** en los tiempos de evacuación
- **Optimizar rutas de escape** y protocolos de emergencia
- **Generar métricas detalladas** para análisis estadístico

## 🎯 Características Principales

### Arquitectura del Edificio
- **5 pisos** con diseño idéntico
- **12 habitaciones** por piso distribuidas en 6 zonas
- **Pasillos centrales** de conexión
- **Sistema de escaleras** bidireccional (subida/bajada)
- **Múltiples puertas** de acceso entre zonas
- **Salida única** a nivel de calle

### Agentes Inteligentes
- **Dos tipos de comportamiento:**
  - 🔴 **Agentes en pánico**: Movimiento rápido y errático (velocidad 0.7)
  - 🔵 **Agentes calmados**: Movimiento eficiente y preciso (velocidad 0.4)
- **Navegación inteligente** basada en campos de distancia
- **Detección automática** de cambios de piso
- **Tracking individual** de métricas

### Sistema de Métricas

#### Métricas Temporales
- Tiempo total de evacuación
- Tiempo del primer evacuado
- Tiempo promedio por persona
- Tiempo de vaciado por piso (1-5)

#### Métricas de Congestión
- Densidad máxima global
- Densidad por zona (escaleras, puertas, pasillos)
- Ubicación de cuellos de botella
- Historial de densidad en tiempo real

#### Métricas de Flujo
- Evacuados por piso de origen
- Uso total de escaleras
- Tasa pico de evacuación
- Personas atascadas

## 🚀 Instalación y Uso

### Requisitos
- [NetLogo 6.x](https://ccl.northwestern.edu/netlogo/download.shtml) o superior

### Pasos

1. **Clonar el repositorio:**
```bash
git clone https://github.com/TU-USUARIO/evacuacion-edificio-netlogo.git
cd evacuacion-edificio-netlogo
```

2. **Abrir en NetLogo:**
   - Ejecutar NetLogo
   - File → Open → Seleccionar `evacuacion_edificio.nlogo`

3. **Configurar parámetros:**
   - `numero-agentes`: Cantidad de personas (recomendado: 50-300)
   - `porcentaje-panico`: Porcentaje de agentes en pánico (0-100)

4. **Ejecutar simulación:**
   - Click en **Setup** para inicializar
   - Click en **Go** para comenzar la simulación
   - Click en **Go** nuevamente para pausar

## 📊 Visualización y Análisis

### Monitores en Tiempo Real
- Personas restantes
- Porcentaje evacuado
- Densidad en zonas críticas
- Personas atascadas
- Ubicación de cuellos de botella

### Exportación de Datos

**Reporte en Consola:**
```netlogo
;; Al finalizar la simulación, se imprime automáticamente
;; un reporte completo con todas las métricas
```

**Exportación CSV:**
```netlogo
;; Ejecutar desde el centro de comandos:
exportar-csv
;; Genera archivo: evacuacion_resultados.csv
```

**Visualización de Calor:**
```netlogo
;; Mostrar mapa de congestión histórica:
mostrar-mapa-congestion

;; Restaurar colores originales:
restaurar-colores
```

## 🧮 Algoritmos Clave

### 1. Algoritmo de Pathfinding (Mapa de Calor)

Implementación de Breadth-First Search modificado:

```
1. Asignar distancia 0 a salidas y escaleras de bajada
2. Propagar distancias a zonas vecinas (+1 por cada paso)
3. Cada agente se mueve hacia la zona con menor distancia
4. Resultado: Campo de gradientes que guía la evacuación óptima
```

**Ventajas:**
- Cálculo pre-computado (eficiente)
- Navegación óptima por piso
- No requiere pathfinding en tiempo real

### 2. Comportamiento de Agentes

```netlogo
cada tick:
  1. Identificar vecinos válidos en mismo piso
  2. Seleccionar patch con menor distancia-salida
  3. Orientarse hacia objetivo
  4. Aplicar componente aleatorio si está en pánico
  5. Avanzar según velocidad
  6. Detectar transiciones (escaleras/salida)
  7. Actualizar métricas personales
```

### 3. Sistema de Transición entre Pisos

```
Si agente en zona "escalera-bajada":
  1. Verificar piso actual > 1
  2. Calcular nueva coordenada Y: y_actual - 40 + ajuste
  3. Teletransportar agente
  4. Incrementar contador de flujo
  5. Continuar navegación en nuevo piso
```

## 📈 Casos de Uso

### 1. Evaluación de Diseño Arquitectónico
Identificar si el diseño actual presenta cuellos de botella peligrosos.

**Ejemplo:**
```
Configuración: 200 agentes, 30% pánico
Resultado: Cuello de botella en Piso 3 (escaleras)
Acción: Evaluar agregar escalera adicional
```

### 2. Análisis de Sensibilidad
Evaluar impacto del porcentaje de pánico en tiempos de evacuación.

**Experimento:**
```
Ejecutar 10 repeticiones para cada configuración:
- 0% pánico
- 25% pánico
- 50% pánico
- 75% pánico
- 100% pánico

Analizar: tiempo_promedio vs porcentaje_panico
```

### 3. Optimización de Capacidad
Determinar capacidad máxima segura del edificio.

**Método:**
```
Incrementar numero-agentes de 50 a 500 (paso 50)
Identificar punto donde:
  - tiempo_evacuacion > umbral_seguridad (ej: 300 ticks)
  - densidad_maxima > umbral_critico (ej: 8 personas/parche)
```

## 🔧 Personalización

### Modificar Arquitectura

```netlogo
;; En la función dibujar-planta-mixta:

;; Cambiar tamaño de habitaciones:
let y-min y-center - 15  ;; Modificar este valor
let y-max y-center + 15  ;; Modificar este valor

;; Agregar/quitar muros:
let muros-verticales (list -17 -9 0 9 17)  ;; Editar lista

;; Agregar/quitar puertas:
;; Duplicar bloques ask patches with [...]
```

### Agregar Nuevos Tipos de Agentes

```netlogo
personas-own [
  ;; Agregar nuevas propiedades:
  nivel-entrenamiento  ;; 1-5
  condicion-fisica     ;; baja/media/alta
  conoce-edificio?     ;; true/false
]

;; Ajustar velocidad según nuevas propiedades
set velocidad-base (0.3 + (nivel-entrenamiento * 0.1))
```

### Nuevas Métricas

```netlogo
globals [
  ;; Agregar nuevas variables globales
  evacuados-por-escalera-A
  evacuados-por-escalera-B
  tiempo-respuesta-alarma
]

;; Crear nuevos reporteros
to-report eficiencia-evacuacion
  report (numero-agentes / tiempo-total-evacuacion)
end
```

## 📚 Estructura del Código

```
evacuacion_edificio.nlogo
│
├── 1. DECLARACIÓN DE VARIABLES
│   ├── Métricas globales
│   ├── Propiedades de patches
│   └── Propiedades de agentes
│
├── 2. CONFIGURACIÓN INICIAL (SETUP)
│   ├── inicializar-colores
│   ├── inicializar-metricas
│   └── crear-edificio-completo
│
├── 3. CONSTRUCCIÓN DEL EDIFICIO
│   ├── crear-edificio-completo
│   ├── dibujar-planta-mixta
│   └── integrar-escaleras-modificadas
│
├── 4. ALGORITMO DE NAVEGACIÓN
│   └── calcular-mapa-calor
│
├── 5. CREACIÓN Y LÓGICA DE AGENTES
│   ├── crear-personas-dos-colores
│   ├── comportamiento-movimiento
│   └── verificar-cambio-piso-o-salida
│
├── 6. SISTEMA DE MÉTRICAS
│   ├── actualizar-estadisticas-avanzadas
│   └── verificar-pisos-vacios
│
├── 7. REPORTEROS PARA MONITORES
│   ├── personas-restantes
│   ├── porcentaje-evacuado
│   └── [otros reporteros...]
│
├── 8. EXPORTACIÓN DE RESULTADOS
│   ├── exportar-reporte-final
│   └── exportar-csv
│
└── 9. VISUALIZACIÓN
    ├── mostrar-mapa-congestion
    └── restaurar-colores
```

## 🧪 Validación del Modelo

### Casos de Prueba Básicos

**Test 1: Evacuación Completa**
```
Configuración: 100 agentes, 0% pánico
Esperado: Todos los agentes evacuados
Criterio: evacuados == numero-agentes
```

**Test 2: Flujo por Escaleras**
```
Configuración: 50 agentes distribuidos en pisos 2-5
Esperado: flujo-por-escalera > 0
Criterio: Todos los agentes usan escaleras
```

**Test 3: Detección de Pánico**
```
Configuración: 100 agentes, 50% pánico
Esperado: ~50 agentes rojos, ~50 agentes azules
Criterio: Distribución binomial
```

### Comportamientos Emergentes Observados

1. **Formación de Colas**: Los agentes forman filas naturales en puertas estrechas
2. **Efecto Cascada**: El pánico se amplifica visualmente cuando muchos agentes rojos convergen
3. **Uso Desigual de Rutas**: Algunas escaleras reciben más flujo que otras
4. **Densificación Progresiva**: La densidad aumenta hacia pisos inferiores


## 📚 Referencias

1. Helbing, D., Farkas, I., & Vicsek, T. (2000). Simulating dynamical features of escape panic. *Nature*, 407(6803), 487-490.

2. Pan, X., Han, C. S., Dauber, K., & Law, K. H. (2007). A multi-agent based framework for the simulation of human and social behaviors during emergency evacuations. *AI & Society*, 22(2), 113-132.

3. Wijermans, N., Conrado, C., van Steen, M., Martella, C., & Li, J. (2016). A landscape of crowd-management support: An integrative approach. *Safety Science*, 86, 142-164.

---

⭐ Si este proyecto te resulta útil, considera darle una estrella en GitHub!
