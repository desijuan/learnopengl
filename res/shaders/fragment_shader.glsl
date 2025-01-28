#version 330 core

uniform float width;
uniform float height;
uniform float time;

out vec4 fragColor;

#define M_PI 3.1415926535897932384626433832795

void main()
{
    float x = 2.0 * gl_FragCoord.x / width - 1.0;
    float y = 2.0 * gl_FragCoord.y / height - 1.0;
    float norm = sqrt(x * x + y * y);

    float s = 0.5 * sin(2.0 * M_PI * norm - 2.0 * time) + 0.5;
    float c = 0.5 * cos(3.0 * M_PI * norm - 3.0 * time) + 0.5;

    fragColor = vec4(s, c, s + c, 1.0);
}
