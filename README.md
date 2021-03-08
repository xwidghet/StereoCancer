# StereoCancer
An open-source stereo-correct screen-space shader for Unity, mainly intended for usage in animations and games such as VRChat.

![](https://github.com/xwidghet/StereoCancer/blob/master/Example%20Gifs/kaleidescope_and_voroni_shader.gif?raw=true)
![](https://github.com/xwidghet/StereoCancer/blob/master/Example%20Gifs/overboard_shader.gif?raw=true)

# Distortion Effects
* Displacement Map
* Virtual Reality Eye Convergence and Separation 
* Shrink/Expand Width & Height  
* Rotation  
* Movement 
* Shake   
* Split  
* Skew  
* Bar  
* Sin Bar
* ZigZag  
* Sin, Cos, and Tan Wave  
* Slice  
* Water Ripple  
* Checkerboard  
* Quantization  
* Ring Rotation  
* Warp  
* Spiral  
* Polar Inversion  
* Fish Eye  
* Kaleidoscope 
* Block Displacement 
* Glitch  
* Simplex Noise  
* Voroni Noise 
* Fan 
* Geometric Dither  
* Color Displacement
* Normal Displacement

# Color Effects
* Image Overlay (Blended, Tiled, Clamped, Alpha-CutOff, Override Screen & Empty Space) 
* Triplanar Map  
* Scalable Static/TV Noise (Referred to as Signal Noise) 
* Movement Blur (Motion blur from original pixel position to final distorted position)  
* Chromatic Abberation 
* Circular Vignette
* Fog  
* Stripes
* Color Mask
* Color Palettization
* Color Inversion
* Color Modifiers (Rcp, Pow, Freedom, Acid, Quantization)  
* HSV Color Adjustment  
* Imaginary Color (Flipped color overlay for VR)  
* Sobel Filter (Outlines)
* RGB Color Displacement (Referred to as Red/Green/Blue Move)  
* Screen-Space Shader Opacity

# Display Settings
* Display Mode (Screen, Mirror, Both)
* Constrain UV Per-Eye  
* UV Wrap/Cutout/Clamp  
* World-Space UV Wrap/Cutout/Clamp   
* Coordinate Space (Screen, Projected)  
* Coordinate Scale  
* Coordinate Quantization, Rotation, and Offset separate from the screen.
  * Ex. Rotating all distortion effects without rotating the screen itself.
* Visibility (Global, Self Only, Others Only)  
* Falloff based on distance to the center of the cube.  
  * Supports applying falloff to the distortion, color, or both at the same time. This supports arbitrary scale and rotation of the cube object, so if you wanted a rectangular or a diamond shape falloff you can do that.
* Particle System Support

# Usage
1. Create a cube.
2. Adjust the scale of the cube. Anyone who enters the cube, or sees the cube, will see the screen-space shader.
    * The screen-space shader effects are independent of the object scale. So if you find it was too big or small, you can always adjust it later.
4. Add StereoCancer to your unity project.
5. Create a material from the StereoCancer shader, and put it on the cube.  
6. Adjust the parameters on the material to your liking, or create an animation.
   * At this point you may wish to enable Falloff to limit how far away people can be and still see the effect. Falloff can be found under Rendering Parameters -> Falloff Enabled -> Yes.

# Performance Considerations
This shader automatically optimizes for performance when the strength of an effect is reduced to 0. So in the interest of keeping what little performance the community gets in VRChat, please ensure unused effects on animations are actually fully disabled to allow the shader to run as efficiently as possible.

# Advanced Usage
I have added comments to this shader's implementation file (StereoCancer v0.1.shader) to hopefully make it easy for users to extend this shader, or write their own afterwards.
