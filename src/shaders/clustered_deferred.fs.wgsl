// TODO-3: implement the Clustered Deferred G-buffer fragment shader

// This shader should only store G-buffer information and should not do any shading.



@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms; 


@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f,
    @builtin(position) fragPos: vec4f
}

struct FragmentOutput
{
    @location(0) albedo: vec4f,
    @location(1) pos: vec4f,
    @location(2) nor: vec4f,
}

@fragment
fn main(in: FragmentInput) -> FragmentOutput
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }

    var output : FragmentOutput;

    output.albedo = diffuseColor;
    output.pos = vec4f(in.pos,1.f);
    output.nor = vec4f(in.nor,1.f); // TODO do I need to remap

    return output;
}
