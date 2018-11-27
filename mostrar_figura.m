%close all
%clear all

pkg load signal

format short g
entra_p_o=0;
f_cutoff = 10e6;
fase = 0;
error_frecuencia = 0;
%a = fopen('senal_imagen.dat');
a = fopen('/home/pablo/senal_imagen.dat');
a = fopen('/Users/Pablo/Maestría/Octave/imagen_VGA_800600.dat');
#a = fopen('/Users/Pablo/Maestría/Octave/imagen_VGA_masking800600.dat');
#a = fopen('/Users/Pablo/Maestría/Octave/imagen_VGA_patron800600.dat');
datos = fread(a,Inf,'float');
datos = datos+min(datos);
fclose(a);

N = length(datos); 

% interpolo con orden 0

inter = 5; 
senial = reshape([datos zeros(length(datos),inter-1)]',1,N*inter);
%    [datos zeros(length(datos),inter-1)]
%P
%    es...
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



ver_total = 624;
hor_total = 1024;
px_rate = ver_total*hor_total*60;
samp_rate = px_rate*inter;

foto_original = reshape(datos(1:px_rate/60),hor_total,ver_total)';

%aplico pulso conformador

shaping_pulse = ones(1,inter); %rectangular NRZ
#shaping_pulse_1=[1 1 1 1 1 0 0 0 0 0]; %RZ
%shaping_pulse = triang(inter); %triangular
%flpf = px_rate;
%shaping_pulse = fir1(30*inter, flpf/(samp_rate/2),'low');
#######################################################
#    Pulsos
#    p_o_1     over y undershooting
#    p_o_2     over solo
#    p_o_3     over solo pero más exagerado
#    p_o       over y undershooting

switch entra_p_o
     case 1
          if (exist('p_o_1') == 1)
               shaping_pulse = p_o_1;
          else
               cd /Users/Pablo/Maestría/Octave;
               load p_o.mat;  
               shaping_pulse = p_o_1;
          endif
     case 2
          if (exist('p_o_2') == 1)
               shaping_pulse = p_o_2;
          else
               cd /Users/Pablo/Maestría/Octave;
               load p_o.mat;  
               shaping_pulse = p_o_2;
          endif
     case 3
          if (exist('p_o_3') == 1)
               shaping_pulse = p_o_3;
          else
               cd /Users/Pablo/Maestría/Octave;
               load p_o.mat;  
               shaping_pulse = p_o_3;
          endif
      otherwise
               shaping_pulse = ones(1,inter);
              # shaping_pulse = [1.12, 0.9, 1, 1, 1];
              # shaping_pulse = [1.12,0.98458,1,1.0001,0.99994,1,1,1,1,1];
endswitch
senial = filter(shaping_pulse,1,senial);

% acá tengo dos pantallas, necesito más

senial = repmat(senial,1,5); %serializa senial 5 veces

% acá ya tiene, en "senial", la señal transmitida por el VGA

largo = length(senial);
f_espectro = [-pi+pi/largo:2*pi/largo:pi];
%espectro = fft(senial);
%figure
%semilogy(f_espectro/pi,abs(fftshift(espectro)))

%figure
%freqz(shaping_pulse)

% bajo a bandabase el primer armónico

f = px_rate ;
t = [1:length(senial)]/samp_rate;
%oscil = cos(2*pi*f*t+fase);
oscil = exp(-j*2*pi*(f+error_frecuencia)*t+fase);

%equa_filter = disenio_inverso_sinc_pasabanda(1/px_rate,inter);
%senial_equa = filter(equa_filter,1,senial);

senial_demodulada = senial.*oscil;

% filtro la señal con un pasabajos

[b a] = butter(5, f_cutoff/(samp_rate/2));

senial_filtrada = filter(b,a,senial_demodulada);
#corr_fase = cos(arg(senial_filtrada))-i*sin(arg(senial_filtrada));
#senial_filtrada_2 = senial_filtrada.*exp(-fase);

% hago un resampling, y lo llevo de nuevo a tasa de pixels 

decim = inter;
delay = 0;
g_ruido = 5;
ruido = g_ruido*rand(1,length(senial_filtrada(1+delay:decim:end)));
resultado_canal   = senial_filtrada(1+delay:decim:end) + ruido;
#resultado_canal_2 = senial_filtrada_2(1+delay:decim:end) + ruido;
t_2 = t(1+delay:decim:end);
% aplico un filtro ecualizador, a nivel de pixeles

equa_filter = disenio_inverso_sinc_bandabase(1/px_rate,inter);
resultado_canal_ecualizado   = filter(equa_filter,1,resultado_canal);
#resultado_canal_ecualizado_2 = filter(equa_filter,1,resultado_canal_2);

#resultado_canal_ecualizado   = filter(equa_filter,1,resultado_canal) + ruido;
#resultado_canal_ecualizado_2 = filter(equa_filter,1,resultado_canal_2) + ruido;
#resultado_canal_ecualizado_2 = filter(equa_filter,1,resultado_canal).*exp(j*pi/4) + g_ruido*rand(1,length(senial_filtrada(1+delay:decim:end)));

foto_resultado_sin_eq = reshape(resultado_canal(1:px_rate/60),hor_total,ver_total)';
foto_resultado   = reshape(resultado_canal_ecualizado(1:px_rate/60),hor_total,ver_total)';
#foto_resultado_2 = reshape(resultado_canal_ecualizado_2(1:px_rate/60),hor_total,ver_total)';



%argumento=arg(resultado_canal);
%corrector_fase=exp(-j*argumento);
%corregida_total = resultado_canal_ecualizado.*corrector_fase;
%foto_resultado_2 = reshape(corregida_total(1:px_rate/60),hor_total,ver_total)';
%foto_resultado_2 = reshape(resultado_canal_ecualizado_2(1:px_rate/60),hor_total,ver_total)';
%imshow(foto_resultado,[min(min(foto_resultado)) max(max(foto_resultado))])


%figure
%imshow(real(foto_resultado_2),[])
%title('Ecualizando, corrigiendo fase y tomando parte real');

aux1 = strcat('Ecualizando y tomando abs, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'MHz',', Fase:',strtrim(num2str(fase)));
aux11 = strcat('Ecualizando y tomando Re, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'MHz',', Fase:',strtrim(num2str(fase)));
aux2 = strcat('TempestSDR, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'MHz',', Fase:',strtrim(num2str(fase)));
aux3 = strcat('TempestSDR tomando parte real, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'Mhz');
aux4 = strcat('Senal transmitida, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'MHz');
aux5 = strcat('Senal ecualizada, frecuencia corte: ',strtrim(num2str(f_cutoff/1e6)),'MHz');
aux6 = strcat('Senal ecualizada, y fase corregida, frecuencia corte: ',strtrim(num2str(f_cutoff)),', Fase:',strtrim(num2str(fase)));


figure
imshow(abs(foto_resultado),[])
title(aux1)
#figure
#imshow(real(foto_resultado),[])
#title(aux11)
#figure
#imshow(real(foto_resultado_2),[])
#title(aux6)
figure
imshow(abs(foto_resultado_sin_eq),[])
title(aux2)
#figure
#imshow(real(foto_resultado_sin_eq),[])
#title(aux3)


largo = 1:2*px_rate/60;


#figure
#plot(largo, real(resultado_canal(largo)),largo,real(resultado_canal_ecualizado(largo)), largo, datos(largo))
#legend("canal","ecualizado","original");

#figure;plot(resultado_canal(largo),'r');hold on;plot(resultado_canal_ecualizado(largo),'b');


