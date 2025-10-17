// TODO-2: implement the Forward+ fragment shader

// See naive.fs.wgsl for basic fragment shader setup; this shader should use light clusters instead of looping over all lights

// ------------------------------------
// Shading process:
// ------------------------------------
// Determine which cluster contains the current fragment.
// Retrieve the number of lights that affect the current fragment from the cluster’s data.
// Initialize a variable to accumulate the total light contribution for the fragment.
// For each light in the cluster:
//     Access the light's properties using its index.
//     Calculate the contribution of the light based on its position, the fragment’s position, and the surface normal.
//     Add the calculated contribution to the total light accumulation.
// Multiply the fragment’s diffuse color by the accumulated light contribution.
// Return the final color, ensuring that the alpha component is set appropriately (typically to 1).




@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms; 
@group(${bindGroup_scene}) @binding(1) var<storage, read> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(2) var<storage, read> clusterSet: ClusterSet;


@group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
@group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;

struct FragmentInput
{
    @location(0) pos: vec3f,
    @location(1) nor: vec3f,
    @location(2) uv: vec2f,
    @builtin(position) fragPos: vec4f
}
fn getDepthSlice(zPos : f32) -> u32 {
    // TODO precalculate parts of this?
    return u32((log(zPos) -  log(camera.nearClip)) * ${clustersDivZ} / log(camera.farClip / camera.nearClip));
    // return u32(log(zPos) * ${clustersDivZ} / log(camera.farClip / camera.nearClip) - ${clustersDivZ} * log(camera.nearClip) / log(camera.farClip/camera.nearClip));
}

@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    let diffuseColor = textureSample(diffuseTex, diffuseTexSampler, in.uv);
    if (diffuseColor.a < 0.5f) {
        discard;
    }
    // var viewPos = camera.viewProjMat * vec4(in.pos,1);
    // var viewPos = vec4(in.pos,1);
    let viewPos = in.fragPos / in.fragPos.w;
    // via https://www.w3.org/TR/WGSL/#built-in-values-position:
    //  "fp.w is the perspective divisor for the fragment, which is the interpolation of 1.0 ÷ vertex_w, where vertex_w is the w component of the position output of the vertex shader."
    // so that implies the inverse of what w I thought it was? but the way it is now seems to work correctly

    // var viewPos = vec4(fragPos,1);
    // return vec4(viewPos.z, 0, 0, 1);
    // TODO <-----
    // viewPos /= viewPos.w;
    // let scaledDepth = -camera.nearClip * pow(camera.farClip / camera.nearClip, viewPos.z);
    let sliceZ = getDepthSlice(viewPos.z);
    // if (sliceZ == 0) { 
        // return vec4(1.f,0.f,0.f,1.f);
    // }
    
    // const colors = array<vec3f,8>(vec3f(1.f,0.f,0.f), vec3f(0.f,1.f,0.f), vec3f(0.f,0.f,1.f), vec3f(1.f,1.f,0.f), vec3f(1.f,0.f,1.f), vec3f(0.f,1.f,1.f), vec3f(1.f,1.f,1.f), vec3f(0.5,0.5,0.5));
    // return vec4(colors[sliceZ % 8], 1);
    // return vec4(f32(sliceZ) / f32(${clustersDivZ}), 0, 0, 1);
    let tileSizePxX = f32(camera.screenWidth) / ${clustersDivX}; // TODO handle dimensions separately for non-square?
    let tileSizePxY = f32(camera.screenHeight) / ${clustersDivY};
    let divPixSpace = in.fragPos.xy / vec2f(tileSizePxX, tileSizePxY);
    let clusterIdx = vec3u(vec2u(divPixSpace),sliceZ);
    // return vec4(f32(clusterIdx.x) / f32(${clustersDivX}), f32(clusterIdx.y) / f32(${clustersDivY}), f32(clusterIdx.z) / f32(${clustersDivZ}), 1);
    let clusterSetIdx = clusterIdx.x + clusterIdx.y * ${clustersDivX} + clusterIdx.z * ${clustersDivX} * ${clustersDivY};




    let nLights = clusterSet.clusters[clusterSetIdx].numLights;
    var totalLightContrib = vec3f(0, 0, 0);
    // TODO I think working but running badly; will test on another computer
//    return vec4f(f32(nLights) / 50.f, f32(nLights) / 50.f, f32(nLights) / 50.f, 1.f);
    for (var lightIdx = 0u; lightIdx < nLights; lightIdx++) {
        let light = lightSet.lights[clusterSet.clusters[clusterSetIdx].lights[lightIdx]];
        totalLightContrib += calculateLightContrib(light, in.pos, normalize(in.nor));
    }

    var finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);
}
