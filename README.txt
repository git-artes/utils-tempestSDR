Este repo contiene una breve descripción de los script de software que complementan la documentación final de la Tesis de Maestrı́a titulada: “Espionaje por Emisiones Electromagnéticas”. 
Ing. Pablo Menoni, tutor: Dr. Ing. Federico La Rocca.

Comentarios, correcciones, etc: pablo.menoni@gmail.com

Más recursos (tesis, algún video y algunas grabaciones para usar desde el TempestSDR o el propio GNU Radio) en https://iie.fing.edu.uy/investigacion/grupos/artes/es/proyectos/espionaje-por-emisiones-electromagneticas/. 

Archivos del repositorio:
+-----------------------------------------+-----------------------------------------------------------+
|  Nombre                                 |                          Descripción                      |
+-----------------------------------------+-----------------------------------------------------------+
| Decodificador_TMDS_2.m                  | Script, decodifica TMDS y entrega en forma matriz         |
| disenio_inverso_sinc_bandabase.m        | Función: Diseña el ecualizador que compensa el sinc       |
| disenio_inverso_sinc_pasabanda.m        | Función: llamada desde disenio_inverso_sinc_bandabase.m   |
| Espectro_TDMS_3.m                       | Script, crea las imágenes VGA y HDMI en .dat              |
| generar_senial_video_pasabanda.grc      | Script de GNU Radio que simula el canal y señal VGA       |
| generar_senial_video_pasabanda_TDMS.grc | Script de GNU Radio que simula el canal y señal HDMI      |
| Imagen_800_600.png                      | Imagen fuente de Espectro_TDMS_3.m                        |
| mostrar_figura.m                        | Script, consume: p_o.mat y la imagen VGA en formato .dat  |
| mostrar_figura_TMDS_3.m                 | Script, consume la imagen HDMI en formato .dat            |
| patrones_pruebas_2.png                  | Imagen fuente de Espectro_TDMS_3.m                        |
| p_o.mat                                 | Pulsos conformadores precargados                          |
| pulsos.mat				  | Pulsos g(t) precargados para graficar                     |
| pulso_VGA_rojo.csv                      | Valores del puso rojo en el osciloscopio (Fig 3.14)       |
| pulso_VGA_azul.csv                      | Valores del puso azul en el osciloscopio (Fig 3.14)       |
+-----------------------------------------+-----------------------------------------------------------+

+------------------------------------+
|        Simulaciones VGA            |
+------------------------------------+
Script: mostrar_figura.m

- Se levanta la imagen VGA, ya serializada, desde una archivo .dat. (Para crear el .dat ver el script Espectro_TDMS_3.m)
- Se hace una interpolación:
    +---------------------------------------------------+
    | d 0 0 0 0 a 0 0 0 0 t 0 0 0 0 o 0 0 0 0 s 0 0 0 0 |
    +---------------------------------------------------+
- Se conforma la señal con el pulso p(t) (shaping_pulse).
- Se sigue la simulación de la figura 3.3:
    demodular->LPF+->mostrar
                  |
                  +->ecualizar->mostrar
- la variable entra_p_o decide que tipo de p(t) usar, donde se puede usar uno con overshooting

Script: generar_senial_video_pasabanda.grc

- Toma como entrada la imagen serializada en un archivo .dat
- Simula todo lo que pasa en "transmisión":
	- conformación,
	- ruido, errores de fase, etc.
	- SDR: demodulación, filtrado, decimación
- Escribe la salida en un archivo fifo que puede levantar TempestSDR

+------------------------------------+
|        Simulaciones HDMI           |
+------------------------------------+
Script: Espectro_TDMS_3.m

- Se levanta una imagen png o cualquier otro formato soportado por la función imread.
- Se serializa la señal para simular la señal que va por el cable (son dos señales, una para VGA y otra para HDMI)
- Se "rellena" con los píxeles de blanking y en el caso de HDMI se codifica (TMDS)
- Se graban en formato .dat, float32. Este archivo puede levantarse desde GNU Radio y es el que se usa en mostrar_figura*.m

Script: mostrar_figura_TMDS_3.m

- Análogo al caso VGA, salvo que se generan varias señales que se diferencian en las acciones tomadas luego de pasar el LPF de detección:
 - foto_Tempest_ec_3: decimación -> ]a cada una de las nb señales[ -> se las ecualiza (sobre el pulso de duración Tb)
 - foto_Tempest:      decimación -> por cada una de las nb señales se carga una imagen, ejemplo: [xd,yd,14]
 - foto_Tempest_ec_2: decimación -> se las ecualiza (sobre el pulso de duración Tp) -> se toma una imagen por c/bit
 - foto_Tempest_ecualizada: ecualización (sobre el pulso de duración Tp) -> decimación -> por cada una de las nb señales se carga una imagen
En estas cuatro matrices se tiene:
			[xd,yd,1:10]	una imagen por cada bit
			[xd,yd,11]	promedio de [xd,yd,1:10]
			[xd,yd,12]	una imagen que elije un bit al azar de los nb de c/píxel
			[xd,yd,13]	una imagen que va tomando un bit por c/píxel en forma circular
			[xd,yd,14]	una imagen que alterna entre dos bit por c/píxel
 - foto_TMDS_decoficada: decimación -> Decodificación TMDS
 - foto_TMDS_decoficada_ecualizada: ecualización -> decimación -> Decodificación TMDS

Script: generar_senial_video_pasabanda_TDMS.grc
Análogo al caso VGA

+-------------------------------------------+
|          Otros script y funciones         |
+-------------------------------------------+

- Decodificador_TMDS_2: se le pasa la señal serializada y devuelve la imagen [xd,yd] decodidicada TMDS
- disenio_inverso_sinc_bandabase y disenio_inverso_sinc_pasabanda: usadas para ecualizar en la simulación VGA asumiendo pulso NRZ.


+-------------------------------------------+
| Generación y/o obtención de las imágenes  |
+-------------------------------------------+
Se describe a continuación la generación simulada de las imágenes de espionaje y el script usado, con alguna de las variables usadas y sus valores.
+--------------------------------------------- -----------+-------------------------------------------------------+
|                          FIGURA                         |                       SCRIPT                          |
+---------------------------------------------------------+-------------------------------------------------------+
| 3.6 Simulación de la imagen VGA                         | mostrar_figura                                        |
| 3.7 Simulación de la imagen VGA                         | generar_senial_video_pasabanda.grc -> TempestSDR      |
| 3.11 Comparación g(t)                                   | g_10 y g_25 de pulsos.mat                             |
| 3.14 Pulsos						  | cargar los dos csv y usar p_o_1 de p_o.mat            |
| 3.20 Comparación del efecto del overshooting a)         | mostrar_figura                                        |
| 4.2 Simulación de la imagen HDMI                        | generar_senial_video_pasabanda_TDMS.grc -> TempestSDR |
| 4.3 Simulación de una imagen HDMI                       | mostrar_figura_TMDS_3, f_cutoff = 40e6                |
| 4.19 Comparación entre g(t)                             | mostrar_figura, azul=filter(equa_filter,1,g_10)       |
| 4.5, 4.6 Simulación de la imagen HDMI                   | mostrar_figura_TMDS_3, f_cutoff = 50e6                |
| 4.7 Simulación de la imagen HDMI                        | mostrar_figura_TMDS_3, f_cutoff = 200e6               |
| 4.8 Sincronización temporal                             | mostrar_figura_TMDS_3, variando: offset y f_cutoff    |
| 4.9 Simulación de la imagen recuperada                  | mostrar_figura, real(foto_resultado)                  |
| 4.15 Simulación de la imagen recuperada usando |x^eq_R| | mostrar_figura, f_cutoff=10e6                         |
| 4.16 Efecto ecualizador                                 | mostrar_figura, plot de foto_resultado_sin_eq y       |  
|                                                         |                foto_resultado                         |
| 4.17 Simulación de la imagen recuperada usando |x^eq_R| | mostrar_figura, f_cutoff=10e6, error_frecuencia=100   |
+---------------------------------------------------------+-------------------------------------------------------+


+-----------------+
|   TempestSDR    |
+-----------------+
Toda la documentación y fuentes en: https://github.com/martinmarinov/TempestSDR
