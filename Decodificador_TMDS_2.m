function [foto_TMDS_decoficada] = Decodificador_TMDS_2(foto_TMDS,offset,yd,xd)
# decodifcador TMDS
#
#
foto_TMDS = shift(foto_TMDS,offset);
foto_TMDS_decoficada=[];
Mat_rellenos = [800  600 60 80 112  0  0  32 24 4 17 0 0 3 59.861;
1024  768 60 104 152 0 0  48 30 4 23 0 0 3 59.920;
1920 1080 60 200 328 0 0 128 40 5 32 0 0 3 59.963;
1280  960 60 128 208 0 0 128 36 4 29 0 0 3 59.939;
1366  768 60 136 208 0 0  72 30 5 22 0 0 3 59.799;
1360  768 60 136 208 0 0  72 30 5 22 0 0 3 59.799;
1280  720 60 128 192 0 0  64 28 5 20 0 0 3 59.855]; 
[h,v] = size(Mat_rellenos);
fr=60;
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

xt = H_sync+H_back_porch+H_left_border + xd + H_right_border+H_front_porch;
yt = V_sync+V_back_porch+V_top_border+yd+V_bottom_border+V_front_porch;
q_out = [0 0 1 0 1 0 1 0 1 1];
[ancho,largo]=size(foto_TMDS);
if (ancho > 1)
     error('No tiene las dimensiones adecuadas, verifique');
endif
columnas = 1;
columna = 1; 
while (columnas <= largo) 
     if (rem(columnas,50) == 0)
          disp(columnas);
          fflush(stdout);
     endif     
#primeros pixeles del blanking
#    xt*(V_sync+V_back_porch+V_top_border)*10 + 10*(H_sync+H_back_porch+H_left_border)
#------------------------------------------------------------------------------
#    son todos los de "arriba" m´as los primeros de la izquierda de la primera util
# 
     D = foto_TMDS(columnas:columnas+9);
     #foto_resultado_promedio(filas,columna) = sum(filas,columnas:columnas+10)/10;
     if (D(10) == 1) 
          D(1:8) = not(D(1:8));
     endif
     q_out(1) = D(1);
     if (D(9) == 1) % quiere decir que se uso XOR en la codificacion
          q_out(2) = xor(D(2),D(1));
          q_out(3) = xor(D(3),D(2));
          q_out(4) = xor(D(4),D(3));
          q_out(5) = xor(D(5),D(4));
          q_out(6) = xor(D(6),D(5));
          q_out(7) = xor(D(7),D(6));
          q_out(8) = xor(D(8),D(7));
     else
          q_out(2) = not(xor(D(2),D(1)));
          q_out(3) = not(xor(D(3),D(2)));
          q_out(4) = not(xor(D(4),D(3)));
          q_out(5) = not(xor(D(5),D(4)));
          q_out(6) = not(xor(D(6),D(5)));
          q_out(7) = not(xor(D(7),D(6)));
          q_out(8) = not(xor(D(8),D(7)));
     endif                   
     #endif
     Valor_pixel = 128*q_out(8) + 64*q_out(7) + 32*q_out(6) + 16*q_out(5) + 8*q_out(4) + 4*q_out(3) +  2*q_out(2) +  q_out(1);
     foto_TMDS_decoficada=[foto_TMDS_decoficada Valor_pixel];
     columnas = columnas+10;
     columna++;
endwhile
foto_TMDS_decoficada = foto_TMDS_decoficada(1:xt*yt);
foto_TMDS_decoficada=reshape(foto_TMDS_decoficada,xt,yt)';