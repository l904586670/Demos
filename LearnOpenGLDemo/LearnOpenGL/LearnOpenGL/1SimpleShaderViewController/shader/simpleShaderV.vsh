attribute vec4 position;
attribute vec2 textCoordinate;
uniform mat4 rotateMatrix;

varying lowp vec2 varyTextCoord;
// https://www.tuicool.com/articles/yEBFvmA
void main()
{
    varyTextCoord = textCoordinate;
    
    vec4 vPos = position;

    vPos = vPos * rotateMatrix;

    gl_Position = vPos;
}
