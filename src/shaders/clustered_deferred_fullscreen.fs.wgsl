// TODO-3: implement the Clustered Deferred fullscreen fragment shader

// Similar to the Forward+ fragment shader, but with vertex information coming from the G-buffer instead.



@group(${bindGroup_scene}) @binding(0) var<uniform> camera: CameraUniforms; 
@group(${bindGroup_second}) @binding(0) var<storage, read> lightSet: LightSet;
@group(${bindGroup_second}) @binding(1) var<storage, read> clusterSet: ClusterSet;
@group(${bindGroup_second}) @binding(2) var albedoTex: texture_2d<f32>;
@group(${bindGroup_second}) @binding(3) var posTex: texture_2d<f32>;
@group(${bindGroup_second}) @binding(4) var norTex: texture_2d<f32>;
// @group(${bindGroup_second}) @binding(5) var depthTex: texture_2d<f32>;


// @group(${bindGroup_material}) @binding(0) var diffuseTex: texture_2d<f32>;
// @group(${bindGroup_material}) @binding(1) var diffuseTexSampler: sampler;
fn getDepthSlice(zPos : f32) -> u32 {
    return u32((log(zPos) -  log(camera.nearClip)) * ${clustersDivZ} / log(camera.farClip / camera.nearClip));
}

struct FragmentInput
{
    @builtin(position) fragPos: vec4f
}
@fragment
fn main(in: FragmentInput) -> @location(0) vec4f
{
    // return textureLoad(albedoTex, vec2u(in.fragPos.xy), 0);
    // return textureLoad(posTex, vec2u(in.fragPos.xy), 0);
    // return vec4f((textureLoad(norTex, vec2u(in.fragPos.xy), 0).xyz + 1.f) * 0.5f, 1.f);
    // return vec4f(vec3f((1.f - textureLoad(depthTex, vec2u(in.fragPos.xy), 0).x )* 50.f), 1.f);



    // let viewPosZ = textureLoad(depthTex, vec2u(in.fragPos.xy), 0).x; // TODO pass in depth texture? or recalc from world pos and camera
    // ^doesn't seem worth it necessarily since have to figure out other remapping; just gonna use world pos I guess
    let worldPos = textureLoad(posTex, vec2u(in.fragPos.xy), 0);
    if (worldPos.w == 0.f) {
        discard;
    }
    let pos = worldPos.xyz;
    let viewPos = (camera.viewProjMat * worldPos);


    // TODO figure out what the deal is with depth values--seem fine but wanna make sure behaving consistently
    //  I don't understand atm why I need to NOT divide this by w
    let sliceZ = getDepthSlice(viewPos.z);
    // let sliceZ = getDepthSlice(viewPos.z * viewPos.w);
    // let sliceZ = getDepthSlice(viewPosZ * camera.farClip);
    // if (sliceZ == 0) { 
        // return vec4(1.f,0.f,0.f,1.f);
    // }
    // return vec4(viewPos.z / viewPos.w, 0, 0, 1);
    
    // const colors = array<vec3f,8>(vec3f(1.f,0.f,0.f), vec3f(0.f,1.f,0.f), vec3f(0.f,0.f,1.f), vec3f(1.f,1.f,0.f), vec3f(1.f,0.f,1.f), vec3f(0.f,1.f,1.f), vec3f(1.f,1.f,1.f), vec3f(0.5,0.5,0.5));
    // return vec4(colors[sliceZ % 8], 1);
    // // return vec4(f32(sliceZ) / f32(${clustersDivZ}), 0, 0, 1);
    let tileSizePxX = f32(camera.screenWidth) / ${clustersDivX}; // TODO handle dimensions separately for non-square?
    let tileSizePxY = f32(camera.screenHeight) / ${clustersDivY};
    let divPixSpace = in.fragPos.xy / vec2f(tileSizePxX, tileSizePxY);
    let clusterIdx = vec3u(vec2u(divPixSpace),sliceZ);
    // // return vec4(f32(clusterIdx.x) / f32(${clustersDivX}), f32(clusterIdx.y) / f32(${clustersDivY}), f32(clusterIdx.z) / f32(${clustersDivZ}), 1);
    let clusterSetIdx = clusterIdx.x + clusterIdx.y * ${clustersDivX} + clusterIdx.z * ${clustersDivX} * ${clustersDivY};


    let diffuseColor = textureLoad(albedoTex, vec2u(in.fragPos.xy), 0).xyz;
    let normal = normalize(textureLoad(norTex, vec2u(in.fragPos.xy), 0).xyz);

    let curCluster = clusterSet.clusters[clusterSetIdx];
    let nLights = curCluster.numLights;
    let lightIndices = curCluster.lights;
    var totalLightContrib = vec3f(0, 0, 0);
    // // TODO I think working but running badly; will test on another computer
    // // return vec4f(f32(nLights) / 50.f, f32(nLights) / 50.f, f32(nLights) / 50.f, 1.f);
    for (var lightIdx = 0u; lightIdx < nLights; lightIdx++) {
        let light = lightSet.lights[lightIndices[lightIdx]];
        totalLightContrib += calculateLightContrib(light, pos, normal);
    }

    var finalColor = diffuseColor.rgb * totalLightContrib;
    return vec4(finalColor, 1);

}