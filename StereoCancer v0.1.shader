// UNITY_SHADER_NO_UPGRADE

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
	// LICENSE: This shader is licensed under GPL V3.
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
		// Rendering Parameters
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode("Cull Mode", Float) = 1
		[Enum(Off, 0, On, 1)] _ZWrite("Z Write", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("Z Test", Int) = 8

		// VRChat workarounds
		[Enum(No, 0, Yes,1)] _DisableNameplates("Disable Nameplates", Int) = 0

		[Enum(Screen,0, Mirror,1, Both,2)] _CancerDisplayMode("Cancer Display Mode", Float) = 0
		[Enum(Fullscreen,0, World Scale,1)] _ObjectDisplayMode("Object Display Mode", Float) = 0
		[Enum(No, 0, Yes,1)] _DisplayOnSurface("Display On Surface", Float) = 0
		[Enum(Clamp,0, Eye Clamp,1, Wrap,2)] _ScreenSamplingMode("Screen Sampling Mode", Float) = 1
		[Enum(Screen,0, Projected (Requires Directional Light),1, Centered On Object,2)] _CoordinateSpace("Coordinate Space", Float) = 0
		_CoordinateScale("Coordinate Scale", Float) = 1
		[Enum(Wrap,0, Cutout,1, Clamp,2, Empty Space,3)] _WorldSamplingMode("World Sampling Mode", Float) = 0
		_WorldSamplingRange("World Sampling Range", Range(0, 1)) = 1
		_CancerEffectQuantization("Cancer Effect Quantization", Range(0, 1)) = 0
		_CancerEffectRotation("Cancer Effect Rotation", Float) = 0
		_CancerEffectOffset("Cancer Effect Offset", Vector) = (0,0,0,0)
		_CancerEffectRange("Cancer Effect Range", Range(0, 1)) = 1
		[Enum(No,0, Yes,1)] _RemoveCameraRoll("Remove Camera Roll", Int) = 0
		[Enum(Global,0, SelfOnly,1, OthersOnly,2)] _Visibility("Visibility", Float) = 0
		[Enum(No,0, Yes,1)] _FalloffEnabled("Falloff Enabled", Int) = 0
		[Enum(OpacityOnly,1, DistortionOnly,2, OpacityAndDistortion,3)] _FalloffFlags("Falloff Flags", Int) = 3
		_FalloffBeginPercentage("Falloff Begin Percentage", Range(0,100)) = 0.75
		_FalloffEndPercentage("Falloff End Percentage", Range(0,100)) = 1.0
		_FalloffAngleBegin("Falloff Angle Begin", Range(0,1)) = 0.1
		_FalloffAngleEnd("Falloff Angle End", Range(0,1)) = 0.2

		[Enum(No,0, Yes,1)] _ParticleSystem("Particle System", Int) = 0

		// Stencil Parameters
		_StencilRef("Stencil Ref", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil Comparison", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilOp("Stencil Operation", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilFail("Stencil Fail", Int) = 0
		[Enum(UnityEngine.Rendering.StencilOp)] _StencilZFail("Stencil ZFail", Int) = 0
		_ReadMask("ReadMask", Int) = 255
		_WriteMask("WriteMask", Int) = 255

		// Blending Parameters
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcFactor("SrcFactor", Float) = 5
		[Enum(UnityEngine.Rendering.BlendMode)] _DstFactor("DstFactor", Float) = 10
		_CancerOpacity("Cancer Opacity", Float) = 1

		// VR Effects
		_EyeConvergence("Eye Convergence", Range(-3.1415926, 3.1415926)) = 0
		_EyeSeparation("Eye Separation", Float) = 0

		// Image Effects
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
		[Enum(No,0, Yes,1)] _MemeImageScaleWithDistance("Meme Image Scale With Distance", Int) = 0

		// Mask Map
		_MaskMap("Mask Map (R)", 2D) = "white" {}
		_MaskMapColumns("Mask Map Columns", Int) = 1
		_MaskMapRows("Mask Map Rows", Int) = 1
		_MaskMapCount("Mask Map Count", Int) = 1
		_MaskMapIndex("Mask Map Index", Int) = 0
		_MaskMapAngle("Mask Map Angle", Float) = 0
		_MaskMapOpacity("Mask Map Opacity", Float) = 0
		[Enum(No,0, Yes,1)] _MaskMapClamp("Mask Map Clamp", Int) = 0
		[Enum(No,0, Yes,1)] _MaskMapCutOut("Mask Map Cut Out", Int) = 0
		[Enum(OpacityOnly,1, DistortionOnly,2, OpacityAndDistortion,3)] _MaskFlags("Mask Flags", Int) = 3
		[Enum(No,0, Yes,1)] _MaskMapScaleWithDistance("Mask Map Scale With Distance", Int) = 0
		[Enum(No,0, Yes,1)] _MaskSampleDistortedCoordinates("Mask Map Sample Distortion", Int) = 0

		// Displacement Map Map Displacement \\/
		_DisplacementMap("Displacement Map (RGB)", 2D) = "white" {}
		[Enum(Normal,0, Color,1)] _DisplacementMapType("Displacement Map Type", Int) = 1
		_DisplacementMapColumns("Displacement Map Columns", Int) = 1
		_DisplacementMapRows("Displacement Map Rows", Int) = 1
		_DisplacementMapCount("Displacement Map Count", Int) = 1
		_DisplacementMapIndex("Displacement Map Index", Int) = 0
		_DisplacementMapAngle("Displacement Map Angle", Float) = 0
		_DisplacementMapIntensity("Displacement Map Intensity", Float) = 0
		_DisplacementMapOscillationSpeed("Displacement Map Oscillation Speed", Float) = 0
		_DisplacementMapIterations("Displacement Map Iterations", Range(1,30)) = 1
		[Enum(No,0, Yes,1)] _DisplacementMapClamp("Displacement Map Clamp", Int) = 0
		[Enum(No,0, Yes,1)] _DisplacementMapCutOut("Displacement Map Cut Out", Int) = 0
		[Enum(No,0, Yes,1)] _DisplacementMapScaleWithDistance("Displacement Map Scale With Distance", Int) = 0

		// Triplanar Map
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
		[Enum(No,0, Yes,1)] _SplitXHalf("Split X Half", Float) = 0

		_SplitYAngle("Split Y Angle", Float) = 0
		_SplitYDistance("Split Y Distance", Float) = 0
		[Enum(No,0, Yes,1)] _SplitYHalf("Split Y Half", Float) = 0

		_SkewXAngle("Skew X Angle", Float) = 0
		_SkewXDistance("Skew X Distance", Float) = 0
		_SkewXInterval("Skew X Interval", Float) = 1
		_SkewXOffset("Skew X Offset", Float) = 0

		_SkewYAngle("Skew Y Angle", Float) = 0
		_SkewYDistance("Skew Y Distance", Float) = 0
		_SkewYInterval("Skew Y Interval", Float) = 1
		_SkewYOffset("Skew Y Offset", Float) = 0

		_BarXAngle("Bar X Angle", Float) = 0
		_BarXDistance("Bar X Distance", Float) = 0
		_BarXInterval("Bar X Interval", Float) = 1
		_BarXOffset("Bar X Offset", Float) = 0
		
		_BarYAngle("Bar Y Angle", Float) = 0
		_BarYDistance("Bar Y Distance", Float) = 0
		_BarYInterval("Bar Y Interval", Float) = 1
		_BarYOffset("Bar Y Offset", Float) = 0

		_SinBarXAngle("Sin Bar X Angle", Float) = 0
		_SinBarXDistance("Sin Bar X Distance", Float) = 0
		_SinBarXInterval("Sin Bar X Interval", Float) = 1
		_SinBarXOffset("Sin Bar X Offset", Float) = 0

		_SinBarYAngle("Sin Bar Y Angle", Float) = 0
		_SinBarYDistance("Sin Bar Y Distance", Float) = 0
		_SinBarYInterval("Sin Bar Y Interval", Float) = 1
		_SinBarYOffset("Sin Bar Y Offset", Float) = 0

		_MeltAngle("Melt Angle", Float) = 0
		_MeltInterval("Melt Interval", Float) = 1
		_MeltVariance("Melt Variance", Range(0, 1)) = 0.9
		_MeltDistance("Melt Distance", Float) = 0
		_MeltSeed("Melt Seed", Float) = 0
		[Enum(No, 0, Yes, 0.5)] _MeltBothDirections("Melt Both Directions", Float) = 0

		_ZigZagXAngle("ZigZag X Angle", Float) = 0
		_ZigZagXDensity("ZigZag X Density", Float) = 10
		_ZigZagXAmplitude("ZigZag X Amplitude", Float) = 0
		_ZigZagXOffset("ZigZag X Offset", Float) = 0

		_ZigZagYAngle("ZigZag Y Angle", Float) = 0
		_ZigZagYDensity("ZigZag Y Density", Float) = 10
		_ZigZagYAmplitude("ZigZag Y Amplitude", Float) = 0
		_ZigZagYOffset("ZigZag Y Offset", Float) = 0

		_SinWaveAngle("Sin Wave Angle", Float) = 0
		_SinWaveDensity("Sin Wave Density", Float) = 10
		_SinWaveAmplitude("Sin Wave Amplitude", Float) = 0
		_SinWaveOffset("Sin Wave Offset", Float) = 0

		_CosWaveAngle("Cos Wave Angle", Float) = 0
		_CosWaveDensity("Cos Wave Density", Float) = 10
		_CosWaveAmplitude("Cos Wave Amplitude", Float) = 0
		_CosWaveOffset("Cos Wave Offset", Float) = 0

		_SinCosWaveAngle("SinCos Wave Angle", Float) = 0
		_SinCosWaveSinDensity("SinCos Wave  Sin Density", Float) = 10
		_SinCosWaveCosDensity("SinCos Wave  Cos Density", Float) = 10
		_SinCosWaveAmplitude("SinCos Wave Amplitude", Float) = 0
		_SinCosWaveSinOffset("SinCos Wave Sin Offset", Float) = 0
		_SinCosWaveCosOffset("SinCos Wave Cos Offset", Float) = 0

		_TanWaveAngle("Tan Wave Angle", Float) = 0
		_TanWaveDensity("Tan Wave Density", Float) = 10
		_TanWaveAmplitude("Tan Wave Amplitude", Float) = 0
		_TanWaveOffset("Tan Wave Offset", Float) = 0

		_SliceAngle("Slice Angle", Float) = 0
		_SliceWidth("Slice Width", Float) = 10
		_SliceDistance("Slice Distance", Float) = 0
		_SliceOffset("Slice Offset", Float) = 0

		_RippleDensity("Ripple Density", Float) = 50
		_RippleAmplitude("Ripple Amplitude", Float) = 0
		_RippleOffset("Ripple Offset", Float) = 0
		_RippleInnerFalloff("Ripple Inner Falloff", Float) = 0
		_RippleOuterFalloff("Ripple Outer Falloff", Float) = 0

		_CheckerboardAngle("Checkerboard Angle", Float) = 0
		_CheckerboardScale("Checkerboard Scale", Float) = 10
		_CheckerboardShift("Checkerboard Shift Distance", Float) = 0
		_Quantization("Quantization", Range(0,1)) = 0

		_RingRotationInnerAngle("Ring Rotation Inner-Angle", Float) = 0
		_RingRotationOuterAngle("Ring Rotation Outer-Angle", Float) = 3.1415926
		_RingRotationRadius("Ring Rotation Radius", Float) = 0
		_RingRotationWidth("Ring Rotation Width", Float) = 0

		_WarpAngle("Warp Angle", Float) = 0
		_WarpIntensity("Warp Intensity", Float) = 0

		_SpiralIntensity("Spiral Intensity", Float) = 0

		_PolarInversionIntensity("Polar Inversion Intensity", Float) = 0

		_FishEyeIntensity("Fish Eye Intensity", Float) = 0

		_KaleidoscopeAngle("Kaleidoscope Angle", Float) = 0
		_KaleidoscopeSegments("Kaleidoscope Segments", Range(0,32)) = 0

		_BlockDisplacementAngle("Block Displacement Angle", Float) = 0
		_BlockDisplacementSize("Block Displacement Size", Float) = 0
		_BlockDisplacementIntensity("Block Displacement Intensity", Float) = 0
		[Enum(Smooth, 0, Random, 1)] _BlockDisplacementMode("Block Displacement Mode", Float) = 0
		_BlockDisplacementOffset("Block Displacement Offset", Float) = 0

		_GlitchAngle("Glitch Angle", Float) = 0
		_GlitchCount("Glitch Count", Range(0, 32)) = 10
		_MinGlitchWidth("Min Glitch Width", Float) = 10
		_MinGlitchHeight("Min Glitch Height", Float) = 10
		_MaxGlitchWidth("Max Glitch Width", Float) = 20
		_MaxGlitchHeight("Max Glitch Height", Float) = 20
		_GlitchIntensity("Glitch Intensity", Float) = 0
		_GlitchSeed("Glitch Seed", Float) = 0
		_GlitchSeedInterval("Glitch Seed Interval", Float) = 1

		_NoiseScale("Simplex Noise Scale", Float) = 10
		_NoiseStrength("Simplex Noise Strength", Float) = 0
		_NoiseOffset("Simplex Noise Offset", Float) = 0

		_VoroniNoiseScale("Voroni Noise Scale", Float) = 10
		_VoroniNoiseStrength("Voroni Noise Strength", Float) = 0
		_VoroniNoiseBorderSize("Voroni Border Size", Float) = 0.1
		[Enum(NoEffect,0, Multiply,1, EmptySpace, 2)] _VoroniNoiseBorderMode("Voroni Border Mode", Float) = 0
		_VoroniNoiseBorderStrength("Voroni Noise Border Strength", Float) = 1
		_VoroniNoiseOffset("Voroni Noise Offset", Float) = 0

		_FanDistance("Fan Distance", Float) = 0
		_FanScale("Fan Scale", Float) = 5
		_FanBlades("Fan Blades", Range(1, 12)) = 5
		_FanOffset("Fan Offset", Float) = 1

		_GeometricDitherDistance("Geometric Dither Distance", Float) = 0
		_GeometricDitherQuality("Geometric Dither Quality", Range(1, 6)) = 5
		_GeometricDitherRandomization("Geometric Dither Randomization", Float) = 0

		_ColorVectorDisplacementStrength("Color Vector Displacement Strength", Float) = 0
		[Enum(View, 0, World, 1)] _ColorVectorDisplacementCoordinateSpace("Color Vector Displacement Coordinate Space", Float) = 1

		_NormalVectorDisplacementStrength("Normal Vector Displacement Strength", Float) = 0
		[Enum(View, 0, World, 1)] _NormalVectorDisplacementCoordinateSpace("Normal Vector Displacement Coordinate Space", Float) = 1
		[Enum(Low, 0, High (Requires Directional Light), 1)] _NormalVectorDisplacementQuality("Normal Vector Displacement Quality", Float) = 1

		// Screen color effects
		[HDR]_EmptySpaceColor("Empty Space Color", Color) = (0, 0, 0, 1)

		_SignalNoiseSize("Signal Noise Size", Float) = 1
		_ColorizedSignalNoise("Signal Noise Colorization", Float) = 0
		_SignalNoiseOpacity("Signal Noise Opacity", Float) = 0

		_BlurMovementSampleCount("Blur Movement Sample Count", Range(1, 100)) = 42
		_BlurMovementTarget("Blur Movement Target", Range(0, 1)) = 0.5
		_BlurMovementRange("Blur Movement Range", Range(0.001, 1)) = 1
		_BlurMovementExtrapolation("Blur Movement Extrapolation", Range(0, 1)) = 0
		_BlurMovementBlurIntensity("Blur Movement Blur Intensity", Range(0, 1)) = 1
		_BlurMovementOpacity("Blur Movement Opacity", Range(0, 1)) = 0
		_BlurMovementBlend("Blur Movement Blend", Range(-1, 1)) = 1

		_ChromaticAberrationStrength("Chromatic Aberration Strength", Float) = 0
		_ChromaticAberrationSeparation("Chromatic Aberration Separation", Float) = 1.5
		[Enum(Spherical, 0, Flat, 1)] _ChromaticAberrationShape("Chromatic Aberration Shape", Float) = 0
		_ChromaticAberrationBlend("Chromatic Aberration Blend", Range(-1,1)) = 1

		_DistortionDesyncR("Red Distortion Desync", Float) = 0
		_DistortionDesyncG("Green Distortion Desync", Float) = 0
		_DistortionDesyncB("Blue Distortion Desync", Float) = 0
		_DistortionDesyncBlend("Distortion Desync Blend", Range(-1, 1)) = 1

		[HDR]_CircularVignetteColor("Circular Vignette Color", Color) = (0, 0, 0, 1)
		_CircularVignetteOpacity("Circular Vignette Opacity", Range(0, 1)) = 0
		[Enum(Linear, 0, Squared, 1, Log2, 2)] _CircularVignetteMode("Circular Vignette Mode", Float) = 2
		_CircularVignetteRoundness("Circular Vignette Roundness", Range(0, 1)) = 1
		_CircularVignetteBegin("Circular Vignette Begin Distance", Float) = 25
		_CircularVignetteEnd("Circular Vignette End Distance", Float) = 50
		[Enum(No, 0, Yes, 1)] _CircularVignetteScaleWithDistance("Circular Vignette Scale With Distance", Float) = 0

		[Enum(None,0, Linear,1, Squared,2, Log2,3, Exponential,4)] _FogType("Fog Type (Requires Directional Light)", Float) = 0
		[HDR]_FogColor("Fog Color", Color) = (0, 0, 0, 1)
		_FogBegin("Fog Begin", Float) = 25
		_FogEnd("Fog End", Float) = 200
			
		[HDR]_EdgelordStripeColor("Edgelord Stripe Color", Color) = (0, 0, 0, 1)
		_EdgelordStripeSize("Edgelord Stripe Size", Float) = 0
		_EdgelordStripeOffset("Edgelord Stripe Offset", Float) = 0

		[HDR]_ColorMask("Color Mask", Color) = (1, 1, 1, 1)

		_PaletteOpacity("Palette Opacity", Float) = 0
		_PaletteScale("Palette Scale", Float) = 1
		_PaletteOffset("Palette Offset", Float) = 0
		[Enum(Screen Color,0, User Specified,1)] _PalleteSource("Palette Source", Float) = 1
		_PaletteA("Palette Bias A", Vector) = (0, 0.5, 0.75, 0)
		_PaletteB("Palette Bias B", Vector) = (0.55, 0.11, 0.33, 0)
		_PaletteOscillation("Palette Oscillation", Vector) = (1, 2, 3, 0)
		_PalettePhase("Palette Phase", Vector) = (0.88, 0.43, 0.92, 0)

		_ColorInversionR("Color Inversion R", Float) = 0
		_ColorInversionG("Color Inversion G", Float) = 0
		_ColorInversionB("Color Inversion B", Float) = 0

		[Enum(None,0, Rcp,1, Pow,2, Freedom,3, Acid,4, Quantization,5)] _ColorModifierMode("Color Modifier Mode", Float) = 0
		_ColorModifierStrength("Color Modifier Strength", Float) = 5
		_ColorModifierBlend("Color Modifier Blend", Float) = 1

		_Hue("Hue", Float) = 0
		_Saturation("Saturation", Float) = 0
		_Value("Value", Float) = 0
		[Enum(No, 0, Yes, 1)] _ClampSaturation("Clamp Saturation", Float) = 0

		[Enum(Multiply, 0, Add, 1, MulAdd, 2)] _ImaginaryColorBlendMode("Imaginary Color Blend Mode", Float) = 2
		_ImaginaryColorOpacity("Imaginary Color Opacity", Float) = 0
		_ImaginaryColorAngle("Imaginary Color Angle", Float) = 0

		_SobelSearchDistance("Sobel Search Distance", Float) = 0.2
		[Enum(Low, 0, High, 1)] _SobelQuality("Sobel Quality", Float) = 1
		_SobelOpacity("Sobel Opacity", Float) = 0
		[Enum(None, 0, Multiply, 1, MulAdd, 2)] _SobelBlendMode("Sobel Blend Mode", Float) = 0

		_colorSkewRDistance("Red Move Distance", Float) = 3
		_colorSkewRAngle("Red Move Angle", Float) = 0
		_colorSkewROpacity("Red Move Opacity", Float) = 0
		[Enum(No, 0, Yes, 1)] _colorSkewROverride("Red Move Override", Float) = 0

		_colorSkewGDistance("Green Move Distance", Float) = -3
		_colorSkewGAngle("Green Move Angle", Float) = 0
		_colorSkewGOpacity("Green Move Opacity", Float) = 0
		[Enum(No, 0, Yes, 1)] _colorSkewGOverride("Green Move Override", Float) = 0

		_colorSkewBDistance("Blue Move Distance", Float) = 3
		_colorSkewBAngle("Blue Move Angle", Float) = -1.57079632
		_colorSkewBOpacity("Blue Move Opacity", Float) = 0
		[Enum(No, 0, Yes, 1)] _colorSkewBOverride("Blue Move Override", Float) = 0
	}
	SubShader
	{
		// Attempt to draw ourselves after all normal avatar and world draws
		// Opaque = 2000, Transparent = 3000, Overlay = 4000
		// Note: As of VRChat 2018 update, object draws are clamped
		//		 to render queue 4000, and particles to 5000.
		Tags { "Queue" = "Overlay" "IgnoreProjector" = "True" "VRCFallback" = "Hidden" }

		// Don't write depth, and ignore the current depth.
		Cull[_CullMode] ZWrite[_ZWrite] ZTest[_ZTest]

		// Blend against the current screen texture to allow for
		// fading in/out the cancer effects and various other shenanigans.
		Blend[_SrcFactor][_DstFactor]
		
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

		Stencil
		{
			Ref[_StencilRef]
			Comp[_StencilComp]
			Pass[_StencilOp]
			Fail[_StencilFail]
			ZFail[_StencilZFail]
			ReadMask[_ReadMask]
			WriteMask[_WriteMask]
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

			#include "StereoCancerParameters.cginc"

			// Leave only grab pass texture parameters in the main shader file,
			// that way layer creation only needs to parse one file.
			
			// SPS-I Support
			UNITY_DECLARE_SCREENSPACE_TEXTURE(_stereoCancerTexture);
			float4 _stereoCancerTexture_TexelSize;

			// SPS-I Support
			// For layer support we need to be able to update the texture variable name. This allows me to do this without having to parse the whole functions file too.
#define SCREEN_SPACE_TEXTURE_NAME _stereoCancerTexture

			// Stereo Cancer function implementations
			#include "StereoCancerFunctions.cginc"

			struct appdata
			{
				float4 vertex : POSITION;

				// For getting particle position and scale
				float4 uv : TEXCOORD0;

				// SPS-I Support
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 viewPos: TEXCOORD1;

				nointerpolation float3 camFront : TEXCOORD2;
				nointerpolation float3 camRight : TEXCOORD3;
				nointerpolation float3 camUp : TEXCOORD4;
				nointerpolation float3 camPos : TEXCOORD5;
				nointerpolation float3 centerCamPos : TEXCOORD6;
				nointerpolation float3 objPos : TEXCOORD7;
				nointerpolation float3 screenSpaceObjPos : TEXCOORD8;
				nointerpolation float2 colorDistortionFalloff : TEXCOORD9;

				// SPS-I Support
				UNITY_VERTEX_OUTPUT_STEREO
			};

			v2f vert (appdata v)
			{
				v2f o;

				// SPS-I Support
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				// Note: This does not utilize cross products to avoid the issue where
				//		 at certain rotations the Up and Right vectors will flip.
				//		 (Roll of +-30 degrees and +-90 degrees).
				o.camFront = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));
				o.camUp = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 1, 0)));
				o.camRight = normalize(mul((float3x3)unity_CameraToWorld, float3(1, 0, 0)));

				// Apparently the built-in _WorldSpaceCameraPos can't be trusted...so manually access the camera position.
				o.camPos = float3(unity_CameraToWorld[0][3], unity_CameraToWorld[1][3], unity_CameraToWorld[2][3]);

#if defined(USING_STEREO_MATRICES)
				o.centerCamPos = lerp(
					float3(unity_StereoCameraToWorld[0][0][3], unity_StereoCameraToWorld[0][1][3], unity_StereoCameraToWorld[0][2][3]),
					float3(unity_StereoCameraToWorld[1][0][3], unity_StereoCameraToWorld[1][1][3], unity_StereoCameraToWorld[1][2][3]),
					0.5);
#else
				o.centerCamPos = o.camPos;
#endif

				// Extract object position from the model matrix.
				o.objPos = float3(UNITY_MATRIX_M[0][3], UNITY_MATRIX_M[1][3], UNITY_MATRIX_M[2][3]);

				// Usage: Set the following Renderer settings for the particle system
				//		  Render Alignment: World
				//		  Custom Vertex Streams:
				//				Position (POSITION.xyz)
				//				Center   (TEXCOORD0.xyz)
				//				Size.x   (TEXCOORD0.w)
				if (_ParticleSystem == 1)
				{
					o.objPos = v.uv.xyz;
				}
				
				// Fullscreen
				if (_ObjectDisplayMode == 0)
				{
					// Place the mesh on the viewer's face, and ensure it covers the entire view
					// even when the user is looking at a mirror at a near-perpindicular angle.
					// Note: This won't handle extraordinarily large mirrors, leaving a gap on the sides
					//		 of what the viewer can see.
					v.vertex.xyz *= 100;

					o.viewPos = v.vertex + float4(o.camPos, 0);
					o.viewPos = mul(UNITY_MATRIX_V, o.viewPos);
				}
				// World Scale
				else
				{
					o.viewPos = mul(UNITY_MATRIX_MV, v.vertex);
				}

				o.pos = mul(UNITY_MATRIX_P, o.viewPos);

				// If visiblity isn't global...
				//
				// Note: With Avatar 3.0 you should use the isLocal variable instead unless you want
				//		 to prevent hacking clients from flipping the local check.
				//		 This would allow you to get the same effect without increasing your avatar
				//		 bounds to 10,000.
				if (_Visibility > 0)
				{
					// Assumes the following:
					// Object is parented to the head
					// Object has a scale of 10,000 in all axes.

					// If the Y scale hasn't been multiplied by 0.0001 then it is not the user of the avatar
					// (or their viewball has drifted far away from their head).
					float objectScale = length(float3(UNITY_MATRIX_M[1][0], UNITY_MATRIX_M[1][1], UNITY_MATRIX_M[1][2]));
					bool isOther = objectScale >= 10;
					
					// Self Only
					if (_Visibility == 1 && (isOther == true))
						o.pos = float4(9999, 9999, 9999, 9999);
					// Others Only...I'm so sorry.
					else if (_Visibility == 2 && (isOther == false))
						o.pos = float4(9999, 9999, 9999, 9999);
				}

				o.colorDistortionFalloff = float2(1, 1);
				// When enabled, generates falloff values and evicts the vertex to outer-space once falloff reaches zero.
				if (_FalloffEnabled == 1)
				{
					// For VR we want to use a consistent camera position and direction so that the eyes get the same amount
					// of opacity and distortion reduction.
#if defined(USING_STEREO_MATRICES)
					int otherCameraIndex = 1 - unity_StereoEyeIndex;
					float3 centerCamDir = lerp(o.camFront, mul((float3x3)unity_StereoCameraToWorld[otherCameraIndex], float3(0, 0, 1)), 0.5);
					centerCamDir = normalize(centerCamDir);
#else
					float3 centerCamDir = o.camFront;
#endif
					float distanceFalloffAlpha = 1;
					
					// Normal Objects
					if (_ParticleSystem == 0)
					{
						// Handle non-uniform scaling and rotation in one easy step!
						float3 objSpaceCamPos = abs(mul(unity_WorldToObject, float4(o.centerCamPos, 1)).xyz);

						distanceFalloffAlpha = max(max(objSpaceCamPos.x, objSpaceCamPos.y), objSpaceCamPos.z);
					}
					// Particles
					else
					{
						// Particle model matrix (UNITY_MATRIX_M) doesn't contain scale or translation,
						// so a spherical distance check will do just fine as a replacement.
						distanceFalloffAlpha = distance(o.objPos, o.centerCamPos) * (rcp(v.uv.w) * 0.5);
					}

					float falloffMin = (0.5 * _FalloffBeginPercentage);
					float falloffMax = (0.5 * _FalloffEndPercentage);
					distanceFalloffAlpha = smoothstep(falloffMin, falloffMax, distanceFalloffAlpha);
					o.colorDistortionFalloff.xy -= distanceFalloffAlpha*float2((_FalloffFlags & 1) != 0, (_FalloffFlags & 2) != 0);
					
					// Angle falloff, basically required for good Centered On Object coordinate space usage.
					if (_FalloffAngleBegin < 1)
					{
						float3 toObjectVec = normalize(o.objPos - o.centerCamPos);
						float angle = clamp(dot(toObjectVec, centerCamDir), -1, 1);

						float angleFalloffBegin = 1 - _FalloffAngleBegin;
						float angleFalloffEnd = 1 - _FalloffAngleEnd;

						float angleFalloffAlpha = smoothstep(angleFalloffBegin, angleFalloffEnd, angle);
						
						o.colorDistortionFalloff.xy -= angleFalloffAlpha*float2((_FalloffFlags & 1) != 0, (_FalloffFlags & 2) != 0);
					}

					// Ensure we haven't gone negative after applying both types of falloff.
					o.colorDistortionFalloff.xy = clamp(o.colorDistortionFalloff.xy, 0, 1);

					// No output, evict mesh to outer-space.
					if (!any(o.colorDistortionFalloff))
						o.pos = float4(9999, 9999, 9999, 9999);
				}

				// Evicts the vertex to outer-space when visibility doesn't match the display mode.
				if(mirrorCheck(_CancerDisplayMode))
					o.pos = float4(9999, 9999, 9999, 9999);

				// Convert object position to screen-space after all coordinate space math
				// is finished.
				o.screenSpaceObjPos = mul(UNITY_MATRIX_V, float4(o.objPos, 1));
				o.screenSpaceObjPos /= o.screenSpaceObjPos.z;

				o.screenSpaceObjPos.xy *= float2(50, -50);

				return o;
			}

			fixed4 frag(v2f i, out float depth : SV_DEPTH) : SV_Target
			{
				// SPS-I Support
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				// VRChat displays nameplates beyond queue 4000 with depth testing enabled,
				// so we can remove them by writting the nearest depth.
				depth = _DisableNameplates ? 1 : i.pos.z;

				if (_DisplayOnSurface)
				{
					// Normally the normalization inverts the coordinates since view-space Z is negative,
					// so we need to reproduce that here. Additionally, the screen space object position
					// needs to be scaled by the view position so that when using Centered On Object
					// coordinates the origin doesn't fly away with view distance.
					i.viewPos.xyz *= -1;
					i.screenSpaceObjPos.xy *= i.viewPos.z;
				}
				else
				{
					// Normalize onto the Z plane to get our 2D coordinates for easy distortion math.
					i.viewPos.xyz /= i.viewPos.z;
				}
			
				// The new screen-space coordinate system is backwards and smaller compared to the old
				// system. So in order to prevent breaking all previously made effects we need to
				// invert and scale our coordinates.
				i.viewPos.xyz *= float3(50, -50, -50);

				// Centered On Object coordinate space
				UNITY_BRANCH
				if(_CoordinateSpace == 2)
					i.viewPos.xy -= i.screenSpaceObjPos.xy;
				
				// Vector from the 'camera' to the world-axis aligned worldPos.
				float3 worldVector = normalize(i.viewPos);

				// Projected coordinate space
				UNITY_BRANCH
				if (_CoordinateSpace == 1)
					i.viewPos = projectCoordinates(i.viewPos, i.camPos, worldVector);

				// Allow for easily changing effect intensities without having to modify
				// an entire animation. Also very useful for adjusting projected coordinates.
				i.viewPos.xyz *= _CoordinateScale;

				// Store the starting position to allow for things like using the
				// derivative (ddx, ddy) to calculate nearby positions to sample depth.
				float4 startingAxisAlignedPos = i.viewPos;
				float4 startingWorldPos = computeWorldPositionFromAxisPosition(startingAxisAlignedPos);

				// Quantize the distortion effects separately from the screen
				float3 cancerEffectQuantizationVector = float3(0, 0, 0);
				UNITY_BRANCH
				if (_CancerEffectQuantization != 0)
				{
					cancerEffectQuantizationVector = i.viewPos.xyz;
					i.viewPos = stereoQuantization(i.viewPos, 10.0 - _CancerEffectQuantization * 10.0);

					cancerEffectQuantizationVector = i.viewPos.xyz - cancerEffectQuantizationVector;
				}

				// Rotate the effects separately from the screen
				UNITY_BRANCH
				if (_CancerEffectRotation != 0)
					i.viewPos.xy = rotate2D(i.viewPos.xy, _CancerEffectRotation);

				// Move the cancer coordiantes separately from the screen
				i.viewPos.xyz += _CancerEffectOffset.xyz;

				// Allow for wrapping the cancer effect coordinates separately from the screen
				float3 cancerEffectWrapVector = float3(0, 0, 0);
				UNITY_BRANCH
				if (_CancerEffectRange != 1)
				{
					cancerEffectWrapVector = i.viewPos.xyz;

					float samplingRange = lerp(1.0, _CancerEffectRange, i.colorDistortionFalloff.y);
					i.viewPos = wrapWorldCoordinates(i.viewPos, samplingRange);

					cancerEffectWrapVector = i.viewPos.xyz - cancerEffectWrapVector;
				}

				float cameraRollAngle = 0;
				UNITY_BRANCH
				if (_RemoveCameraRoll)
				{
					// Note: Cancer coordinates will flip upside down when the camera angle beyond 90 degrees up or down.
					cameraRollAngle = atan2(i.camRight.y, i.camUp.y);

					i.viewPos.xy = rotate2D(i.viewPos.xy, cameraRollAngle);
				}

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
					i.viewPos = stereoEyeConvergence(i.viewPos, axisUp, _EyeConvergence);

				UNITY_BRANCH
				if(_EyeSeparation != 0)
					i.viewPos = stereoEyeSeparation(i.viewPos, axisRight, _EyeSeparation);

				  //////////////////////////////////////////
				 // Apply World-Space Distortion Effects //
				//////////////////////////////////////////
				UNITY_BRANCH
				if (_ShrinkHeight != 0)
					i.viewPos.y += i.viewPos.y*(_ShrinkHeight * 0.02);
				UNITY_BRANCH
				if (_ShrinkWidth != 0)
					i.viewPos.x += i.viewPos.x*(_ShrinkWidth * 0.02);
				
				UNITY_BRANCH
				if (_RotationX != 0)
					i.viewPos.zy = rotate2D(i.viewPos.zy, _RotationX);
				UNITY_BRANCH
				if (_RotationY != 0)
					i.viewPos.xz = rotate2D(i.viewPos.xz, _RotationY);
				UNITY_BRANCH
				if (_RotationZ != 0)
					i.viewPos.xy = rotate2D(i.viewPos.xy, _RotationZ);
				
				i.viewPos.xyz += float3(_MoveX, _MoveY, _MoveZ);

				UNITY_BRANCH
				if(_ScreenShakeXIntensity != 0 || _ScreenShakeYIntensity != 0 || _ScreenShakeZIntensity != 0)
					i.viewPos = stereoShake(i.viewPos, _ScreenShakeSpeed, _ScreenShakeXIntensity, _ScreenShakeXAmplitude, _ScreenShakeYIntensity, _ScreenShakeYAmplitude,
						_ScreenShakeZIntensity, _ScreenShakeZAmplitude);

				UNITY_BRANCH
				if (_SplitXDistance != 0)
				{
					// Since this function sets clearPixel for pixels inside the split
					// we need to scale the split point to syncronize with distortion
					// falloff.
					float flipPoint = rotate2D(i.viewPos.xy/i.colorDistortionFalloff.y, _SplitXAngle).x;

					i.viewPos = stereoSplit(i.viewPos, axisRight, flipPoint, _SplitXDistance, _SplitXHalf, clearPixel);
				}
				UNITY_BRANCH
				if (_SplitYDistance != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy/i.colorDistortionFalloff.y, _SplitYAngle).y;

					i.viewPos = stereoSplit(i.viewPos, axisUp, flipPoint, _SplitYDistance, _SplitYHalf, clearPixel);
				}

				UNITY_BRANCH
				if (_SkewXDistance != 0)
				{
					i.viewPos.xyz += stereoSkew(rotate2D(i.viewPos.xy, _SkewXAngle), axisRight, i.viewPos.y, _SkewXInterval, _SkewXDistance, _SkewXOffset);
				}
				UNITY_BRANCH
				if (_SkewYDistance != 0)
				{
					i.viewPos.xyz += stereoSkew(rotate2D(i.viewPos.xy, _SkewYAngle), axisUp, i.viewPos.x, _SkewYInterval, _SkewYDistance, _SkewYOffset);
				}

				UNITY_BRANCH
				if (_BarXDistance != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _BarXAngle).y;

					i.viewPos.xyz += stereoBar(axisRight, flipPoint, _BarXInterval, _BarXOffset, _BarXDistance);
				}
				UNITY_BRANCH
				if (_BarYDistance != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _BarYAngle).x;

					i.viewPos.xyz += stereoBar(axisUp, flipPoint, _BarYInterval, _BarYOffset, _BarYDistance);
				}

				UNITY_BRANCH
				if (_SinBarXDistance != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _SinBarXAngle).y;

					i.viewPos.xyz += stereoSinBar(axisRight, flipPoint, _SinBarXInterval, _SinBarXOffset, _SinBarXDistance);
				}
				UNITY_BRANCH
				if (_SinBarYDistance != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _SinBarYAngle).x;

					i.viewPos.xyz += stereoSinBar(axisUp, flipPoint, _SinBarYInterval, _SinBarYOffset, _SinBarYDistance);
				}

				UNITY_BRANCH
				if (_MeltDistance != 0)
				{
					i.viewPos.xy += rotate2D(float2(0,1), _MeltAngle) * stereoMelt(rotate2D(i.viewPos.xy, _MeltAngle), _MeltInterval, _MeltVariance, _MeltSeed, _MeltDistance, _MeltBothDirections);
				}

				UNITY_BRANCH
				if (_ZigZagXAmplitude != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _ZigZagXAngle).y;

					i.viewPos = stereoZigZag(i.viewPos, axisRight, flipPoint, _ZigZagXDensity, _ZigZagXAmplitude, _ZigZagXOffset);
				}
				UNITY_BRANCH
				if (_ZigZagYAmplitude != 0)
				{
					float flipPoint = rotate2D(i.viewPos.xy, _ZigZagYAngle).x;

					i.viewPos = stereoZigZag(i.viewPos, axisUp, flipPoint, _ZigZagYDensity, _ZigZagYAmplitude, _ZigZagYOffset);
				}

				UNITY_BRANCH
				if (_SinWaveAmplitude != 0 && _SinWaveAmplitude != 0)
				{
					float3 axis = float3(rotate2D(axisRight.xy, _SinWaveAngle), axisRight.z);

					i.viewPos.xyz += stereoSinWave(rotate2D(i.viewPos.xy, _SinWaveAngle), axis, _SinWaveDensity / 100, _SinWaveAmplitude, _SinWaveOffset);
				}
				UNITY_BRANCH
				if (_CosWaveAmplitude != 0 && _CosWaveAmplitude != 0)
				{
					float3 axis = float3(rotate2D(axisUp.xy, _CosWaveAngle), axisUp.z);

					i.viewPos.xyz += stereoCosWave(rotate2D(i.viewPos.xy, _CosWaveAngle), axis, _CosWaveDensity / 100, _CosWaveAmplitude, _CosWaveOffset);
				}

				UNITY_BRANCH
				if (_SinCosWaveAmplitude != 0 && _SinCosWaveAmplitude != 0)
				{
					float3 axis = float3(rotate2D(axisRight.xy, _SinCosWaveAngle), axisRight.z);

					i.viewPos.xyz += stereoSinCosWave(rotate2D(i.viewPos.xy, _SinCosWaveAngle), axis, _SinCosWaveSinDensity / 100, _SinCosWaveCosDensity / 100, _SinCosWaveAmplitude, _SinCosWaveSinOffset, _SinCosWaveCosOffset);
				}

				UNITY_BRANCH
				if (_TanWaveDensity != 0 && _TanWaveAmplitude != 0)
				{
					float3 axis = float3(rotate2D(axisRight.xy, _TanWaveAngle), axisRight.z);

					i.viewPos.xyz += stereoTanWave(rotate2D(i.viewPos.xy, _TanWaveAngle), axis, _TanWaveDensity / 100, _TanWaveAmplitude, _TanWaveOffset);
				}

				UNITY_BRANCH
				if (_SliceDistance != 0)
					i.viewPos = stereoSlice(i.viewPos, axisUp, _SliceAngle, _SliceWidth, _SliceDistance, _SliceOffset);
				
				UNITY_BRANCH
				if (_RippleAmplitude != 0)
					i.viewPos = stereoRipple(i.viewPos, axisFront, _RippleDensity / 100, _RippleAmplitude, _RippleOffset, _RippleInnerFalloff, _RippleOuterFalloff);

				UNITY_BRANCH
				if (_CheckerboardShift != 0)
					i.viewPos = stereoCheckerboard(i.viewPos, axisFront, _CheckerboardAngle, _CheckerboardScale, _CheckerboardShift);

				UNITY_BRANCH
				if (_Quantization != 0)
					i.viewPos = stereoQuantization(i.viewPos, 10.0 - _Quantization*10.0);

				UNITY_BRANCH
				if (_RingRotationWidth != 0)
					i.viewPos = stereoRingRotation(i.viewPos, _RingRotationInnerAngle, _RingRotationOuterAngle, _RingRotationRadius / 10, _RingRotationWidth / 10);

				UNITY_BRANCH
				if (_WarpIntensity != 0)
					i.viewPos = stereoWarp(i.viewPos, axisFront, _WarpAngle, _WarpIntensity);

				UNITY_BRANCH
				if (_SpiralIntensity != 0)
					i.viewPos = stereoSpiral(i.viewPos, _SpiralIntensity / 1000);

				UNITY_BRANCH
				if (_PolarInversionIntensity != 0)
					i.viewPos = stereoPolarInversion(i.viewPos, _PolarInversionIntensity);

				UNITY_BRANCH
				if(_FishEyeIntensity != 0)
					i.viewPos.xyz += stereoFishEye(i.viewPos, axisFront, _FishEyeIntensity);

				UNITY_BRANCH
				if(_KaleidoscopeSegments > 0)
					i.viewPos = stereoKaleidoscope(i.viewPos, _KaleidoscopeAngle, _KaleidoscopeSegments);

				UNITY_BRANCH
				if (_BlockDisplacementSize != 0)
					i.viewPos.xy += stereoBlockDisplacement(rotate2D(i.viewPos.xy, _BlockDisplacementAngle), _BlockDisplacementSize, _BlockDisplacementIntensity, _BlockDisplacementMode, _BlockDisplacementOffset, clearPixel);
				
				UNITY_BRANCH
				if (_GlitchCount != 0 && _GlitchIntensity != 0)
				{
					// Think you have enough function parameters there buddy?
					i.viewPos.xyz += stereoGlitch(float3(rotate2D(i.viewPos.xy, _GlitchAngle), i.viewPos.z), axisFront, axisRight, axisUp,
						_GlitchCount, _MinGlitchWidth, _MinGlitchHeight, _MaxGlitchWidth, 
						_MaxGlitchHeight, _GlitchIntensity, _GlitchSeed, _GlitchSeedInterval);
				}

				UNITY_BRANCH
				if (_NoiseStrength != 0)
				{
					float noiseScale = abs(_NoiseScale) > 0.00001 ? _NoiseScale : 0.00001;
					i.viewPos.xyz += snoise((i.viewPos.xyz + axisFront * _NoiseOffset) / noiseScale) * _NoiseStrength;
				}
					
				UNITY_BRANCH
				if (_VoroniNoiseStrength != 0 || _VoroniNoiseBorderStrength != 0)
				{
					float voroniNoiseScale = abs(_VoroniNoiseScale) > 0.00001 ? _VoroniNoiseScale : 0.00001;
					i.viewPos = stereoVoroniNoise(i.viewPos, voroniNoiseScale, _VoroniNoiseOffset, _VoroniNoiseStrength, _VoroniNoiseBorderSize, _VoroniNoiseBorderMode, _VoroniNoiseBorderStrength, clearPixel);
				}
					
				UNITY_BRANCH
				if (_FanDistance != 0 && _FanScale != 0)
					i.viewPos = fan(i.viewPos, axisRight, axisUp, _FanScale, _FanDistance*0.1, _FanBlades, _FanOffset*0.1);

				UNITY_BRANCH
				if (_GeometricDitherDistance != 0)
					i.viewPos = geometricDither(i.viewPos, axisRight, axisUp, _GeometricDitherDistance, _GeometricDitherQuality, _GeometricDitherRandomization);

				// Apply displacement map after distortion effects so that it isn't just a static element.
				UNITY_BRANCH
				if (_DisplacementMapIntensity != 0)
				{
					UNITY_LOOP
					for (int q = 0; q < _DisplacementMapIterations; q++)
					{
						float4 samplePosition = i.viewPos;
						if (_DisplacementMapAngle != 0)
							samplePosition.xy = rotate2D(samplePosition.xy, _DisplacementMapAngle);

						samplePosition.xy *= 1 + _DisplacementMapScaleWithDistance * distance(i.centerCamPos, i.objPos);

						bool dropDistortion = false;
						half4 displacementVector = stereoImageOverlay(samplePosition, startingAxisAlignedPos,
							_DisplacementMap, _DisplacementMap_ST, _DisplacementMap_TexelSize,
							_DisplacementMapColumns, _DisplacementMapRows, _DisplacementMapCount, _DisplacementMapIndex,
							_DisplacementMapClamp, _DisplacementMapCutOut,
							dropDistortion);

						float displacementAmount = (!dropDistortion) * _DisplacementMapIntensity;

						// Interpret displacement map using the screen as a surface
						// Red = Left-Right
						// Green = Forward-Back
						// Blue = Up-Down

						// Normal Map
						if (_DisplacementMapType == 0)
							displacementVector.xyz = UnpackNormal(displacementVector).xyz;
						// Color
						// Textures are 8 bits per color, so in order to have a '0' distortion value
						// we need to calculate the origin from 127/255.
						//
						// Note: This assumes the user has unchecked the 'sRGB (Color Texture)' box
						//		 for their texture.
						else
							displacementVector.xyz = (displacementVector.xzy - 0.4980392);

						// Since cos is a symetrical function we can add our displacement to its input value
						// to create a wobble which changes interval based on the distortion. This makes it
						// much more interesting to look at than a global sin/cos multiplication.
						if (_DisplacementMapOscillationSpeed != 0)
							displacementVector.xyz += cos(UNITY_TWO_PI * frac((_Time.x * _DisplacementMapOscillationSpeed) + (q+1)*rcp(_DisplacementMapIterations)) + UNITY_TWO_PI*displacementVector.xyz);

						i.viewPos.xyz += displacementVector.xyz * (displacementAmount * rcp(_DisplacementMapIterations));
					}
				}

				// Shift world pos back from its current axis-aligned position to
				// the position it should be in-front of the camera.
				float4 worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);

				// Finally acquire our stereo position with which we can sample the screen texture.
				float4 stereoPosition = computeStereoUV(worldCoordinates);

				UNITY_BRANCH
				if (_ColorVectorDisplacementStrength != 0)
				{
					float3 colorDisplacement = colorVectorDisplacement(stereoPosition, _ColorVectorDisplacementStrength);

					// View Space
					UNITY_BRANCH
					if (_ColorVectorDisplacementCoordinateSpace == 0)
					{
						i.viewPos.xyz += colorDisplacement;

						// Update world pos to match our new modified view-space position.
						worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);
					}
					// World Space
					else
					{
						worldCoordinates.xyz -= colorDisplacement;

						// Update view-space pos to match our new modified world position.
						i.viewPos = mul(UNITY_MATRIX_V, worldCoordinates);
						i.viewPos.x *= -1;
					}

					stereoPosition = computeStereoUV(worldCoordinates);
				}

				// Requires a directional light to be in the scene so that _CameraDepthTexture is enabled.
				UNITY_BRANCH
				if (_NormalVectorDisplacementStrength != 0)
				{
					float3 normalDisplacement = normalVectorDisplacement(stereoPosition,
						worldCoordinates, i.camPos, i.camRight, i.camUp, _NormalVectorDisplacementCoordinateSpace, _NormalVectorDisplacementQuality);

					normalDisplacement *= _NormalVectorDisplacementStrength;

					// Debug normals
					//return float4(normalDisplacement*0.5 + 0.5, 1);

					// View Space
					UNITY_BRANCH
					if (_NormalVectorDisplacementCoordinateSpace == 0)
					{
						i.viewPos.xyz += normalDisplacement;

						// Update world pos to match our new modified view-space position.
						worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);
					}
					// World Space
					else
					{
						worldCoordinates.xyz -= normalDisplacement;

						// Update view-space pos to match our new modified world position.
						i.viewPos = mul(UNITY_MATRIX_V, worldCoordinates);
						i.viewPos.x *= -1;
					}

					stereoPosition = computeStereoUV(worldCoordinates);
				}

				// Wrap world coordinates after all effects have been applied
				// This allows for hiding the VR Mask when wrapping around
				//
				// Todo: Grab the frustum corners to calculate the starting
				//		 wrap value.

				if (_WorldSamplingRange != 1)
				{
					float samplingRange = lerp(1.0, _WorldSamplingRange, i.colorDistortionFalloff.y);

					// Wrap
					if (_WorldSamplingMode == 0)
					{
						i.viewPos = wrapWorldCoordinates(i.viewPos, samplingRange);

						worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);

						stereoPosition = computeStereoUV(worldCoordinates);
					}
					// Cutout
					else if (_WorldSamplingMode == 1)
					{
						float sampleLimit = samplingRange * 100;
						sampleLimit -= (abs(i.viewPos.z - 100) / 100)*sampleLimit;
						sampleLimit = abs(sampleLimit);

						if (i.viewPos.x < -sampleLimit || i.viewPos.x > sampleLimit ||
							i.viewPos.y < -sampleLimit || i.viewPos.y > sampleLimit)
							discard;
					}
					// Clamp
					else if (_WorldSamplingMode == 2)
					{
						float sampleLimit = samplingRange * 100;
						sampleLimit -= (abs(i.viewPos.z - 100) / 100)*sampleLimit;
						sampleLimit = abs(sampleLimit);

						i.viewPos.xy = clamp(i.viewPos.xy, -sampleLimit, sampleLimit);

						// Update world pos to match our new modified world axis position.
						worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);

						stereoPosition = computeStereoUV(worldCoordinates);
					}
					// Empty Space
					else if (_WorldSamplingMode == 3)
					{
						float sampleLimit = samplingRange * 100;
						sampleLimit -= (abs(i.viewPos.z - 100) / 100)*sampleLimit;
						sampleLimit = abs(sampleLimit);

						if (i.viewPos.x < -sampleLimit || i.viewPos.x > sampleLimit
							|| i.viewPos.y < -sampleLimit || i.viewPos.y > sampleLimit)
						{
							clearPixel = true;
						}
					}
				}

				// Distortion effects which take the inout variable clearPixel create empty space, 
				// so we can return now if we aren't filling the empty space (Override mode 2).
				if (clearPixel && _MemeTexOverrideMode != 2)
					return half4(_EmptySpaceColor.rgb, _CancerOpacity);

				UNITY_BRANCH
				if (_MaskMapOpacity != 0)
				{
					// Toggle between final and starting pos
					// May need to adjust for sample mode etc
					float4 samplePosition = _MaskSampleDistortedCoordinates == 1 ? i.viewPos : startingAxisAlignedPos;

					if (_MaskMapAngle != 0)
						samplePosition.xy = rotate2D(samplePosition.xy, _MaskMapAngle);

					samplePosition.xy *= 1 + _MaskMapScaleWithDistance * distance(i.centerCamPos, i.objPos);

					bool dropMask = false;
					float cancerMaskValue = 1 - stereoImageOverlay(samplePosition, startingAxisAlignedPos,
						_MaskMap, _MaskMap_ST, _MaskMap_TexelSize,
						_MaskMapColumns, _MaskMapRows, _MaskMapCount, _MaskMapIndex,
						_MaskMapClamp, _MaskMapCutOut,
						dropMask).r;

					cancerMaskValue *= _MaskMapOpacity;

					if (dropMask)
						cancerMaskValue = 1;

					// Hijack falloff to apply the mask without additional work
					i.colorDistortionFalloff -= i.colorDistortionFalloff*float2(cancerMaskValue * ((_MaskFlags & 1) != 0), cancerMaskValue * ((_MaskFlags & 2) != 0));
					i.colorDistortionFalloff = clamp(i.colorDistortionFalloff, 0, 1);
				}

				// Apply falloff to distortion
				UNITY_BRANCH
				if (i.colorDistortionFalloff.y < 1)
				{
					i.viewPos.xyz = lerp(startingAxisAlignedPos.xyz, i.viewPos.xyz, i.colorDistortionFalloff.y);

					worldCoordinates = lerp(startingWorldPos, worldCoordinates, i.colorDistortionFalloff.y);
					stereoPosition = computeStereoUV(worldCoordinates);
				}

				// Undo the camera roll removal, cancer effect offset, rotation, and quantization for ONLY the screen sample coordinates
				// This allows for moving effects around without affecting the screen.
				// Ex. Meme spotlight movement via Vignette 
				float4 originalViewPos = i.viewPos;

				UNITY_BRANCH
				if (_RemoveCameraRoll)
				{
					i.viewPos.xy = rotate2D(i.viewPos.xy, -cameraRollAngle * i.colorDistortionFalloff.y);

					worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);
					stereoPosition = computeStereoUV(worldCoordinates);
				}

				UNITY_BRANCH
				if (any(_CancerEffectOffset.xyz) || _CancerEffectRotation != 0 || _CancerEffectRange != 1.f)
				{
					i.viewPos.xyz -= cancerEffectWrapVector*i.colorDistortionFalloff.y;

					i.viewPos.xyz -= _CancerEffectOffset.xyz*i.colorDistortionFalloff.y;
					i.viewPos.xy = rotate2D(i.viewPos.xy, -_CancerEffectRotation);

					float4 temp = computeWorldPositionFromAxisPosition(i.viewPos);
					stereoPosition = computeStereoUV(temp);
				}

				UNITY_BRANCH
				if (_CancerEffectQuantization != 0)
				{
					i.viewPos.xyz -= cancerEffectQuantizationVector*i.colorDistortionFalloff.y;

					float4 temp = computeWorldPositionFromAxisPosition(i.viewPos);
					stereoPosition = computeStereoUV(temp);
				}

				// Centered On Object coordinate space
				UNITY_BRANCH
				if (_CoordinateSpace == 2)
				{
					i.viewPos.xy += i.screenSpaceObjPos.xy*_CoordinateScale*i.colorDistortionFalloff.y;

					worldCoordinates = computeWorldPositionFromAxisPosition(i.viewPos);
					stereoPosition = computeStereoUV(worldCoordinates);

					i.camFront = normalize(i.objPos - i.centerCamPos);
				}

				i.viewPos = originalViewPos;

				// Default UV clamping works for desktop, but for VR
				// we may want to constrain UV coordinates to
				// each eye.
				UNITY_BRANCH
				if (_ScreenSamplingMode == 1)
					stereoPosition = clampUVCoordinates(stereoPosition);
				// Wrapping allows for creating 'infinite' texture
				// and tunnel effects.
				else if (_ScreenSamplingMode == 2)
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
					bgcolor = UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, stereoPosition.xy / stereoPosition.w);

					UNITY_BRANCH
					if (_ChromaticAberrationBlend != 0 && _ChromaticAberrationStrength != 0)
					{
						half3 chromaticColor = chromaticAberration( worldCoordinates, i.camFront, _ChromaticAberrationStrength, _ChromaticAberrationSeparation, _ChromaticAberrationShape);
						bgcolor.rgb = lerp(bgcolor.rgb, chromaticColor, _ChromaticAberrationBlend);
					}
					UNITY_BRANCH
					if (_BlurMovementBlend != 0 && _BlurMovementOpacity != 0)
					{
						half3 blurColor = blurMovement(startingWorldPos, worldCoordinates, _BlurMovementSampleCount,
							_BlurMovementTarget, _BlurMovementRange, _BlurMovementExtrapolation, _BlurMovementBlurIntensity, _BlurMovementOpacity);
						bgcolor.rgb = lerp(bgcolor.rgb, blurColor, _BlurMovementBlend);
					}
					UNITY_BRANCH
					if (_DistortionDesyncBlend != 0 && any(float3(_DistortionDesyncR, _DistortionDesyncG, _DistortionDesyncB)))
					{
						half3 rgbColor = rgbColorDesync(startingWorldPos, worldCoordinates, _DistortionDesyncR, _DistortionDesyncG, _DistortionDesyncB);
						bgcolor.rgb = lerp(bgcolor.rgb, rgbColor, _DistortionDesyncBlend);
					}

					// Ensure pure black is not captured, which ruins image blending and other effects
					// such as value adjustment
					bgcolor.rgb += 0.00000001;

					bgcolor *= _ColorMask;
				}

				UNITY_BRANCH
				if (_PaletteOpacity != 0)
				{
					float3 palleteWorldPos = worldPosFromDepth(computeStereoUV(worldCoordinates), i.camPos, worldCoordinates);
					half3 paletteColor = palletization(palleteWorldPos, bgcolor, _PalleteSource, _PaletteScale, _PaletteOffset, _PaletteA, _PaletteB, _PaletteOscillation, _PalettePhase);
					
					bgcolor.rgb = lerp(bgcolor.rgb, paletteColor, _PaletteOpacity);
				}

				float3 inversionParameters = float3(_ColorInversionR, _ColorInversionG, _ColorInversionB);
				UNITY_BRANCH
				if (any(inversionParameters))
				{
					float3 invertedColor = length(bgcolor.rgb) - bgcolor.rgb;

					bgcolor.rgb = lerp(bgcolor.rgb, invertedColor.rgb, inversionParameters.rgb);
				}

				UNITY_BRANCH
				if (_ColorModifierMode != 0)
					bgcolor.rgb = colorModifier(bgcolor.rgb, _ColorModifierMode, _ColorModifierStrength, _ColorModifierBlend);

				UNITY_BRANCH
				if (_TriplanarOpacity != 0)
				{
					float3 normal = normalVectorDisplacement(stereoPosition,
						worldCoordinates, i.camPos, i.camRight, i.camUp, _TriplanarCoordinateSrc == 2 ? 0 : 1, _TriplanarQuality);

					// UV range is reduced to the range(0.2, 0.8) to hide the VR mask.
					float sampleRange = _TriplanarSampleSrc == 0 ? 1 : 0.6;

					half3 triplanarColor = stereoTriplanarMappping(_TriplanarMap, _TriplanarMap_ST, stereoPosition, i.camPos, normal, worldCoordinates, i.viewPos,
						_TriplanarOffsetX, _TriplanarOffsetY, _TriplanarOffsetZ, _TriplanarCoordinateSrc, _TriplanarScale, _TriplanarSharpness, sampleRange, _TriplanarSampleSrc > 0);

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
					bgcolor.rgb += signalNoise(i.viewPos, _SignalNoiseSize, _ColorizedSignalNoise, _SignalNoiseOpacity);

				UNITY_BRANCH
				if (_FogType != 0)
				{
					float4 fogWorldPosition = i.viewPos;

					// Fog requires projected coordinates, so if the user isn't using them
					// then we need to project the coordinates ourself.
					if (_CoordinateSpace == 0)
						fogWorldPosition = projectCoordinates(fogWorldPosition, i.camPos, normalize(fogWorldPosition));
					// Center On Object, doesn't support mirrors. Will be black.
					else if(_CoordinateSpace == 2)
					{
						fogWorldPosition.xyz = worldPosFromDepth(stereoPosition, i.camPos, worldCoordinates);
						fogWorldPosition.xyz -= i.objPos;
					}

					bgcolor.rgb = fog(bgcolor.rgb, fogWorldPosition, _FogType, _FogColor, _FogBegin, _FogEnd);
				}

				UNITY_BRANCH
				if (_EdgelordStripeSize != 0)
				{
					float2 edgelordUV = (i.viewPos.xy / i.viewPos.w);
					bgcolor = edgelordStripes(edgelordUV, bgcolor, _EdgelordStripeColor, _EdgelordStripeSize, _EdgelordStripeOffset);
				}

				UNITY_BRANCH
				if(_MemeTexOpacity != 0)
				{
					float4 samplePosition = i.viewPos;
					if (_MemeImageAngle != 0)
						samplePosition.xy = rotate2D(samplePosition.xy, _MemeImageAngle);

					samplePosition.xy *= 1 + _MemeImageScaleWithDistance*distance(i.centerCamPos, i.objPos);

					bool dropMemePixels = false;
					half4 memeColor = stereoImageOverlay(samplePosition, startingAxisAlignedPos,
						_MemeTex, _MemeTex_ST, _MemeTex_TexelSize,
						_MemeImageColumns, _MemeImageRows, _MemeImageCount, _MemeImageIndex,
						_MemeTexClamp, _MemeTexCutOut,
						dropMemePixels);

					if (dropMemePixels == false)
					{
						if (memeColor.a > _MemeTexAlphaCutOff)
						{
							// No override mode, blend image in.
							if (_MemeTexOverrideMode == 0)
							{
								bgcolor.rgb = lerp(bgcolor.rgb, memeColor.rgb, (_MemeTexOpacity*memeColor.a));
							}
							// Override Background
							else if (_MemeTexOverrideMode == 1)
							{
								bgcolor = float4(memeColor.rgb * (_MemeTexOpacity*memeColor.a), 1);
							}
							// Override Empty Space
							else if (_MemeTexOverrideMode == 2)
							{
								if (clearPixel)
								{
									bgcolor = float4(memeColor.rgb * (_MemeTexOpacity*memeColor.a), 1);
									return bgcolor;
								}
							}
						}
						// Overriding background but pixel has been cutout.
						else if (_MemeTexOverrideMode == 1)
							discard;
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
				{
					float4 samplePos = _CircularVignetteScaleWithDistance == 1 ? i.viewPos * distance(i.centerCamPos, i.objPos) : i.viewPos;

					bgcolor.rgb = circularVignette(bgcolor, samplePos, _CircularVignetteColor, _CircularVignetteOpacity,
						_CircularVignetteRoundness, _CircularVignetteMode, _CircularVignetteBegin, _CircularVignetteEnd);
				}

				UNITY_BRANCH
				if (_Hue != 0 || _Saturation != 0 || _Value != 0)
					bgcolor.rgb = applyHSV(bgcolor, _Hue, _Saturation, _Value, _ClampSaturation);

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

				UNITY_BRANCH
				if (_SobelOpacity != 0)
				{
					float sobelMagnitude = sobelFilter(i.camRight, i.camUp, worldCoordinates, _SobelSearchDistance, _SobelQuality)*_SobelOpacity;

					// None, aka Overwrite
					if (_SobelBlendMode == 0)
						bgcolor = float4(sobelMagnitude, sobelMagnitude, sobelMagnitude, 1);
					// Multiply
					else if (_SobelBlendMode == 1)
						bgcolor.rgb *= sobelMagnitude;
					// MulAdd
					else if (_SobelBlendMode == 2)
						bgcolor.rgb += bgcolor.rgb*sobelMagnitude;
				}

				// Check opacity and override since the user may be intentionally
				// removing the color channel.
				UNITY_BRANCH
				if (_colorSkewROpacity != 0 || _colorSkewROverride != 0)
				{
					float redColor = colorShift(_colorSkewRAngle, _colorSkewRDistance,
						_colorSkewROpacity, stereoPosition).r;

					if (_colorSkewROverride != 0)
						bgcolor.r = redColor;
					else
						bgcolor.r += redColor;
				}
				UNITY_BRANCH
				if (_colorSkewGOpacity != 0 || _colorSkewGOverride != 0)
				{
					float greenColor = colorShift(_colorSkewGAngle, _colorSkewGDistance,
						_colorSkewGOpacity, stereoPosition).g;

					if (_colorSkewGOverride != 0)
						bgcolor.g = greenColor;
					else
						bgcolor.g += greenColor;
				}
				UNITY_BRANCH
				if (_colorSkewBOpacity != 0 || _colorSkewBOverride != 0)
				{
					float blueColor = colorShift(_colorSkewBAngle, _colorSkewBDistance,
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

				// Apply falloff to color
				bgcolor.a = _CancerOpacity*i.colorDistortionFalloff.x;

				// I'm sorry fellow VRChat players, but you've just contracted eye-cancer.
				//	-xwidghet
				return bgcolor;
			}
			ENDCG
		}
	}
	CustomEditor "StereoCancerGUI"
}
