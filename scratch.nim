
import fancygl
import macros


macro myDslInner(arg: typed): untyped =
  echo arg.treeRepr

proc stripPragmas(arg: NimNode): NimNode =
  if arg.kind == nnkPragmaExpr:
    result = arg[0].stripPragmas
  elif arg.len == 0:
    result = arg
  else:
    result = arg.kind.newTree
    for child in arg:
      result.add child.stripPragmas

proc genResultType(targets: openarray[string]): NimNode {.compileTime.} =
  let identDefs = nnkIdentDefs.newTree
  for target in targets:
    identDefs.add ident(target)
  identDefs.add bindSym"Vec4f"
  identDefs.add newEmptyNode()
  result = nnkTupleTy.newTree(identDefs)

macro myDsl(arg: untyped): untyped =
  let innerCall = newCall(bindSym"myDslInner", arg[^1][1].stripPragmas)
  let resultType = genResultType(["color"])
  result = quote do:
    var gl_Position {.inject.}: Vec4f
    var result {.inject.}: `resultType`
    `innerCall`

#  for stmt in arg:
#    echo arg.kind

let window, context = defaultSetup()


let vertices = arrayBuffer([
  vec4f(1,0,0,1),
  vec4f(0,1,0,1),
  vec4f(0,0,1,1)
])

let normals = arrayBuffer([
  vec4f(1,1,1,0),
  vec4f(1,1,1,0),
  vec4f(1,1,1,0)
])

let colors = arrayBuffer([
  vec4f(1,0,0,1),
  vec4f(0,1,0,1),
  vec4f(0,0,1,1)
])

var projection_mat: Mat4f

var camera: WorldNode
var node: WorldNode

proc `[]`[T](arg: ArrayBuffer[T]): T =
  discard

template VS(arg: untyped): untyped = arg
  ## does nothing

myDsl:
  primitiveMode = GL_TRIANGLES
  numVertices = 3

  shadingLanguage:
    let a_vertex = vertices[]
    let a_normal = normals[]
    let a_color  = colors[]

    let proj = projection_mat
    let modelView = camera.viewMat * node.modelMat

    gl_Position = (proj * modelView) * a_vertex

    let v_vertex = a_vertex {.VS.}
    let v_normal  = modelView * a_normal {.VS.}
    let v_color  = a_color {.VS.}

    result.color = v_color * v_normal.z;
