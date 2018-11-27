%close all
%clear all
martin = 0;    # artificio para poner la misma cantidad de blankings que TempestSDR o lo que usa Martin
pkg load signal
tic();
format short g
fr=60;
Vswing = 128;
tic();
pkg load control;
cd /home/pablo2/Pictures;
color = 1;
#[imagen,map,alfa]=imread('imagen_1024_768.png');
[imagen,map,alfa]=imread('Imagen_800_600.png');
#[imagen,map,alfa]=imread('Imagen_800_600_contraste.png');
#[imagen,map,alfa]=imread('patrones_pruebas_2.png');
red=imagen(:,:,1);
blue=imagen(:,:,3);
green=imagen(:,:,2);
[yd,xd]=size(red);                      # obtiene la resolución 

# habría que serializarlo, ponerle el sincronismo, etc.
# usando norma VESA
# Construimos una matriz con todos esos parámetros donde:
# en cada fila, las primeras tres columnas son la resolución
#
# [res_hor, res_vert, refresh_rat,
#  H_sync, H_back_porch, H_left_border, H_right_border, H_front_porch,
# V_blank, V_sync, V_back_porch, V_top_border, V_bottom_border, V_front_porch]
#
# recordar que los H está en píxeles y lo V en líneas
#    En la planilla VESA
#1) Enter Desired Horizontal Pixels Here =>									1024	
#2) Enter Desired Vertical Lines Here =>									768	
#3) Enter If You Want Margins Here (Y or N) =>								n	
#4) Enter If You Want Interlace Here (Y or N) =>						 		y	
#5) Enter Vertical Scan Frame Rate Here =>		
#6) Enter If You Want Reduced Blanking Here (Y or N)  =>	     				LINES	
#7) Use Reduced Blank Timing version 2  (Y or N) =>							LINES	Applicaple if  answer to question 6 is "Y"
#8) Apply (1000/1001) factor to Frame Rate for video optimized variant (Y or N) =>	n	Applicaple if  answer to question 6 & 7 is "Y"

INTERLACE  = 0;
MIN_V_PORCH_RND = 0;
if (martin == 0)    #construimos rellenos iguales a los de martin o no, solo a los efectos de ver mejor en el TempesSDR
   
Mat_rellenos = [800  600 60 80 112  0  0  32 24 4 17 0 0 3 59.861;
1024  768 60 104 152 0 0  48 30 4 23 0 0 3 59.920;
1920 1080 60 200 328 0 0 128 40 5 32 0 0 3 59.963;
1280  960 60 128 208 0 0 128 36 4 29 0 0 3 59.939;
1366  768 60 136 208 0 0  72 30 5 22 0 0 3 59.799;
1360  768 60 136 208 0 0  72 30 5 22 0 0 3 59.799;
1280  720 60 128 192 0 0  64 28 5 20 0 0 3 59.855];     
else

Mat_rellenos = [800  600 60 80 112  16  16  32 24 4 17 1 1 3 59.861;
1024  768 60 104 152 8 8  48 30 4 23 4 4 3 59.920;
1920 1080 60 200 328 0 0 128 40 5 32 2 2 3 59.963;
1280  960 60 128 208 52 52 128 36 4 29 2 2 3 59.939;
1366  768 60 136 208 2 2  72 30 5 22 0 0 3 59.799;
1360  768 60 136 208 2 2  72 30 5 22 0 0 3 59.799;
1280  720 60 128 192 0 0  64 28 5 20 0 0 3 59.855];  
endif

# OJO que la 1366x768 no es VESA...
# buscamos las lineas
[h,v] = size(Mat_rellenos);
# si no existen las resolución asumimos que es 1024x768@60

fila = 0;
for i=1:h
	if (and(Mat_rellenos(i,1)==xd,Mat_rellenos(i,2)==yd,Mat_rellenos(i,3)==fr))
		fila = i;
		break;
	endif
end
if (fila == 0)
	error("No encontramos las frecuencias corresponientes en Mat_frec");
else
	H_sync = Mat_rellenos(fila,4);
	H_back_porch = Mat_rellenos(fila,5);
	H_left_border = Mat_rellenos(fila,6);
	H_right_border = Mat_rellenos(fila,7);
	H_front_porch = Mat_rellenos(fila,8);

	V_blank = Mat_rellenos(fila,9);
	V_sync = Mat_rellenos(fila,10);
	V_back_porch = Mat_rellenos(fila,11);
	V_top_border = Mat_rellenos(fila,12);
	V_bottom_border = Mat_rellenos(fila,13);
	V_front_porch = Mat_rellenos(fila,14);
     fr= Mat_rellenos(fila,15);
endif
pix_tot_linea = xd + H_sync +	H_back_porch + H_left_border + H_right_border + H_front_porch;
# Lineas totales:
# 2*(V_LINES_RND+TOP_MARGIN+BOT_MARGIN+V_SYNC_BP+INTERLACE+MIN_V_PORCH_RND)
# donde:
# V_LINES_RND = res_vert/2
# TOP_MARGIN = V_top_border      
# BOT_MARGIN = V_bottom_border   
# V_SYNC_BP  = V_sync + V_back_porch
# INTERLACE  = 0.5
# MIN_V_PORCH_RND = 3
lineas_totales = (yd/2 + V_top_border + V_bottom_border + V_sync + V_back_porch + INTERLACE + MIN_V_PORCH_RND);
#si tuvimos una coincidencia en la matriz de relleno, debemos poner la verdadera fr que difiere un cacho de 60Hz
fp=pix_tot_linea*lineas_totales*fr;
# construimos la señal serializada del rojo
# al rojo le agrego los blankings
# primero los de la izquiera y derecha...
trama_red = [zeros(yd,H_sync+H_back_porch+H_left_border) red  zeros(yd,H_right_border+H_front_porch)];
trama_blue = [zeros(yd,H_sync+H_back_porch+H_left_border) blue  zeros(yd,H_right_border+H_front_porch)];
trama_green = [zeros(yd,H_sync+H_back_porch+H_left_border) green  zeros(yd,H_right_border+H_front_porch)];
[aux,xt]=size(trama_red);
# luego los de arriba y abajo y el flyback
trama_red = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_red; zeros((V_bottom_border+V_front_porch),xt)];
trama_blue = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_blue; zeros((V_bottom_border+V_front_porch),xt)];
trama_green = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_green; zeros((V_bottom_border+V_front_porch),xt)];
[yt,xt] = size(trama_red);

# ya tenemos en "trama" la imagen "grande" con los blankings
#
# ahora deberiamos serializarla

imagen_blanking(:,:,1)=trama_red;
imagen_blanking(:,:,2)=trama_green;
imagen_blanking(:,:,3)=trama_blue;
cd /Users/Pablo/Maestría/Octave;
#fid=fopen('imagen_VGA.dat','w');
#fwrite(fid,reshape(trama_red',1,[]),'float32');
#fclose(fid);
#imwrite(imagen_blanking,'imagen_blanking.png');
lineas = 1;
cnt = 0;
salida=[];
switch color
     case 1     
          pixel = dec2bin(trama_red',8);
          color_archivo = '_red';
     case 2
          pixel = dec2bin(trama_green',8);    
          color_archivo = '_green';
     case 3
          pixel = dec2bin(trama_blue',8);     
          color_archivo = '_blue';
     otherwise
          pixel = dec2bin(trama_red',8);
          color_archivo = '_red';
endswitch          
dd =  toascii(pixel);
pixel_serial=reshape(pixel',1,[]);
#    OJO con los traspuestos ' es por como hace el reshape, de a columnas y la Tx de la imagen es de a filas :(
#    En pixel_serial tenemos en un vector la salida en 1s y 0s serial de los 8 bits sin codificar
#    
#    trama_red      pixel          pixel_serial
#    +--------      ---------      ------------------
#    | Vp           b7b6...b0      b7b6...b0b7b6...b0
#    |              b7b6...b0      ------------------
#----------------------------------------------------------------------------------------------------------------
#    Dado un pixel, de la matriz original que este en f,c: trama_red(f,c)
#    En la matriz pixel, la que tiene por cada pixel su valor codificado en 8 bits, estara en:
#    pixel((f-1)*xt+c,:)
#    Ese bit serial estara en pixel_serial((linea-1)*8+1:linea*8) donde linea = (f-1)*xt+c
#    y en salida estara en salida((linea-1)*10:linea*10)
#    Por lo tanto para plotear una seria de bits ploteamos pixel_serial
#-----------------------------------------------------------------------------------------------------------------
#    Recordar que:
#                          xt
#    +----------------------------------------------+
#    |
#    |
#    |
#    | yt
#    |
#    |
#    |
#    +
#    Las salidas de control (diferentes a Hsync y Vsync deben estar el 0 (pagina 26 de la norma)

fila_blank=[];
q_out = [0 0 1 0 1 0 1 0 1 1];
q_D = [0 0 0 0 0 0 0 0];
fila_blank=repmat(q_out,1,xt); %aca no hace el fliplr pues ya esta ordenado LSB fisrt
fila_blank_D=repmat(q_D,1,xt);
lineas = (V_sync+V_back_porch+V_top_border);
salida = repmat(fila_blank,1,lineas);
salida_D = repmat(fila_blank_D,1,lineas);
cnt=0;
DE=0;
columnas=1;
lineas++;      #paso a la siguiente linea
aux_D = 0;
aux_qout = 0;
#    En la matriz imagen_de_bits sacamos las 10 imagenes compuestas una por cada bit de codificacion
#    Además el promedio y otra imagen con un bit de 10 elegido randomicamente
imagen_de_bits=[];
filas = 1;
disp("Entrando a codificar...");
toc();
fflush(stdout);
cuenta_todos = 0;
cuenta_iguales = 0;
while (lineas <= (yt - (V_bottom_border+V_front_porch)))
# Las primeras (V_sync+V_back_porch+V_top_border) son cero
# Las ultimas (V_bottom_border+V_front_porch) son cero 
     #disp(columnas);
     #fflush(stdout);
     columnas = 1;
     columna_bit = 1;
     auxiliar=[];
     auxiliar_D=[];
     while (columnas <= xt)
          # Las primeras (H_sync+H_back_porch+H_left_border) son cero
          # Las ultimas (H_right_border+H_front_porch) son cero
          if ((columnas <= (H_sync+H_back_porch+H_left_border)) || (columnas >= (xt- (H_right_border+H_front_porch))))
               DE=0;
               q_out = [0 0 1 0 1 0 1 0 1 1];
               q_D = [0 0 0 0 0 0 0 0];
               cnt = 0;
          else
               cuenta_todos++;
               DE=1;
               #para contar los "1" y dado que convertimos a ASCII, dd es tipo char y cuento los ascii=49                        
               D = fliplr((dd((lineas-1)*xt+columnas,:)==49));
               q_D = D;              
               aux_D = D(8);
               N1D = sum(D(:)==1); 
               N0 = 8-N1D;
               #LSB first
               if (N1D > 4 || (N1D == 4 && D(1) == 0))
                    #OJO con los indices q_m[0] en la norma es q_m[1] aca
                    q_m(1) = D(1);
                    q_m(2) = not(xor(q_m(1),D(2)));
                    q_m(3) = not(xor(q_m(2),D(3)));
                    q_m(4) = not(xor(q_m(3),D(4)));
                    q_m(5) = not(xor(q_m(4),D(5)));
                    q_m(6) = not(xor(q_m(5),D(6)));
                    q_m(7) = not(xor(q_m(6),D(7)));
                    q_m(8) = not(xor(q_m(7),D(8)));
                    q_m(9) = 0;
               else
                    q_m(1) = D(1);
                    q_m(2) = xor(q_m(1),D(2));
                    q_m(3) = xor(q_m(2),D(3));
                    q_m(4) = xor(q_m(3),D(4));
                    q_m(5) = xor(q_m(4),D(5));
                    q_m(6) = xor(q_m(5),D(6));
                    q_m(7) = xor(q_m(6),D(7));
                    q_m(8) = xor(q_m(7),D(8));
                    q_m(9) = 1;     
               endif
               N1q_m = sum(q_m(1:8)==1);
               N0q_m = sum(q_m(1:8)==0);                    
               if (cnt == 0 || (N1q_m == N0q_m))
                    q_out(10) = not(q_m(9));
                    q_out(9)  = q_m(9);
                    if (q_m(9) == 1)
                         q_out(1:8)= q_m(1:8);
                         cnt = cnt + N1q_m - N0q_m;
                    else
                         q_out(1:8)= not(q_m(1:8));
                         cnt = cnt - N1q_m + N0q_m;
                    endif                        
               else
                    if (((cnt>0) && (N1q_m>N0q_m)) || ((cnt<0) && (N0q_m>N1q_m)))
                         q_out(10)=1;
                         q_out(9) =q_m(9);
                         q_out(1:8) = not(q_m(1:8));
                         cnt = cnt +2*q_m(9)+(N0q_m-N1q_m);
                    else
                         q_out(10)=0;
                         q_out(9) =q_m(9);
                         q_out(1:8) = q_m(1:8);
                         cnt = cnt -2*not(q_m(9))+(N1q_m-N0q_m);
                    endif
               endif              
               if (D(8) == q_out(9))
                    cuenta_iguales++;
               endif
               aux_qout = q_out(10);              
               promedio = sum(q_out)/10;
               al_azar = fix(rand(1)*10 + 1);
               imagen_de_bits(filas,columna_bit,:) = [q_out promedio q_out(al_azar)];
               columna_bit++;
          endif
          columnas++;
          % se transmite el LSB primero, punto 3.2.3 de la norma          
          auxiliar = [auxiliar q_out];
          auxiliar_D = [auxiliar_D q_D];
     endwhile
     salida = [salida auxiliar];
     salida_D = [salida_D auxiliar_D];   
     if (rem(lineas,25) == 0)  
          disp(lineas);
      #    disp(salida((lin_aux-1)*10:lin_aux*10));
          #disp(length(salida));
          fflush(stdout);
     endif
     lineas++;
     filas++;
endwhile
#repito la ultima fila de imagen de bit
imagen_de_bits(:,columna_bit,:) = imagen_de_bits(:,columna_bit-1,:);
imagen_de_bits(imagen_de_bits(:,:,:)==1)=Vswing;
imagen_de_bits(imagen_de_bits(:,:,:)==0)=-Vswing;
[a1,a2,cant] = size(imagen_de_bits);
for i=1:cant
     nombre_archivo = strcat('imagen_',num2str(i),'.png');
     imwrite(imagen_de_bits(:,:,i),nombre_archivo);
endfor
#disp(length(salida));
#disp(lineas);
#fflush(stdout);
q_out = [0 0 1 0 1 0 1 0 1 1];
lineas_finales = repmat(fila_blank,1,(V_bottom_border+V_front_porch));
salida = [salida lineas_finales];
toc();
imagen_TDMS(salida(:)==1)=Vswing;
imagen_TDMS(salida(:)==0)=-Vswing;
imagen_DIGITAL(salida_D(:)==1)=Vswing;
imagen_DIGITAL(salida_D(:)==0)=-Vswing;
imagen_TMDS_impar = imagen_TDMS(1:2:end);
imagen_TMDS_par = imagen_TDMS(2:2:end);
cd /Users/Pablo/Maestría/Octave;
if (martin==0)
     nombre_archivo = strcat("imagen_TDMS_",color_archivo,num2str(xd),num2str(yd),".dat");
     nombre_archivo_2 = strcat("imagen_VGA_",num2str(xd),num2str(yd),".dat");
     nombre_archivo_3 = strcat("imagen_TMDS_inter",color_archivo,num2str(xd),num2str(yd),".dat");
     nombre_archivo_4 = strcat("imagen_Digital",color_archivo,num2str(xd),num2str(yd),".dat");
else
     nombre_archivo = strcat("imagen_TDMS_promedio",num2str(xd),num2str(yd),"_martin.dat");
     nombre_archivo_2 = strcat("imagen_VGA_",num2str(xd),num2str(yd),"_martin.dat");
     nombre_archivo_3 = strcat("imagen_TMDS_inter",color_archivo,num2str(xd),num2str(yd),"_martin.dat");
endif
disp("comienza a grabar...");
toc();
fflush(stdout);
fid=fopen(nombre_archivo,'w');
fwrite(fid,imagen_TDMS,'float32');
fclose(fid);
toc();
fid=fopen(nombre_archivo_4,'w');
fwrite(fid,imagen_DIGITAL,'float32');
fclose(fid);
senal_VGA=reshape(trama_red',1,[]);
fid=fopen(nombre_archivo_2,'w');
fwrite(fid,senal_VGA,'float32');
fclose(fid);
#-------------------------------------------------------
# Espectros....
disp("Calculando espectros");
fflush(stdout);
fs_VGA = xt*yt*60;
fs_TDMS = xt*yt*60*10;
#fft_VGA = (1/fs_VGA)*fft(senal_VGA);
fft_TDMS = (1/fs_TDMS)*fft(imagen_TDMS);
#f_plot_VGA = [-length(fft_VGA)/2:length(fft_VGA)/2]*(fs_VGA/length(fft_VGA));
#f_plot_VGA = f_plot_VGA(1:length(f_plot_VGA) -1);
f_plot_TDMS = [-length(fft_TDMS)/2:length(fft_TDMS)/2]*(fs_TDMS/length(fft_TDMS));
f_plot_TDMS = f_plot_TDMS(1:length(f_plot_TDMS) -1);
#figure();
#plot(f_plot_VGA,fftshift(abs(fft_VGA)));
#aux = strcat('Espectro de la señal VGA');
#title(aux);
figure(2);
plot(f_plot_TDMS,fftshift(abs(fft_TDMS)));
aux = strcat('Espectro de la señal TDMS');
title(aux);
# mostremos como se ve uno de esos 10 bits
unbit=toascii(reshape(pixel(:,6),xt,yt)');
#    unbit tiene solo valores 48 y 49
#    los paso a unos y ceros
unbit=unbit(:,:)==49;
#figure();
#imshow(unbit);
#aux = strcat('Imagen generada a partir del bit 6 de cada uno de los 10 codificados');
#title(aux); 
%save TDMS.mat salda imagen_TDMS;