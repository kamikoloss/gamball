// https://godotshaders.com/shader/neuronal-network-waves/
shader_type canvas_item;

uniform vec2 mouse_position = vec2(0.5, 0.5);
uniform vec4 wave_color: source_color = vec4(1.0, 2.0, 4.0, 1.0);
uniform float wave_transparency: hint_range(0.0, 1.0) = 1.0;

mat2 rotate2D(float r) {
	// Matriz de rotación 2D	
	return mat2(vec2(cos(r), sin(r)), vec2(-sin(r), cos(r)));
}

void fragment() {
	// Coordenadas de textura
	vec2 uv = (FRAGCOORD.xy / TEXTURE_PIXEL_SIZE.y) * 0.001;	
	// Color inicial
	vec3 col = vec3(0.0);
	// Tiempo
	float t = TIME;
	// Variables para el cálculo del ruido
	vec2 n = vec2(0.0), q;
	vec2 N = vec2(0.0);
	// Posición inicial
	vec2 p = uv + sin(t*0.1/10.0);
	// Escala inicial
	float S = 10.0;
	// Matriz de rotación
	mat2 m = rotate2D(1.0 - (mouse_position.x * 0.001));
	// Bucle principal para generar el ruido
	for (float j = 0.0; j < 30.0; j++) {
		// Rotar la posición y el vector normal
		p *= m;
		n *= m;
		// Calcular el valor del ruido
		q = p * S + j + n + t;
		n += sin(q);
		N += cos(q) / S;
		// Aumentar la escala
		S *= 1.2;
	}

	// Evitar divisiones por cero
	float lengthN = max(length(N), 0.001);
	// Calcular el color final
	col = wave_color.rgb * pow((N.x + N.y + 0.4) + 0.005 / lengthN, 2.1);
	// col = pow(max(vec3(0),(N.x+N.y+.5)*.1*wave_color.rgb+.003/length(N)),vec3(.65));
	COLOR = vec4(col, wave_transparency);
}