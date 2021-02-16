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

GLuint vbo_screen;
GLuint program;
GLint attribute_coord2d;
std::chrono::_V2::system_clock::time_point begin = std::chrono::high_resolution_clock::now();

int init_resources()
{
  // the idea is to make a square screen where the ray tracing happens
 GLfloat pixels[12] = {
    -1.0, 1.0,
    1.0, 1.0,
    -1.0, -1.0,

    1.0, 1.0,
    1.0, -1.0
    -1.0, -1.0

  };
  
  glGenBuffers(1, &vbo_screen);
  glBindBuffer(GL_ARRAY_BUFFER, vbo_screen);
  glBufferData(GL_ARRAY_BUFFER, sizeof(pixels), pixels, GL_STATIC_DRAW);

  GLint link_ok = GL_FALSE;
  // Create raytracing shaders
  GLuint vs, fs;
  if ((vs = create_shader("src/shaders/background.v.glsl", GL_VERTEX_SHADER))   == 0) return 0;
  if ((fs = create_shader("src/shaders/background.f.glsl", GL_FRAGMENT_SHADER)) == 0) return 0;

  

  //create a program
  program = glCreateProgram();
  //attach shaders to the program
  glAttachShader(program, vs);
  glAttachShader(program, fs);
  
  glLinkProgram(program);
  glGetProgramiv(program, GL_LINK_STATUS, &link_ok);
  if (!link_ok) {
    fprintf(stderr, "glLinkProgram:");
    print_log(program);
    return 0;
  }

  const char* attribute_name = "coord2d"; // 2d as two dimensions
  attribute_coord2d = glGetAttribLocation(program, attribute_name);
  if (attribute_coord2d == -1) {
    fprintf(stderr, "Could not bind attribute %s\n", attribute_name);
    return 0;
  }

  return 1;
}

void onDisplay()
{
  
  GLfloat pixels[12] = {
    -1.0, 1.0,
    1.0, 1.0,
    -1.0, -1.0,

    1.0, 1.0,
    1.0, -1.0
    -1.0, -1.0

  };
  

  auto uNow = std::chrono::high_resolution_clock::now();
  std::chrono::duration<float> time = uNow - begin;
  float t = time.count();
  //set uniforms
  int loc2 = glGetUniformLocation(program,"u_Timer");
  glUniform1f(loc2, t);

  glClearColor(0.0, 0.0, 0.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT);

  glUseProgram(program);
  glEnableVertexAttribArray(attribute_coord2d);
  // Describe our vertices array to OpenGL (it can't guess its format automatically) 
  glBindBuffer(GL_ARRAY_BUFFER, vbo_screen);
  glVertexAttribPointer(
    attribute_coord2d, // attribute
    2,                 // number of elements per vertex, here (x,y)
    GL_FLOAT,          // the type of each element
    GL_FALSE,          // take our values as-is
    0,                 // no extra data between each position
    0                  // offset of first element
  );

  // Push each element in buffer_vertices to the vertex shader 
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(pixels), &pixels);
  glDrawArrays(GL_TRIANGLE_STRIP, 0, 12);

  glDisableVertexAttribArray(attribute_coord2d);
  glutSwapBuffers();
  
}

void free_resources()
{
  glDeleteProgram(program);
  glDeleteBuffers(1, &vbo_screen);
}


void timer(int)
{
  unsigned int fps = 1000/60; //60 fps
  glutPostRedisplay();
  glutTimerFunc(fps, timer,0);
}


int main(int argc, char* argv[]) {
  glutInit(&argc, argv);
  glutInitContextVersion(2,0);
  glutInitDisplayMode(GLUT_RGBA|GLUT_ALPHA|GLUT_DOUBLE|GLUT_DEPTH);
  glutInitWindowSize(WIDTH, HEIGHT);
  glutCreateWindow("My Second Triangle");

  GLenum glew_status = glewInit();
  if (glew_status != GLEW_OK) {
    fprintf(stderr, "Error: %s\n", glewGetErrorString(glew_status));
    return 1;
  }

  if (!GLEW_VERSION_2_0) {
    fprintf(stderr, "Error: your graphic card does not support OpenGL 2.0\n");
    return 1;
  }

  if (init_resources()) {
    glutDisplayFunc(onDisplay);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glutTimerFunc(0,timer, 0);
    glutMainLoop();
  }

  free_resources();
  return 0;
}

