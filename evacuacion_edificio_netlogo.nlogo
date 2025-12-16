;; ============================================================================
;; MODELO DE SIMULACIÓN: EVACUACIÓN DE EDIFICIO MULTINIVEL (5 PISOS)
;; ============================================================================

;; ----------------------------------------------------------------------------
;; 1. DECLARACIÓN DE VARIABLES Y AGENTES
;; ----------------------------------------------------------------------------

globals [
  ;; === MÉTRICAS BÁSICAS ===
  evacuados
  inicio-simulacion?
  
  ;; === MÉTRICAS TEMPORALES ===
  tiempo-total-evacuacion
  tiempo-primer-evacuado
  suma-tiempos-evacuacion
  
  ;; === MÉTRICAS POR PISO ===
  evacuados-piso-1
  evacuados-piso-2
  evacuados-piso-3
  evacuados-piso-4
  evacuados-piso-5
  tiempo-vacio-piso-1
  tiempo-vacio-piso-2
  tiempo-vacio-piso-3
  tiempo-vacio-piso-4
  tiempo-vacio-piso-5
  
  ;; === MÉTRICAS DE CONGESTIÓN ===
  densidad-maxima
  densidad-maxima-escaleras
  densidad-maxima-puertas
  densidad-maxima-pasillos
  historial-densidad
  
  ;; === MÉTRICAS DE FLUJO ===
  flujo-por-escalera
  evacuados-ultimo-tick
  tasa-evacuacion-pico
  
  ;; === IDENTIFICACIÓN DE CUELLOS DE BOTELLA ===
  cuello-botella-x
  cuello-botella-y
  cuello-botella-piso
  
  ;; === CONFIGURACIÓN VISUAL ===
  altura-piso-visual
  offset-entre-pisos
  
  ;; === PALETA DE COLORES ===
  color-piso
  color-pared
  color-puerta
  color-escalera-bajada
  color-escalera-arriba
  color-pasillo
  color-calle
]

breed [personas persona]

patches-own [
  distancia-salida
  tipo-zona
  numero-piso
  acumulado-personas
  pico-densidad
  tiempo-pico-densidad
]

personas-own [
  en-panico?
  velocidad-base
  velocidad-actual
  evacuado?
  tiempo-inicio
  piso-origen
  tiempo-evacuacion
  distancia-recorrida
  tiempo-atascado
  posicion-anterior-x
  posicion-anterior-y
]

;; ----------------------------------------------------------------------------
;; 2. CONFIGURACIÓN INICIAL (SETUP)
;; ----------------------------------------------------------------------------

to setup
  clear-all
  
  inicializar-colores
  set altura-piso-visual 32
  set offset-entre-pisos 40
  
  inicializar-metricas
  
  crear-edificio-completo
  calcular-mapa-calor
  crear-personas-dos-colores
  
  reset-ticks
end

to inicializar-metricas
  set evacuados 0
  set inicio-simulacion? false
  
  set tiempo-total-evacuacion 0
  set tiempo-primer-evacuado 0
  set suma-tiempos-evacuacion 0
  
  set evacuados-piso-1 0
  set evacuados-piso-2 0
  set evacuados-piso-3 0
  set evacuados-piso-4 0
  set evacuados-piso-5 0
  set tiempo-vacio-piso-1 0
  set tiempo-vacio-piso-2 0
  set tiempo-vacio-piso-3 0
  set tiempo-vacio-piso-4 0
  set tiempo-vacio-piso-5 0
  
  set densidad-maxima 0
  set densidad-maxima-escaleras 0
  set densidad-maxima-puertas 0
  set densidad-maxima-pasillos 0
  set historial-densidad []
  
  set flujo-por-escalera 0
  set evacuados-ultimo-tick 0
  set tasa-evacuacion-pico 0
  
  set cuello-botella-x 0
  set cuello-botella-y 0
  set cuello-botella-piso 0
end

to inicializar-colores
  set color-piso 47
  set color-pared 0
  set color-puerta 65
  set color-escalera-bajada 55
  set color-escalera-arriba 57
  set color-pasillo 37
  set color-calle 95
end

;; ----------------------------------------------------------------------------
;; 3. CONSTRUCCIÓN DEL EDIFICIO
;; ----------------------------------------------------------------------------

to crear-edificio-completo
  ask patches [
    set pcolor black
    set tipo-zona "vacio"
    set numero-piso 0
    set distancia-salida 9999
    set acumulado-personas 0
    set pico-densidad 0
    set tiempo-pico-densidad 0
  ]
  
  let piso-actual 1
  let base-y min-pycor + 20
  
  repeat 5 [
    let y-centro (base-y + ((piso-actual - 1) * offset-entre-pisos))
    dibujar-planta-mixta y-centro piso-actual
    integrar-escaleras-modificadas y-centro piso-actual
    set piso-actual piso-actual + 1
  ]
end

to integrar-escaleras-modificadas [y-center numero]
  if numero = 1 [
    crear-zona-grande (min-pxcor + 3) y-center numero "salida-calle" color-calle
    crear-zona-linea-muro "derecha" (y-center + 1.5) numero "escalera-arriba" color-escalera-arriba
  ]
  
  if numero > 1 [
    crear-zona-linea-muro "derecha" (y-center - 1.5) numero "escalera-bajada" color-escalera-bajada
    if numero < 5 [
      crear-zona-linea-muro "derecha" (y-center + 1.5) numero "escalera-arriba" color-escalera-arriba
    ]
  ]
end

to crear-zona-grande [x y numero tipo col]
  ask patches with [abs (pxcor - x) <= 2 and abs (pycor - y) <= 2 and numero-piso = numero] [
    set pcolor col
    set tipo-zona tipo
  ]
end

to crear-zona-linea-muro [lado y numero tipo col]
  if lado = "derecha" [
    ask patches with [pxcor >= (max-pxcor - 1) and abs (pycor - y) <= 0.5 and numero-piso = numero] [
      set pcolor col
      set tipo-zona tipo
    ]
  ]
end

to dibujar-planta-mixta [y-center numero]
  let y-min y-center - 15
  let y-max y-center + 15
  
  ask patches with [pycor >= y-min and pycor <= y-max and pxcor > min-pxcor and pxcor < max-pxcor] [
    set pcolor color-piso
    set tipo-zona "habitacion"
    set numero-piso numero
  ]
  ask patches with [(pycor = y-min or pycor = y-max or pxcor = min-pxcor or pxcor = max-pxcor) and numero-piso = numero] [
    set pcolor color-pared
    set tipo-zona "pared"
  ]
  
  ask patches with [abs (pycor - y-center) <= 2 and numero-piso = numero and pxcor > min-pxcor and pxcor < max-pxcor] [
    set pcolor color-pasillo
    set tipo-zona "pasillo"
  ]
  ask patches with [(pycor = y-center + 3 or pycor = y-center - 3) and numero-piso = numero] [
    set pcolor color-pared
    set tipo-zona "pared"
  ]
  
  let muros-verticales (list -17 -9 0 9 17)
  foreach muros-verticales [ muro-x ->
    ask patches with [pxcor = muro-x and abs (pycor - y-center) > 2 and numero-piso = numero] [
      set pcolor color-pared
      set tipo-zona "pared"
    ]
  ]
  ask patches with [(pycor = y-center + 10 or pycor = y-center - 10) and numero-piso = numero and abs pxcor < max-pxcor] [
    set pcolor color-pared
    set tipo-zona "pared"
  ]
  
  let columnas-salida (list -13 13)
  foreach columnas-salida [ x ->
    ask patches with [pxcor = x and (pycor = y-center + 3 or pycor = y-center - 3) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
  ]
  
  let centros-salas (list -21 -13 -4 4 13 21)
  foreach centros-salas [ x ->
    ask patches with [pxcor = x and (pycor = y-center + 10 or pycor = y-center - 10) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
  ]
  
  let muros-con-puerta (list -17 -9 0 9 17)
  foreach muros-con-puerta [ muro-x ->
    ask patches with [pxcor = muro-x and (pycor = y-center - 13) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
    ask patches with [pxcor = muro-x and (pycor = y-center - 6) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
    ask patches with [pxcor = muro-x and (pycor = y-center + 13) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
    ask patches with [pxcor = muro-x and (pycor = y-center + 6) and numero-piso = numero] [
      set pcolor color-puerta
      set tipo-zona "puerta"
    ]
  ]
end

;; ----------------------------------------------------------------------------
;; 4. ALGORITMO DE NAVEGACIÓN
;; ----------------------------------------------------------------------------

to calcular-mapa-calor
  ask patches [ set distancia-salida 9999 ]
  
  ask patches with [tipo-zona = "salida-calle"] [ set distancia-salida 0 ]
  ask patches with [tipo-zona = "escalera-bajada"] [ set distancia-salida 0 ]
  
  let cola patches with [distancia-salida = 0]
  let visitados cola
  
  while [any? cola] [
    let nuevos patch-set nobody
    ask cola [
      let d distancia-salida
      let mi-piso numero-piso
      ask neighbors4 with [
        tipo-zona != "pared" and tipo-zona != "vacio" and
        numero-piso = mi-piso and
        not member? self visitados
      ] [
        set distancia-salida d + 1
        set nuevos (patch-set nuevos self)
      ]
    ]
    set visitados (patch-set visitados nuevos)
    set cola nuevos
  ]
end

;; ----------------------------------------------------------------------------
;; 5. CREACIÓN Y LÓGICA DE AGENTES
;; ----------------------------------------------------------------------------

to crear-personas-dos-colores
  let lugares patches with [tipo-zona = "habitacion" and numero-piso > 0]
  if not any? lugares [ stop ]
  
  create-personas numero-agentes [
    move-to one-of lugares
    set shape "person"
    set size 1.5
    set evacuado? false
    set tiempo-inicio 0
    
    set piso-origen [numero-piso] of patch-here
    
    set distancia-recorrida 0
    set tiempo-atascado 0
    set posicion-anterior-x xcor
    set posicion-anterior-y ycor
    set tiempo-evacuacion 0
    
    set en-panico? (random 100 < porcentaje-panico)
    
    ifelse en-panico? [
      set color red
      set velocidad-base 0.7
    ] [
      set color blue
      set velocidad-base 0.4
    ]
    set velocidad-actual velocidad-base
  ]
end

to go
  if not inicio-simulacion? [
    set inicio-simulacion? true
    ask personas [ set tiempo-inicio ticks ]
  ]
  
  let evacuados-antes evacuados
  
  if not any? personas with [not evacuado?] [
    set tiempo-total-evacuacion ticks
    exportar-reporte-final
    stop
  ]
  
  ask personas with [not evacuado?] [
    set posicion-anterior-x xcor
    set posicion-anterior-y ycor
    
    comportamiento-movimiento
    verificar-cambio-piso-o-salida
    
    let dist-tick sqrt ((xcor - posicion-anterior-x) ^ 2 + (ycor - posicion-anterior-y) ^ 2)
    set distancia-recorrida distancia-recorrida + dist-tick
    
    if dist-tick < 0.1 [
      set tiempo-atascado tiempo-atascado + 1
    ]
  ]
  
  actualizar-estadisticas-avanzadas
  
  let evacuados-este-tick evacuados - evacuados-antes
  if evacuados-este-tick > tasa-evacuacion-pico [
    set tasa-evacuacion-pico evacuados-este-tick
  ]
  set evacuados-ultimo-tick evacuados-este-tick
  
  verificar-pisos-vacios
  
  tick
end

to comportamiento-movimiento
  let piso-agente [numero-piso] of patch-here
  
  let opciones neighbors with [
    tipo-zona != "pared" and tipo-zona != "vacio" and
    numero-piso = piso-agente
  ]
  
  let mejor min-one-of opciones [distancia-salida]
  
  if mejor != nobody [
    face mejor
    if en-panico? [ rt random 20 - 10 ]
    fd velocidad-actual
  ]
end

to verificar-cambio-piso-o-salida
  let zona [tipo-zona] of patch-here
  
  if zona = "salida-calle" [
    set evacuado? true
    set tiempo-evacuacion (ticks - tiempo-inicio)
    set suma-tiempos-evacuacion suma-tiempos-evacuacion + tiempo-evacuacion
    set evacuados evacuados + 1
    
    if tiempo-primer-evacuado = 0 [
      set tiempo-primer-evacuado ticks
    ]
    
    registrar-evacuado-por-piso piso-origen
    
    hide-turtle
    stop
  ]
  
  if zona = "escalera-bajada" [
    let piso-actual [numero-piso] of patch-here
    if piso-actual > 1 [
      set flujo-por-escalera flujo-por-escalera + 1
      let nueva-y (ycor - offset-entre-pisos + 3)
      let patch-destino patch xcor nueva-y
      if patch-destino != nobody [
        set ycor nueva-y
      ]
    ]
  ]
end

to registrar-evacuado-por-piso [piso]
  if piso = 1 [ set evacuados-piso-1 evacuados-piso-1 + 1 ]
  if piso = 2 [ set evacuados-piso-2 evacuados-piso-2 + 1 ]
  if piso = 3 [ set evacuados-piso-3 evacuados-piso-3 + 1 ]
  if piso = 4 [ set evacuados-piso-4 evacuados-piso-4 + 1 ]
  if piso = 5 [ set evacuados-piso-5 evacuados-piso-5 + 1 ]
end

to verificar-pisos-vacios
  if tiempo-vacio-piso-1 = 0 and not any? personas with [not evacuado? and [numero-piso] of patch-here = 1] [
    set tiempo-vacio-piso-1 ticks
  ]
  if tiempo-vacio-piso-2 = 0 and not any? personas with [not evacuado? and [numero-piso] of patch-here = 2] [
    set tiempo-vacio-piso-2 ticks
  ]
  if tiempo-vacio-piso-3 = 0 and not any? personas with [not evacuado? and [numero-piso] of patch-here = 3] [
    set tiempo-vacio-piso-3 ticks
  ]
  if tiempo-vacio-piso-4 = 0 and not any? personas with [not evacuado? and [numero-piso] of patch-here = 4] [
    set tiempo-vacio-piso-4 ticks
  ]
  if tiempo-vacio-piso-5 = 0 and not any? personas with [not evacuado? and [numero-piso] of patch-here = 5] [
    set tiempo-vacio-piso-5 ticks
  ]
end

;; ----------------------------------------------------------------------------
;; 6. SISTEMA DE MÉTRICAS AVANZADAS
;; ----------------------------------------------------------------------------

to actualizar-estadisticas-avanzadas
  ask patches with [tipo-zona != "pared" and tipo-zona != "vacio"] [
    let personas-aqui count personas-here with [not evacuado?]
    set acumulado-personas acumulado-personas + personas-aqui
    
    if personas-aqui > pico-densidad [
      set pico-densidad personas-aqui
      set tiempo-pico-densidad ticks
    ]
  ]
  
  let escaleras patches with [tipo-zona = "escalera-bajada" or tipo-zona = "escalera-arriba"]
  let puertas patches with [tipo-zona = "puerta"]
  let pasillos patches with [tipo-zona = "pasillo"]
  
  if any? escaleras [
    let max-esc max [count personas-here with [not evacuado?]] of escaleras
    if max-esc > densidad-maxima-escaleras [
      set densidad-maxima-escaleras max-esc
    ]
  ]
  
  if any? puertas [
    let max-pue max [count personas-here with [not evacuado?]] of puertas
    if max-pue > densidad-maxima-puertas [
      set densidad-maxima-puertas max-pue
    ]
  ]
  
  if any? pasillos [
    let max-pas max [count personas-here with [not evacuado?]] of pasillos
    if max-pas > densidad-maxima-pasillos [
      set densidad-maxima-pasillos max-pas
    ]
  ]
  
  let zonas-riesgo patches with [tipo-zona = "pasillo" or tipo-zona = "escalera-bajada" or tipo-zona = "puerta"]
  if any? zonas-riesgo [
    let max-densidad-actual max [count personas-here with [not evacuado?]] of zonas-riesgo
    if max-densidad-actual > densidad-maxima [
      set densidad-maxima max-densidad-actual
      let peor-patch max-one-of zonas-riesgo [count personas-here with [not evacuado?]]
      if peor-patch != nobody [
        set cuello-botella-x [pxcor] of peor-patch
        set cuello-botella-y [pycor] of peor-patch
        set cuello-botella-piso [numero-piso] of peor-patch
      ]
    ]
  ]
  
  if ticks mod 10 = 0 [
    let densidad-promedio-actual 0
    if any? zonas-riesgo [
      set densidad-promedio-actual mean [count personas-here with [not evacuado?]] of zonas-riesgo
    ]
    set historial-densidad lput densidad-promedio-actual historial-densidad
  ]
end

;; ----------------------------------------------------------------------------
;; 7. REPORTEROS PARA MONITORES
;; ----------------------------------------------------------------------------

to-report personas-restantes
  report count personas with [not evacuado?]
end

to-report porcentaje-evacuado
  if numero-agentes > 0 [
    report (evacuados / numero-agentes) * 100
  ]
  report 0
end

to-report personas-en-panico-actuales
  report count personas with [en-panico? and not evacuado?]
end

to-report tiempo-promedio-evacuacion
  if evacuados > 0 [
    report suma-tiempos-evacuacion / evacuados
  ]
  report 0
end

to-report densidad-actual-escaleras
  let escaleras patches with [tipo-zona = "escalera-bajada" or tipo-zona = "escalera-arriba"]
  if any? escaleras [
    report max [count personas-here with [not evacuado?]] of escaleras
  ]
  report 0
end

to-report densidad-actual-puertas
  let puertas patches with [tipo-zona = "puerta"]
  if any? puertas [
    report max [count personas-here with [not evacuado?]] of puertas
  ]
  report 0
end

to-report densidad-actual-pasillos
  let pasillos patches with [tipo-zona = "pasillo"]
  if any? pasillos [
    report max [count personas-here with [not evacuado?]] of pasillos
  ]
  report 0
end

to-report personas-atascadas
  report count personas with [not evacuado? and tiempo-atascado > 10]
end

to-report info-cuello-botella
  report (word "Piso " cuello-botella-piso " (" cuello-botella-x ", " cuello-botella-y ")")
end

;; ----------------------------------------------------------------------------
;; 8. EXPORTACIÓN DE RESULTADOS
;; ----------------------------------------------------------------------------

to exportar-reporte-final
  print "=============================================="
  print "       REPORTE FINAL DE EVACUACIÓN"
  print "=============================================="
  print ""
  print (word "TIEMPO TOTAL: " tiempo-total-evacuacion " ticks")
  print (word "PRIMER EVACUADO: tick " tiempo-primer-evacuado)
  print (word "TIEMPO PROMEDIO: " precision tiempo-promedio-evacuacion 2 " ticks")
  print ""
  print "--- EVACUADOS POR PISO DE ORIGEN ---"
  print (word "  Piso 1: " evacuados-piso-1 " personas")
  print (word "  Piso 2: " evacuados-piso-2 " personas")
  print (word "  Piso 3: " evacuados-piso-3 " personas")
  print (word "  Piso 4: " evacuados-piso-4 " personas")
  print (word "  Piso 5: " evacuados-piso-5 " personas")
  print ""
  print "--- TIEMPO VACIADO POR PISO ---"
  print (word "  Piso 1: tick " tiempo-vacio-piso-1)
  print (word "  Piso 2: tick " tiempo-vacio-piso-2)
  print (word "  Piso 3: tick " tiempo-vacio-piso-3)
  print (word "  Piso 4: tick " tiempo-vacio-piso-4)
  print (word "  Piso 5: tick " tiempo-vacio-piso-5)
  print ""
  print "--- MÉTRICAS DE CONGESTIÓN ---"
  print (word "  Densidad máxima global: " densidad-maxima " personas/parche")
  print (word "  Densidad máx. escaleras: " densidad-maxima-escaleras)
  print (word "  Densidad máx. puertas: " densidad-maxima-puertas)
  print (word "  Densidad máx. pasillos: " densidad-maxima-pasillos)
  print (word "  Cuello de botella: Piso " cuello-botella-piso)
  print ""
  print "--- MÉTRICAS DE FLUJO ---"
  print (word "  Uso total escaleras: " flujo-por-escalera " transiciones")
  print (word "  Tasa pico evacuación: " tasa-evacuacion-pico " personas/tick")
  print ""
  print "=============================================="
end

to exportar-csv
  file-open "evacuacion_resultados.csv"
  file-print "metrica,valor"
  file-print (word "tiempo_total," tiempo-total-evacuacion)
  file-print (word "tiempo_primer_evacuado," tiempo-primer-evacuado)
  file-print (word "tiempo_promedio," precision tiempo-promedio-evacuacion 2)
  file-print (word "evacuados_piso_1," evacuados-piso-1)
  file-print (word "evacuados_piso_2," evacuados-piso-2)
  file-print (word "evacuados_piso_3," evacuados-piso-3)
  file-print (word "evacuados_piso_4," evacuados-piso-4)
  file-print (word "evacuados_piso_5," evacuados-piso-5)
  file-print (word "densidad_maxima," densidad-maxima)
  file-print (word "densidad_max_escaleras," densidad-maxima-escaleras)
  file-print (word "densidad_max_puertas," densidad-maxima-puertas)
  file-print (word "flujo_escaleras," flujo-por-escalera)
  file-print (word "tasa_pico," tasa-evacuacion-pico)
  file-print (word "porcentaje_panico," porcentaje-panico)
  file-print (word "numero_agentes," numero-agentes)
  file-close
  print "Datos exportados a evacuacion_resultados.csv"
end

;; ----------------------------------------------------------------------------
;; 9. VISUALIZACIÓN DE CALOR
;; ----------------------------------------------------------------------------

to mostrar-mapa-congestion
  ask patches with [tipo-zona != "pared" and tipo-zona != "vacio"] [
    if pico-densidad > 0 [
      set pcolor scale-color red pico-densidad 10 0
    ]
  ]
end

to restaurar-colores
  ask patches with [tipo-zona = "habitacion"] [ set pcolor color-piso ]
  ask patches with [tipo-zona = "pasillo"] [ set pcolor color-pasillo ]
  ask patches with [tipo-zona = "puerta"] [ set pcolor color-puerta ]
  ask patches with [tipo-zona = "escalera-bajada"] [ set pcolor color-escalera-bajada ]
  ask patches with [tipo-zona = "escalera-arriba"] [ set pcolor color-escalera-arriba ]
  ask patches with [tipo-zona = "salida-calle"] [ set pcolor color-calle ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
823
824
-1
-1
5.0
1
10
1
1
1
0
0
0
1
-60
60
-80
80
1
1
1
ticks
30.0

BUTTON
15
15
88
48
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
95
15
168
48
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
60
187
93
numero-agentes
numero-agentes
10
500
200.0
10
1
NIL
HORIZONTAL

SLIDER
15
100
187
133
porcentaje-panico
porcentaje-panico
0
100
30.0
5
1
%
HORIZONTAL

MONITOR
15
150
132
195
Personas Restantes
personas-restantes
0
1
11

MONITOR
15
200
132
245
% Evacuado
porcentaje-evacuado
2
1
11

MONITOR
15
250
132
295
Personas en Pánico
personas-en-panico-actuales
0
1
11

MONITOR
15
300
132
345
Tiempo Promedio
tiempo-promedio-evacuacion
2
1
11

MONITOR
15
350
132
395
Evacuados Totales
evacuados
0
1
11

MONITOR
15
400
132
445
Ticks Transcurridos
ticks
0
1
11

MONITOR
140
150
267
195
Densidad Escaleras
densidad-actual-escaleras
0
1
11

MONITOR
140
200
267
245
Densidad Puertas
densidad-actual-puertas
0
1
11

MONITOR
140
250
267
295
Densidad Pasillos
densidad-actual-pasillos
0
1
11

MONITOR
140
300
267
345
Personas Atascadas
personas-atascadas
0
1
11

MONITOR
140
350
267
395
Cuello Botella
info-cuello-botella
0
1
11

BUTTON
15
460
150
493
Exportar CSV
exportar-csv
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
500
175
533
Mapa Congestión
mostrar-mapa-congestion
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
15
540
175
573
Restaurar Colores
restaurar-colores
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
20
600
200
628
Configuración de la Simulación
14
0.0
1

TEXTBOX
20
630
195
696
- Azul: Personas calmadas\n- Rojo: Personas en pánico\n- Verde claro: Salida\n- Naranja: Escaleras
11
0.0
1

@#$#@#$#@
## ¿QUÉ ES?

Este modelo simula la evacuación de un edificio de 5 pisos durante una situación de emergencia. El modelo permite estudiar cómo diferentes factores (número de personas, porcentaje de pánico, diseño arquitectónico) afectan la eficiencia de la evacuación.

## ¿CÓMO FUNCIONA?

El modelo utiliza un algoritmo de pathfinding basado en distancias para guiar a las personas hacia la salida. Las personas pueden estar en dos estados: calmadas (azules, velocidad 0.4) o en pánico (rojas, velocidad 0.7 con movimiento errático).

Cada piso tiene:
- 12 habitaciones distribuidas en 6 zonas
- Pasillos centrales de conexión
- Múltiples puertas de acceso
- Escaleras para descender al siguiente piso
- Una salida única en la planta baja

## ¿CÓMO USARLO?

1. Ajustar los sliders:
   - **numero-agentes**: Cantidad de personas (10-500)
   - **porcentaje-panico**: Porcentaje que entrará en pánico (0-100%)

2. Presionar **Setup** para inicializar el modelo

3. Presionar **Go** para ejecutar la simulación

4. Observar los monitores en tiempo real

5. Al finalizar, usar **Exportar CSV** para guardar resultados

6. Usar **Mapa Congestión** para visualizar zonas críticas

## COSAS A NOTAR

- Las personas en pánico se mueven más rápido pero de forma menos eficiente
- Los cuellos de botella se forman típicamente en escaleras y puertas
- Los pisos superiores tardan más en evacuarse
- La densidad máxima indica zonas de riesgo

## COSAS A INTENTAR

- Comparar evacuaciones con 0% vs 100% de pánico
- Probar con diferentes números de agentes
- Identificar el número máximo seguro de ocupantes
- Observar cómo cambian los cuellos de botella

## EXTENDIENDO EL MODELO

Ideas para mejorar:
- Agregar múltiples salidas
- Implementar obstáculos dinámicos
- Modelar ascensores (fuera de servicio)
- Agregar personas con movilidad reducida
- Simular propagación de fuego o humo

## CRÉDITOS Y REFERENCIAS

Modelo creado para análisis de evacuación de edificios.
Basado en principios de modelos basados en agentes (ABM).

Referencias académicas:
- Helbing, D., et al. (2000). Simulating dynamical features of escape panic.
- Pan, X., et al. (2007). Multi-agent based framework for evacuation simulation.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
