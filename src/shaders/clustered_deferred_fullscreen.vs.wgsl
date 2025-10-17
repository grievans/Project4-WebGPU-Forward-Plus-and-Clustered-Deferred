// TODO-3: implement the Clustered Deferred fullscreen vertex shader

// This shader should be very simple as it does not need all of the information passed by the the naive vertex shader.



// @group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms; 


// @group(${bindGroup_model}) @binding(0) var<uniform> modelMat: mat4x4f;

// struct VertexInput
// {
//     @location(0) pos: vec3f,
//     @location(1) nor: vec3f,
//     @location(2) uv: vec2f
// }

struct VertexOutput
{
    @builtin(position) fragPos: vec4f,
}


@vertex
fn main(@builtin(vertex_index) vertexIndex: u32) -> VertexOutput
{
    
    // using triangle way per Avi's suggestion (apparently slightly more performant since 1: less vertex data and 2: no potential double-evaluation of positions at seam)
    const pos = array<vec2f, 3>(
        vec2f(-1.0,-1.0),
        vec2f(-1.0,3.0),
        vec2f(3.0,-1.0)
    );
    var out: VertexOutput;
    out.fragPos = vec4f(pos[vertexIndex], 0.f, 1.f);
    return out;
}
