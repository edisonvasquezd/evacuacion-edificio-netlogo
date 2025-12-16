<?xml version="1.0" encoding="utf-8"?>
<model version="NetLogo 7.0.2" snapToGrid="true">
  <code><![CDATA[;; ============================================================================
;; MODELO DE SIMULACIÓN: EVACUACIÓN DE EDIFICIO MULTINIVEL (5 PISOS)
;; VERSIÓN MEJORADA CON MÉTRICAS AVANZADAS
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
end]]></code>
  <widgets>
    <view x="240" wrappingAllowedX="false" y="10" frameRate="30.0" minPycor="-100" height="1993" showTickCounter="true" patchSize="10.0" fontSize="10" wrappingAllowedY="false" width="508" tickCounterLabel="ticks" maxPycor="100" updateMode="1" maxPxcor="25" minPxcor="-25"></view>
    <button x="10" actionKey="S" y="10" height="40" disableUntilTicks="false" forever="false" kind="Observer" width="90" display="Setup">setup</button>
    <button x="110" actionKey="G" y="10" height="40" disableUntilTicks="false" forever="true" kind="Observer" width="90" display="Go">go</button>
    <slider x="10" step="10" y="62" max="500" width="190" display="numero-agentes" height="50" min="10" direction="Horizontal" default="500.0" variable="numero-agentes" units="personas"></slider>
    <slider x="10" step="5" y="119" max="100" width="190" display="porcentaje-panico" height="50" min="0" direction="Horizontal" default="20.0" variable="porcentaje-panico" units="%"></slider>
    <monitor x="10" precision="0" y="181" height="60" fontSize="11" width="100" display="Tiempo">ticks</monitor>
    <monitor x="120" precision="0" y="181" height="60" fontSize="11" width="100" display="Evacuados">evacuados</monitor>
    <monitor x="10" precision="0" y="251" height="60" fontSize="11" width="100" display="Restantes">personas-restantes</monitor>
    <monitor x="120" precision="1" y="251" height="60" fontSize="11" width="100" display="% Evacuado">porcentaje-evacuado</monitor>
    <monitor x="10" precision="2" y="321" height="60" fontSize="11" width="190" display="Tiempo Promedio Evacuación">tiempo-promedio-evacuacion</monitor>
    <monitor x="10" precision="0" y="391" height="60" fontSize="11" width="100" display="Primer Evacuado">tiempo-primer-evacuado</monitor>
    <monitor x="120" precision="0" y="391" height="60" fontSize="11" width="100" display="En Pánico">personas-en-panico-actuales</monitor>
    <monitor x="10" precision="0" y="466" height="60" fontSize="11" width="100" display="Densidad Escaleras">densidad-actual-escaleras</monitor>
    <monitor x="120" precision="0" y="466" height="60" fontSize="11" width="100" display="Densidad Puertas">densidad-actual-puertas</monitor>
    <monitor x="10" precision="0" y="536" height="60" fontSize="11" width="100" display="Densidad Pasillos">densidad-actual-pasillos</monitor>
    <monitor x="120" precision="0" y="536" height="60" fontSize="11" width="100" display="Densidad Máxima">densidad-maxima</monitor>
    <monitor x="10" precision="0" y="606" height="60" fontSize="11" width="100" display="Atascados">personas-atascadas</monitor>
    <monitor x="120" precision="0" y="606" height="60" fontSize="11" width="100" display="Uso Escaleras">flujo-por-escalera</monitor>
    <button x="10" actionKey="E" y="681" height="40" disableUntilTicks="false" forever="false" kind="Observer" width="90" display="Exportar CSV">exportar-csv</button>
    <button x="10" y="733" height="40" disableUntilTicks="false" forever="false" kind="Observer" width="90" display="Ver Congestión">mostrar-mapa-congestion</button>
    <button x="110" y="726" height="40" disableUntilTicks="false" forever="false" kind="Observer" width="90" display="Restaurar">restaurar-colores</button>
    <plot x="760" autoPlotX="true" yMax="100.0" autoPlotY="true" yAxis="Personas" y="10" xMin="0.0" height="206" legend="true" xMax="100.0" yMin="0.0" width="310" xAxis="Tiempo (ticks)" display="Progreso de Evacuación">
      <setup></setup>
      <update></update>
      <pen interval="1.0" mode="0" display="Evacuados" color="-10899396" legend="true">
        <setup></setup>
        <update>plot evacuados</update>
      </pen>
      <pen interval="1.0" mode="0" display="Restantes" color="-2674135" legend="true">
        <setup></setup>
        <update>plot personas-restantes</update>
      </pen>
    </plot>
    <plot x="760" autoPlotX="true" yMax="10.0" autoPlotY="true" yAxis="Personas/parche" y="226" xMin="0.0" height="206" legend="true" xMax="100.0" yMin="0.0" width="310" xAxis="Tiempo (ticks)" display="Niveles de Congestión">
      <setup></setup>
      <update></update>
      <pen interval="1.0" mode="0" display="Escaleras" color="-955883" legend="true">
        <setup></setup>
        <update>plot densidad-actual-escaleras</update>
      </pen>
      <pen interval="1.0" mode="0" display="Puertas" color="-13345367" legend="true">
        <setup></setup>
        <update>plot densidad-actual-puertas</update>
      </pen>
      <pen interval="1.0" mode="0" display="Pasillos" color="-7500403" legend="true">
        <setup></setup>
        <update>plot densidad-actual-pasillos</update>
      </pen>
    </plot>
    <plot x="760" autoPlotX="true" yMax="50.0" autoPlotY="true" yAxis="Cantidad" y="442" xMin="0.0" height="175" legend="false" xMax="100.0" yMin="0.0" width="310" xAxis="Tiempo (ticks)" display="Personas en Pánico">
      <setup></setup>
      <update></update>
      <pen interval="1.0" mode="0" display="En Pánico" color="-2674135" legend="true">
        <setup></setup>
        <update>plot personas-en-panico-actuales</update>
      </pen>
    </plot>
    <monitor x="760" precision="0" y="627" height="60" fontSize="11" width="310" display="Cuello de Botella Identificado">info-cuello-botella</monitor>
    <note x="765" y="697" backgroundDark="0" fontSize="11" width="300" markdown="false" height="80" textColorDark="-1" textColorLight="-16777216" backgroundLight="0">LEYENDA DE COLORES:
• Azul claro = Zona segura (salida)
• Verde oscuro = Escalera (bajada)
• Verde claro = Llegada escalera
• Café = Pasillo
• Cyan = Puerta
• Amarillo = Habitación
• Negro = Pared</note>
    <note x="10" y="785" backgroundDark="0" fontSize="11" width="200" markdown="false" height="80" textColorDark="-1" textColorLight="-16777216" backgroundLight="0">INSTRUCCIONES:
1. Ajusta sliders
2. Clic en Setup
3. Clic en Go
4. Al terminar, ver reporte
   en Command Center
5. Exportar datos con CSV</note>
  </widgets>
  <info>## SIMULACIÓN DE EVACUACIÓN DE EDIFICIO

### DESCRIPCIÓN
Este modelo simula la evacuación de emergencia de un edificio de 5 pisos. Los agentes (personas) deben encontrar la ruta más corta hacia la salida, navegando por habitaciones, pasillos y escaleras.

### CONTROLES
- **numero-agentes**: Cantidad total de personas en el edificio
- **porcentaje-panico**: Porcentaje de personas que entrarán en pánico

### MÉTRICAS PRINCIPALES
- Tiempo total de evacuación
- Tiempo promedio por persona
- Niveles de congestión por zona
- Identificación de cuellos de botella

### CÓMO USAR
1. Ajustar los sliders según el escenario deseado
2. Presionar **Setup** para inicializar
3. Presionar **Go** para ejecutar
4. Observar gráficos y monitores en tiempo real
5. Al finalizar, revisar el reporte en Command Center

### CRÉDITOS
Proyecto universitario - Simulación basada en agentes</info>
  <turtleShapes>
    <shape name="default" rotatable="true" editableColorIndex="0">
      <polygon color="-1920102913" filled="true" marked="true">
        <point x="150" y="5"></point>
        <point x="40" y="250"></point>
        <point x="150" y="205"></point>
        <point x="260" y="250"></point>
      </polygon>
    </shape>
    <shape name="person" rotatable="false" editableColorIndex="0">
      <circle x="110" y="5" marked="true" color="-1920102913" diameter="80" filled="true"></circle>
      <polygon color="-1920102913" filled="true" marked="true">
        <point x="105" y="90"></point>
        <point x="120" y="195"></point>
        <point x="90" y="285"></point>
        <point x="105" y="300"></point>
        <point x="135" y="300"></point>
        <point x="150" y="225"></point>
        <point x="165" y="300"></point>
        <point x="195" y="300"></point>
        <point x="210" y="285"></point>
        <point x="180" y="195"></point>
        <point x="195" y="90"></point>
      </polygon>
      <rectangle endX="172" startY="79" marked="true" color="-1920102913" endY="94" startX="127" filled="true"></rectangle>
      <polygon color="-1920102913" filled="true" marked="true">
        <point x="195" y="90"></point>
        <point x="240" y="150"></point>
        <point x="225" y="180"></point>
        <point x="165" y="105"></point>
      </polygon>
      <polygon color="-1920102913" filled="true" marked="true">
        <point x="105" y="90"></point>
        <point x="60" y="150"></point>
        <point x="75" y="180"></point>
        <point x="135" y="105"></point>
      </polygon>
    </shape>
  </turtleShapes>
  <linkShapes>
    <shape name="default" curviness="0.0">
      <lines>
        <line x="-0.2" visible="false">
          <dash value="0.0"></dash>
          <dash value="1.0"></dash>
        </line>
        <line x="0.0" visible="true">
          <dash value="1.0"></dash>
          <dash value="0.0"></dash>
        </line>
        <line x="0.2" visible="false">
          <dash value="0.0"></dash>
          <dash value="1.0"></dash>
        </line>
      </lines>
      <indicator>
        <shape name="link direction" rotatable="true" editableColorIndex="0">
          <line endX="90" startY="150" marked="true" color="-1920102913" endY="180" startX="150"></line>
          <line endX="210" startY="150" marked="true" color="-1920102913" endY="180" startX="150"></line>
        </shape>
      </indicator>
    </shape>
  </linkShapes>
  <previewCommands>setup repeat 75 [ go ]</previewCommands>
</model>
