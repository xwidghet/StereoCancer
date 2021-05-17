#ifndef STEREO_CANCER_PARAMTERS
#define STEREO_CANCER_PARAMETERS

int _ParticleSystem;
float _CoordinateSpace;
float _CoordinateScale;
float _WorldSamplingMode;
float _WorldSamplingRange;
float _CancerEffectQuantization;
float _CancerEffectRotation;
float4 _CancerEffectOffset;
float _CancerEffectRange;
int _RemoveCameraRoll;
float _Visibility;
int _FalloffEnabled;
int _FalloffFlags;
float _FalloffBeginPercentage;
float _FalloffEndPercentage;
float _FalloffAngleBegin;
float _FalloffAngleEnd;

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
int _MemeImageScaleWithDistance;

// Mask Map params
sampler2D _MaskMap;
float4 _MaskMap_TexelSize;
float4 _MaskMap_ST;
int _MaskMapColumns;
int _MaskMapRows;
int _MaskMapCount;
int _MaskMapIndex;
float _MaskMapAngle;
float _MaskMapOpacity;
int _MaskMapClamp;
int _MaskMapCutOut;
int _MaskFlags;
int _MaskMapScaleWithDistance;
int _MaskSampleDistortedCoordinates;

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
int _DisplacementMapScaleWithDistance;

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

float _FanDistance;
float _FanScale;
float _FanBlades;
float _FanOffset;

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

float _RingRotationInnerAngle;
float _RingRotationOuterAngle;
float _RingRotationRadius;
float _RingRotationWidth;

float _SpiralIntensity;

float _PolarInversionIntensity;

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
float _RippleInnerFalloff;
float _RippleOuterFalloff;

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
float4 _EmptySpaceColor;

float _FogType;
float4 _FogColor;
float _FogBegin;
float _FogEnd;

float4 _EdgelordStripeColor;
float _EdgelordStripeSize;
float _EdgelordStripeOffset;

float4 _ColorMask;

float _PaletteOpacity;
float _PaletteScale;
float _PaletteOffset;
float _PalleteSource;
float4 _PaletteA;
float4 _PaletteB;
float4 _PaletteOscillation;
float4 _PalettePhase;

float _ColorInversionR;
float _ColorInversionG;
float _ColorInversionB;

float _ColorModifierMode;
float _ColorModifierStrength;
float _ColorModifierBlend;

float _Hue;
float _Saturation;
float _Value;
float _ClampSaturation;

float _ImaginaryColorBlendMode;
float _ImaginaryColorOpacity;
float _ImaginaryColorAngle;

float _BlurMovementSampleCount;
float _BlurMovementTarget;
float _BlurMovementRange;
float _BlurMovementExtrapolation;
float _BlurMovementOpacity;
float _BlurMovementBlend;

float _ChromaticAberrationStrength;
float _ChromaticAberrationSeparation;
float _ChromaticAberrationShape;
float _ChromaticAberrationBlend;

float _DistortionDesyncR;
float _DistortionDesyncG;
float _DistortionDesyncB;
float _DistortionDesyncBlend;

float _SignalNoiseSize;
float _ColorizedSignalNoise;
float _SignalNoiseOpacity;

float4 _CircularVignetteColor;
float _CircularVignetteOpacity;
float _CircularVignetteRoundness;
float _CircularVignetteMode;
float _CircularVignetteBegin;
float _CircularVignetteEnd;
float _CircularVignetteScaleWithDistance;

float _SobelSearchDistance;
float _SobelQuality;
float _SobelOpacity;
float _SobelBlendMode;

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
float _DisplayOnSurface;
float _ObjectDisplayMode;
float _ScreenSamplingMode;

#endif