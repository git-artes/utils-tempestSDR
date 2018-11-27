function ccf = disenio_inverso_sinc_pasabanda(Tp, inter)
%Tp =1.0/71576640;
numpoints = 100000;
min_tol = 0.01;

min_frec = 0.5/Tp*1.02;

max_frec = 3.0/(2*Tp)*1.02;
%min_frec = 1.0/(2*Tp);
samp_rate = 1.0/Tp*inter;

if (max_frec > samp_rate/2.0)
     rango_frec = [0 min_frec min_frec:(max_frec-min_frec)/(numpoints-2):max_frec max_frec max_frec];
else
     rango_frec = [0 min_frec min_frec:(max_frec-min_frec)/(numpoints-2):max_frec max_frec samp_rate/2.0];
endif
filtro_ideal = [0 0 1.0./sinc(rango_frec(3:end-2)*Tp) 0 0];
filtro_objetivo = filtro_ideal;
rango_corregir = find(abs(filtro_ideal)>1.0/min_tol);

filtro_objetivo(rango_corregir) = filtro_ideal(rango_corregir(1))+(filtro_ideal(rango_corregir(end))-filtro_ideal(rango_corregir(1)))/length(rango_corregir)*[1:length(rango_corregir)];

%semilogy(rango_frec,abs(filtro_ideal),";ideal;",rango_frec,abs(filtro_objetivo),";obj;")

frec = rango_frec/(rango_frec(length(rango_frec)));

ccf = fir2(501,frec,filtro_objetivo);

%[h, w] = freqz (ccf);
%figure
%plot (w/pi, abs(h), ";obtained response;", rango_frec./max(rango_frec),  abs(filtro_objetivo), ";target response;");

%figure
%freqz(ccf)
