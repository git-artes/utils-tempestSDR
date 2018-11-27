function h_final_decim = disenio_inverso_sinc_bandabase(Tp,inter)

% inter no sirve para mucho. con que sea mayor a 3 es suficiente

px_rate = 1/Tp;
samp_rate = px_rate*inter;

% lo disenio en pasabanda, que octave me deja
h = disenio_inverso_sinc_pasabanda(Tp,inter);

% lo bajo a bandabase con una exponencial compleja
f = px_rate ;
t = [1:length(h)]/samp_rate;
fase = 0;
oscil = exp(-j*2*pi*f*t+fase);

h_mod = h.*oscil;

% lo paso por un pasabajos para sacarme de arriba la otra imagen
f_cutoff = px_rate;
h_lpf = fir1(51, f_cutoff/(samp_rate/2));

h_final = conv(h_mod,h_lpf);

% decimo porque supongo que estoy trabajando a tasa de pixel

h_final_decim = h_final(1:inter:end);



