#include <stdio.h>
#include <stdlib.h>
/* Use glew.h instead of gl.h to get all the GL prototypes declared */
#include <GL/glew.h>
/* Using the GLUT library for the base windowing setup */
#include <GL/freeglut.h>
#include "./common/shader_utils.h"
#include "./common/shader_utils.cpp"
#include <iostream>
//math library 
#include "../glm/glm.hpp"
#include <chrono> 

#define WIDTH 600
#define HEIGHT 400


// the idea is to make a square screen where the ray tracing happens
GLfloat pixels[12] = {
    -1.0, 1.0,
    1.0, 1.0,
    -1.0, -1.0,

    1.0, 1.0,
    1.0, -1.0
    -1.0, -1.0

  };


GLuint program;
GLint attribute_coord2d;

int msaalvl = 8;

std::chrono::_V2::system_clock::time_point begin = std::chrono::high_resolution_clock::now();

int init_resources()
{
 
  
  GLint link_ok = GL_FALSE; 
  // Create raytracing shaders
  GLuint vs, fs;
  if ((vs = create_shader("src/shaders/background.v.glsl", GL_VERTEX_SHADER))   == 0) return 0;
  if ((fs = create_shader("src/shaders/background.f.glsl", GL_FRAGMENT_SHADER)) == 0) return 0;
  
  // create a program
  program = glCreateProgram();
  
  // attach shaders to the program
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  
  // link program object
  glLinkProgram(program);
  glGetProgramiv(program, GL_LINK_STATUS, &link_ok);
  if (!link_ok) {
    fprintf(stderr, "glLinkProgram:");
    print_log(program);
    return 0;
  }

  return 1;
}

void onDisplay()
{
  
  auto uNow = std::chrono::high_resolution_clock::now();
  std::chrono::duration<float> time = uNow - begin;
  float t = time.count();
  //set uniforms
  int loc2 = glGetUniformLocation(program,"u_Timer");
  glUniform1f(loc2, t);
  glUseProgram(program);
  glEnableVertexAttribArray(attribute_coord2d);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 3);
  glDisableVertexAttribArray(attribute_coord2d);
  glutSwapBuffers();
  
}

void free_resources()
{
  glDeleteProgram(program);
  //glDeleteBuffers(1, &fbo_screen);
}


void timer(int)
{
  unsigned int fps = 1000/60; //60 fps
  glutPostRedisplay();
  glutTimerFunc(fps, timer,0);
}

int main(int argc, char* argv[]) {

  glutInit(&argc, argv);
  
  glutInitDisplayMode(GLUT_RGBA|GLUT_ALPHA|GLUT_DOUBLE|GLUT_DEPTH|GLUT_MULTISAMPLE);
  glutSetOption(GLUT_MULTISAMPLE, 8);
  glutInitWindowSize(WIDTH, HEIGHT);

  glutCreateWindow("Ray Tracing");

  GLenum glew_status = glewInit();
  if (glew_status != GLEW_OK) {
    fprintf(stderr, "Error: %s\n", glewGetErrorString(glew_status));
    return 1;
  }
  // things that are good to know 
  const GLubyte* renderer = glGetString(GL_RENDERER); // get renderer string
	const GLubyte* vendor = glGetString(GL_VENDOR); // vendor
	const GLubyte* version = glGetString(GL_VERSION); // version as a string
	const GLubyte* glslVersion = glGetString(GL_SHADING_LANGUAGE_VERSION); // glsl version string
	GLint major, minor;
	glGetIntegerv(GL_MAJOR_VERSION, &major); // get integer (only if gl version > 3)
	glGetIntegerv(GL_MINOR_VERSION, &minor); // get dot integer (only if gl version > 3)
	printf("OpenGL on %s %s\n", vendor, renderer);
	printf("OpenGL version supported %s\n", version);
	printf("GLSL version supported %s\n", glslVersion);
	printf("Will now set GL to version %i.%i\n", major, minor);


  if (init_resources()) {
   
    glutDisplayFunc(onDisplay);
    glutTimerFunc(0,timer, 0);
    glutMainLoop();
  }

  free_resources();
  return 0;
}

