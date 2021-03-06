
layout (location = 0) out vec4 out_color1;
uniform float u_Timer;

const float invalid_t=1.0e9; // far away
const float close_t=1.0e-5; // too close (behind head, self-intersection, etc)

// This struct describes light
struct Light {
    vec3 position;
    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

// This struct describes how a surface looks 
struct surface_hit_t {
	float shiny; /* 0: totally matte surface; 1: big highlight */
	vec3 diffuseColor; /* diffuse color */
	float mirror; /* proportion of perfect mirror specular reflection */
	float refract; /* if not 1.0, the refractive index of the material */
};
// A ray hit
struct ray_hit_t {
	vec3 P; /* world coords location of hit */
	vec3 N; /* surface normal of the hit */
	float t; /* ray t value at hit (or invalid_t if a miss) */
	float opacity; /* fraction of incoming light that makes it through us */
	surface_hit_t s;
};

void sphere_hit(inout ray_hit_t rh,vec3 C,vec3 D,   // ray parameters
		vec3 center,float r, // object parameters
		surface_hit_t surface)  // shading parameters
{
    vec3 oc = C - center;
	float a = dot(D,D);
	float b = 2.0*dot(oc, D);
	float c = dot(oc,oc) - r*r;
	float det = b*b-4.0*a*c;
	if (det<0.0) return; // miss
	float t = (-b - sqrt(det)) / (2.0 * a);
	if (t < close_t || t>rh.t) return; 
	
	vec3 P = C + t*D; // ray-object intersection point (world coordinates)
	
	//closest hit so far
	rh.t = t;
	rh.P = P;
	rh.N = normalize(P-center);
	rh.s = surface;

}




struct ray_stack_t {
	vec3 C; // start of ray
	vec3 D; // direction of ray
	float frac; // fraction of object light that contributes to this pixel
};


ray_hit_t world_hit(vec3 C,vec3 D)
{
    ray_hit_t rh; rh.t=invalid_t; rh.s.mirror=0.0; rh.opacity=1.0;
    

    sphere_hit(rh,C,D, vec3(-0.2 * cos(u_Timer), 0.0, -1.0), 0.15,
        surface_hit_t(0.4,vec3(1.0, 0.0, 0.0),0.0,1.0));
    
    sphere_hit(rh,C,D, vec3(0.0, 0.00, -1.5), 0.15,
        surface_hit_t(0.1,vec3(0.8),1.0,1.0));

    sphere_hit(rh,C,D, vec3(0.3, 0.0, -1.0), 0.15,
        surface_hit_t(0.4,vec3(0.0, 0.0, 1.0),0.0,1.0));

    
     sphere_hit(rh,C,D, vec3(0.0, -150.0, -1.0), 149.8,
        surface_hit_t(0.0,vec3(0.0, 0.0, 1.0),0.0,1.0));

    
    return rh;
}


//point at parameter = C + t*D
vec3 calc_world_color(vec3 C,vec3 D) {
    //setup light 
    vec3 lpos = normalize(vec3(-1.50, 10.0, 10.0)); // it needs to bounce if it wants to move
    Light light = Light(lpos, vec3(0.2), vec3(0.5), vec3(1.0));

    float frac = 1.0; // fraction of object light that makes it to the camera 
	vec3 color=vec3(0.0, 0.0, 0.0); // return parameter
	vec3 skyColor = vec3( 0.3, 0.50, 0.50); //vec3(0.2);//
    
    // virtual stack for checking bounces
    ray_stack_t stack[3];
	stack[0].C=C;
	stack[0].D=D;
	stack[0].frac=frac;
	int stacktop=0;
	
    for (int bounce=0; bounce < 3 ;bounce++) 
	{
        C=stack[stacktop].C;
		D=stack[stacktop].D;
		frac=stack[stacktop].frac;
		stacktop--;
        
        ray_hit_t rh = world_hit(C,D);

        if (rh.t >= invalid_t) { // Sky
            color+=frac*skyColor*(1.5-D.z);
        }
        else 
        { 
            float frontSide = 1.0;
            if (dot(rh.N,D)>0.0) {
                rh.N=-rh.N; // flip normal to face right way
                rh.s.refract = 1.0 / rh.s.refract; // leaving the surface
                frontSide=0.0; 
            }
            vec3 L = light.position;
            vec3 H = normalize( light.position + normalize(-D)); // pointing to eye-ray
            
            float diffuse = max(dot(rh.N,light.position),0);
            float ambient = 0.3;    
            float specular = rh.s.shiny*pow(max(dot(H,rh.N),0.0),32); // pow to 32 determines the shinyness      
            // simple shadow
            ray_hit_t shadow = world_hit(rh.P,L); 
            if (shadow.t<invalid_t) {diffuse*=(1.0-shadow.opacity); specular=0.0;}

            vec3 amb = ambient*light.ambient*rh.s.diffuseColor;
            vec3 dif = (diffuse*rh.s.diffuseColor) * light.diffuse;  
            vec3 spec = specular * light.specular;
            // phong shading model
            vec3 curObject = amb + dif + spec;

            color += frac*curObject;

            
            if (frac>0.02) { // only do more rays if needed
                float doReflect = rh.s.mirror;
                vec3 I = normalize(D);
                vec3 N = normalize(rh.N);
                if (rh.s.refract!=1.0) 
                { // reflection/refraction 

                    // Mirror reflection first 
                    float mirror = 0.08+0.92*pow(1.0 - dot(-I, N), 2.0); // fresnel 
                    if (frontSide <= mirror) {
                        doReflect+=mirror;
                        frac*=(1.0-mirror); // all non-mirror light is refracted
                    }

                    // refraction snells law
                    vec3 R;
                    float dt2 = dot(N, I) * dot(N, I);
                    float eta = 1.0 / rh.s.refract; //air / glass intersection 
                    float k = 1.0 - eta * eta * (1.0 - dt2); //discriminant
                    if (k < 0.0) {
                        doReflect+=1.0; // total internal reflection 
                    }
                    else
                    { // refraction 
                        R = eta * I - (eta * dot(N, I) + sqrt(k)) * N;

                        stacktop++;
                        stack[stacktop].frac=frac;
                        stack[stacktop].C=rh.P;  
                        stack[stacktop].D=R;
                    }
                } 
                if (doReflect>0.0) { // pure mirror reflection 
                    stacktop++;
                    stack[stacktop].frac = frac*doReflect;
                    stack[stacktop].C = rh.P;
                    stack[stacktop].D = reflect(I,N);
                }

            }
        }
         if (stacktop<0) break; // no more rays found
    }
    return color;
}




void main(void) {
    /*-------------CAMERA-THINGS---------------------*/
	// PERSPECTIVE CAMERA CONTROLS
    float fovAngle = 0.2;
    float d = 1.0 / tan(fovAngle * 0.5);
    // RASTERSPACE --> NDC  
    float aspec = 600.0/400.0; // image rectangle
    float ux =  (gl_FragCoord.x / 600.0); // [0 1]
    float vy =  (gl_FragCoord.y / 400.0); // [0 1]
	float ax = -aspec + 2.0*aspec*ux;     // [-a a]
	float ay = -1.0 + 2.0*vy;             // [-1 1]
    // RAY CREATION
    vec3 e = vec3( 0.0, 0.0, 0.0);   // eye position
	vec3 w = vec3(0.0, 0.01, -0.1);  // direction
    vec3 u = vec3(1.0, 0.0, 0.0) * 0.5;   // horizontal
    vec3 v = vec3(0.0, 1.0, 0.0) * 0.5;   // up
    // RAY DIRECTION
    vec3 dir =  ax*u + ay*v + d*w ;              
   
 	/*-------------CAMERA-THINGS---------------------*/
   
	vec3 col = calc_world_color(e, dir);
    
	out_color1 = vec4(col, 1.0);
    
    
	
}



/* 

Scenes for world hit function

vec3 col1 = vec3(gl_FragColor.x / 600.0, (1 - (gl_FragCoord.y / 400.0)), 1.0);
    vec3 col2 = vec3( 1,             (gl_FragCoord.y / 400.0), 1.0);
    
    vec3 col4 = vec3( gl_FragCoord.x / 600.0,      0, 1.0);
    // Red, Green and blue ball
    vec3 col3 = vec3(0.6);

sphere_hit(rh,C,D,vec3(-0.0, 0.05, -0.5) , 0.1,
        surface_hit_t(0.2,col3,0.0, 1.40)); 

    sphere_hit(rh,C,D, vec3(-0.17, 0.10, -1.0), 0.15,
        surface_hit_t(0.02,col2,0.0,1.0));
    sphere_hit(rh,C,D, vec3(0.17, 0.10, -1.0), 0.15,
        surface_hit_t(0.2,col4,0.0,1.0));

    sphere_hit(rh,C,D, vec3(0.0, 0.37, -1.0), 0.15,
        surface_hit_t(0.4,col1,0.0,1.0));
    sphere_hit(rh,C,D, vec3(0.0, -0.17, -1.0), 0.15,
        surface_hit_t(0.9,vec3(0.6,0.4 ,0.8 ),0.0,1.0));
*/

