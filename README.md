WebGL Forward+ and Clustered Deferred Shading
======================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 4**

* Griffin Evans
* Tested on: Windows 11 Education, i9-12900F @ 2.40GHz 64.0GB, NVIDIA GeForce RTX 3090 (Levine 057 #1)

## Live Demo

[![](https://github.com/user-attachments/assets/4a9d0f67-d5cc-45ee-b87a-1c4527fc429b)](http://grievans.github.io/Project4-WebGPU-Forward-Plus-and-Clustered-Deferred)

(Click the above thumbnail to open; requires a WebGPU-capable browser.)

## Demo Video

https://github.com/user-attachments/assets/2940de4e-fda4-43f3-a6d6-8681a222f9d7


## Overview

This project is a WebGPU-based renderer which displays a scene containing a user-controllable number of moving point lights. Three rendering modes are included: 

- A naïve forward-rendering method, where the fragment shader iterates through all of the lights in the scene for each fragment in order to determine how that fragment is illuminated.
- A [Forward+ method](https://takahiroharada.wordpress.com/wp-content/uploads/2015/04/forward_plus.pdf), which divides the viewing frustum along its height, width, and depth to create [clusters](https://www.aortiz.me/2018/12/21/CG.html#clustered-shading) which we use to track the set of lights which will affect that cluster's volume, such that for each fragment we only need to iterate through the set of lights for the cluster it lies within.
- A Clustered Deferred method, which uses the same clustering as above but also performs two shading passes, first storing albedo, position, and normals in textures then running a second pass which uses these textures to perform the same light calculations as in Forward+, but now already having discarded any fragments that will be unseen according to the depth buffer.

## Analysis
<img width="1518" height="938" alt="Screen Shot 2025-10-17 at 11 13 12 PM" src="https://github.com/user-attachments/assets/d9cd5c10-2fa7-4b53-ad47-986593aa8429" />

Both Forward+ and Clustered Deferred appeared to run signficantly faster than the naïve implementation. Even in the case of a single light (not shown above), the naïve implementation appeared to perform at-best equal in speed to the Forward+ implementation, suggesting the added cost of the compute shader to find the cluster bounds and sets of lights is so minor that it outweighs performing the light contribution for even a single light per fragment. The deferred renderer is slightly slower in that very dark case, but increasing the number of lights to 15 already gives faster performance than the naïve (on a much weaker machine than the main one I tested on, naïve takes 23ms for 1 light and 52ms for 15 lights, whereas deferred takes a consistent 47ms for both 1 and 15 lights).

As the number of lights increases the margin in performance compared to the naïve case widens, with Forward+ taking 50ms per frame with 15,000 lights and the naïve method taking 706ms. Clustered Deferred rendering slows down even more gradually than Forward+, keeping a speed of 16ms per frame for 15,000 lights. At least for the hardware tested, Clustered Deferred seemed to be the most performant method in nearly every situation, with it only being slower in the case of very few lights, at which point all of the methods are fast enough that it hardly makes a difference.

<img width="1518" height="937" alt="Screen Shot 2025-10-17 at 11 13 04 PM" src="https://github.com/user-attachments/assets/25306346-eaef-4ae2-a2ea-b96ede094642" />

In either of the cluster-based methods, a tradeoff is present in the maximum number of lights allowed in each cluster. Since the clusters store lights indices in an array in order to track the set of lights affecting that cluster, the number of lights that can illuminate a surface in each cluster is limited by the length allocated for that array. When the number of lights within range of a cluster is greater than this limit, any excess lights will be ignored when shading the fragments within that cluster. Since the set of lights that fall within the cluster bounds varies between adjacent clusters, this can cause visible artifacts as the resulting illumination abruptly jumps in value, as in the video below:

https://github.com/user-attachments/assets/b403ec5b-0304-41c3-9d89-45fa22384763

*Above: 15,000 lights with max 511 lights per cluster*

For a limit of 511 lights per cluster (note: using one less than a power of 2 in order to align our array of cluster structs, where each cluster contains an array of light indices, each an unsigned 32-bit integer, and one 32-bit integer to denote the number of lights used in that array; 511 plus the extra integer to store the count is hence 512), we start seeing these artifacts when populating our scene with around 5,000 lights. Increasing the limit to 1023 lights reduces these artifacts significantly, but as we increase the light count past around 10,000 they can again be seen, though less dramatically than for a smaller maximum:

https://github.com/user-attachments/assets/c6e32f07-946a-489b-853f-57a939179629

*Above: 15,000 lights with max 1023 lights per cluster*

Further increasing the limit to 2047 lights per cluster appears to make the artifacts effectively disappear for even 15,000 lights:

https://github.com/user-attachments/assets/a9a1e595-4f4d-43aa-aff5-b755d4f29144

*Above: 15,000 lights with max 2047 lights per cluster*

Note that even with this high limit there are technically still clusters where the limit is reached. The videos below show the scene rendered as a gradient depending on the number of lights affecting each cluster. For all values below the limit per cluster, we show grayscale tones ranging from black for 0 lights to white for one less than our limit. All clusters at the limit appear instead in red, meaning that these should be areas where such artifacts may appear:

https://github.com/user-attachments/assets/412ad590-6385-4858-acba-08a276d85188

*Above: Debug view of 10,000 lights with max 1023 lights per cluster*


https://github.com/user-attachments/assets/1333481f-59ef-493d-8ce9-66d7b7205119

*Above: Debug view of 10,000 lights with max 2047 lights per cluster*

Note though that just because we hit the limit per cluster in some regions, this doesn't necessarily mean the effects of that limit will be visible to the human eye. Many of the lights may have very little influence on the illumination, and with so many lights present the illumination will be so bright that the color of the fragments there will be largely blown out anyways. Hence to the human eye 2047 lights per cluster appears sufficient for 15,000 lights even if we do fail to capture all the lights affecting the cluster in some instances.

Of course, inceasing the limit and the associated array's length does incur some performance detriments as there is more overhead for the reading and writing of this larger memory space, and the fragment shader takes longer as it has more lights it needs to iterate through (but in the cases where it does take longer it is resulting in a more accurately lit result). There is a slowdown as we increase the maximum, but this is not hugely significant—note that for the limits of 511 and 1023 in the Clustered Deferred renderer we actually see the larger size perform slightly faster. I would suspect that this greater speed is not actually indicative of 1023 being a faster option, but rather that it indicates that these configurations perform so similarly that the margin of performance variation between subsequent runs of the same program is greater than the difference caused by changing this limit.


<img width="1515" height="936" alt="Screen Shot 2025-10-17 at 11 14 06 PM" src="https://github.com/user-attachments/assets/c9440b97-688d-4db0-a438-7ebe979ff382" />
<img width="1517" height="937" alt="Screen Shot 2025-10-17 at 11 12 43 PM" src="https://github.com/user-attachments/assets/292a6843-e73e-4e6a-af54-b813ccb1b9e1" />

A factor which significantly impacted performance during development was the accidental copying of the cluster struct (and the light array within it) within the fragment shader for Foward+; removing this copying caused the draw time for 5000 lights with 1023 max lights per cluster and 16x8x32 clusters to lower from around 91ms to 13ms, a sevenfold division.

### Credits

- [Vite](https://vitejs.dev/)
- [loaders.gl](https://loaders.gl/)
- [dat.GUI](https://github.com/dataarts/dat.gui)
- [stats.js](https://github.com/mrdoob/stats.js)
- [wgpu-matrix](https://github.com/greggman/wgpu-matrix)
- https://www.aortiz.me/2018/12/21/CG.html#clustered-shading
- https://takahiroharada.wordpress.com/wp-content/uploads/2015/04/forward_plus.pdf
- https://hacks.mozilla.org/2014/01/webgl-deferred-shading/
