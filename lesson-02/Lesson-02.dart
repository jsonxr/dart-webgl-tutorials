library lesson2;

import 'dart:html';
import 'package:vector_math/vector_math.dart';
import 'dart:web_gl' as webgl;
import 'dart:typed_data';

/**
 * based on:
 * http://learningwebgl.com/blog/?p=134
 */
class Lesson02 {

  CanvasElement _canvas;
  webgl.RenderingContext _gl;
  webgl.Program _shaderProgram;
  int _dimensions = 3;
  int _viewportWidth;
  int _viewportHeight;

  webgl.Buffer _triangleVertexPositionBuffer;
  webgl.Buffer _triangleVertexColorBuffer;

  webgl.Buffer _squareVertexPositionBuffer;
  webgl.Buffer _squareVertexColorBuffer;

  Matrix4 _pMatrix;
  Matrix4 _mvMatrix;

  int _aVertexPosition;
  int _aVertexColor;
  webgl.UniformLocation _uPMatrix;
  webgl.UniformLocation _uMVMatrix;


  Lesson02(CanvasElement canvas) {
    _viewportWidth = canvas.width;
    _viewportHeight = canvas.height;
    _gl = canvas.getContext("experimental-webgl");

    _initShaders();
    _initBuffers();

    _gl.clearColor(0.0, 0.0, 0.0, 1.0);
    _gl.enable(webgl.RenderingContext.DEPTH_TEST);
  }


  void _initShaders() {
    // vertex shader source code. uPosition is our variable that we'll
    // use to create animation
    String vsSource = """
    attribute vec3 aVertexPosition;
    attribute vec4 aVertexColor;
  
    uniform mat4 uMVMatrix;
    uniform mat4 uPMatrix;
  
    varying vec4 vColor;
  
    void main(void) {
      gl_Position = uPMatrix * uMVMatrix * vec4(aVertexPosition, 1.0);
      vColor = aVertexColor;
    }
    """;

    // fragment shader source code. uColor is our variable that we'll
    // use to animate color
    String fsSource = """
    precision mediump float;

    varying vec4 vColor;

    void main(void) {
      gl_FragColor = vColor;
    }
    """;

    // vertex shader compilation
    webgl.Shader vs = _gl.createShader(webgl.RenderingContext.VERTEX_SHADER);
    _gl.shaderSource(vs, vsSource);
    _gl.compileShader(vs);

    // fragment shader compilation
    webgl.Shader fs = _gl.createShader(webgl.RenderingContext.FRAGMENT_SHADER);
    _gl.shaderSource(fs, fsSource);
    _gl.compileShader(fs);

    // attach shaders to a WebGL program
    _shaderProgram = _gl.createProgram();
    _gl.attachShader(_shaderProgram, vs);
    _gl.attachShader(_shaderProgram, fs);
    _gl.linkProgram(_shaderProgram);
    _gl.useProgram(_shaderProgram);

    /**
     * Check if shaders were compiled properly. This is probably the most painful part
     * since there's no way to "debug" shader compilation
     */
    if (!_gl.getShaderParameter(vs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(vs));
    }

    if (!_gl.getShaderParameter(fs, webgl.RenderingContext.COMPILE_STATUS)) {
      print(_gl.getShaderInfoLog(fs));
    }

    if (!_gl.getProgramParameter(_shaderProgram, webgl.RenderingContext.LINK_STATUS)) {
      print(_gl.getProgramInfoLog(_shaderProgram));
    }

    _aVertexPosition = _gl.getAttribLocation(_shaderProgram, "aVertexPosition");
    _gl.enableVertexAttribArray(_aVertexPosition);

    _aVertexColor = _gl.getAttribLocation(_shaderProgram, "aVertexColor");
    _gl.enableVertexAttribArray(_aVertexColor);

    _uPMatrix = _gl.getUniformLocation(_shaderProgram, "uPMatrix");
    _uMVMatrix = _gl.getUniformLocation(_shaderProgram, "uMVMatrix");

  }

  void _initBuffers() {
    // variable to store verticies
    List<double> vertices;

    // create triangle
    _triangleVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);

    // fill "current buffer" with triangle verticies
    vertices = [
       0.0,  1.0,  0.0,
      -1.0, -1.0,  0.0,
       1.0, -1.0,  0.0
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _triangleVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    List<double> colors = [
        1.0, 0.0, 0.0, 1.0,
        0.0, 1.0, 0.0, 1.0,
        0.0, 0.0, 1.0, 1.0
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors), webgl.RenderingContext.STATIC_DRAW);

    //_triangleVertexPositionBuffer.itemSize = 3;
    //_triangleVertexPositionBuffer.numItems = 3;

    // create square
    _squareVertexPositionBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);

    // fill "current buffer" with triangle verticies
    vertices = [
         1.0,  1.0,  0.0,
        -1.0,  1.0,  0.0,
         1.0, -1.0,  0.0,
        -1.0, -1.0,  0.0
    ];
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(vertices), webgl.RenderingContext.STATIC_DRAW);

    _squareVertexColorBuffer = _gl.createBuffer();
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);

    colors = new List();
    for (int i=0; i < 4; i++) {
      colors.addAll([0.5, 0.5, 1.0, 1.0]);
    }
    _gl.bufferDataTyped(webgl.RenderingContext.ARRAY_BUFFER, new Float32List.fromList(colors), webgl.RenderingContext.STATIC_DRAW);

  }

  void _setMatrixUniforms() {
    Float32List tmpList = new Float32List(16);

    _pMatrix.copyIntoArray(tmpList);
    _gl.uniformMatrix4fv(_uPMatrix, false, tmpList);

    _mvMatrix.copyIntoArray(tmpList);
    _gl.uniformMatrix4fv(_uMVMatrix, false, tmpList);
  }

  void render() {
    _gl.viewport(0, 0, _viewportWidth, _viewportHeight);
    _gl.clear(webgl.RenderingContext.COLOR_BUFFER_BIT | webgl.RenderingContext.DEPTH_BUFFER_BIT);

    // field of view is 45°, width-to-height ratio, hide things closer than 0.1 or further than 100
    _pMatrix = makePerspectiveMatrix(radians(45.0), _viewportWidth / _viewportHeight, 0.1, 100.0);

    // draw triangle
    _mvMatrix = new Matrix4.identity();
    _mvMatrix.translate(new Vector3(-1.5, 0.0, -7.0));

    // verticies
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _triangleVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    _gl.drawArrays(webgl.RenderingContext.TRIANGLES, 0, 3); // triangles, start at 0, total 3

    // draw square
    _mvMatrix.translate(new Vector3(3.0, 0.0, 0.0));

    // verticies
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexPositionBuffer);
    _gl.vertexAttribPointer(_aVertexPosition, _dimensions, webgl.RenderingContext.FLOAT, false, 0, 0);
    // color
    _gl.bindBuffer(webgl.RenderingContext.ARRAY_BUFFER, _squareVertexColorBuffer);
    _gl.vertexAttribPointer(_aVertexColor, 4, webgl.RenderingContext.FLOAT, false, 0, 0);

    _setMatrixUniforms();
    _gl.drawArrays(webgl.RenderingContext.TRIANGLE_STRIP, 0, 4); // square, start at 0, total 4

  }

}

void main() {
  Lesson02 lesson = new Lesson02(document.query('#drawHere'));
  lesson.render();
}
