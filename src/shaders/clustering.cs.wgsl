// TODO-2: implement the light clustering compute shader
// TODO I'm uncertain if this ought to be two passes? they describe it as such but not sure if we're doing any sort of excising of clusters between them?

@group(${bindGroup_scene}) @binding(0) var<storage, read_write> lightSet: LightSet;
@group(${bindGroup_scene}) @binding(1) var<storage, read_write> clusterSet: ClusterSet;
@group(${bindGroup_scene}) @binding(2) var<uniform> camera: CameraUniforms; 


// ------------------------------------
// Calculating cluster bounds:
// ------------------------------------
// For each cluster (X, Y, Z):
//     - Calculate the screen-space bounds for this cluster in 2D (XY).
//     - Calculate the depth bounds for this cluster in Z (near and far planes).
//     - Convert these screen and depth bounds into view-space coordinates.
//     - Store the computed bounding box (AABB) for the cluster.

// from talking w/ TAs can just do as one pass in this implementation since not required to skip empty clusters before light assignment
// fn calculateClusterBounds(vec3u clusterPos) {

// }
// TODO probably should do as two passes though and not rerun computation every time (only if frustum changes) if wanting to be optimal performance-wise though

// ------------------------------------
// Assigning lights to clusters:
// ------------------------------------
// For each cluster:
//     - Initialize a counter for the number of lights in this cluster.

//     For each light:
//         - Check if the light intersects with the cluster’s bounding box (AABB).
//         - If it does, add the light to the cluster's light list.
//         - Stop adding lights if the maximum number of lights is reached.

//     - Store the number of lights assigned to this cluster.

fn screenToView(screenPos : vec4f) -> vec4f{

    let ndcPos: vec2f = screenPos.xy / vec2f(f32(camera.screenWidth), f32(camera.screenHeight));
    let clipPos: vec4f = vec4f(vec2f(ndcPos.x, 1.0 - ndcPos.y) * 2.0 - 1.0, screenPos.z, screenPos.w);
    var viewPos: vec4f = camera.invProjMat * clipPos;
    viewPos = viewPos / viewPos.w;
    return viewPos;
}

// fn testSphereAABB(u32 ) // might just do in main since only need one call


@compute
@workgroup_size(${clustersWorkgroupX}, ${clustersWorkgroupY}, ${clustersWorkgroupZ})
fn main(@builtin(global_invocation_id) globalIdx: vec3u) {
    let clusterIdx = globalIdx;
    if (clusterIdx.x >= ${clustersDivX} || clusterIdx.y >= ${clustersDivY} || clusterIdx.z >= ${clustersDivZ}) {
        return;
    }

    const tileSizePx = 32.0; // TODO get actual val--pass in dimensions? can vary w/ window so not just constant
    let maxPointScreenSpace = vec4f((vec2f(clusterIdx.xy) + 1.0) * tileSizePx, -1.0, 1.0);
    let minPointScreenSpace = vec4f(vec2f(clusterIdx.xy) * tileSizePx, -1.0, 1.0);

    let maxPointViewSpace = screenToView(maxPointScreenSpace).xyz;
    let minPointViewSpace = screenToView(minPointScreenSpace).xyz;

    let tileNear = -camera.nearClip * pow(camera.farClip / camera.nearClip, f32(clusterIdx.z) / f32(clustersDivZ));
    let tileFar = -camera.nearClip * pow(camera.farClip / camera.nearClip, f32(clusterIdx.z + 1) / f32(clustersDivZ));

    let minPointNear = minPointViewSpace * (tileNear / minPointViewSpace.z);
    let minPointFar = minPointViewSpace * (tileFar / minPointViewSpace.z);
    let maxPointNear = maxPointViewSpace * (tileNear / maxPointViewSpace.z);
    let maxPointFar = maxPointViewSpace * (tileFar / maxPointViewSpace.z);

    // TODO surely this can be found consistently? following article but the check seems unnecessary
    let minPointAABB = min(min(minPointNear, minPointFar), min(maxPointNear, maxPointFar));
    let maxPointAABB = max(max(minPointNear, minPointFar), max(maxPointNear, maxPointFar));
    // TODO maybe will actually store these instead of recalculating each frame? but maybe this is actually better performance-wise (memory access?)?
    

    // note compared to articles linked in recitation that we're skipping the finding active clusters step here since not doing a depth prepass


    clusterSet[clusterIdx.x + clusterIdx.y * ${clustersDivX} + clusterIdx.z * ${clustersDivX} * ${clustersDivY}].numLights = 0;

    for (var i = 0; i < lightSet.numLights; ++i) {
        // lightSet.lights[i] // TODO AABB sphere test
    }

}