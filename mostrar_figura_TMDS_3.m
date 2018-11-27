close all;
clear all;
tic();
pkg load signal
martin = 0; 
xd = 800;
yd = 600;
fr = 60;
bits = 10;
prom = 3;
inter = 3; 
f_cutoff = 50e6;
delay = 0;
fase = 0;
offset = 0;
repetir = 4;
format short g
switch prom
     case 0
          a = fopen('/Users/Pablo/Maestría/imagen_TDMS_red800600.dat');          
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_patron_red800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_contraste__red800600.dat');          
          datos = fread(a,Inf,'float');
          datos = datos+abs(min(datos));
          fclose(a);       
     otherwise
          a = fopen('/Users/Pablo/Maestría/imagen_TDMS_red800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_patron_red800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_contraste__red800600.dat');
          datos_red = fread(a,Inf,'float');
          datos_red = datos_red+abs(min(datos_red));
          fclose(a);
          a = fopen('/Users/Pablo/Maestría/imagen_TDMS_blue800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_patron_red800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_contraste__red800600.dat');
          datos_blue = fread(a,Inf,'float');
          datos_blue = datos_blue+abs(min(datos_blue));
          fclose(a);
          a = fopen('/Users/Pablo/Maestría/imagen_TDMS_green800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_patron_red800600.dat');
          #a = fopen('/Users/Pablo/Maestría/Octave/imagen_TDMS_contraste__red800600.dat');
          datos_green = fread(a,Inf,'float');
          datos_green = datos_green+abs(min(datos_green));
          fclose(a);
          datos = (datos_red + datos_blue + datos_green)/prom;
endswitch

N = length(datos); 

% interpolo con orden 0


senial = reshape([datos zeros(length(datos),inter-1)]',1,N*inter);
%    [datos zeros(length(datos),inter-1)]
%
%    es..., si inter = 5
%
%    +---+ +---------+
%    | d | | 0 0 0 0 |
%    | a | | 0 0 0 0 |
%    | t | | 0 0 0 0 |
%    | o | | 0 0 0 0 |
%    | s | | 0 0 0 0 |
%    +---+ +---------+
%    
%    en senial queda una señal vector con un dato y 4 ceros, lo que se dice upsampling :)
%    +---------------------------------------------------+
%    | d 0 0 0 0 a 0 0 0 0 t 0 0 0 0 o 0 0 0 0 s 0 0 0 0 |
%    +---------------------------------------------------+


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
red = zeros(yd,xd);
blue= zeros(yd,xd);
green=zeros(yd,xd);
trama_red = [zeros(yd,H_sync+H_back_porch+H_left_border) red  zeros(yd,H_right_border+H_front_porch)];
trama_blue = [zeros(yd,H_sync+H_back_porch+H_left_border) blue  zeros(yd,H_right_border+H_front_porch)];
trama_green = [zeros(yd,H_sync+H_back_porch+H_left_border) green  zeros(yd,H_right_border+H_front_porch)];
[aux,xt]=size(trama_red);
# luego los de arriba y abajo y el flyback
trama_red = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_red; zeros((V_bottom_border+V_front_porch),xt)];
trama_blue = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_blue; zeros((V_bottom_border+V_front_porch),xt)];
trama_green = [zeros((V_sync+V_back_porch+V_top_border),xt); trama_green; zeros((V_bottom_border+V_front_porch),xt)];
[yt,xt] = size(trama_red);


ver_total = yt;
hor_total = xt;
bit_rate = ver_total*hor_total*60*bits; #esta es la tasa de bits
samp_rate = bit_rate*inter;


%aplico pulso conformador

shaping_pulse = ones(1,inter); %rectangular NRZ
senial = filter(shaping_pulse,1,senial);

% acá tengo una pantalla, necesito más

senial = repmat(senial,1,repetir); %serializa senial 4 veces

% acá ya tiene, en "senial", la señal transmitida por el cable
g_ruido = 1;
#le agrego ruido...
largo = length(senial);
senial_in = senial + g_ruido*rand(1,length(senial));


% bajo a bandabase el primer armónico
f = bit_rate ;
t = [1:length(senial_in)]/samp_rate;
toc();
disp("arrancando con oscil...");
fflush(stdout);
oscil = exp(-j*2*pi*f*t+fase);
toc();
disp("Saliendo de oscil...");
fflush(stdout);

senial_demodulada = senial_in.*oscil;
#save oscil.mat oscil;
#clear oscil;
#
# filtro la señal con un pasabajos


[b a] = butter(5, f_cutoff/(samp_rate/2));
senial_filtrada = filter(b,a,senial_demodulada);

% hago un resampling, y lo llevo de nuevo a tasa de bits 
toc();
disp("Saliendo de senial_filtrda...");
fflush(stdout);
decim = inter;

t_2 = t(1+delay:decim:end);
resultado_canal = senial_filtrada(1+delay:decim:end);


#Para las dos señales hacemos dos cosas: decodificar, lo que no hace TempestSDR y demodular AM
#
#primero decodificamos
#
#decidimos

digital_canal = real(resultado_canal(:))>0;
toc();
disp("Entrando a decodificar...");
fflush(stdout);
[foto_TMDS_decoficada] = Decodificador_TMDS_2(digital_canal(1:bit_rate/60)',offset,yd,xd);
toc();
disp("Finaliza decodificacion...");
fflush(stdout);
aux1 = strcat('foto\_TMDS\_decoficada Foto decodificada sin ecualizar, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'Offset: ',num2str(offset),'\_Fase\_',num2str(fase));
%figure;
%imshow(real(foto_TMDS_decoficada),[]);
%title(aux1);

% aplico un filtro ecualizador, a nivel de bits
equa_filter = disenio_inverso_sinc_bandabase(1/(bit_rate),inter);
resultado_canal_ec = filter(equa_filter,1,senial_filtrada);
resultado_canal_ec_2 = filter(equa_filter,1,resultado_canal);
resultado_canal_ecualizado = resultado_canal_ec(1+delay:decim:end);
digital_ecualizada = real(resultado_canal_ecualizado(:))>0;
toc();
disp("Entrando a decodificar otra vez...");
fflush(stdout);
[foto_TMDS_decoficada_ecualizada] = Decodificador_TMDS_2(digital_ecualizada(1:bit_rate/60)', offset,yd,xd);
toc();
disp("Finaliza la 2da decodificacion...");
fflush(stdout);

# lo que haria TempestSDR.....
# de los 10 bits de senial_demodulada se quedaria con todos en una matriz tridemensional
# en foto_Tempest guardamos:
#    foto_Tempest(:,:,1:10) => los 10 bits
#    foto_Tempest(:,:,11) => el promedio de los 10 bits
#    foto_Tempest(:,:,12) => una imagen con un bit aleatorio por pixel
#    foto_Tempest(:,:,13) => una imagen con un bit con offset
#    foto_Tempest(:,:,14) => una imagen que va alternando entre dos bits, al rededor de bit_central
#
#    Esto lo hago en la decodificada tambien.
for delay=0:(bits-1)     
     resultado_canal_Tempest = resultado_canal(1+delay:bits:end);
     resultado_canal_Tempest_ecualizado = resultado_canal_ecualizado(1+delay:bits:end);     
     resultado_canal_Tempest_ec_2 = resultado_canal_ec_2(1+delay:bits:end); 
     resultado_canal_Tempest_ec_3 = filter(equa_filter,1,resultado_canal_Tempest);     
     #nos quedamos con la primera de las 4 imagenes
     resultado_canal_Tempest = resultado_canal_Tempest(1:length(resultado_canal_Tempest)/4);
     resultado_canal_Tempest_ecualizado = resultado_canal_Tempest_ecualizado(1:length(resultado_canal_Tempest_ecualizado)/4);     
     resultado_canal_Tempest_ec_2 = resultado_canal_Tempest_ec_2(1:length(resultado_canal_Tempest_ec_2)/4);     
     resultado_canal_Tempest_ec_3 = resultado_canal_Tempest_ec_3(1:length(resultado_canal_Tempest_ec_3)/4);
     if (length(resultado_canal_Tempest) < xt*yt)
          padding = xt*yt-length(resultado_canal_Tempest);
          texto = strcat('Hay padding en Tempest: ',num2str(padding));
          disp(texto);
          fflush(stdout);
          foto_Tempest(:,:,delay+1) = reshape([resultado_canal_Tempest zeros(1,padding)],xt,yt)';          
     else
          foto_Tempest(:,:,delay+1) = reshape(resultado_canal_Tempest,xt,yt)';
     endif     
     if (length(resultado_canal_Tempest_ecualizado) < xt*yt)
          padding = xt*yt-length(resultado_canal_Tempest_ecualizado);
          texto = strcat('Hay padding en Tempest ecualizado: ',num2str(padding));
          disp(texto);
          fflush(stdout);
          foto_Tempest_ecualizado(:,:,delay+1) = reshape([resultado_canal_Tempest_ecualizado zeros(1,padding)],xt,yt)';
     else          
          foto_Tempest_ecualizado(:,:,delay+1) = reshape(resultado_canal_Tempest_ecualizado,xt,yt)';          
     endif
     if (length(resultado_canal_Tempest_ec_2) < xt*yt)
          padding = xt*yt-length(resultado_canal_Tempest_ec_2);
          texto = strcat('Hay padding en Tempest ec 2: ',num2str(padding));
          disp(texto);
          fflush(stdout);
          foto_Tempest_ec_2(:,:,delay+1) = reshape([resultado_canal_Tempest_ec_2 zeros(1,padding)],xt,yt)';
     else
          foto_Tempest_ec_2(:,:,delay+1) = reshape(resultado_canal_Tempest_ec_2,xt,yt)';
     endif
     if (length(resultado_canal_Tempest_ec_3) < xt*yt)
          padding = xt*yt-length(resultado_canal_Tempest_ec_3);
          texto = strcat('Hay padding en Tempest ec 3: ',num2str(padding));
          disp(texto);
          fflush(stdout);
          foto_Tempest_ec_3(:,:,delay+1) = reshape([resultado_canal_Tempest_ec_3 zeros(1,padding)],xt,yt)';
     else
          foto_Tempest_ec_3(:,:,delay+1) = reshape(resultado_canal_Tempest_ec_3,xt,yt)';
     endif
     #auxt = strcat('foto\_Tempest sin ecualizar, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'delay\_',num2str(delay),'\_Fase\_',num2str(fase));
     #figure;
     #imshow(real(foto_Tempest(:,:,delay+1)),[]);
     #title(auxt);
     # lo mismo con el resto
     #######################################################     
     #auxt = strcat('foto\_Tempest\_ecualizada, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'delay\_',num2str(delay),'\_Fase\_',num2str(fase));
     #figure;
     #imshow(real(foto_Tempest_ecualizado(:,:,delay+1)),[]);
     #title(auxt);
     #auxt = strcat('foto\_Tempest\_ec_2 ecualizada luego, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'delay\_',num2str(delay),'\_Fase\_',num2str(fase));
     #figure;
     #imshow(real(foto_Tempest_ec_2(:,:,delay+1)),[]);
     #title(auxt);
     #auxt = strcat('foto\_Tempest\_ec3 al final, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'delay\_',num2str(delay),'\_Fase\_',num2str(fase));
     #figure;
     #imshow(real(foto_Tempest_ec_3(:,:,delay+1)),[]);
     #title(auxt);
endfor
#saco el promedio
[a1,a2,tramas]=size(foto_Tempest);
foto_Tempest(:,:,tramas+1) = (foto_Tempest(:,:,1)+foto_Tempest(:,:,2)+foto_Tempest(:,:,3)+foto_Tempest(:,:,4)+foto_Tempest(:,:,5)+foto_Tempest(:,:,6)+foto_Tempest(:,:,7)+foto_Tempest(:,:,8)+foto_Tempest(:,:,9)+foto_Tempest(:,:,10))/10; #suma en la dimension 3 (los bits)
foto_Tempest_ecualizado(:,:,tramas+1) = (foto_Tempest_ecualizado(:,:,1)+foto_Tempest_ecualizado(:,:,2)+foto_Tempest_ecualizado(:,:,3)+foto_Tempest_ecualizado(:,:,4)+foto_Tempest_ecualizado(:,:,5)+foto_Tempest_ecualizado(:,:,6)+foto_Tempest_ecualizado(:,:,7)+foto_Tempest_ecualizado(:,:,8)+foto_Tempest_ecualizado(:,:,9)+foto_Tempest_ecualizado(:,:,10))/10; #suma en la dimension 3 (los bits)
foto_Tempest_ec_2(:,:,tramas+1) = (foto_Tempest_ec_2(:,:,1)+foto_Tempest_ec_2(:,:,2)+foto_Tempest_ec_2(:,:,3)+foto_Tempest_ec_2(:,:,4)+foto_Tempest_ec_2(:,:,5)+foto_Tempest_ec_2(:,:,6)+foto_Tempest_ec_2(:,:,7)+foto_Tempest_ec_2(:,:,8)+foto_Tempest_ec_2(:,:,9)+foto_Tempest_ec_2(:,:,10))/10; #suma en la dimension 3 (los bits)
#suma en la dimension 3 (los bits)
foto_Tempest_ec_3(:,:,tramas+1) = (foto_Tempest_ec_3(:,:,1)+foto_Tempest_ec_3(:,:,2)+foto_Tempest_ec_3(:,:,3)+foto_Tempest_ec_3(:,:,4)+foto_Tempest_ec_3(:,:,5)+foto_Tempest_ec_3(:,:,6)+foto_Tempest_ec_3(:,:,7)+foto_Tempest_ec_3(:,:,8)+foto_Tempest_ec_3(:,:,9)+foto_Tempest_ec_3(:,:,10))/10; #suma en la dimension 3 (los bits)
auxt = strcat('foto_Tempest sin ecualizar promedio, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
figure;
imshow(foto_Tempest_decoficada,[]);
title('Decodificada...');
%auxt = strcat('foto_Tempest_ecualizada promedio, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
%figure;
%imshow(abs(foto_Tempest_ecualizado(:,:,tramas+1)),[]);
%title(auxt);
%auxt = strcat('foto_Tempest_ec_2 ecualizada luego promedio, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
%figure;
%imshow(abs(foto_Tempest_ec_2(:,:,tramas+1)),[]);
%title(auxt);
%auxt = strcat('foto_Tempest_ec_3 ecualizada al final promedio, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
%figure;
%imshow(abs(foto_Tempest_ec_2(:,:,tramas+1)),[]);
%title(auxt);


#vamos por las otras tres senales
bitt = tramas + 1;
deriva = 0.0001/(xt*yt*60);     #deriva en el Tp, tiempo de pixel
Tb = 1/(xt*yt*60*bits);         #Tb es el tiempo de cada bit
#cada cuantos bits salta al siguente??
salto_de_bit = ceil(Tb/deriva);
#cada salto_de_bit bits saltara al siguiente bit
# o lo que es lo mismo cada salto_de_bit/bits pixeles saltara a la otra imagen
salto_pixel = salto_de_bit/bits;
conteo_pixel = 0;
shift_bit =0 ;
salto_bit = 0;
bit_sgte = 0;
bit_central = 1;
disp("Calculando aleatorio y deriva...");
fflush(stdout);
for fila=1:a1
     for columna=1:a2
          conteo_pixel++;
          salto_bit++;
          if (conteo_pixel > salto_pixel)
               conteo_pixel = 0;
               shift_bit++;               
               if (shift_bit > bits)
                    shift_bit=0;
               endif               
          endif               
          if (salto_bit > salto_de_bit)
               bit_sgte = not(bit_sgte);     #agarra uno u otro, se alterna entre dos bits o "imagenes"
               salto_bit = 0;
          endif          
          aux_bit = ceil(rand(1)*10);
          foto_Tempest(fila,columna,bitt+1) = foto_Tempest(fila,columna,aux_bit);
          foto_Tempest(fila,columna,bitt+2) = foto_Tempest(fila,columna,shift_bit+1);
          foto_Tempest(fila,columna,bitt+3) = foto_Tempest(fila,columna,bit_sgte+bit_central);
          foto_Tempest_ecualizado(fila,columna,bitt+1) = foto_Tempest_ecualizado(fila,columna,aux_bit);
          foto_Tempest_ecualizado(fila,columna,bitt+2) = foto_Tempest_ecualizado(fila,columna,shift_bit+1);
          foto_Tempest_ecualizado(fila,columna,bitt+3) = foto_Tempest_ecualizado(fila,columna,bit_sgte+bit_central);
          foto_Tempest_ec_2(fila,columna,bitt+1) = foto_Tempest_ec_2(fila,columna,aux_bit);
          foto_Tempest_ec_2(fila,columna,bitt+2) = foto_Tempest_ec_2(fila,columna,shift_bit+1);
          foto_Tempest_ec_2(fila,columna,bitt+3) = foto_Tempest_ec_2(fila,columna,bit_sgte+bit_central);
          foto_Tempest_ec_3(fila,columna,bitt+1) = foto_Tempest_ec_3(fila,columna,aux_bit);
          foto_Tempest_ec_3(fila,columna,bitt+2) = foto_Tempest_ec_3(fila,columna,shift_bit+1);
          foto_Tempest_ec_3(fila,columna,bitt+3) = foto_Tempest_ec_3(fila,columna,bit_sgte+bit_central);                    
     endfor
endfor         

#auxt = strcat('foto\_Tempest sin ec bit aleatorio por vez, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
#figure;
#imshow(real(foto_Tempest(:,:,bitt+1)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest sin ec shitf entre bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_pixel),' pixeles');
#figure;
#imshow(real(foto_Tempest(:,:,bitt+2)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest sin ec shitf entre 2 bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_de_bit),' bits');
#figure;
#imshow(real(foto_Tempest(:,:,bitt+3)),[]);
#title(auxt);

#auxt = strcat('foto\_Tempest\_ecualizada bit aleatorio por vez, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
#figure;
#imshow(real(foto_Tempest_ecualizado(:,:,bitt+1)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ecualizada shitf entre bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_pixel),' pixeles');
#figure;
#imshow(real(foto_Tempest_ecualizado(:,:,bitt+2)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ecualizada shitf entre 2 bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_de_bit),' bits');
#figure;
#imshow(real(foto_Tempest_ecualizado(:,:,bitt+3)),[]);
#title(auxt);

#auxt = strcat('foto\_Tempest\_ec\_2 ecualizada luego bit aleatorio por vez, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
#figure;
#imshow(real(foto_Tempest_ec_2(:,:,bitt+1)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ec\_2 ecualizada luego shitf entre bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_pixel),' pixeles');
#figure;
#imshow(real(foto_Tempest_ec_2(:,:,bitt+2)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ec\_2 ecualizada luego shitf entre 2 bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_de_bit),' bits');
#figure;
#imshow(real(foto_Tempest_ec_2(:,:,bitt+3)),[]);
#title(auxt);

#auxt = strcat('foto\_Tempest\_ec\_3 ecualizada al final bit aleatorio por vez, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase));
#figure;
#imshow(real(foto_Tempest_ec_3(:,:,bitt+1)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ec\_3 ecualizada al final shitf entre bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_pixel),' pixeles');
#figure;
#imshow(real(foto_Tempest_ec_3(:,:,bitt+2)),[]);
#title(auxt);
#auxt = strcat('foto\_Tempest\_ec\_3 ecualizada al final shitf entre 2 bits, f\_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_Fase\_',num2str(fase),'cada :',num2str(salto_de_bit),' bits');
#figure;
#imshow(real(foto_Tempest_ec_3(:,:,bitt+3)),[]);
#title(auxt);


%aux2 = strcat('foto\_TMDS\_decod\_ecualizada decodificada ecualizada, f_cutoff: ',num2str(f_cutoff/1e6),' inter: ',num2str(inter),'\_prom\_',num2str(prom),'\_fase\_',num2str(fase),'Offset: ',num2str(offset));
%figure;
%imshow(real(foto_TMDS_decoficada_ecualizada),[]);
%title(aux2);
foto_resultado = reshape(resultado_canal_ecualizado(1:bit_rate/60),bits*hor_total,ver_total)';    

disp("Tiempo total en segundos...");
toc();













