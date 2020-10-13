Shader "xwidghet/StereoCancer v0.1"
{
	// A collection of effects made by xwidghet to allow for creating dynamic stereo-correct shader animations
	// which can be combined together without creating massive performance issues.
	//
	// This has only been tested on the Valve Index, VRChat Desktop mode and Unity Editor.
	// However I haven't heard from anyone I know using the HTC Vive, Oculus CV1, or Samsung Odyssey+ complain
	// about anything causing issues. I would be interested to know if features like meme images work
	// correctly on high FOV headsets such as the ones from Pimax.
	//
	// Effect implementations take parameters, rather than reading the shader parameters
	// directly, to allow for combining them together to create more powerful effects
	// without copy-pasting code. 
	//
	// ex. Geometric Dither is created by using Skew repeatedly with varying parameter values
	//
	// LICENSE: This shader is licensed under GPL V3 as it makes usage of
	//			CancerSpace's mirror check which inherently means this must be
	//			licensed under the same GPL V3 license.
	//			https://www.gnu.org/licenses/gpl-3.0.en.html
	//
	//			This shader makes use of the perlin noise generator from https://github.com/keijiro/NoiseShader
	//			which is licensed under the MIT License.
	//			https://opensource.org/licenses/MIT
	//
	//			This shader also makes use of the voroni noise generator created by Ronja Bohringer,
	//			which is licensed under the CC-BY 4.0 license (https://creativecommons.org/licenses/by/4.0/)
	//			https://github.com/ronja-tutorials/ShaderTutorials
	//
	//			Various math helpers shared on the internet without an explicitly stated license
	//			are included in CancerHelper.cginc.
	//			Math helpers written by me start at the comment "// Begin xwidghet helpers"
	//			and end before the comment "// End xwidghet helpers".
	//
	//			See LICENSE for more info.

	Properties
	{
		[Header(Rendering Parameters)]
		_CancerOpacity("Cancer Opacity", Float) = 1
		[Enum(Screen,0, Mirror,1, Both,2)] _CancerDisplayMode("Cancer Display Mode", Float) = 0
		[Enum(Clamp,0, Eye Clamp,1, Wrap,2)] _ScreenSamplingMode("Screen Sampling Mode", Float) = 0
		[Enum(Screen,0, Projected (Requires Directional Light),1)] _CoordinateSpace("Coordinate Space", Float) = 0
		_CoordinateScale("Coordinate Scale", Float) = 1
		_WorldCoordinatesWrapValue("Wrap World Coordinates", Range(0, 1)) = 0
		[Enum(Global,0, SelfOnly,1, OthersOnly,2)] _Visibility("Visibility", Float) = 0

		[Enum(No,0, Yes,1)] _ParticleSystem("Particle System", Int) = 0

		// VR Effects
		[Header(Virtual Reality Effects)]
		_EyeConvergence("Eye Convergence", Range(-3.1415926, 3.1415926)) = 0
		_EyeSeparation("Eye Separation", Float) = 0

		// Image Effects
		[Header(Image Overlay)]
		_MemeTex("Meme Image (RGB)", 2D) = "white" {}
		_MemeImageColumns("Meme Image Columns", Int) = 1
		_MemeImageRows("Meme Image Rows", Int) = 1
		_MemeImageCount("Meme Image Count", Int) = 1
		_MemeImageIndex("Meme Image Index", Int) = 0
		_MemeImageAngle("Meme Image Angle", Float) = 0
		_MemeTexOpacity("Meme Opacity", Float) = 0
		[Enum(No,0, Yes,1)] _MemeTexClamp("Meme Clamp", Int) = 0
		[Enum(No,0, Yes,1)] _MemeTexCutOut("Meme Cut Out", Int) = 0
		_MemeTexAlphaCutOff("Meme Alpha CutOff", Float) = 0.9
		[Enum(None,0, Background,1, Empty Space,2)] _MemeTexOverrideMode("Meme Screen Override Mode", Float) = 0

		// Displacement Map Map Displacement \\/
		[Header(Displacement Map)]
		_DisplacementMap("Displacement Map (RGB)", 2D) = "white" {}
		[Enum(Normal,0, Color,1)] _DisplacementMapType("Displacement Map Type", Int) = 1
		_DisplacementMapColumns("Displacement Map Columns", Int) = 1
		_DisplacementMapRows("Displacement Map Rows", Int) = 1
		_DisplacementMapCount("Displacement Map Count", Int) = 1
		_DisplacementMapIndex("Displacement Map Index", Int) = 0
		_DisplacementMapAngle("Displacement Map Angle", Float) = 0
		_DisplacementMapIntensity("Displacement Map Intensity", Float) = 0
		[Enum(No,0, Yes,1)] _DisplacementMapClamp("Displacement Map Clamp", Int) = 0
		[Enum(No,0, Yes,1)] _DisplacementMapCutOut("Displacement Map Cut Out", Int) = 0

		// Triplanar Map
		[Header(Triplanar Map)]
		_TriplanarMap("Triplanar Map (RGB)", 2D) = "white" {}
		[Enum(Map, 0, Screen, 1)]_TriplanarSampleSrc("Triplanar Sample Source", Float) = 0
		[Enum(WorldPos, 0, WorldNormal, 1, ViewNormal, 2)]_TriplanarCoordinateSrc("Triplanar Coordinate Source", Float) = 0
		_TriplanarScale("Triplanar Coordinate Scale", Float) = 1
		_TriplanarOffsetX("Triplanar Offset X", Float) = 0
		_TriplanarOffsetY("Triplanar Offset Y", Float) = 0
		_TriplanarOffsetZ("Triplanar Offset Z", Float) = 0
		_TriplanarSharpness("Triplanar Sharpness", Float) = 2
		[Enum(Low, 0, High (Requires Directional Light),1)]_TriplanarQuality("Triplanar Quality", Float) = 1
		[Enum(None, 0, Multiply, 1, MulAdd, 2)]_TriplanarBlendMode("Triplanar Blend Mode", Float) = 1
		_TriplanarOpacity("Triplanar Opacity", Float) = 0

		// Screen Distortion Effects
		[Header(Screen Distortion Effects)]
		_ShrinkWidth("Shrink Width", Float) = 0
		_ShrinkHeight("Shrink Height", Float) = 0
		
		_RotationX("Rotation X (Pitch Down-/Up+)", Float) = 0
		_RotationY("Rotation Y (Yaw Left-/Right+)", Float) = 0
		_RotationZ("Rotation Z (Roll Left-/Right+)", Float) = 0
		
		_MoveX("Move X (Left-/Right+)", Float) = 0
		_MoveY("Move Y (Down-/Up+)", Float) = 0
		_MoveZ("Move Z (Forward-/Back+)", Float) = 0

		_ScreenShakeSpeed("Screen Shake Speed", Float) = 50
		_ScreenShakeXIntensity("Screen Shake X Intensity", Float) = 0
		_ScreenShakeXAmplitude("Screen Shake X Amplitude", Float) = 10
		_ScreenShakeYIntensity("Screen Shake Y Intensity", Float) = 0
		_ScreenShakeYAmplitude("Screen Shake Y Amplitude", Float) = 10
		_ScreenShakeZIntensity("Screen Shake Z Intensity", Float) = 0
		_ScreenShakeZAmplitude("Screen Shake Z Amplitude", Float) = 10

		_SplitXAngle("Split X Angle", Float) = 0
		_SplitXDistance("Split X Distance", Float) = 0
		_SplitXHalf("Split X Half", Float) = 0

		_SplitYAngle("Split Y Angle", Float) = 0
		_SplitYDistance("Split Y Distance", Float) = 0
		_SplitYHalf("Split Y Half", Float) = 0

		_SkewXAngle("Skew X Angle", Float) = 0
		_SkewXDistance("Skew X Distance", Float) = 0
		_SkewXInterval("Skew X Interval", Float) = 0
		_SkewXOffset("Skew X Offset", Float) = 0

		_SkewYAngle("Skew Y Angle", Float) = 0
		_SkewYDistance("Skew Y Distance", Float) = 0
		_SkewYInterval("Skew Y Interval", Float) = 0
		_SkewYOffset("Skew Y Offset", Float) = 0

		_BarXAngle("Bar X Angle", Float) = 0
		_BarXDistance("Bar X Distance", Float) = 0
		_BarXInterval("Bar X Interval", Float) = 0
		_BarXOffset("Bar X Offset", Float) = 0
		
		_BarYAngle("Bar Y Angle", Float) = 0
		_BarYDistance("Bar Y Distance", Float) = 0
		_BarYInterval("Bar Y Interval", Float) = 0
		_BarYOffset("Bar Y Offset", Float) = 0

		_SinBarXAngle("Sin Bar X Angle", Float) = 0
		_SinBarXDistance("Sin Bar X Distance", Float) = 0
		_SinBarXInterval("Sin Bar X Interval", Float) = 0
		_SinBarXOffset("Sin Bar X Offset", Float) = 0

		_SinBarYAngle("Sin Bar Y Angle", Float) = 0
		_SinBarYDistance("Sin Bar Y Distance", Float) = 0
		_SinBarYInterval("Sin Bar Y Interval", Float) = 0
		_SinBarYOffset("Sin Bar Y Offset", Float) = 0

		_ZigZagXAngle("ZigZag X Angle", Float) = 0
		_ZigZagXDensity("ZigZag X Density", Float) = 0
		_ZigZagXAmplitude("ZigZag X Amplitude", Float) = 0
		_ZigZagXOffset("ZigZag X Offset", Float) = 0

		_ZigZagYAngle("ZigZag Y Angle", Float) = 0
		_ZigZagYDensity("ZigZag Y Density", Float) = 0
		_ZigZagYAmplitude("ZigZag Y Amplitude", Float) = 0
		_ZigZagYOffset("ZigZag Y Offset", Float) = 0

		_SinWaveAngle("Sin Wave Angle", Float) = 0
		_SinWaveDensity("Sin Wave Density", Float) = 0
		_SinWaveAmplitude("Sin Wave Amplitude", Float) = 0
		_SinWaveOffset("Sin Wave Offset", Float) = 0

		_CosWaveAngle("Cos Wave Angle", Float) = 0
		_CosWaveDensity("Cos Wave Density", Float) = 0
		_CosWaveAmplitude("Cos Wave Amplitude", Float) = 0
		_CosWaveOffset("Cos Wave Offset", Float) = 0

		_TanWaveAngle("Tan Wave Angle", Float) = 0
		_TanWaveDensity("Tan Wave Density", Float) = 0
		_TanWaveAmplitude("Tan Wave Amplitude", Float) = 0
		_TanWaveOffset("Tan Wave Offset", Float) = 0

		_SliceAngle("Slice Angle", Float) = 0
		_SliceWidth("Slice Width", Float) = 0
		_SliceDistance("Slice Distance", Float) = 0
		_SliceOffset("Slice Offset", Float) = 0

		_RippleDensity("Ripple Density", Float) = 0
		_RippleAmplitude("Ripple Amplitude", Float) = 0
		_RippleOffset("Ripple Offset", Float) = 0
		_RippleFalloff("Ripple Falloff", Float) = 0

		_CheckerboardAngle("Checkerboard Angle", Float) = 0
		_CheckerboardScale("Checkerboard Scale", Float) = 0
		_CheckerboardShift("Checkerboard Shift Distance", Float) = 0
		_Quantization("Quantization", Range(0,1)) = 0

		_RingRotationAngle("Ring Rotation Angle", Float) = 3.1415926
		_RingRotationRadius("Ring Rotation Radius", Float) = 0
		_RingRotationWidth("Ring Rotation Width", Float) = 0

		_WarpIntensity("Warp Intensity", Float) = 0
		_WarpAngle("Warp Angle", Float) = 0

		_SpiralIntensity("Spiral Intensity", Float) = 0

		_FishEyeIntensity("Fish Eye Intensity", Float) = 0

		_KaleidoscopeSegments("Kaleidoscope Segments", Range(0,32)) = 0
		_KaleidoscopeAngle("Kaleidoscope Angle", Float) = 0

		_BlockDisplacementAngle("Block Displacement Angle", Float) = 0
		_BlockDisplacementSize("Block Displacement Size", Float) = 0
		_BlockDisplacementIntensity("Block Displacement Intensity", Float) = 0
		[Enum(Smooth, 0, Random, 1)] _BlockDisplacementMode("Block Displacement Mode", Float) = 0
		_BlockDisplacementOffset("Block Displacement Offset", Float) = 0

		_GlitchAngle("Glitch Angle", Float) = 0
		_GlitchCount("Glitch Count", Range(0, 32)) = 0
		_MinGlitchWidth("Min Glitch Width", Float) = 0
		_MinGlitchHeight("Min Glitch Height", Float) = 0
		_MaxGlitchWidth("Max Glitch Width", Float) = 0
		_MaxGlitchHeight("Max Glitch Height", Float) = 0
		_GlitchIntensity("Glitch Intensity", Float) = 0
		_GlitchSeed("Glitch Seed", Float) = 0
		_GlitchSeedInterval("Glitch Seed Interval", Float) = 1

		_NoiseScale("Simplex Noise Scale", Float) = 0
		_NoiseStrength("Simplex Noise Strength", Float) = 0
		_NoiseOffset("Simplex Noise Offset", Float) = 0

		_VoroniNoiseScale("Voroni Noise Scale", Float) = 0
		_VoroniNoiseStrength("Voroni Noise Strength", Float) = 0
		_VoroniNoiseBorderSize("Voroni Border Size", Float) = 0
		[Enum(NoEffect,0, Multiply,1, EmptySpace, 2)] _VoroniNoiseBorderMode("Voroni Border Mode", Float) = 0
		_VoroniNoiseBorderStrength("Voroni Noise Border Strength", Float) = 1
		_VoroniNoiseOffset("Voroni Noise Offset", Float) = 0

		_GeometricDitherDistance("Geometric Dither Distance", Float) = 0
		_GeometricDitherQuality("Geometric Dither Quality", Range(1, 6)) = 5
		_GeometricDitherRandomization("Geometric Dither Randomization", Float) = 0

		_ColorVectorDisplacementStrength("Color Vector Displacement Strength", Float) = 0
		[Enum(View, 0, World, 1)] _ColorVectorDisplacementCoordinateSpace("Color Vector Displacement Coordinate Space", Float) = 1

		_NormalVectorDisplacementStrength("Normal Vector Displacement Strength", Float) = 0
		[Enum(View, 0, World, 1)] _NormalVectorDisplacementCoordinateSpace("Normal Vector Displacement Coordinate Space", Float) = 1
		[Enum(Low, 0, High (Requires Directional Light), 1)] _NormalVectorDisplacementQuality("Normal Vector Displacement Quality", Float) = 1

		// Screen color effects
		[Header(Screen Color Effects)]
		_SignalNoiseSize("Signal Noise Size", Float) = 0
		_ColorizedSignalNoise("Signal Noise Colorization", Float) = 0
		_SignalNoiseOpacity("Signal Noise Opacity", Float) = 0

		_BlurMovementSampleCount("Blur Movement Sample Count", Range(1, 42)) = 30
		_BlurMovementTarget("Blur Movement Target", Range(0, 1)) = 0.5
		_BlurMovementRange("Blur Movement Range", Range(0.001, 1)) = 1
		_BlurMovementExtrapolation("Blur Movement Extrapolation", Range(0, 1)) = 0
		_BlurMovementOpacity("Blur Movement Opacity", Range(0, 1)) = 0

		_ChromaticAbberationStrength("Chromatic Abberation Strength", Float) = 0
		_ChromaticAbberationSeparation("Chromatic Abberation Separation", Float) = 1.5
		[Enum(Spherical, 0, Flat, 1)] _ChromaticAbberationShape("Chromatic Abberation Shape", Float) = 0

		_CircularVignetteColor("Circular Vignette Color", Color) = (0, 0, 0, 1)
		_CircularVignetteOpacity("Circular Vignette Opacity", Range(0, 1)) = 0
		[Enum(Linear, 0, Squared, 1, Log2, 2)] _CircularVignetteMode("Circular Vignette Mode", Float) = 2
		_CircularVignetteRoundness("Circular Vignette Roundness", Range(0, 1)) = 1
		_CircularVignetteBegin("Circular Vignette Begin Distance", Float) = 25
		_CircularVignetteEnd("Circular Vignette End Distance", Float) = 50
			
		_EdgelordStripeColor("Edgelord Stripe Color", Color) = (0, 0, 0, 1)
		_EdgelordStripeSize("Edgelord Stripe Size", Float) = 0
		_EdgelordStripeOffset("Edgelord Stripe Offset", Float) = 0

		_ColorMask("Color Mask", Color) = (1, 1, 1, 1)

		_Hue("Hue", Float) = 0
		_Saturation("Saturation", Float) = 0
		_Value("Value", Float) = 0

		[Enum(Multiply, 0, Add, 1, MulAdd, 2)] _ImaginaryColorBlendMode("Imaginary Color Blend Mode", Float) = 2
		_ImaginaryColorOpacity("Imaginary Color Opacity", Float) = 0
		_ImaginaryColorAngle("Imaginary Color Angle", Float) = 0

		_colorSkewRDistance("Red Move Distance", Float) = 0
		_colorSkewRAngle("Red Move Angle", Float) = 0
		_colorSkewROpacity("Red Move Opacity", Float) = 0
		_colorSkewROverride("Red Move Override", Float) = 0

		_colorSkewGDistance("Green Move Distance", Float) = 0
		_colorSkewGAngle("Green Move Angle", Float) = 0
		_colorSkewGOpacity("Green Move Opacity", Float) = 0
		_colorSkewGOverride("Green Move Override", Float) = 0

		_colorSkewBDistance("Blue Move Distance", Float) = 0
		_colorSkewBAngle("Blue Move Angle", Float) = 0
		_colorSkewBOpacity("Blue Move Opacity", Float) = 0
		_colorSkewBOverride("Blue Move Override", Float) = 0
	}
	SubShader
	{
		// Attempt to draw ourselves after all normal avatar and world draws
		// Opaque = 2000, Transparent = 3000, Overlay = 4000
		// Note: As of VRChat 2018 update, object draws are clamped
		//		 to render queue 4000, and particles to 5000.
		Tags { "Queue" = "Overlay" }

		// Don't write depth, and ignore the current depth.
		Cull Front ZWrite Off ZTest Off

		// Blend against the current screen texture to allow for
		// fading in/out the cancer effects and various other shenanigans.
		Blend SrcAlpha OneMinusSrcAlpha
		
		// Grab Pass textures are shared by name, so this must be a unique name.
		// Otherwise we'll get the screen texture from the time the first object rendered
		//
		// Thus when using this shader, or any other public GrabPass based shader,
		// you should use your own name to avoid users being able to break your shader.
		//
		// ex. Rendering an invisible object at render queue '0' to make everyone using
		//	   the label '_backgroundTexture' render nothing.
		//
		// If you would like to layer multiple StereoCancer shaders, then the additional
		// shaders should user their own label otherwise like stated above, you'll get
		// just the original cancer-free texture.
		//
		// Ex. _stereoCancerTexture1, _stereoCancerTexture2
		//
		// Note: If you modify this label, then the following variables will need to be renamed
		//		 along with all of their references to match: 
		//			sampler2D _stereoCancerTexture;
		//			float4 _stereoCancerTexture_TexelSize;

		GrabPass
		{
			"_stereoCancerTexture"
		}

		Pass
		{
			CGPROGRAM
			// Request Shader Model 5.0 to increase our uniform limit.
			// VRChat runs on DirectX 11 so this should be supported by all GPUs.
			#pragma target 5.0

			#pragma vertex vert
			#pragma fragment frag
			
			// Unity default includes
			#include "UnityCG.cginc"

			// Math Helpers
			#include "CancerHelper.cginc"
			#include "SimplexNoise.cginc"
			#include "VoroniNoise.cginc"

			// Stereo Cancer function implementations
			#include "StereoCancerFunctions.cginc"
			
			int _ParticleSystem;
			float _CoordinateSpace;
			float _CoordinateScale;
			float _WorldCoordinatesWrapValue;
			float _Visibility;
			
			// Image Overlay params
			sampler2D _MemeTex;
			float4 _MemeTex_TexelSize;
			float4 _MemeTex_ST;
			int _MemeImageColumns;
			int _MemeImageRows;
			int _MemeImageCount;
			int _MemeImageIndex;
			float _MemeImageAngle;
			float _MemeTexOpacity;
			int _MemeTexClamp;
			int _MemeTexCutOut;
			float _MemeTexAlphaCutOff;
			float _MemeTexOverrideMode;

			sampler2D _stereoCancerTexture;
			float4 _stereoCancerTexture_TexelSize;

			sampler2D _CameraDepthTexture;
			float4 _CameraDepthTexture_TexelSize;

			float _CancerOpacity;

			// Displacement Map params
			sampler2D _DisplacementMap;
			float4 _DisplacementMap_TexelSize;
			float4 _DisplacementMap_ST;
			int _DisplacementMapType;
			int _DisplacementMapColumns;
			int	_DisplacementMapRows;
			int	_DisplacementMapCount;
			int	_DisplacementMapIndex;
			float _DisplacementMapAngle;
			float _DisplacementMapIntensity;
			int _DisplacementMapClamp;
			int _DisplacementMapCutOut;

			// Triplanar params
			sampler2D _TriplanarMap;
			float4 _TriplanarMap_ST;
			float _TriplanarSampleSrc;
			float _TriplanarCoordinateSrc;
			float _TriplanarScale;
			float _TriplanarOffsetX;
			float _TriplanarOffsetY;
			float _TriplanarOffsetZ;
			float _TriplanarSharpness;
			float _TriplanarQuality;
			float _TriplanarBlendMode;
			float _TriplanarOpacity;

			// Screen distortion params
			float _ShrinkWidth;
			float _ShrinkHeight;

			float _EyeConvergence;
			float _EyeSeparation;

			float _RotationX;
			float _RotationY;
			float _RotationZ;

			float _MoveX;
			float _MoveY;
			float _MoveZ;

			float _ScreenShakeSpeed;
			float _ScreenShakeXIntensity;
			float _ScreenShakeXAmplitude;
			float _ScreenShakeYIntensity;
			float _ScreenShakeYAmplitude;
			float _ScreenShakeZIntensity;
			float _ScreenShakeZAmplitude;

			float _SplitXAngle;
			float _SplitXDistance;
			float _SplitXHalf;

			float _SplitYAngle;
			float _SplitYDistance;
			float _SplitYHalf;

			float _SkewXAngle;
			float _SkewXDistance;
			float _SkewXInterval;
			float _SkewXOffset;

			float _SkewYAngle;
			float _SkewYDistance;
			float _SkewYInterval;
			float _SkewYOffset;

			float _GeometricDitherDistance;
			float _GeometricDitherQuality;
			float _GeometricDitherRandomization;

			float _ColorVectorDisplacementStrength;
			float _ColorVectorDisplacementCoordinateSpace;

			float _NormalVectorDisplacementStrength;
			float _NormalVectorDisplacementCoordinateSpace;
			float _NormalVectorDisplacementQuality;

			float _WarpIntensity;
			float _WarpAngle;

			float _BarXAngle;
			float _BarXDistance;
			float _BarXInterval;
			float _BarXOffset;

			float _BarYAngle;
			float _BarYDistance;
			float _BarYInterval;
			float _BarYOffset;

			float _SinBarXAngle;
			float _SinBarXDistance;
			float _SinBarXInterval;
			float _SinBarXOffset;

			float _SinBarYAngle;
			float _SinBarYDistance;
			float _SinBarYInterval;
			float _SinBarYOffset;

			float _CheckerboardAngle;
			float _CheckerboardScale;
			float _CheckerboardShift;
			float _Quantization;

			float _RingRotationAngle;
			float _RingRotationRadius;
			float _RingRotationWidth;

			float _SpiralIntensity;

			float _FishEyeIntensity;

			float _SinWaveAngle;
			float _SinWaveDensity;
			float _SinWaveAmplitude;
			float _SinWaveOffset;

			float _CosWaveAngle;
			float _CosWaveDensity;
			float _CosWaveAmplitude;
			float _CosWaveOffset;

			float _TanWaveAngle;
			float _TanWaveDensity;
			float _TanWaveAmplitude;
			float _TanWaveOffset;

			float _SliceAngle;
			float _SliceWidth;
			float _SliceDistance;
			float _SliceOffset;

			float _RippleDensity;
			float _RippleAmplitude;
			float _RippleOffset;
			float _RippleFalloff;

			float _ZigZagXAngle;
			float _ZigZagXDensity;
			float _ZigZagXAmplitude;
			float _ZigZagXOffset;

			float _ZigZagYAngle;
			float _ZigZagYDensity;
			float _ZigZagYAmplitude;
			float _ZigZagYOffset;

			float _KaleidoscopeSegments;
			float _KaleidoscopeAngle;

			float _BlockDisplacementAngle;
			float _BlockDisplacementSize;
			float _BlockDisplacementIntensity;
			float _BlockDisplacementMode;
			float _BlockDisplacementOffset;

			float _GlitchAngle;
			float _GlitchCount;
			float _MinGlitchWidth;
			float _MinGlitchHeight;
			float _MaxGlitchWidth;
			float _MaxGlitchHeight;
			float _GlitchIntensity;
			float _GlitchSeed;
			float _GlitchSeedInterval;

			float _NoiseScale;
			float _NoiseStrength;
			float _NoiseOffset;

			float _VoroniNoiseScale;
			float _VoroniNoiseStrength;
			float _VoroniNoiseBorderSize;
			float _VoroniNoiseBorderMode;
			float _VoroniNoiseBorderStrength;
			float _VoroniNoiseOffset;

			// Screen color params
			float4 _EdgelordStripeColor;
			float _EdgelordStripeSize;
			float _EdgelordStripeOffset;

			float4 _ColorMask;

			float _Hue;
			float _Saturation;
			float _Value;

			float _ImaginaryColorBlendMode;
			float _ImaginaryColorOpacity;
			float _ImaginaryColorAngle;

			float _BlurMovementSampleCount;
			float _BlurMovementTarget;
			float _BlurMovementRange;
			float _BlurMovementExtrapolation;
			float _BlurMovementOpacity;

			float _ChromaticAbberationStrength;
			float _ChromaticAbberationSeparation;
			float _ChromaticAbberationShape;

			float _SignalNoiseSize;
			float _ColorizedSignalNoise;
			float _SignalNoiseOpacity;

			float4 _CircularVignetteColor;
			float _CircularVignetteOpacity;
			float _CircularVignetteRoundness;
			float _CircularVignetteMode;
			float _CircularVignetteBegin;
			float _CircularVignetteEnd;

			float _colorSkewRDistance;
			float _colorSkewRAngle;
			float _colorSkewROpacity;
			float _colorSkewROverride;

			float _colorSkewGDistance;
			float _colorSkewGAngle;
			float _colorSkewGOpacity;
			float _colorSkewGOverride;

			float _colorSkewBDistance;
			float _colorSkewBAngle;
			float _colorSkewBOpacity;
			float _colorSkewBOverride;

			// For some magic reason, these have to be down here or the shader explodes.
			float _CancerDisplayMode;
			float _ScreenSamplingMode;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;

				// For getting particle position and scale
				float4 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 worldPos: TEXCOORD1;
				float3 camFront : TEXCOORD2;
				float3 camRight : TEXCOORD3;
				float3 camUp : TEXCOORD4;
				float3 camPos : TEXCOORD5;
				float3x3 viewMatRot : TEXCOORD6;
				float3x3 inverseViewMatRot : TEXCOORD9;
				float4 pos : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;

				// I could normalize the direction vectors, or I could just live dangerously
				// with reckless abandon to save insignificant amounts of performance.
				//
				// Note: This does not utilize cross products to avoid the issue where
				//		 at certain rotations the Up and Right vectors will flip.
				//		 (Roll of +-30 degrees and +-90 degrees).
				o.camFront = mul((float3x3)unity_CameraToWorld, float3(0, 0, 1));
				o.camUp = mul((float3x3)unity_CameraToWorld, float3(0, 1, 0));
				o.camRight = mul((float3x3)unity_CameraToWorld, float3(1, 0, 0));

				o.viewMatRot = extract_rotation_matrix(UNITY_MATRIX_V);
				o.inverseViewMatRot = transpose(o.viewMatRot);

				// The particle knows where it is, and where it isn't.
				// It subtracts where it is, from where it isn't,
				// to move vertices to where they wasn't.
				//
				// Usage: Set the following Renderer settings for the particle system
				//		  Render Alignment: World
				//		  Custom Vertex Streams:
				//				Position (POSITION.xyz)
				//				Center   (TEXCOORD0.xyz)
				//				Size.x   (TEXCOORD0.w)
				if (_ParticleSystem == 1)
				{
					// Move particle back to the coordinates (0,0,0)
					// and remove scaling.
					float3 particleSystemOrigin = v.uv.xyz;
					v.vertex.xyz -= particleSystemOrigin;

					v.vertex.xyz *= rcp(v.uv.w);
				}
				
				// Scale the shape so that the user isn't able to see the sides
				// of the object being shaded. Some maps use a small maximum
				// Z distance, so the Z-Axis must be scaled a smaller amount.
				v.vertex.xy *= 10000;
				v.vertex.z *= 100;

				// Rotate the object to match the user's view direction
				// and then place it onto their face
				//
				// I'm pretty sure I could do this without any matrix math.
				// However the current implementation is fully tested to have no issues,
				// and when I'm only going to be calcualting a grand total of
				// 8 verts it won't make a real-world performance difference.
				//
				// Hey, remember that comment above about saving insignificant amounts
				// of performance...?
				o.worldPos = float4(mul(o.inverseViewMatRot, v.vertex), 1);

				// Apparently the built-in _WorldSpaceCameraPos can't be trusted...so manually access the camera position.
				o.camPos = float3(unity_CameraToWorld[0][3], unity_CameraToWorld[1][3], unity_CameraToWorld[2][3]);
				o.worldPos.xyz += o.camPos;

				o.pos = mul(UNITY_MATRIX_VP, o.worldPos);

				// Align world pos with default world axis.
				//
				// This makes it easy to write effects as the coordinates
				// are all on a 2D XY plane, 100 units away from the camera.
				o.worldPos.xyz = v.vertex.xyz;

				// If visiblity isn't global...
				if (_Visibility > 0)
				{
					// Assumes the following:
					// Object is parented to the head
					// Object has a scale of 10,000 in all axes.

					// If the Y scale hasn't been multiplied by 0.0001 then it is not the user of the avatar
					// (or their viewball has drifted far away from their head).
					bool isOther = length(float3(UNITY_MATRIX_M[1][0], UNITY_MATRIX_M[1][1], UNITY_MATRIX_M[1][2])) >= 10;
					
					// Self Only
					if (_Visibility == 1 && (isOther == true))
						o.pos = float4(9999, 9999, 9999, 9999);
					// Others Only...I'm so sorry.
					else if (_Visibility == 2 && (isOther == false))
						o.pos = float4(9999, 9999, 9999, 9999);
				}

				// Evicts the vertex to outer-space when visibility doesn't match the display mode.
				if(mirrorCheck(_CancerDisplayMode))
					o.pos = float4(9999, 9999, 9999, 9999);
				
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// Discards when visibility doesn't match the display mode.
				if (mirrorCheck(_CancerDisplayMode))
					discard;
				
				// Vector from the 'camera' to the world-axis aligned worldPos.
				float3 worldVector = normalize(i.worldPos);

				// Projected coordinate space
				if (_CoordinateSpace == 1)
				{
					// Convert from world-axis aligned coordinates to world space coordinates.
					i.worldPos.xyz = mul(i.inverseViewMatRot, i.worldPos.xyz);
					i.worldPos.xyz += i.camPos;

					// Reconstruct view coordinates from depth
					float4 uv = computeStereoUV(i.worldPos);
					float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, uv);
					
					// Use the length of the reconstructed view ray to adjust our position
					// and retain the custom world-axis aligned coordinate system.
					depth = length(viewPosFromDepth(inverse(UNITY_MATRIX_P), uv.xy / uv.w, depth));
					i.worldPos.xyz = worldVector.xyz * depth;
				}

				// Allow for easily changing effect intensities without having to modify
				// an entire animation. Also very useful for adjusting projected coordinates.
				i.worldPos.xyz *= _CoordinateScale;

				// Store the starting position to allow for things like using the
				// derivative (ddx, ddy) to calculate nearby positions to sample depth.
				float4 startingAxisAlignedPos = i.worldPos;
				float4 startingWorldPos = startingAxisAlignedPos;
				startingWorldPos.xyz = mul(i.inverseViewMatRot, startingWorldPos.xyz);
				startingWorldPos.xyz += i.camPos;

				// Default world-axis values for usage with axis-based effects
				const float3 axisFront = float3(0, 0, -1);
				const float3 axisRight = float3(1, 0, 0);
				const float3 axisUp = float3(0, 1, 0);

				// Allow for functions which create empty space
				bool clearPixel = false;

				// Uniforms (Shader Parameters in Unity) can be branched on to successfully
				// avoid taking the performance hit of unused effects. This is used on every
				// effect with the most intuitive value to automatically improve performance.

				// Note: Not all effects contain all of the final parameters since I don't
				//		 know how many effects I will add yet, and don't want to have to
				//		 remove parameters users are using to make space for effects.

				  ////////////////////////////////////
				 // Apply Virtual Reality Effects ///
				////////////////////////////////////
				UNITY_BRANCH
				if (_EyeConvergence != 0)
					i.worldPos = stereoEyeConvergence(i.worldPos, axisUp, _EyeConvergence);

				UNITY_BRANCH
				if(_EyeSeparation != 0)
					i.worldPos = stereoEyeSeparation(i.worldPos, axisRight, _EyeSeparation);

				  //////////////////////////////////////////
				 // Apply World-Space Distortion Effects //
				//////////////////////////////////////////
				UNITY_BRANCH
				if (_ShrinkHeight != 0)
					i.worldPos = shrink(worldVector, axisUp, i.worldPos, _ShrinkHeight);
				UNITY_BRANCH
				if (_ShrinkWidth != 0)
					i.worldPos = shrink(worldVector, axisRight, i.worldPos, _ShrinkWidth);

				UNITY_BRANCH
				if(_RotationX != 0)
					i.worldPos = stereoRotate(i.worldPos, axisRight, _RotationX);
				UNITY_BRANCH
				if (_RotationY != 0)
					i.worldPos = stereoRotate(i.worldPos, axisUp, _RotationY);
				UNITY_BRANCH
				if (_RotationZ != 0)
					i.worldPos = stereoRotate(i.worldPos, axisFront, _RotationZ);

				i.worldPos.xyz += float3(_MoveX, _MoveY, _MoveZ);

				UNITY_BRANCH
				if(_ScreenShakeXIntensity != 0 || _ScreenShakeYIntensity != 0 || _ScreenShakeZIntensity != 0)
					i.worldPos = stereoShake(i.worldPos, _ScreenShakeSpeed, _ScreenShakeXIntensity, _ScreenShakeXAmplitude, _ScreenShakeYIntensity, _ScreenShakeYAmplitude,
						_ScreenShakeZIntensity, _ScreenShakeZAmplitude);

				UNITY_BRANCH
				if (_SplitXDistance != 0)
				{
					float flipPoint = i.worldPos.x;
					UNITY_BRANCH
					if (_SplitXAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _SplitXAngle).x;

					i.worldPos = stereoSplit(i.worldPos, axisRight, flipPoint, _SplitXDistance, _SplitXHalf, clearPixel);
				}
				UNITY_BRANCH
				if (_SplitYDistance != 0)
				{
					float flipPoint = i.worldPos.y;
					UNITY_BRANCH
					if (_SplitYAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _SplitYAngle).y;

					i.worldPos = stereoSplit(i.worldPos, axisUp, flipPoint, _SplitYDistance, _SplitYHalf, clearPixel);
				}

				// At interval of 0 the screen will be blank,
				// so we must check both distance and interval
				UNITY_BRANCH
				if (_SkewXDistance != 0 && _SkewXInterval != 0)
				{
					UNITY_BRANCH
					if(_SkewXAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, _SkewXAngle);

					i.worldPos = stereoSkew(i.worldPos, axisRight, i.worldPos.y, _SkewXInterval, _SkewXDistance, _SkewXOffset);

					UNITY_BRANCH
					if (_SkewXAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_SkewXAngle);
				}
				UNITY_BRANCH
				if (_SkewYDistance != 0 && _SkewYInterval != 0)
				{
					UNITY_BRANCH
					if (_SkewYAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, _SkewYAngle);

					i.worldPos = stereoSkew(i.worldPos, axisUp, i.worldPos.x, _SkewYInterval, _SkewYDistance, _SkewYOffset);

					UNITY_BRANCH
					if (_SkewYAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_SkewYAngle);
				}

				UNITY_BRANCH
				if (_BarXDistance != 0)
				{
					float flipPoint = i.worldPos.y;
					UNITY_BRANCH
					if (_BarXAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _BarXAngle).y;

					i.worldPos = stereoBar(i.worldPos, axisFront, axisRight, flipPoint, _BarXInterval, _BarXOffset, _BarXDistance);
				}
				UNITY_BRANCH
				if (_BarYDistance != 0)
				{
					float flipPoint = i.worldPos.x;
					UNITY_BRANCH
					if (_BarYAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _BarYAngle).x;

					i.worldPos = stereoBar(i.worldPos, axisFront, axisUp, flipPoint, _BarYInterval, _BarYOffset, _BarYDistance);
				}

				UNITY_BRANCH
				if (_SinBarXDistance != 0 && _SinBarXInterval != 0)
				{
					float flipPoint = i.worldPos.y;
					UNITY_BRANCH
					if (_SinBarXAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _SinBarXAngle).y;

					i.worldPos = stereoSinBar(i.worldPos, axisFront, axisRight, flipPoint, _SinBarXInterval, _SinBarXOffset, _SinBarXDistance);
				}
				UNITY_BRANCH
				if (_SinBarYDistance != 0 && _SinBarYInterval != 0)
				{
					float flipPoint = i.worldPos.x;
					UNITY_BRANCH
					if (_SinBarYAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _SinBarYAngle).x;

					i.worldPos = stereoSinBar(i.worldPos, axisFront, axisUp, flipPoint, _SinBarYInterval, _SinBarYOffset, _SinBarYDistance);
				}

				UNITY_BRANCH
				if (_ZigZagXDensity != 0)
				{
					float flipPoint = i.worldPos.y;
					UNITY_BRANCH
					if (_ZigZagXAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _ZigZagXAngle).y;

					i.worldPos = stereoZigZag(i.worldPos, axisRight, flipPoint, _ZigZagXDensity, _ZigZagXAmplitude, _ZigZagXOffset);
				}
				UNITY_BRANCH
				if (_ZigZagYDensity != 0)
				{
					float flipPoint = i.worldPos.x;
					UNITY_BRANCH
					if (_ZigZagYAngle != 0)
						flipPoint = stereoRotate(i.worldPos, axisFront, _ZigZagYAngle).x;

					i.worldPos = stereoZigZag(i.worldPos, axisUp, flipPoint, _ZigZagYDensity, _ZigZagYAmplitude, _ZigZagYOffset);
				}

				UNITY_BRANCH
				if (_SinWaveDensity != 0)
				{
					float3 axis = axisRight;
					UNITY_BRANCH
					if (_SinWaveAngle != 0)
					{
						axis = stereoRotate(float4(axis, 0), axisFront, _SinWaveAngle);
						i.worldPos = stereoRotate(i.worldPos, axisFront, _SinWaveAngle);
					}

					i.worldPos = stereoSinWave(i.worldPos, axis, _SinWaveDensity / 100, _SinWaveAmplitude, _SinWaveOffset);

					UNITY_BRANCH
					if (_SinWaveAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_SinWaveAngle);
				}
				UNITY_BRANCH
				if (_CosWaveDensity != 0)
				{
					float3 axis = axisUp;
					UNITY_BRANCH
					if (_CosWaveAngle != 0)
					{
						axis = stereoRotate(float4(axis, 0), axisFront, _CosWaveAngle);
						i.worldPos = stereoRotate(i.worldPos, axisFront, _CosWaveAngle);
					}

					i.worldPos = stereoCosWave(i.worldPos, axis, _CosWaveDensity / 100, _CosWaveAmplitude, _CosWaveOffset);

					UNITY_BRANCH
					if (_CosWaveAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_CosWaveAngle);
				}
				UNITY_BRANCH
				if (_TanWaveDensity != 0)
				{
					float3 axis = axisRight;
					UNITY_BRANCH
					if (_TanWaveAngle != 0)
					{
						axis = stereoRotate(float4(axis, 0), axisFront, _TanWaveAngle);
						i.worldPos = stereoRotate(i.worldPos, axisFront, _TanWaveAngle);
					}

					i.worldPos = stereoTanWave(i.worldPos, axisRight, _TanWaveDensity / 100, _TanWaveAmplitude, _TanWaveOffset);

					UNITY_BRANCH
					if (_TanWaveAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_TanWaveAngle);
				}

				UNITY_BRANCH
				if (_SliceDistance != 0)
					i.worldPos = stereoSlice(i.worldPos, axisUp, _SliceAngle, _SliceWidth, _SliceDistance, _SliceOffset);
				
				UNITY_BRANCH
				if (_RippleAmplitude != 0)
					i.worldPos = stereoRipple(i.worldPos, axisFront, _RippleDensity / 100, _RippleAmplitude, _RippleOffset, _RippleFalloff);

				UNITY_BRANCH
				if (_CheckerboardScale != 0)
					i.worldPos = stereoCheckerboard(i.worldPos, axisFront, _CheckerboardAngle, _CheckerboardScale, _CheckerboardShift);

				UNITY_BRANCH
				if (_Quantization != 0)
					i.worldPos = stereoQuantization(i.worldPos, 10.0 - _Quantization*10.0);

				UNITY_BRANCH
				if (_RingRotationWidth != 0)
					i.worldPos = stereoRingRotation(i.worldPos, axisFront, _RingRotationAngle, _RingRotationRadius / 10, _RingRotationWidth / 10);

				UNITY_BRANCH
				if (_WarpIntensity != 0)
					i.worldPos = stereoWarp(i.worldPos, axisFront, _WarpAngle, _WarpIntensity);

				UNITY_BRANCH
				if (_SpiralIntensity != 0)
					i.worldPos = stereoSpiral(i.worldPos, axisFront, _SpiralIntensity / 1000);

				UNITY_BRANCH
				if(_FishEyeIntensity != 0)
					i.worldPos = stereoFishEye(i.worldPos, axisFront, _FishEyeIntensity);

				UNITY_BRANCH
				if(_KaleidoscopeSegments > 0)
					i.worldPos = stereoKaleidoscope(i.worldPos, axisFront, _KaleidoscopeAngle, _KaleidoscopeSegments);

				UNITY_BRANCH
				if (_BlockDisplacementSize != 0)
				{
					UNITY_BRANCH
					if (_BlockDisplacementAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, _BlockDisplacementAngle);

					i.worldPos = stereoBlockDisplacement(i.worldPos, _BlockDisplacementSize, _BlockDisplacementIntensity, _BlockDisplacementMode, _BlockDisplacementOffset, clearPixel);

					UNITY_BRANCH
					if (_BlockDisplacementAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_BlockDisplacementAngle);
				}

				// Think you have enough function parameters there buddy?
				UNITY_BRANCH
				if (_GlitchCount != 0 && _GlitchIntensity != 0)
				{
					UNITY_BRANCH
					if (_GlitchAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, _GlitchAngle);

					i.worldPos = stereoGlitch(i.worldPos, axisFront, axisRight, axisUp,
						_GlitchCount, _MinGlitchWidth, _MinGlitchHeight, _MaxGlitchWidth, 
						_MaxGlitchHeight, _GlitchIntensity, _GlitchSeed, _GlitchSeedInterval);

					UNITY_BRANCH
					if (_GlitchAngle != 0)
						i.worldPos = stereoRotate(i.worldPos, axisFront, -_GlitchAngle);
				}

				UNITY_BRANCH
				if(_NoiseScale != 0 && _NoiseStrength != 0)
					i.worldPos.xyz += snoise((i.worldPos.xyz + axisFront*_NoiseOffset) / _NoiseScale)*_NoiseStrength;
				UNITY_BRANCH
				if (_VoroniNoiseScale != 0 && (_VoroniNoiseStrength != 0 || _VoroniNoiseBorderStrength != 0))
					i.worldPos = stereoVoroniNoise(i.worldPos, _VoroniNoiseScale, _VoroniNoiseOffset, _VoroniNoiseStrength, _VoroniNoiseBorderSize, _VoroniNoiseBorderMode, _VoroniNoiseBorderStrength, clearPixel);
					
				UNITY_BRANCH
				if (_GeometricDitherDistance != 0)
					i.worldPos = geometricDither(i.worldPos, axisRight, axisUp, _GeometricDitherDistance, _GeometricDitherQuality, _GeometricDitherRandomization);

				// Apply displacement map after distortion effects so that it isn't just a static element.
				UNITY_BRANCH
				if (_DisplacementMapIntensity != 0)
				{
					float4 samplePosition = i.worldPos;
					if (_DisplacementMapAngle != 0)
						samplePosition.xyz = mul(rotAxis(axisFront, _DisplacementMapAngle), samplePosition.xyz);

					bool dropDistortion = false;
					half4 displacementVector = stereoImageOverlay(samplePosition, startingAxisAlignedPos,
						_DisplacementMap, _DisplacementMap_ST, _DisplacementMap_TexelSize,
						_DisplacementMapColumns, _DisplacementMapRows, _DisplacementMapCount, _DisplacementMapIndex,
						1.0, _DisplacementMapClamp, _DisplacementMapCutOut,
						dropDistortion);

					float displacementAmount = (!dropDistortion)*_DisplacementMapIntensity;

					// Interpret displacement map using the screen as a surface
					// Red = Left-Right
					// Green = Forward-Back
					// Blue = Up-Down

					// Normal Map
					if (_DisplacementMapType == 0)
						i.worldPos.xyz += UnpackNormal(displacementVector).xyz*displacementAmount;
					// Color
					// Textures are 8 bits per color, so in order to have a '0' distortion value
					// we need to calculate the origin from 127/255.
					//
					// Note: This assumes the user has unchecked the 'sRGB (Color Texture)' box
					//		 for their texture.
					else
						i.worldPos.xyz += (displacementVector.xzy - 0.4980392)*displacementAmount;
				}

				// Distortion effects which take the inout variable clearPixel create empty space, 
				// so we can return now if we aren't filling the empty space (Override mode 2).
				if (clearPixel && _MemeTexOverrideMode != 2)
					return half4(0, 0, 0, _CancerOpacity);

				// Shift world pos back from its current axis-aligned position to
				// the position it should be in-front of the camera.
				float4 finishedWorldPos = i.worldPos;

				i.worldPos.xyz = mul(i.inverseViewMatRot, i.worldPos.xyz);
				i.worldPos.xyz += i.camPos;

				// Finally acquire our stereo position with which we can sample the screen texture.
				float4 stereoPosition = computeStereoUV(i.worldPos);

				UNITY_BRANCH
				if (_ColorVectorDisplacementStrength != 0)
				{
					float3 colorDisplacement = colorVectorDisplacement(_stereoCancerTexture, stereoPosition, _ColorVectorDisplacementStrength);

					// View Space
					UNITY_BRANCH
					if (_ColorVectorDisplacementCoordinateSpace == 0)
					{
						finishedWorldPos.xyz += colorDisplacement;

						// Update world pos to match our new modified world axis position.
						i.worldPos.xyz = mul(i.inverseViewMatRot, finishedWorldPos.xyz);
						i.worldPos.xyz += i.camPos;
					}
					// World Space
					else
					{
						i.worldPos.xyz += colorDisplacement;

						// The world axis aligned position (finishedWorldPos) is utilized for some effects like image overlay
						// and vignette, so we need to propogate the world space displacement backwards.
						finishedWorldPos.xyz = i.worldPos.xyz - i.camPos;
						finishedWorldPos.xyz = mul(i.viewMatRot, finishedWorldPos.xyz);
					}

					stereoPosition = computeStereoUV(i.worldPos);
				}

				// Requires a directional light to be in the scene so that _CameraDepthTexture is enabled.
				UNITY_BRANCH
				if (_NormalVectorDisplacementStrength != 0)
				{
					float3 normalDisplacement = normalVectorDisplacement(_CameraDepthTexture, _CameraDepthTexture_TexelSize, stereoPosition,
						i.worldPos, startingAxisAlignedPos, i.camPos, i.camRight, i.camUp, _NormalVectorDisplacementCoordinateSpace, _NormalVectorDisplacementStrength, _NormalVectorDisplacementQuality);

					// Debug normals
					//return float4(normalDisplacement, 1);

					// View Space
					UNITY_BRANCH
					if (_NormalVectorDisplacementCoordinateSpace == 0)
					{
						finishedWorldPos.xyz += normalDisplacement;

						// Update world pos to match our new modified world axis position.
						i.worldPos.xyz = mul(i.inverseViewMatRot, finishedWorldPos.xyz);
						i.worldPos.xyz += i.camPos;
					}
					// World Space
					else
					{
						i.worldPos.xyz += normalDisplacement;

						// The world axis aligned position (finishedWorldPos) is utilized for some effects like image overlay
						// and vignette, so we need to propogate the world space displacement backwards.
						finishedWorldPos.xyz = i.worldPos.xyz - i.camPos;
						finishedWorldPos.xyz = mul(i.viewMatRot, finishedWorldPos.xyz);
					}

					stereoPosition = computeStereoUV(i.worldPos);
				}

				// Wrap world coordinates after all effects have been applied
				// This allows for hiding the VR Mask when wrapping around
				//
				// Todo: Grab the frustum corners to calculate the starting
				//		 wrap value.
				if (_WorldCoordinatesWrapValue != 0)
				{
					finishedWorldPos = wrapWorldCoordinates(finishedWorldPos, _WorldCoordinatesWrapValue);

					i.worldPos.xyz = mul(i.inverseViewMatRot, finishedWorldPos.xyz);
					i.worldPos.xyz += i.camPos;

					stereoPosition = computeStereoUV(i.worldPos);
				}

				// Default UV clamping works for desktop, but for VR
				// we may want to constrain UV coordinates to
				// each eye.
				UNITY_BRANCH
				if (_ScreenSamplingMode == 1)
					stereoPosition = clampUVCoordinates(stereoPosition);

				// Wrapping allows for creating 'infinite' texture
				// and tunnel effects.
				UNITY_BRANCH
				if (_ScreenSamplingMode == 2)
					stereoPosition = wrapUVCoordinates(stereoPosition);

				  /////////////////////////
				 // Apply Color Effects //
			    /////////////////////////

				half4 bgcolor = half4(0, 0, 0, 0);

				// No point in sampling background color if the user is going to override it
				// anyway.
				UNITY_BRANCH
				if (_colorSkewROverride == 0 || _colorSkewGOverride == 0 || _colorSkewBOverride == 0)
				{
					if (_ChromaticAbberationStrength != 0)
						bgcolor += chromaticAbberation(_stereoCancerTexture, i.worldPos, i.camFront, _ChromaticAbberationStrength, _ChromaticAbberationSeparation, _ChromaticAbberationShape);
					else if (_BlurMovementOpacity != 0)
						bgcolor.rgb += blurMovement(_stereoCancerTexture, startingWorldPos, i.worldPos, _BlurMovementSampleCount,
							_BlurMovementTarget, _BlurMovementRange, _BlurMovementExtrapolation, _BlurMovementOpacity);
					else
						bgcolor += tex2Dproj(_stereoCancerTexture, stereoPosition);

					bgcolor *= _ColorMask;
				}

				UNITY_BRANCH
				if (_TriplanarOpacity != 0)
				{
					half3 triplanarColor = half3(0, 0, 0);

					float3 normal = normalVectorDisplacement(_CameraDepthTexture, _CameraDepthTexture_TexelSize, stereoPosition,
						i.worldPos, startingAxisAlignedPos, i.camPos, i.camRight, i.camUp, _TriplanarCoordinateSrc == 2 ? 0 : 1, 1, _TriplanarQuality);

					// Sample map
					if (_TriplanarSampleSrc == 0)
						triplanarColor = stereoTriplanarMappping(_TriplanarMap, _TriplanarMap_ST, _CameraDepthTexture, stereoPosition, i.camPos, normal, i.worldPos, startingAxisAlignedPos,
							_TriplanarOffsetX, _TriplanarOffsetY, _TriplanarOffsetZ, _TriplanarCoordinateSrc, _TriplanarScale, _TriplanarSharpness, 1, false);
					// Sample screen, UV range is reduced to the range (0.2, 0.8) to hide the VR mask.
					else
						triplanarColor = stereoTriplanarMappping(_stereoCancerTexture, _TriplanarMap_ST, _CameraDepthTexture, stereoPosition, i.camPos, normal, i.worldPos, startingAxisAlignedPos,
							_TriplanarOffsetX, _TriplanarOffsetY, _TriplanarOffsetZ, _TriplanarCoordinateSrc, _TriplanarScale, _TriplanarSharpness, 0.6, true);

					triplanarColor *= _TriplanarOpacity;

					// None, aka Override.
					if (_TriplanarBlendMode == 0)
						bgcolor.rgb = triplanarColor;
					// Multiply
					else if (_TriplanarBlendMode == 1)
						bgcolor.rgb *= triplanarColor;
					// MulAdd
					else
						bgcolor.rgb += bgcolor.rgb*triplanarColor;
				}

				UNITY_BRANCH
				if (_SignalNoiseSize != 0 && _SignalNoiseOpacity != 0)
					bgcolor.rgb += signalNoise(finishedWorldPos, _SignalNoiseSize, _ColorizedSignalNoise, _SignalNoiseOpacity);

				UNITY_BRANCH
				if (_EdgelordStripeSize != 0)
				{
					float2 edgelordUV = (stereoPosition.xyz / stereoPosition.w).xy;
					bgcolor = edgelordStripes(edgelordUV, bgcolor, _EdgelordStripeColor, _EdgelordStripeSize, _EdgelordStripeOffset);
				}

				UNITY_BRANCH
				if(_MemeTexOpacity != 0)
				{
					float4 samplePosition = finishedWorldPos;
					if (_MemeImageAngle != 0)
						samplePosition.xyz = mul(rotAxis(axisFront, _MemeImageAngle), samplePosition.xyz);

					bool dropMemePixels = false;
					half4 memeColor = stereoImageOverlay(samplePosition, startingAxisAlignedPos,
						_MemeTex, _MemeTex_ST, _MemeTex_TexelSize,
						_MemeImageColumns, _MemeImageRows, _MemeImageCount, _MemeImageIndex,
						_MemeTexOpacity, _MemeTexClamp, _MemeTexCutOut,
						dropMemePixels);

					if (dropMemePixels == false)
					{
						if (memeColor.a > _MemeTexAlphaCutOff)
						{
							// Override Background
							if (_MemeTexOverrideMode == 1)
							{
								bgcolor.rgb = memeColor * _MemeTexOpacity;
							}
							// Override Empty Space
							else if (_MemeTexOverrideMode == 2)
							{
								if (clearPixel)
								{
									bgcolor = memeColor * _MemeTexOpacity;
									return bgcolor;
								}
							}
							else
							{
								bgcolor += memeColor * _MemeTexOpacity;
							}
						}
					}
					else
					{
						// Override Background
						if (_MemeTexOverrideMode == 1)
							discard;
					}
				}

				UNITY_BRANCH
				if (_CircularVignetteOpacity != 0)
					bgcolor.rgb = circularVignette(bgcolor, finishedWorldPos, _CircularVignetteColor, _CircularVignetteOpacity,
						_CircularVignetteRoundness,_CircularVignetteMode,_CircularVignetteBegin, _CircularVignetteEnd);

				UNITY_BRANCH
				if (_Hue != 0 || _Saturation != 0 || _Value != 0)
					bgcolor.rgb = applyHSV(bgcolor, _Hue, _Saturation, _Value);

				UNITY_BRANCH
				if (_ImaginaryColorOpacity != 0)
				{
					half3 imaginaryColor = imaginaryColors(worldVector, _ImaginaryColorAngle)*_ImaginaryColorOpacity;
					
					if (_ImaginaryColorBlendMode == 0)
						bgcolor.rgb *= imaginaryColor;
					else if (_ImaginaryColorBlendMode == 1)
						bgcolor.rgb += imaginaryColor;
					else if (_ImaginaryColorBlendMode == 2)
						bgcolor.rgb += bgcolor.rgb*imaginaryColor;
				}

				// Check opacity and override since the user may be intentionally
				// removing the color channel.
				UNITY_BRANCH
				if (_colorSkewROpacity != 0 || _colorSkewROverride != 0)
				{
					float redColor = colorShift(_stereoCancerTexture, i.camFront, i.camRight, _colorSkewRAngle, _colorSkewRDistance,
						_colorSkewROpacity, stereoPosition).r;

					if (_colorSkewROverride != 0)
						bgcolor.r = redColor;
					else
						bgcolor.r += redColor;
				}
				UNITY_BRANCH
				if (_colorSkewGOpacity != 0 || _colorSkewGOverride != 0)
				{
					float greenColor = colorShift(_stereoCancerTexture, i.camFront, i.camRight, _colorSkewGAngle, _colorSkewGDistance,
						_colorSkewGOpacity, stereoPosition).g;

					if (_colorSkewGOverride != 0)
						bgcolor.g = greenColor;
					else
						bgcolor.g += greenColor;
				}
				UNITY_BRANCH
				if (_colorSkewBOpacity != 0 || _colorSkewBOverride != 0)
				{
					float blueColor = colorShift(_stereoCancerTexture, i.camFront, i.camRight, _colorSkewBAngle, _colorSkewBDistance,
						_colorSkewBOpacity, stereoPosition).b;

					if (_colorSkewBOverride != 0)
						bgcolor.b = blueColor;
					else
						bgcolor.b += blueColor;
				}

				// Allow the user to fade the cancer shader effects in and out
				// as well as do blending shenanigans
				// e.g. Negative or large positive values, layering effects, etc
				//
				// Usage example: 'Cursed' graphics
				//				 _CancerOpacity = -45.00 
				//
				//				 _SkewXDistance = 15.00
				//				 _SkewXInterval = 2.8
				//
				//				_BarXDistance = 10.00
				//				_BarXInterval = 18.00
				bgcolor.a = _CancerOpacity;

				// I'm sorry fellow VRChat players, but you've just contracted eye-cancer.
				//	-xwidghet
				return bgcolor;
			}
			ENDCG
		}
	}
}
