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

Both Forward+ and Clustered Deferred appeared to run signficantly faster than the naïve implementation. Even in the case of a single light (not shown above), the naïve implementation appeared to perform at-best equal in speed to the Forward+ implementation, suggesting the added cost of the compute shader to find the cluster bounds and sets of lights is so minor that it outweighs performing the light contribution for even a single light per fragment.

<img width="1518" height="937" alt="Screen Shot 2025-10-17 at 11 13 04 PM" src="https://github.com/user-attachments/assets/25306346-eaef-4ae2-a2ea-b96ede094642" />
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
