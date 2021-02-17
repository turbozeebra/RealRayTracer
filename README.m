# RealRayTracer


		

				################################################
				#To run this program:                          #
				#g++ src/main.cpp -o run -lGLEW -lglut -lGL    #
				#./run                                         #
				################################################
				(if you want to build this program you have to have freeglut and glew installed) 

This program is a realtime ray tracer. It uses openGL for making window and set up everything that is seen in the window. The ray tracing happens in the GLSL-shaders. I have implemented simple shadows, phong shadin and simple reflections and refractions to the ray tracing model. The ray tracer also uses perspective camera.

Known issues:
- Camera doesen't suppor z = 0 views

Development ideas:
- Better camera (moving camera and a support for moving with WASD-keys and mouse)
- take models to the openGL side of the program
- make samplers
- Implement particle simulation
- Improve the shading model
- Better dielectric material
