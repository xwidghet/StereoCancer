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
	// ex. Geometric Dither is created by using SkewX and SkewY repeatedly with varying parameter values
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
	//			This shader also makes use of the voroni noise generator created by Ronja Böhringer,
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
		// Particle System parameters
		_ParticleSystem("Particle System", Int) = 0

		// Image Effects
		_MemeTex("Meme Image (RGB)", 2D) = "white" {}
		_MemeTexOpacity("Meme Opacity", Float) = 0
		_MemeTexClamp("Meme Clamp", Int) = 0
		_MemeTexCutOut("Meme Cut Out", Int) = 0
		_MemeTexAlphaCutOff("Meme Alpha CutOff", Float) = 0.9
		_MemeTexOverride("Meme Override Background", Int) = 0

		_CancerOpacity("Cancer Opacity", Float) = 1

		_ShrinkWidth("Shrink Width", Float) = 0
		_ShrinkHeight("Shrink Height", Float) = 0

		// Screen Distortion Effects
		_RotationX("Rotation X (Pitch Down-/Up+)", Float) = 0
		_RotationY("Rotation Y (Yaw Left-/Right+)", Float) = 0
		_RotationZ("Rotation Z (Roll Left-/Right+)", Float) = 0
		
		_MoveX("Move X (Left-/Right+)", Float) = 0
		_MoveY("Move Y (Down-/Up+)", Float) = 0
		_MoveZ("Move Z (Forward-/Back+)", Float) = 0

		_SkewXDistance("Skew X Distance", Float) = 0
		_SkewXInterval("Skew X Interval", Float) = 0
		_SkewXOffset("Skew X Offset", Float) = 0

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

		_ZigZagXDensity("ZigZag X Density", Float) = 0
		_ZigZagXAmplitude("ZigZag X Amplitude", Float) = 0
		_ZigZagXOffset("ZigZag X Offset", Float) = 0

		_ZigZagYDensity("ZigZag Y Density", Float) = 0
		_ZigZagYAmplitude("ZigZag Y Amplitude", Float) = 0
		_ZigZagYOffset("ZigZag Y Offset", Float) = 0

		_SinWaveDensity("Sin Wave Density", Float) = 0
		_SinWaveAmplitude("Sin Wave Amplitude", Float) = 0
		_SinWaveOffset("Sin Wave Offset", Float) = 0

		_TanWaveDensity("Tan Wave Density", Float) = 0
		_TanWaveAmplitude("Tan Wave Amplitude", Float) = 0
		_TanWaveOffset("Tan Wave Offset", Float) = 0

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

		_GlitchCount("Glitch Count", Range(0, 32)) = 0
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
		_VoroniNoiseOffset("Voroni Noise Offset", Float) = 0

		_GeometricDitherDistance("Geometric Dither Distance", Float) = 0
		_GeometricDitherQuality("Geometric Dither Quality", Range(1, 6)) = 5
		_GeometricDitherRandomization("Geometric Dither Randomization", Float) = 0

		// Screen color effects
		_EdgelordStripeColor("Edgelord Stripe Color", Color) = (0, 0, 0, 1)
		_EdgelordStripeSize("Edgelord Stripe Size", Float) = 0
		_EdgelordStripeOffset("Edgelord Stripe Offset", Float) = 0

		_Hue("Hue", Float) = 0
		_Saturation("Saturation", Float) = 0
		_Value("Value", Float) = 0

		_ChromaticAbberationStrength("Chromatic Abberation Strength", Float) = 0

		_SignalNoiseSize("Signal Noise Size", Float) = 0
		_ColorizedSignalNoise("Colorized Signal Noise", Float) = 0
		_SignalNoiseOpacity("Signal Noise opacity", Float) = 0

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
			
			sampler2D _MemeTex;
			float4 _MemeTex_TexelSize;
			float4 _MemeTex_ST;
			float _MemeTexOpacity;
			int _MemeTexClamp;
			int _MemeTexCutOut;
			float _MemeTexAlphaCutOff;
			int _MemeTexOverride;

			sampler2D _stereoCancerTexture;
			float4 _stereoCancerTexture_TexelSize;

			float _CancerOpacity;

			// Screen distortion params
			float _ShrinkWidth;
			float _ShrinkHeight;

			float _RotationX;
			float _RotationY;
			float _RotationZ;

			float _MoveX;
			float _MoveY;
			float _MoveZ;

			float _SkewXDistance;
			float _SkewXInterval;
			float _SkewXOffset;

			float _SkewYDistance;
			float _SkewYInterval;
			float _SkewYOffset;

			float _GeometricDitherDistance;
			float _GeometricDitherQuality;
			float _GeometricDitherRandomization;

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

			float _CheckerboardScale;
			float _CheckerboardShift;
			float _Quantization;

			float _RingRotationAngle;
			float _RingRotationRadius;
			float _RingRotationWidth;

			float _SpiralIntensity;

			float _FishEyeIntensity;

			float _SinWaveDensity;
			float _SinWaveAmplitude;
			float _SinWaveOffset;

			float _TanWaveDensity;
			float _TanWaveAmplitude;
			float _TanWaveOffset;

			float _ZigZagXDensity;
			float _ZigZagXAmplitude;
			float _ZigZagXOffset;

			float _ZigZagYDensity;
			float _ZigZagYAmplitude;
			float _ZigZagYOffset;

			float _KaleidoscopeSegments;
			float _KaleidoscopeAngle;

			float _GlitchCount;
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
			float _VoroniNoiseOffset;

			// Screen color params
			float4 _EdgelordStripeColor;
			float _EdgelordStripeSize;
			float _EdgelordStripeOffset;

			float _Hue;
			float _Saturation;
			float _Value;

			float _ChromaticAbberationStrength;

			float _SignalNoiseSize;
			float _ColorizedSignalNoise;
			float _SignalNoiseOpacity;

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

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;

				// For getting particle position and scale
				// Scale currently unimplemented
				float4 uv : TEXCOORD0;
				float4 uv2 : TEXCOORD1;
			};

			struct v2f
			{
				float4 worldPos: TEXCOORD1;
				float3 camFront : TEXCOORD2;
				float3 camRight : TEXCOORD3;
				float3 camUp : TEXCOORD4;
				float3x3 inverseViewMatRot : TEXCOORD5;
				float4 pos : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;

				// I could normalize camFront, or I could just live dangerously
				// with reckless abandon to save insignificant amounts of performance.
				o.camFront = mul((float3x3)unity_CameraToWorld, float3(0, 0, 1));
				o.camRight = normalize(cross(o.camFront, float3(0.0, 1.0, 0.0)));
				o.camUp = normalize(cross(o.camFront, o.camRight));

				float3x3 viewMatRot = extract_rotation_matrix(UNITY_MATRIX_V);
				o.inverseViewMatRot = transpose(viewMatRot);

				// The particle knows where it is, and where it isn't.
				// It subtracts where it is, from where it isn't,
				// to move vertices to where they wasn't.
				//
				// Usage: This expects that the user has enabled Center output
				//		  under Custom Vertex Streams in their particle system renderer.
				if (_ParticleSystem == 1)
				{
					// TODO: Add particle size support and rotation negation. The current implementation
					//		 will result in particles with a size greater than 10 being Z-culled in a lot of worlds.
					float3 particleSystemOrigin = v.uv.xyz;
					v.vertex.xyz -= particleSystemOrigin;
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
				o.worldPos.xyz += _WorldSpaceCameraPos;

				o.pos = mul(UNITY_MATRIX_VP, o.worldPos);

				// Align world pos with default world axis.
				//
				// This makes it easy to write effects as the coordinates
				// are all on a 2D XY plane, 100 units away from the camera.
				o.worldPos.xyz = v.vertex.xyz;
				
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// Disable for mirrors so effects like Swirl don't get unwrapped by mirrors.
				// Check shamelessly copy-pasted from CancerSpace, shout outs to AkaiMage.
				// https://github.com/AkaiMage/VRC-Cancerspace
				//
				// Note: Does not contain the additional checks CancerSpace includes,
				//		 such as Per-Eye exclusion, but is otherwise unmodified.
				if (unity_CameraProjection[2][0] != 0 || unity_CameraProjection[2][1] != 0)
				{
					discard;
				}
				
				// Vector from the 'camera' to the world-axis aligned worldPos.
				float3 worldVector = normalize(i.worldPos);

				// Default world-axis values for usage with axis-based effects
				const float3 axisFront = float3(0, 0, -1);
				const float3 axisRight = float3(1, 0, 0);
				const float3 axisUp = float3(0, 1, 0);

				// Uniforms (Shader Parameters in Unity) can be branched on to successfully
				// avoid taking the performance hit of unused effects. This is used on every
				// effect with the most intuitive value to automatically improve performance.

				// Note: Not all effects contain all of the final parameters since I don't
				//		 know how many effects I will add yet, and don't want to have to
				//		 remove parameters users are using to make space for effects.

				  //////////////////////////////////////////
				 // Apply world-space distortion effects //
				//////////////////////////////////////////

				if (_ShrinkHeight != 0)
					i.worldPos = shrink(worldVector, axisUp, i.worldPos, _ShrinkHeight);
				if (_ShrinkWidth != 0)
					i.worldPos = shrink(worldVector, axisRight, i.worldPos, _ShrinkWidth);

				if(_RotationX != 0)
					i.worldPos = stereoRotate(i.worldPos, axisRight, _RotationX);
				if (_RotationY != 0)
					i.worldPos = stereoRotate(i.worldPos, axisUp, _RotationY);
				if (_RotationZ != 0)
					i.worldPos = stereoRotate(i.worldPos, axisFront, _RotationZ);

				i.worldPos.xyz += float3(_MoveX, _MoveY, _MoveZ);
				
				// At interval of 0 the screen will be blank,
				// so we must check both distance and interval
				if(_SkewXDistance != 0 && _SkewXInterval != 0)
					i.worldPos = stereoSkewX(i.worldPos, axisRight, _SkewXInterval, _SkewXDistance, _SkewXOffset);
				if (_SkewYDistance != 0 && _SkewYInterval != 0)
					i.worldPos = stereoSkewY(i.worldPos, axisUp, _SkewYInterval, _SkewYDistance, _SkewYOffset);

				if(_BarXDistance != 0)
					i.worldPos = stereoBarX(i.worldPos, axisFront, axisRight, _BarXAngle, _BarXInterval, _BarXOffset, _BarXDistance);
				if (_BarYDistance != 0)
					i.worldPos = stereoBarY(i.worldPos, axisFront, axisUp, _BarYAngle, _BarYInterval, _BarYOffset, _BarYDistance);

				if (_ZigZagXDensity != 0)
					i.worldPos = stereoZigZagX(i.worldPos, axisRight, _ZigZagXDensity, _ZigZagXAmplitude, _ZigZagXOffset);
				if (_ZigZagYDensity != 0)
					i.worldPos = stereoZigZagY(i.worldPos, axisUp, _ZigZagYDensity, _ZigZagYAmplitude, _ZigZagYOffset);

				if (_SinWaveDensity != 0)
					i.worldPos = stereoSinWave(i.worldPos, axisRight, _SinWaveDensity, _SinWaveAmplitude, _SinWaveOffset);
				if (_TanWaveDensity != 0)
					i.worldPos = stereoTanWave(i.worldPos, axisRight, _TanWaveDensity / 100, _TanWaveAmplitude, _TanWaveOffset);

				if (_CheckerboardScale != 0)
					i.worldPos = stereoCheckerboard(i.worldPos, _CheckerboardScale, _CheckerboardShift);

				if (_Quantization != 0)
					i.worldPos = stereoQuantization(i.worldPos, 10.0 - _Quantization*10.0);

				if (_RingRotationWidth != 0)
					i.worldPos = stereoRingRotation(i.worldPos, axisFront, _RingRotationAngle, _RingRotationRadius / 10, _RingRotationWidth / 10);

				if (_WarpIntensity != 0)
					i.worldPos = stereoWarp(i.worldPos, axisFront, _WarpAngle, _WarpIntensity);

				if (_SpiralIntensity != 0)
					i.worldPos = stereoSpiral(i.worldPos, axisFront, _SpiralIntensity / 1000);

				if(_FishEyeIntensity != 0)
					i.worldPos = stereoFishEye(i.worldPos, axisFront, _FishEyeIntensity);

				if(_KaleidoscopeSegments > 0)
					i.worldPos = stereoKaleidoscope(i.worldPos, axisFront, _KaleidoscopeAngle, _KaleidoscopeSegments);

				// Think you have enough function parameters there buddy?
				if (_GlitchCount != 0 && _GlitchIntensity != 0)
					i.worldPos = stereoGlitch(i.worldPos, axisFront, axisRight, axisUp,
						_GlitchCount, _MaxGlitchWidth, _MaxGlitchHeight, _GlitchIntensity,
						_GlitchSeed, _GlitchSeedInterval);

				if(_NoiseScale != 0)
					i.worldPos.xyz += snoise((i.worldPos.xyz + axisFront*_NoiseOffset) / _NoiseScale)*_NoiseStrength;
				if (_VoroniNoiseScale != 0)
					i.worldPos = stereoVoroniNoise(i.worldPos, _VoroniNoiseScale, _VoroniNoiseOffset, _VoroniNoiseStrength, _VoroniNoiseBorderSize);
				
				if (_GeometricDitherDistance != 0)
					i.worldPos = geometricDither(i.worldPos, axisRight, axisUp, _GeometricDitherDistance, _GeometricDitherQuality, _GeometricDitherRandomization);

				// Initialize color now so we can apply signal noise in default world-axis space
				half4 bgcolor = half4(0, 0, 0, 0);

				if (_SignalNoiseSize != 0 && _SignalNoiseOpacity != 0)
					bgcolor.rgb += signalNoise(i.worldPos, _SignalNoiseSize, _ColorizedSignalNoise, _SignalNoiseOpacity);

				// Shift world pos back from its current axis-aligned position to
				// the position it should be in-front of the camera.
				i.worldPos.xyz = mul(i.inverseViewMatRot, i.worldPos.xyz);
				i.worldPos.xyz += _WorldSpaceCameraPos;

				// Finally convert world position to the stereo-correct position
				float4 stereoPosition = computeStereoUV(i.worldPos);

				  /////////////////////////
				 // Apply color effects //
			    /////////////////////////

				// No point in sampling background color if the user is going to override it
				// anyway.
				if (_colorSkewROverride == 0 || _colorSkewGOverride == 0 || _colorSkewBOverride == 0)
				{
					if (_ChromaticAbberationStrength != 0)
						bgcolor += chromaticAbberation(_stereoCancerTexture, i.worldPos, i.camFront, _ChromaticAbberationStrength);
					else
						bgcolor += tex2Dproj(_stereoCancerTexture, stereoPosition);
				}

				if (_EdgelordStripeSize != 0)
				{
					float2 edgelordUV = (stereoPosition.xyz / stereoPosition.w).xy;
					bgcolor = edgelordStripes(edgelordUV, bgcolor, _EdgelordStripeColor, _EdgelordStripeSize, _EdgelordStripeOffset);
				}

				// This feature is not in a function as it will discard the current fragment
				// if the user has chosen to completely override the background color, and I
				// don't want that hidden.
				if (_MemeTexOpacity != 0)
				{
					float2 screenUV = (stereoPosition.xyz / stereoPosition.w).xy;
					float offset = 0;

#ifdef UNITY_SINGLE_PASS_STEREO
					// Convert UV coordinates to eye-specific 0-1 coordiantes
					offset = 0.5 * step(1, unity_StereoEyeIndex);
					float min = offset;
					float max = 0.5 + offset;

					float uvDist = max - min;
					screenUV.x = (screenUV.x - min) / uvDist;
#endif

					// Shift UV to the range (-0.5, 0.5) to allow for simpler
					// scaling math.
					screenUV -= 0.5;

					// Use Valve Index as standard FOV scale
					// https://docs.google.com/spreadsheets/d/1q7Va5Q6iU40CGgewoEqRAeypUa1c0zZ86mqR8uIyDeE/edit#gid=0
					screenUV *= getCameraFOV() / 103.6;

					// Apply tiling (Scaling)
					// Not stereo correct, must use the above Shrink Height/Shrink Width functions
					//screenUV *= _MemeTex_ST.xy;

					// Ensure the image doesn't get stretched or squished
					// depending on the users HMD/Display aspect ratio.
					float screenWidth = _ScreenParams.x;
					float screenHeight = _ScreenParams.y;

#ifdef UNITY_SINGLE_PASS_STEREO
					// Ooga, Booga.
					screenWidth *= 2;
#endif

					float ratioX = screenWidth / _MemeTex_TexelSize.z;
					float ratioY = screenHeight / _MemeTex_TexelSize.w;
					screenUV.x /= 1.0 / ratioX;
					screenUV.y /= 1.0 / ratioY;

					// Normalize image scale with respect to Valve Index 100% SS (2016x2240)
					//
					// This prevents HMD rendering resolutions and Super Sampling values
					// changing the image scale.
					float normalizationScaler = 2240 / screenHeight;
					screenUV *= normalizationScaler;

					// Move back to correct coordinate space
					// and apply offset
					screenUV += 0.5;
					screenUV += _MemeTex_ST.zw;

					bool dropMemePixels = false;
					if (_MemeTexCutOut == 1)
					{
						// Exclude the edge pixels when doing _MemeTexCutOut
						// to prevent bilinear sampling artifacts at the image border.
						if (screenUV.y < 0.001 || screenUV.y > 0.999)
							dropMemePixels = true;

						if (offset != 0)
						{
							if (screenUV.x < -0.999 || screenUV.x > 0.999)
								dropMemePixels = true;
						}
						else
						{
							float maxUV = 0.999;

#ifdef UNITY_SINGLE_PASS_STEREO
							maxUV = 1.999;
#endif

							if (screenUV.x < 0.001 || screenUV.x > maxUV)
								dropMemePixels = true;
						}
					}

					if (_MemeTexClamp == 1)
					{
						screenUV.y = clamp(screenUV.y, 0, 1);

						if (offset != 0)
							screenUV.x = clamp(screenUV.x, -1, 1);
						else
						{
							float maxUV = 1;
#ifdef UNITY_SINGLE_PASS_STEREO
							maxUV = 2;
#endif
							screenUV.x = clamp(screenUV.x, 0, maxUV);
						}
					}

#ifdef UNITY_SINGLE_PASS_STEREO
					// Convert the eye-specific 0-1 coordinates back to 0-1 UV coordinates
					screenUV.x = (screenUV.x * uvDist) + min;
#endif

					if (dropMemePixels == false)
					{
						half4 memeColor = tex2D(_MemeTex, screenUV);

						if (memeColor.a > _MemeTexAlphaCutOff)
						{
							if (_MemeTexOverride)
								bgcolor.rgb = memeColor*_MemeTexOpacity;
							else
								bgcolor += memeColor*_MemeTexOpacity;
						}
					}
					else
					{
						if (_MemeTexOverride)
							discard;
					}
				}

				if (_Hue != 0 || _Saturation != 0 || _Value != 0)
				{
					bgcolor.rgb = applyHSV(bgcolor, _Hue, _Saturation, _Value);
				}

				// Check opacity and override since the user may be intentionally
				// removing the color channel.
				if (_colorSkewROpacity != 0 || _colorSkewROverride != 0)
				{
					float redColor = colorShift(_stereoCancerTexture, i.camFront, i.camRight, _colorSkewRAngle, _colorSkewRDistance,
						_colorSkewROpacity, stereoPosition).r;

					if (_colorSkewROverride != 0)
						bgcolor.r = redColor;
					else
						bgcolor.r += redColor;
				}
				if (_colorSkewGOpacity != 0 || _colorSkewGOverride != 0)
				{
					float greenColor = colorShift(_stereoCancerTexture, i.camFront, i.camRight, _colorSkewGAngle, _colorSkewGDistance,
						_colorSkewGOpacity, stereoPosition).g;

					if (_colorSkewGOverride != 0)
						bgcolor.g = greenColor;
					else
						bgcolor.g += greenColor;
				}
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
