# StereoCancer
An open-source stereo-correct screen-space shader for Unity, mainly intended for usage in animations and games such as VRChat.

![](https://github.com/xwidghet/StereoCancer/blob/master/Example%20Gifs/kaleidescope_and_voroni_shader.gif?raw=true)
![](https://github.com/xwidghet/StereoCancer/blob/master/Example%20Gifs/overboard_shader.gif?raw=true)

# Features
Image Overlay (Blended, Tiled, Clamped, Alpha-Cutout)  
Rotation  
Movement  
Skew  
Bar  
ZigZag  
Wave  
Checkerboard  
Quantization  
Ring Rotation  
Warp  
Spiral  
Fish Eye  
Kaleidoscope  
Simplex Noise  
Voroni Noise  
Geometric Dither  
Stripes  
HSV Color Adjustment  
Scalable Static/TV Noise (Referred to as Signal Noise)  
RGB Color displacement (Referred to as Red/Green/Blue Move)  

# Usage
1. Create a cube.
2. Adjust the scale of the cube. Anyone who enters the cube, or sees the cube, will see the screen-space shader. The effects are independent of the object scale. So if you find it was too big or too small, you can always adjust it later.
3. Create a material from the StereoCancer shader, and put it on the cube.
4. Adjust the parameters on the material to your liking, or create an animation.
