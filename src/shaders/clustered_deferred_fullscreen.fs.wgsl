// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.



@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms; 
@group(${bindGroup_second}) @binding(0) var<storage, read> lightSet: LightSet;
@group(${bindGroup_second}) @binding(1) var<storage, read> clusterSet: ClusterSet;
@group(${bindGroup_second}) @binding(2) var albedoTex: texture_2d<f32>;
@group(${bindGroup_second}) @binding(3) var posTex: texture_2d<f32>;
@group(${bindGroup_second}) @binding(4) var norTex: texture_2d<f32>;


// @group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
// @group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;


struct FragmentInput
{
    @builtin(position) fragPos: vec4f
}
@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    return textureLoad(albedoTex, vec2u(in.fragPos.xy), 0);
}