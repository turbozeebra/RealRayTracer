
float hit_sphere(vec3 center, float radius, vec3 rayOrigin, vec3 rayDirection){
    float retStatement = -1.0;
    vec3 oc = rayOrigin - center;
    float a = dot(rayDirection, rayDirection);
    float b = 2.0 * dot(oc,rayDirection);
    float c = dot(oc,oc) - radius*radius;
    float d = b*b - 4.0*a*c;
    if( !(d < 0.0) ) {
        retStatement = (-b - sqrt(d)) / (2.0*a);
    }
    return retStatement;
}
//point at parameter = origin + t*direction

vec3 color(vec3 or, vec3 dir) {
    
    vec3 retVec;
    float t = hit_sphere(vec3(0.0, 0.0, -1.0), 0.5, or, dir ); //0.5*(dir.y + 1); //  (1.0 - 0.5*(dir.y + 1))*
    
    if(t > 0.0){
        vec3 pointAtParameter = or + t*dir;
        vec3 N = normalize( pointAtParameter - vec3(0.0, 0.0, -1.0));
        retVec = 0.5 * (N + 1.0);
    } else {
        vec3 dn = normalize(dir);
        float t2 = 0.5*(dn.y + 1.0);
        retVec = (1.0 - t2)*vec3(1.0, 1.0, 1.0) + t2*vec3(0.5, 0.7, 1.0);
    }

    return retVec;

}

void main(void) {

  vec3 gin = vec3(0.0, 0.0, 0.0);
  vec3 lowerLeftCor = vec3(-2.0,-1.5,-1.0);
  vec3 horizontal = vec3(4.0, 0.0, 0.0);
  vec3 vertical = vec3(0.0, 3.1, 0.0);
  float u = gl_FragCoord.x / 600.0;
  float v = gl_FragCoord.y / 500.0;
  vec3 col = color(gin,lowerLeftCor + u*horizontal + v*vertical);

  gl_FragColor = vec4(col, 1.0);

}