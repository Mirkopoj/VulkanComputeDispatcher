#version 330
layout (location = 0) out vec4 daColor;

//in vec4 vertexPosition;
in vec2 uv;

uniform vec3 cameraDirection;
uniform vec3 cameraPosition;
uniform float ambientLight;
uniform vec3 HeadLightPos;
uniform vec3 HeadLightDir;

uniform sampler2D tex0;
uniform sampler2D tex1;//TexIS (acumulado)
uniform sampler2D tex2;// mapas de Slope Aspect WindInt Forest
uniform sampler2D tex3;//Mapas de Altitud (Incendio)Real Vegetacion WindAngle
uniform float filas;
uniform float columnas;

uniform vec3 ambientLightColor;
uniform vec3 skyColor;

/*inline float4 EncodeFloatRGBA( float v ) {
  float4 enc = float4(1.0, 255.0, 65025.0, 16581375.0) * v;
  enc = frac(enc);
  enc -= enc.yzww * float4(1.0/255.0,1.0/255.0,1.0/255.0,0.0);
  return enc;
}

inline float DecodeFloatRGBA( float4 rgba ) {
  return dot( rgba, float4(1.0, 1/255.0, 1/65025.0, 1/16581375.0) );
}*/

void main()
{
	vec4 outc;
	float beta = 1.0f;//1.0;
	float gamma = 0.2f;//0.2;
	float Difu = 1.0f;//1.0;
	float Cwind = 0.1f;//0.1f;//1.5; //constante a ajustar que acompa?a al vector viento
	float Cslope = 0.2f;//0.2;


	// NO ANALIZA BORDES, YA QUE NO TIENEN TODOS SUS VECINOS
	if ( (uv.x > (1.0 / columnas)) && (uv.x < (1.0 - (1.0 / columnas))) &&
			(uv.y > (1.0 / filas)) && (uv.y < (1.0 - (1.0 / filas)))
	 ) {
			// NO ES BORDE

				vec2 centro=uv;
				vec2 arriba=uv-vec2(0,1.0/filas);
				vec2 abajo=uv+vec2(0,1.0/filas);
				vec2 izquierda=uv-vec2(1.0/columnas,0);
				vec2 derecha=uv+vec2(1.0/columnas,0);

				vec2 arriba2=uv-vec2(0,2.0/filas);
				vec2 abajo2=uv+vec2(0,2.0/filas);
				vec2 izquierda2=uv-vec2(2.0/columnas,0);
				vec2 derecha2=uv+vec2(2.0/columnas,0);

				float Sus_centro = texture(tex1,centro).g;
				//Sus_centro=1.0f;

				float Inc_arriba = texture(tex1,arriba).r;
				float Inc_izquierda = texture(tex1,izquierda).r;
				float Inc_centro = texture(tex1,centro).r;
				float Inc_derecha = texture(tex1,derecha).r;
				float Inc_abajo = texture(tex1,abajo).r;


				float alti_arriba =texture(tex3,arriba).r;
				float alti_izquierda =texture(tex3,izquierda).r;
				float alti_derecha =texture(tex3,derecha).r;
				float alti_abajo =texture(tex3,abajo).r;
				float alti_centro =texture(tex3,centro).r;

				float alti_arriba2 =texture(tex3,arriba2).r;
				float alti_izquierda2 = texture(tex3,izquierda2).r;
				float alti_derecha2 =texture(tex3,derecha2).r;
				float alti_abajo2 =texture(tex3,abajo2).r;

				float vege_centro = texture(tex3,centro).b;

				float winda_centro=texture(tex3,centro).a;
				float windi_centro=texture(tex2,centro).b;

			/* En cada celda tendremos un tipo mayoritario de combustible que determinara la velocidad
			   de la transmision del calor beta que cambiara de celda en celda pero que en cada celda es constante.
				 Por esto beta(r)S es el n�mero efectivo de sitios que pueden quemarse. Si tengo un beta bajo, aunque tenga
				 muchos S se va a quemar poco y lo mismo si tengo un beta alto y pocos sitios S para quemar.*/


				if(vege_centro>=0.0f && vege_centro<2.5f) // vege == 0,1 o 2 no queman
					{
						Difu = 0.0f;//0.0f;
						beta = 0.0f;
					}
					else if(vege_centro>2.5f && vege_centro<3.5f) // vege == 3, Bosque A
					{
						Difu = 0.4f;//0.2f;
						beta = 0.4f;
					}
					else if(vege_centro>3.5f && vege_centro<4.5f) // vege == 4  Bosque B
					{
						Difu = 0.5f;//0.3f;
						beta = 0.5f;
					}
					else if(vege_centro>4.5f && vege_centro<5.5f) // vege == 5 Bosque Insertado el que mas quema
					{
						Difu = 0.6f;//0.5f;
						beta = 0.6f;
					}
					else if(vege_centro>5.5f && vege_centro<6.5f) // vege == 6 pastizal
					{
						Difu = 0.9f;//0.9f;
						beta = 0.9f;
					}
					else if(vege_centro>6.5f && vege_centro<7.5f) // vege == 7 arbustal
					{
						Difu = 0.7f;//0.7f;
						beta = 0.7f;
					}

				//Difu = 0.7f;//0.7f;
				//beta = 0.7f;

				float Inc_clamp_value=2.0f;

				float laplacianInc = 0.0;
				// si no esta en ninguno de los 4 bordes
				//Termino de difusion del calor es como si los sitios incendiandose "difundieran" a sus vecinos. La corriente de transmision del calor es proporcional al gradiente de T y suponemos que la Temperatura aumenta con el numero de sitios incendiandose.
				//if (x>0 && x<l - 1 && y>0 && y<l - 1) {
				laplacianInc = clamp(Inc_arriba - Inc_centro,-Inc_clamp_value,Inc_clamp_value) + clamp(Inc_abajo - Inc_centro,-Inc_clamp_value,Inc_clamp_value) +
						clamp(Inc_derecha - Inc_centro,-Inc_clamp_value,Inc_clamp_value) + clamp(Inc_izquierda - Inc_centro,-Inc_clamp_value,Inc_clamp_value);
				laplacianInc=0.25f*laplacianInc;
				//}

				//Termino convectivo (viento, pendiente)
				//VIENTO
				float vecx = +0.5f;
				//sin(d_wind[centro]); //aca habria que descomponer el viento en x y en y REVISAR d_wind es el angulo de la direccion del viento
				float vecy = -0.5f;
				//cos(d_wind[centro]);

				//windi_centro=0.001f;

				vecx=-windi_centro*sin(winda_centro*3.1415f/180.0f);
				vecy=-windi_centro*cos(winda_centro*3.1415f/180.0f);

				vec3 waux=vec3(0,0,0);
				vec3 wauxi=vec3(0,0,0);

				if(vecx<0) {wauxi.x=1.0f;}
				if(vecx>0) {waux.x=1.0f;}
				if(vecy>0) {wauxi.y=1.0f;}
				if(vecy<0) {waux.y=1.0f;}

				float viento_clamp_value=50.0f;


				float convective_wind = 	-clamp(vecx,-viento_clamp_value,viento_clamp_value)*(wauxi.x)*clamp(Inc_derecha - Inc_centro,-Inc_clamp_value,Inc_clamp_value) +
											+clamp(-vecx,-viento_clamp_value,viento_clamp_value)*(waux.x)*clamp(Inc_centro - Inc_izquierda,-Inc_clamp_value,Inc_clamp_value) +
											+clamp(vecy,-viento_clamp_value,viento_clamp_value)*(wauxi.y)*clamp(Inc_abajo - Inc_centro,-Inc_clamp_value,Inc_clamp_value) +
											+clamp(vecy,-viento_clamp_value,viento_clamp_value)*(waux.y)*clamp(Inc_centro - Inc_arriba,-Inc_clamp_value,Inc_clamp_value);


				//Gradiente de ALTURAS por gradiente de Sitios Incendiandose

				//float convective_slope = (alti_derecha - alti_izquierda)*0.5*(Inc_derecha - Inc_izquierda) +(alti_arriba - alti_abajo)*0.5*(Inc_arriba - Inc_abajo);

				waux=vec3(0,0,0);
				wauxi=vec3(0,0,0);

				if((alti_centro-alti_derecha)>0) {wauxi.x=1.0f;}
				if((alti_centro-alti_izquierda)>0) {waux.x=1.0f;}
				if((alti_centro-alti_abajo)>0) {wauxi.y=1.0f;}
				if((alti_centro-alti_arriba)>0) {waux.y=1.0f;}

				float pendiente_clamp_value=50.0f; //OJO, ES PORCENTAJE DE PENDIENTE, NO GRADOS.


				float convective_slope = 	-clamp((alti_derecha - alti_centro)/0.3f,-pendiente_clamp_value,pendiente_clamp_value)*(wauxi.x)*clamp(Inc_derecha - Inc_centro,-Inc_clamp_value,Inc_clamp_value) +
											-clamp((alti_centro - alti_izquierda)/0.3f,-pendiente_clamp_value,pendiente_clamp_value)*(waux.x)*clamp(Inc_centro - Inc_izquierda,-Inc_clamp_value,Inc_clamp_value) +
											-clamp((alti_abajo - alti_centro)/0.3f,-pendiente_clamp_value,pendiente_clamp_value)*(wauxi.y)*clamp(Inc_abajo - Inc_centro,-Inc_clamp_value,Inc_clamp_value) +
											-clamp((alti_centro - alti_arriba)/0.3f,-pendiente_clamp_value,pendiente_clamp_value)*(waux.y)*clamp(Inc_centro - Inc_arriba,-Inc_clamp_value,Inc_clamp_value);

				/*float convective_slope = 	-(-alti_derecha2 + 6.0f*alti_derecha - 3.0f*alti_centro - 2.0f*alti_izquierda)*(wauxi.x)*(Inc_derecha - Inc_centro)/6.0f +
								-(2.0f*alti_derecha + 3.0f*alti_centro - 6.0f*alti_izquierda+alti_izquierda2)*(waux.x)*(Inc_centro - Inc_izquierda)/6.0f +
								+(-alti_abajo2 + 6.0f*alti_abajo - 3.0f*alti_centro-2.0f*alti_arriba)*(wauxi.y)*(Inc_centro - Inc_arriba)/6.0f +
								+(2.0f*alti_abajo + 3.0f*alti_centro - -6.0f*alti_arriba+alti_arriba2)*(waux.y)*(Inc_abajo - Inc_centro)/6.0f;

			*/






				//*dIncdt = Difu*laplacianInc + beta*Sus_centro*Inc_centro - gamma*Inc_centro + Cwind*convective_viento;
				//Cslope*convective_slope;
				//+ Cwind*convective_viento

				//*dSusdt = -beta*Sus_centro*Inc_centro;

			//	outc.r=Difu*laplacianInc + beta*Sus_centro*Inc_centro - gamma * Inc_centro;// + Cwind*convective_viento + Cslope*convective_slope;

				//beta*Sus_centro*Inc_centro Es bastante suave y gradual. valores menores que 1
				//Difu * laplacianInc 	Tiene con valores altos las zonas donde se producen las divergencias. valores andan por 1.0f
				//gamma * Inc_centro 	Valores menores que 1 y suaves en todo el mapa
				//Cslope*convective_slope Valores altos en zonas de divergencias, valores max entre 1 y 2

				//outc.r = beta*Sus_centro*Inc_centro + Difu * laplacianInc- gamma * Inc_centro + 0.3f*Cslope*convective_slope + Cwind*convective_wind; // + Cslope*convective_slope;
				outc.r = beta*Sus_centro*Inc_centro + Difu * laplacianInc- gamma * Inc_centro + 0.3f*Cslope*convective_slope + Cwind*convective_wind; // + Cslope*convective_slope;
				//outc.g=-outc.r;
				outc.g= -beta*Sus_centro*Inc_centro;

				if(outc.r<0.0001f && outc.r>0.0f)outc.r=0.0f;//PARA EVITAR PROPAGACION DE INCENDIANDOSE SIN RESTAR SUCEPTIBLES
				if(outc.g<0.0001f && outc.g>0.0f)outc.g=0.0f;//PROBANDO

				outc.b=1.0f;

				if((vege_centro>=0.0f && vege_centro<2.5f)||Sus_centro<=0.0001f) // vege == 0,1 o 2 no queman
				{
					outc.r=0.0f;//PONERLO FUERA DEL SHADER
					outc.g=0.0f;
					outc.b=0.0f;
				}

				if(isinf(outc.r)||isnan(outc.r)||outc.r>100.0f||outc.r<-100.0f){outc.r=0.0f;}
				if(isinf(outc.g)||isnan(outc.g)||outc.g>0.0f||outc.g<-100.0){outc.g=0.0f;}
				//outc.g=-0.005;
				//outc.b=max(abs(alti_derecha - alti_centro),max(abs(alti_centro - alti_izquierda),max(abs(alti_abajo - alti_centro),abs(alti_centro - alti_arriba))))/50.0f;
			//	outc.b= Cslope*convective_slope /10.0f;  NOVIEMBRE 2022 COMENTO ESTA LINEA
				outc.a=1.0;


				daColor=outc;
	} //no analiza bordes
}
