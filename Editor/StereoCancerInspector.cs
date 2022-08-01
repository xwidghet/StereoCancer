using System.Collections;
using System.Collections.Generic;
using System;
using System.IO;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Text;
using UnityEngine;
using UnityEditor;

public class StereoCancerGUI : ShaderGUI
{
    // Custom render layer data
    string grabPassName = "newStereoCancerLayer";

    // GUIStyles
    GUIStyle scFoldoutStyle;

    // GUI Display Parameters
    bool displayRawParameters = false;

    // Main parameter category foldout states
    bool displayLayerParameters = false;
    bool displayRenderParameters = false;
    bool displayStencilParameters = false;
    bool displayBlendingParameters = false;
    bool displayVRParameters = false;
    bool displayImageOverlayParameters = false;
    bool displayMaskMapParameters = false;
    bool displayDisplacementMapParameters = false;
    bool displayTriplanarMapParameters = false;
    bool displayDistortionParameters = false;
    bool displayColorParameters = false;

    // Distortion effect foldout states
    bool displayDistortionShink = false;
    bool displayDistortionRotation = false;
    bool displayDistortionMovement = false;
    bool displayDistortionScreenShake = false;
    bool displayDistortionSplit = false;
    bool displayDistortionSkew = false;
    bool displayDistortionBar = false;
    bool displayDistortionSinBar = false;
    bool displayDistortionMelt = false;
    bool displayDistortionZigZag = false;
    bool displayDistortionSinWave = false;
    bool displayDistortionCosWave = false;
    bool displayDistortionSinCosWave = false;
    bool displayDistortionTanWave = false;
    bool displayDistortionSlice = false;
    bool displayDistortionRipple = false;
    bool displayDistortionCheckerboard = false;
    bool displayDistortionQuantization = false;
    bool displayDistortionRingRotation = false;
    bool displayDistortionWarp = false;
    bool displayDistortionSpiral = false;
    bool displayDistortionPolarInversion = false;
    bool displayDistortionFishEye = false;
    bool displayDistortionKaleidoscope = false;
    bool displayDistortionBlockDisplacement = false;
    bool displayDistortionGlitch = false;
    bool displayDistortionSimplexNoise = false;
    bool displayDistortionVoroniNoise = false;
    bool displayDistortionFan = false;
    bool displayDistortionGeometricDither = false;
    bool displayDistortionColorDisplacement = false;
    bool displayDistortionNormalDisplacement = false;
    // End distortion effect foldout states

    // Begin color effect foldout states
    bool displayEmptySpace = false;
    bool displaySignalNoise = false;
    bool displayBlurMovement = false;
    bool displayChromaticAberration = false;
    bool displayRGBDistortionDesync = false;
    bool displayCircularVignette = false;
    bool displayFog = false;
    bool displayEdgelordStriples = false;
    bool displayColorMask = false;
    bool displayColorPalette = false;
    bool displayColorInversion = false;
    bool displayColorModifier = false;
    bool displayHSV = false;
    bool displayImaginaryColor = false;
    bool displaySobel = false;
    bool displayColorShift = false;
    // End color effect foldout states

    // Begin wall of parameter madness
    MaterialProperty _CullMode = null;
    MaterialProperty _ZWrite = null;
    MaterialProperty _ZTest = null;

    MaterialProperty _DisableNameplates = null;

    MaterialProperty _StencilRef = null;
    MaterialProperty _StencilComp = null;
    MaterialProperty _StencilOp = null;
    MaterialProperty _StencilFail = null;
    MaterialProperty _StencilZFail = null;
    MaterialProperty _ReadMask = null;
    MaterialProperty _WriteMask = null;

    MaterialProperty _ParticleSystem = null;
    MaterialProperty _CoordinateSpace = null;
    MaterialProperty _CoordinateScale = null;
    MaterialProperty _WorldSamplingMode = null;
    MaterialProperty _WorldSamplingRange = null;
    MaterialProperty _CancerEffectQuantization = null;
    MaterialProperty _CancerEffectRotation = null;
    MaterialProperty _CancerEffectOffset = null;
    MaterialProperty _CancerEffectRange = null;
    MaterialProperty _RemoveCameraRoll = null;
    MaterialProperty _Visibility = null;
    MaterialProperty _FalloffEnabled = null;
    MaterialProperty _FalloffFlags = null;
    MaterialProperty _FalloffBeginPercentage = null;
    MaterialProperty _FalloffEndPercentage = null;
    MaterialProperty _FalloffAngleBegin = null;
    MaterialProperty _FalloffAngleEnd = null;

    // Image Overlay params
    MaterialProperty _MemeTex = null;
    MaterialProperty _MemeTex_TexelSize = null;
    MaterialProperty _MemeTex_ST = null;
    MaterialProperty _MemeImageColumns = null;
    MaterialProperty _MemeImageRows = null;
    MaterialProperty _MemeImageCount = null;
    MaterialProperty _MemeImageIndex = null;
    MaterialProperty _MemeImageAngle = null;
    MaterialProperty _MemeTexOpacity = null;
    MaterialProperty _MemeTexClamp = null;
    MaterialProperty _MemeTexCutOut = null;
    MaterialProperty _MemeTexAlphaCutOff = null;
    MaterialProperty _MemeTexOverrideMode = null;
    MaterialProperty _MemeImageScaleWithDistance = null;

    MaterialProperty _stereoCancerTexture = null;
    MaterialProperty _stereoCancerTexture_TexelSize = null;

    MaterialProperty _CameraDepthTexture = null;
    MaterialProperty _CameraDepthTexture_TexelSize = null;

    MaterialProperty _CancerOpacity = null;
    MaterialProperty _SrcFactor = null;
    MaterialProperty _DstFactor = null;

    // Mask Map params
    MaterialProperty _MaskMap = null;
    MaterialProperty _MaskMap_TexelSize = null;
    MaterialProperty _MaskMap_ST = null;
    MaterialProperty _MaskMapColumns = null;
    MaterialProperty _MaskMapRows = null;
    MaterialProperty _MaskMapCount = null;
    MaterialProperty _MaskMapIndex = null;
    MaterialProperty _MaskMapAngle = null;
    MaterialProperty _MaskMapOpacity = null;
    MaterialProperty _MaskMapClamp = null;
    MaterialProperty _MaskMapCutOut = null;
    MaterialProperty _MaskFlags = null;
    MaterialProperty _MaskMapScaleWithDistance = null;
    MaterialProperty _MaskSampleDistortedCoordinates = null;

    // Displacement Map params
    MaterialProperty _DisplacementMap = null;
    MaterialProperty _DisplacementMap_TexelSize = null;
    MaterialProperty _DisplacementMap_ST = null;
    MaterialProperty _DisplacementMapType = null;
    MaterialProperty _DisplacementMapColumns = null;
    MaterialProperty _DisplacementMapRows = null;
    MaterialProperty _DisplacementMapCount = null;
    MaterialProperty _DisplacementMapIndex = null;
    MaterialProperty _DisplacementMapAngle = null;
    MaterialProperty _DisplacementMapIntensity = null;
    MaterialProperty _DisplacementMapOscillationSpeed = null;
    MaterialProperty _DisplacementMapIterations = null;
    MaterialProperty _DisplacementMapClamp = null;
    MaterialProperty _DisplacementMapCutOut = null;
    MaterialProperty _DisplacementMapScaleWithDistance = null;

    // Triplanar params
    MaterialProperty _TriplanarMap = null;
    MaterialProperty _TriplanarMap_ST = null;
    MaterialProperty _TriplanarSampleSrc = null;
    MaterialProperty _TriplanarCoordinateSrc = null;
    MaterialProperty _TriplanarScale = null;
    MaterialProperty _TriplanarOffsetX = null;
    MaterialProperty _TriplanarOffsetY = null;
    MaterialProperty _TriplanarOffsetZ = null;
    MaterialProperty _TriplanarSharpness = null;
    MaterialProperty _TriplanarQuality = null;
    MaterialProperty _TriplanarBlendMode = null;
    MaterialProperty _TriplanarOpacity = null;

    // Screen distortion params
    MaterialProperty _ShrinkWidth = null;
    MaterialProperty _ShrinkHeight = null;

    MaterialProperty _EyeConvergence = null;
    MaterialProperty _EyeSeparation = null;

    MaterialProperty _RotationX = null;
    MaterialProperty _RotationY = null;
    MaterialProperty _RotationZ = null;

    MaterialProperty _MoveX = null;
    MaterialProperty _MoveY = null;
    MaterialProperty _MoveZ = null;

    MaterialProperty _ScreenShakeSpeed = null;
    MaterialProperty _ScreenShakeXIntensity = null;
    MaterialProperty _ScreenShakeXAmplitude = null;
    MaterialProperty _ScreenShakeYIntensity = null;
    MaterialProperty _ScreenShakeYAmplitude = null;
    MaterialProperty _ScreenShakeZIntensity = null;
    MaterialProperty _ScreenShakeZAmplitude = null;

    MaterialProperty _SplitXAngle = null;
    MaterialProperty _SplitXDistance = null;
    MaterialProperty _SplitXHalf = null;

    MaterialProperty _SplitYAngle = null;
    MaterialProperty _SplitYDistance = null;
    MaterialProperty _SplitYHalf = null;

    MaterialProperty _SkewXAngle = null;
    MaterialProperty _SkewXDistance = null;
    MaterialProperty _SkewXInterval = null;
    MaterialProperty _SkewXOffset = null;

    MaterialProperty _SkewYAngle = null;
    MaterialProperty _SkewYDistance = null;
    MaterialProperty _SkewYInterval = null;
    MaterialProperty _SkewYOffset = null;

    MaterialProperty _FanDistance = null;
    MaterialProperty _FanScale = null;
    MaterialProperty _FanBlades = null;
    MaterialProperty _FanOffset = null;

    MaterialProperty _GeometricDitherDistance = null;
    MaterialProperty _GeometricDitherQuality = null;
    MaterialProperty _GeometricDitherRandomization = null;

    MaterialProperty _ColorVectorDisplacementStrength = null;
    MaterialProperty _ColorVectorDisplacementCoordinateSpace = null;

    MaterialProperty _NormalVectorDisplacementStrength = null;
    MaterialProperty _NormalVectorDisplacementCoordinateSpace = null;
    MaterialProperty _NormalVectorDisplacementQuality = null;

    MaterialProperty _WarpIntensity = null;
    MaterialProperty _WarpAngle = null;

    MaterialProperty _BarXAngle = null;
    MaterialProperty _BarXDistance = null;
    MaterialProperty _BarXInterval = null;
    MaterialProperty _BarXOffset = null;

    MaterialProperty _BarYAngle = null;
    MaterialProperty _BarYDistance = null;
    MaterialProperty _BarYInterval = null;
    MaterialProperty _BarYOffset = null;

    MaterialProperty _SinBarXAngle = null;
    MaterialProperty _SinBarXDistance = null;
    MaterialProperty _SinBarXInterval = null;
    MaterialProperty _SinBarXOffset = null;

    MaterialProperty _SinBarYAngle = null;
    MaterialProperty _SinBarYDistance = null;
    MaterialProperty _SinBarYInterval = null;
    MaterialProperty _SinBarYOffset = null;

    MaterialProperty _MeltAngle = null;
    MaterialProperty _MeltInterval = null;
    MaterialProperty _MeltVariance = null;
    MaterialProperty _MeltDistance = null;
    MaterialProperty _MeltSeed = null;
    MaterialProperty _MeltBothDirections = null;

    MaterialProperty _CheckerboardAngle = null;
    MaterialProperty _CheckerboardScale = null;
    MaterialProperty _CheckerboardShift = null;
    MaterialProperty _Quantization = null;

    MaterialProperty _RingRotationInnerAngle = null;
    MaterialProperty _RingRotationOuterAngle = null;
    MaterialProperty _RingRotationRadius = null;
    MaterialProperty _RingRotationWidth = null;

    MaterialProperty _SpiralIntensity = null;

    MaterialProperty _PolarInversionIntensity = null;

    MaterialProperty _FishEyeIntensity = null;

    MaterialProperty _SinWaveAngle = null;
    MaterialProperty _SinWaveDensity = null;
    MaterialProperty _SinWaveAmplitude = null;
    MaterialProperty _SinWaveOffset = null;

    MaterialProperty _CosWaveAngle = null;
    MaterialProperty _CosWaveDensity = null;
    MaterialProperty _CosWaveAmplitude = null;
    MaterialProperty _CosWaveOffset = null;

    MaterialProperty _SinCosWaveAngle = null;
    MaterialProperty _SinCosWaveSinDensity = null;
    MaterialProperty _SinCosWaveCosDensity = null;
    MaterialProperty _SinCosWaveAmplitude = null;
    MaterialProperty _SinCosWaveSinOffset = null;
    MaterialProperty _SinCosWaveCosOffset = null;

    MaterialProperty _TanWaveAngle = null;
    MaterialProperty _TanWaveDensity = null;
    MaterialProperty _TanWaveAmplitude = null;
    MaterialProperty _TanWaveOffset = null;

    MaterialProperty _SliceAngle = null;
    MaterialProperty _SliceWidth = null;
    MaterialProperty _SliceDistance = null;
    MaterialProperty _SliceOffset = null;

    MaterialProperty _RippleDensity = null;
    MaterialProperty _RippleAmplitude = null;
    MaterialProperty _RippleOffset = null;
    MaterialProperty _RippleInnerFalloff = null;
    MaterialProperty _RippleOuterFalloff = null;

    MaterialProperty _ZigZagXAngle = null;
    MaterialProperty _ZigZagXDensity = null;
    MaterialProperty _ZigZagXAmplitude = null;
    MaterialProperty _ZigZagXOffset = null;

    MaterialProperty _ZigZagYAngle = null;
    MaterialProperty _ZigZagYDensity = null;
    MaterialProperty _ZigZagYAmplitude = null;
    MaterialProperty _ZigZagYOffset = null;

    MaterialProperty _KaleidoscopeSegments = null;
    MaterialProperty _KaleidoscopeAngle = null;

    MaterialProperty _BlockDisplacementAngle = null;
    MaterialProperty _BlockDisplacementSize = null;
    MaterialProperty _BlockDisplacementIntensity = null;
    MaterialProperty _BlockDisplacementMode = null;
    MaterialProperty _BlockDisplacementOffset = null;

    MaterialProperty _GlitchAngle = null;
    MaterialProperty _GlitchCount = null;
    MaterialProperty _MinGlitchWidth = null;
    MaterialProperty _MinGlitchHeight = null;
    MaterialProperty _MaxGlitchWidth = null;
    MaterialProperty _MaxGlitchHeight = null;
    MaterialProperty _GlitchIntensity = null;
    MaterialProperty _GlitchSeed = null;
    MaterialProperty _GlitchSeedInterval = null;

    MaterialProperty _NoiseScale = null;
    MaterialProperty _NoiseStrength = null;
    MaterialProperty _NoiseOffset = null;

    MaterialProperty _VoroniNoiseScale = null;
    MaterialProperty _VoroniNoiseStrength = null;
    MaterialProperty _VoroniNoiseBorderSize = null;
    MaterialProperty _VoroniNoiseBorderMode = null;
    MaterialProperty _VoroniNoiseBorderStrength = null;
    MaterialProperty _VoroniNoiseOffset = null;

    // Screen color params
    MaterialProperty _EmptySpaceColor = null;

    MaterialProperty _FogType = null;
    MaterialProperty _FogColor = null;
    MaterialProperty _FogBegin = null;
    MaterialProperty _FogEnd = null;

    MaterialProperty _EdgelordStripeColor = null;
    MaterialProperty _EdgelordStripeSize = null;
    MaterialProperty _EdgelordStripeOffset = null;

    MaterialProperty _ColorMask = null;

    MaterialProperty _PaletteOpacity = null;
    MaterialProperty _PaletteScale = null;
    MaterialProperty _PaletteOffset = null;
    MaterialProperty _PalleteSource = null;
    MaterialProperty _PaletteA = null;
    MaterialProperty _PaletteB = null;
    MaterialProperty _PaletteOscillation = null;
    MaterialProperty _PalettePhase = null;

    MaterialProperty _ColorInversionR = null;
    MaterialProperty _ColorInversionG = null;
    MaterialProperty _ColorInversionB = null;

    MaterialProperty _ColorModifierMode = null;
    MaterialProperty _ColorModifierStrength = null;
    MaterialProperty _ColorModifierBlend = null;

    MaterialProperty _Hue = null;
    MaterialProperty _Saturation = null;
    MaterialProperty _Value = null;
    MaterialProperty _ClampSaturation = null;

    MaterialProperty _ImaginaryColorBlendMode = null;
    MaterialProperty _ImaginaryColorOpacity = null;
    MaterialProperty _ImaginaryColorAngle = null;

    MaterialProperty _BlurMovementSampleCount = null;
    MaterialProperty _BlurMovementTarget = null;
    MaterialProperty _BlurMovementRange = null;
    MaterialProperty _BlurMovementExtrapolation = null;
    MaterialProperty _BlurMovementBlurIntensity = null;
    MaterialProperty _BlurMovementOpacity = null;
    MaterialProperty _BlurMovementBlend = null;

    MaterialProperty _ChromaticAberrationStrength = null;
    MaterialProperty _ChromaticAberrationSeparation = null;
    MaterialProperty _ChromaticAberrationShape = null;
    MaterialProperty _ChromaticAberrationBlend = null;

    MaterialProperty _DistortionDesyncR = null;
    MaterialProperty _DistortionDesyncG = null;
    MaterialProperty _DistortionDesyncB = null;
    MaterialProperty _DistortionDesyncBlend = null;

    MaterialProperty _SignalNoiseSize = null;
    MaterialProperty _ColorizedSignalNoise = null;
    MaterialProperty _SignalNoiseOpacity = null;

    MaterialProperty _CircularVignetteColor = null;
    MaterialProperty _CircularVignetteOpacity = null;
    MaterialProperty _CircularVignetteRoundness = null;
    MaterialProperty _CircularVignetteMode = null;
    MaterialProperty _CircularVignetteBegin = null;
    MaterialProperty _CircularVignetteEnd = null;
    MaterialProperty _CircularVignetteScaleWithDistance = null;

    MaterialProperty _SobelSearchDistance = null;
    MaterialProperty _SobelQuality = null;
    MaterialProperty _SobelOpacity = null;
    MaterialProperty _SobelBlendMode = null;

    MaterialProperty _colorSkewRDistance = null;
    MaterialProperty _colorSkewRAngle = null;
    MaterialProperty _colorSkewROpacity = null;
    MaterialProperty _colorSkewROverride = null;

    MaterialProperty _colorSkewGDistance = null;
    MaterialProperty _colorSkewGAngle = null;
    MaterialProperty _colorSkewGOpacity = null;
    MaterialProperty _colorSkewGOverride = null;

    MaterialProperty _colorSkewBDistance = null;
    MaterialProperty _colorSkewBAngle = null;
    MaterialProperty _colorSkewBOpacity = null;
    MaterialProperty _colorSkewBOverride = null;
    
    MaterialProperty _CancerDisplayMode = null;
    MaterialProperty _ObjectDisplayMode = null;
    MaterialProperty _DisplayOnSurface = null;
    MaterialProperty _ScreenSamplingMode = null;

    // End wall of parameter madness

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        // Default Renderer
        if (displayRawParameters)
        {
            base.OnGUI(materialEditor, properties);
        }
        // Custom GUI
        else
        {
            // Loop shamelessly copied from Xiexe's XSToonInspector (MIT License)
            // https://github.com/Xiexe/Xiexes-Unity-Shaders/blob/2bade4beb87e96d73811ac2509588f27ae2e989f/Editor/XSToonInspector.cs#L156
            foreach (var property in GetType().GetFields(BindingFlags.NonPublic | BindingFlags.Instance))
            {
                if (property.FieldType == typeof(MaterialProperty))
                {
                    try { property.SetValue(this, FindProperty(property.Name, properties)); } catch { /*Is it really a problem if it doesn't exist?*/ }
                }
            }

            scFoldoutStyle = StereoCancerCSS.createSCFoldOutStyle();
            Material material = materialEditor.target as Material;

            drawLayerParameters(materialEditor, material, properties);
            drawRenderParameters(materialEditor, properties);
            drawStencilParameters(materialEditor, properties);
            drawBlendingParamters(materialEditor, properties);
            drawOverlayParameters(materialEditor, properties);
            drawMaskParameters(materialEditor, properties);
            drawDisplacementParameters(materialEditor, properties);
            drawTriplanarParameters(materialEditor, properties);
            drawVRParamters(materialEditor, properties);
            drawDistortionParamters(materialEditor, properties);
            drawColorParamters(materialEditor, properties);
        }
    }

    public void drawLayerParameters(MaterialEditor materialEditor, Material material, MaterialProperty[] properties)
    {
        displayLayerParameters = EditorGUILayout.Foldout(displayLayerParameters, "Layer Parameters", true, scFoldoutStyle);

        if (displayLayerParameters == true)
        {
            materialEditor.RenderQueueField();
            GUILayout.Space(20);

            GUILayout.BeginHorizontal();
            GUILayout.Label("New Layer Name: ");

            GUIStyle textLabelAlignmentStyle = new GUIStyle(EditorStyles.textField);
            textLabelAlignmentStyle.alignment = TextAnchor.MiddleRight;

            grabPassName = GUILayout.TextField(grabPassName, 31, textLabelAlignmentStyle);
            GUILayout.EndHorizontal();

            // Inspired by AkaiMage's render queue exporting from CancerSpace
            // https://github.com/AkaiMage/VRC-Cancerspace/blob/5118fc7c40977f73791d39fe3929e90c14eb5f77/Editor/CancerspaceInspector.cs#L430
            bool createLayer = GUILayout.Button("Create New Layer");
            if (createLayer)
            {
                // Separate the internal grab pass name to avoid users becoming confused
                // when an underscore suddenly appears in their custom name.
                // This also avoids the issue of appending more and more underscores to
                // the start when the user creates multiple layers.
                StringBuilder sb = new StringBuilder("_", 32);

                // Sanitize the user's input to ensure they don't try to create
                // a layer using characters incompatibile with file and grab pass
                // names. 
                Regex rx = new Regex(@"^[A-Za-z0-9_]+$", RegexOptions.Compiled);

                foreach(var matchingCharacters in rx.Matches(grabPassName))
                {
                    sb.Append(matchingCharacters);
                }
                string internalGrabPassName = sb.ToString();

                if (internalGrabPassName.Length == 1 || internalGrabPassName.Length != (grabPassName.Length + 1))
                {
                    Debug.LogError("New Layer Name must be at least 1 character long and consist of only english characters.");
                }
                else
                {
                    string shaderPath = AssetDatabase.GetAssetPath(material.shader.GetInstanceID());

                    // Grab the base shader for easy grab pass replacement. If the user decided to
                    // rename my shader then that's their problem. :)
                    shaderPath = shaderPath.Substring(0, shaderPath.IndexOf("v0.1") + 4);

                    string outputLocation = shaderPath + internalGrabPassName + ".shader";
                    shaderPath += ".shader";

                    string customShaderName = "Shader \"xwidghet/StereoCancer v0.1" + internalGrabPassName + "\"\n";

                    int customRenderQueue = material.renderQueue - 4000;
                    string renderQueueString = "\"Overlay\"";
                    if (customRenderQueue != 0)
                    {
                        renderQueueString = String.Format("\"Overlay{0}\"", customRenderQueue.ToString("+#;-#;0"));
                    }

                    if (File.Exists(outputLocation))
                    {
                        Debug.LogError("A layer with this name was already created. Please choose a new name.");
                    }
                    else
                    {
                        try
                        {
                            using (StreamWriter sw = new StreamWriter(outputLocation))
                            {
                                string[] shaderFileText = File.ReadAllLines(shaderPath);
                                StringBuilder shaderStringBuilder = new StringBuilder("// UNITY_SHADER_NO_UPGRADE\n\n" + customShaderName);

                                bool foundAllLinesToReplace = false;

                                // Skip past old name line
                                for (int i = 3; i < shaderFileText.Length; i++)
                                {
                                    // Skip running expensive string functions where we know there's nothing to replace
                                    if (i < 412 || foundAllLinesToReplace)
                                    {
                                        shaderStringBuilder.AppendLine(shaderFileText[i]);
                                    }
                                    else
                                    {
                                        if (shaderFileText[i].Contains("\"Overlay\""))
                                        {
                                            shaderStringBuilder.AppendLine(shaderFileText[i].Replace("\"Overlay\"", renderQueueString));
                                        }
                                        else if (shaderFileText[i].Contains("appdata"))
                                        {
                                            foundAllLinesToReplace = true;
                                            shaderStringBuilder.AppendLine(shaderFileText[i]);
                                        }
                                        else
                                        {
                                            shaderStringBuilder.AppendLine(shaderFileText[i].Replace("_stereoCancerTexture", internalGrabPassName));
                                        }
                                    }
                                }

                                sw.Write(shaderStringBuilder.ToString());
                            }

                            AssetDatabase.Refresh();

                            string customShaderLayerPath = "xwidghet/StereoCancer v0.1" + internalGrabPassName;
                            material.shader = Shader.Find(customShaderLayerPath);

                            AssetDatabase.SaveAssets();
                        }
                        catch (Exception e)
                        {
                            Debug.LogError("Failed to create a new layer. Either the shader failed to be read, or the layer failed to be created.");
                            Debug.LogError(e.Message);
                        }
                    }
                }
            }
        }
    }

    public void drawRenderParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayRenderParameters = EditorGUILayout.Foldout(displayRenderParameters, "Rendering Parameters", true, scFoldoutStyle);

        if(displayRenderParameters == true)
        {
            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_CullMode, new GUIContent("Cull Mode", "Select if the vertices should be culled. This should be set to Front for fullscreen Object Display Mode, and off for world scale."));
            materialEditor.ShaderProperty(_ZWrite, new GUIContent("Z Write", "Select if the depth should be written to the depth buffer. This should be off for fullscreen Object Display Mode, and on for world scale."));
            materialEditor.ShaderProperty(_ZTest, new GUIContent("Z Test", "Select if pixels from this object should be discarded when an object is closer than the pixel. This should be set to Always for fullscreen Object Display Mode, and LessEqual for world scale."));
            GUILayout.Space(20);

            materialEditor.ShaderProperty(_DisableNameplates, new GUIContent("Disable Nameplates (Requires Z Write)", "Writes the nearest possible depth to prevent nameplates from displaying."));
            GUILayout.Space(20);

            materialEditor.ShaderProperty(_CancerDisplayMode, new GUIContent("Cancer Display Mode", "Select if cancer effects should be selectively displayed on the screen, mirrors, or both."));
            materialEditor.ShaderProperty(_ObjectDisplayMode, new GUIContent("Object Display Mode", "Select if cancer object should fully cover the viewers screen, or displayed in the world like a normal object."));
            materialEditor.ShaderProperty(_DisplayOnSurface, new GUIContent("Display On Surface", "Select if the cancer effects should be displayed on the surface of the object like a texture."));
            materialEditor.ShaderProperty(_CoordinateSpace, new GUIContent("Coordinate Space", "Select if the cancer coordinates should be a flat 'Screen' plane, 'Projected' onto the scene like a flashlight, 'Centered On Object'."));
            materialEditor.ShaderProperty(_CoordinateScale, new GUIContent("Coordinate Scale", "Adjust the scale of the screen-space cancer coordinates. Useful for adjusting 'Projected' coordinates and making final adjustments to animations."));
            materialEditor.ShaderProperty(_ScreenSamplingMode, new GUIContent("Screen Sampling Mode", "Select how the screen texture is sampled when pixels go outside of the screen/eye."));
            materialEditor.ShaderProperty(_WorldSamplingMode, new GUIContent("World Sampling Mode", "Select how the screen texture is sampled when the coordinates exit the World Sampling Range."));
            materialEditor.ShaderProperty(_WorldSamplingRange, new GUIContent("World Sampling Range", "Adjust the cancer coordinate sampling range used for the currently selected 'World Sampling Mode'."));

            GUILayout.Space(20);
            materialEditor.ShaderProperty(_RemoveCameraRoll, new GUIContent("Remove Camera Roll", "Select if camera roll should be removed from cancer effects."));
            materialEditor.ShaderProperty(_CancerEffectQuantization, new GUIContent("Cancer Effect Quantization", "Adjust the quantization of the cancer effects separately from the quantization of the screen."));
            materialEditor.ShaderProperty(_CancerEffectRotation, new GUIContent("Cancer Effect Rotation", "Adjust the rotation of the cancer effects separately from the rotation of the screen."));
            materialEditor.ShaderProperty(_CancerEffectOffset, new GUIContent("Cancer Effect Offset", "Adjust the movement of the cancer effects separately from the movement of the screen."));
           
            // Remove spacing after vector UI display so all cancer coordinate parameters are kept together
            GUILayout.Space(-16);
            materialEditor.ShaderProperty(_CancerEffectRange, new GUIContent("Cancer Effect Range", "Adjust the wrapping of the cancer effects separately from the wrapping of the screen."));


            GUILayout.Space(20);
            materialEditor.ShaderProperty(_FalloffEnabled, new GUIContent("Falloff Enabled", "Enable or disable falloff. Note: Falloff requires that all of the object scale axes are positive."));
            if(_FalloffEnabled.floatValue != 0)
            {
                materialEditor.ShaderProperty(_FalloffFlags, new GUIContent("Falloff Flags", "Select if only opacity or distortion should falloff, or if both should be affected simultaneously."));
                materialEditor.ShaderProperty(_FalloffBeginPercentage, new GUIContent("Falloff Begin Distance", "The percentage of the object scale that the falloff begins at. This should be a value between 0 and 1 for fullscreen Object Display Mode."));
                materialEditor.ShaderProperty(_FalloffEndPercentage, new GUIContent("Falloff End Distance", "The percentage of the object scale that the falloff ends at. This should be a value between 0 and 1 for fullscreen Object Display Mode."));

                materialEditor.ShaderProperty(_FalloffAngleBegin, new GUIContent("Falloff Begin Angle", "The percentage falloff begins as the viewer looks away from the object. Set to 1 to disable angle falloff."));
                materialEditor.ShaderProperty(_FalloffAngleEnd, new GUIContent("Falloff End Angle", "The percentage falloff ends as the viewer looks away from the object."));
            }

            GUILayout.Space(20);
            materialEditor.ShaderProperty(_Visibility, new GUIContent("Visibility", "Select which users should see the cancer effects. Settings other than 'Global' require that the object containing the StereoCancer material is parented to your avatar's head, and has a scale of 10,000 or greater."));
            materialEditor.ShaderProperty(_ParticleSystem, new GUIContent("Particle System", "Select 'Yes' when the material is on a particle."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawStencilParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayStencilParameters = EditorGUILayout.Foldout(displayStencilParameters, "Stencil Parameters", true, scFoldoutStyle);

        if (displayStencilParameters == true)
        {
            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_StencilRef, new GUIContent("Stencil Reference", "The target stencil value to compare against."));
            materialEditor.ShaderProperty(_StencilComp, new GUIContent("Stencil Comparison", "The comparison function to be used when comparing the reference value against the stencil buffer."));
            materialEditor.ShaderProperty(_StencilOp, new GUIContent("Stencil Operation", "The operation to apply to the stencil buffer if the stencil comparison passes."));
            materialEditor.ShaderProperty(_StencilFail, new GUIContent("Stencil Fail", "The operation to apply to the stencil buffer if the stencil comparison fails."));
            materialEditor.ShaderProperty(_StencilZFail, new GUIContent("Stencil ZFail", "The operation to apply to the stencil buffer when the stencil comparison is successful but Z-Test fails."));
            materialEditor.ShaderProperty(_ReadMask, new GUIContent("Read Mask", "The bitwise mask to apply against the stencil buffer before doing the stencil comparison. If you don't know what this means, you probably want 255."));
            materialEditor.ShaderProperty(_WriteMask, new GUIContent("Write Mask", "The bitwise mask used to determine which stencil bits are written to the stencil buffer. If you don't know what this means, you probably want 255."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawBlendingParamters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayBlendingParameters = EditorGUILayout.Foldout(displayBlendingParameters, "Blending Parameters", true, scFoldoutStyle);

        if (displayBlendingParameters == true)
        {
            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_SrcFactor, new GUIContent("SrcFactor", "Select the Source Factor for blending."));
            materialEditor.ShaderProperty(_DstFactor, new GUIContent("DstFactor", "Select the Destination Factor for blending."));
            materialEditor.ShaderProperty(_CancerOpacity, new GUIContent("Cancer Opacity", "Adjust the blending opacity for this material."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawVRParamters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayVRParameters = EditorGUILayout.Foldout(displayVRParameters, "Virtual Reality Effects", true, scFoldoutStyle);

        if (displayVRParameters == true)
        {
            materialEditor.ShaderProperty(_EyeConvergence, new GUIContent("Eye Convergence", "Adjust the viewer's eye convergence. Positive values will result in the viewer going cross-eyed."));
            materialEditor.ShaderProperty(_EyeSeparation, new GUIContent("Eye Separation", "Adjust the separation distance between the viewer's eyes."));
        }
    }

    public void drawOverlayParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayImageOverlayParameters = EditorGUILayout.Foldout(displayImageOverlayParameters, "Image Overlay", true, scFoldoutStyle);

        if (displayImageOverlayParameters == true)
        {
            materialEditor.ShaderProperty(_MemeTex, new GUIContent("", "Select the image to overlay and adjust the tiling and offset."));

            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_MemeImageColumns, new GUIContent("Image Columns", "The number of images packed into the overlay texture horizontally."));
            materialEditor.ShaderProperty(_MemeImageRows, new GUIContent("Image Rows", "The number of images packed into the overlay texture vertically."));
            materialEditor.ShaderProperty(_MemeImageCount, new GUIContent("Image Count", "The total number of images packed into the overlay texture. Allows for the index to loop seemlessly when not all of the image spaces have been filled."));
            materialEditor.ShaderProperty(_MemeImageIndex, new GUIContent("Image Index", "The current index of the image in the potentially packed overlay texture."));
            materialEditor.ShaderProperty(_MemeImageAngle, new GUIContent("Image Angle", "Adjust the rotation of the image."));
            materialEditor.ShaderProperty(_MemeTexOpacity, new GUIContent("Image Opacity", "Adjust the opacity of the image."));
            materialEditor.ShaderProperty(_MemeTexClamp, new GUIContent("Image Clamp", "Select 'Yes' if the image should be clamped to the edge pixels."));
            materialEditor.ShaderProperty(_MemeTexCutOut, new GUIContent("Image Cutout", "Select 'Yes' if the image should be cutout."));
            materialEditor.ShaderProperty(_MemeTexAlphaCutOff, new GUIContent("Image Alpha Cutoff", "Adjust the minimum alpha value used to determine if the pixels should be discarded."));
            materialEditor.ShaderProperty(_MemeTexOverrideMode, new GUIContent("Image Override Mode", "Select 'None' to overlay the image on-top of cancer effects, 'Background' if the overlay should replace the screen color, and 'Empty Space' to fill in only the space created by effects like 'Screen Split'."));

            GUILayout.Space(20);
            materialEditor.ShaderProperty(_MemeImageScaleWithDistance, new GUIContent("Image Scale With Distance", "Select if the image should be scaled with distance. Recommended when using coordinate space Centered On Object."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawMaskParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayMaskMapParameters = EditorGUILayout.Foldout(displayMaskMapParameters, "Mask Map", true, scFoldoutStyle);

        if (displayMaskMapParameters == true)
        {
            materialEditor.ShaderProperty(_MaskMap, new GUIContent("", "Select the texture to use as a mask map."));

            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_MaskMapColumns, new GUIContent("Mask Map Columns", "The number of images packed into the texture horizontally."));
            materialEditor.ShaderProperty(_MaskMapRows, new GUIContent("Mask Map Rows", "The number of images packed into the texture vertically."));
            materialEditor.ShaderProperty(_MaskMapCount, new GUIContent("Mask Map Count", "The total number of images packed into the texture. Allows for the index to loop seemlessly when not all of the image spaces have been filled."));
            materialEditor.ShaderProperty(_MaskMapIndex, new GUIContent("Mask Map Index", "The current index of the image in the potentially packed texture."));
            materialEditor.ShaderProperty(_MaskMapAngle, new GUIContent("Mask Map Angle", "Adjust the rotation of the mask map."));
            materialEditor.ShaderProperty(_MaskMapOpacity, new GUIContent("Mask Map Opacity", "Adjust the opacity of the mask map."));
            materialEditor.ShaderProperty(_MaskMapClamp, new GUIContent("Mask Map Clamp", "Select 'Yes' if the mask map should be clamped to the edge pixels."));
            materialEditor.ShaderProperty(_MaskMapCutOut, new GUIContent("Mask Map Cutout", "Select 'Yes' if the mask map should be cutout."));

            GUILayout.Space(20);
            materialEditor.ShaderProperty(_MaskFlags, new GUIContent("Mask Flags", "Select if only opacity or distortion should be masked, or if both should be masked simultaneously."));
            materialEditor.ShaderProperty(_MaskMapScaleWithDistance, new GUIContent("Mask Map Scale With Distance", "Select if the mask map should be scaled with distance. Recommended when using coordinate space Centered On Object."));
            materialEditor.ShaderProperty(_MaskSampleDistortedCoordinates, new GUIContent("Mask Map Sample Distortion", "Select 'Yes' if the mask map should be distorted."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawDisplacementParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayDisplacementMapParameters = EditorGUILayout.Foldout(displayDisplacementMapParameters, "Displacement Map", true, scFoldoutStyle);

        if (displayDisplacementMapParameters == true)
        {
            materialEditor.ShaderProperty(_DisplacementMap, new GUIContent("", "Select the texture to use as a displacement map."));

            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_DisplacementMapType, new GUIContent("Displacement Map Type", "Select 'Normal' for normal maps, and 'Color' for images. When using 'Color' the sRGB checkbox should be disabled on the texture."));
            materialEditor.ShaderProperty(_DisplacementMapColumns, new GUIContent("Displacement Map Columns", "The number of images packed into the texture horizontally."));
            materialEditor.ShaderProperty(_DisplacementMapRows, new GUIContent("Displacement Map Rows", "The number of images packed into the texture vertically."));
            materialEditor.ShaderProperty(_DisplacementMapCount, new GUIContent("Displacement Map Count", "The total number of images packed into the texture. Allows for the index to loop seemlessly when not all of the image spaces have been filled."));
            materialEditor.ShaderProperty(_DisplacementMapIndex, new GUIContent("Displacement Map Index", "The current index of the image in the potentially packed texture."));
            materialEditor.ShaderProperty(_DisplacementMapAngle, new GUIContent("Displacement Map Angle", "Adjust the rotation of the displacement map."));
            materialEditor.ShaderProperty(_DisplacementMapIntensity, new GUIContent("Displacement Map Distance", "Adjust the maximum distance of the displacement map."));
            materialEditor.ShaderProperty(_DisplacementMapOscillationSpeed, new GUIContent("Displacement Map Oscillation Speed", "Adjust the speed that the displacement oscillates between positive and negative values."));
            materialEditor.ShaderProperty(_DisplacementMapIterations, new GUIContent("Displacement Map Iterations", "Adjust how many times the displacement map is sampled. Different values will result in different patterns, so this value shouldn't be simply left at the minimum or maximum amounts."));
            
            materialEditor.ShaderProperty(_DisplacementMapClamp, new GUIContent("Displacement Map Clamp", "Select 'Yes' if the displacement map should be clamped to the edge pixels."));
            materialEditor.ShaderProperty(_DisplacementMapCutOut, new GUIContent("Displacement Map Cutout", "Select 'Yes' if the displacement map should be cutout."));

            GUILayout.Space(20);
            materialEditor.ShaderProperty(_DisplacementMapScaleWithDistance, new GUIContent("Displacement Map Scale With Distance", "Select if the displacement map should be scaled with distance. Recommended when using coordinate space Centered On Object."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawTriplanarParameters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayTriplanarMapParameters = EditorGUILayout.Foldout(displayTriplanarMapParameters, "Triplanar Map", true, scFoldoutStyle);

        if (displayTriplanarMapParameters == true)
        {
            materialEditor.ShaderProperty(_TriplanarMap, new GUIContent("", "Select the texture to map onto the scene."));

            EditorGUI.indentLevel = 1;
            materialEditor.ShaderProperty(_TriplanarSampleSrc, new GUIContent("Triplanar Sample Source", "Select 'Map' to use the above texture, and 'Screen' to utilize the viewers screen as the sampling source."));
            materialEditor.ShaderProperty(_TriplanarCoordinateSrc, new GUIContent("Triplanar Coordinate Source", "Select 'WorldPos' to use the projected position of the pixels in the scene, 'WorldNormal' for the scene surface normals, and 'ViewNormal' for the view-space version of the scene surface normals."));
            materialEditor.ShaderProperty(_TriplanarScale, new GUIContent("Triplanar Coordinate Scale", "Adjust the scale of the triplanar coordinates."));
            materialEditor.ShaderProperty(_TriplanarOffsetX, new GUIContent("Triplanar Offset X", "Adjust the X-Axis offset of the triplanar coordinates."));
            materialEditor.ShaderProperty(_TriplanarOffsetY, new GUIContent("Triplanar Offset Y", "Adjust the Y-Axis offset of the triplanar coordinates."));
            materialEditor.ShaderProperty(_TriplanarOffsetZ, new GUIContent("Triplanar Offset Z", "Adjust the Z-Axis offset of the triplanar coordinates."));
            materialEditor.ShaderProperty(_TriplanarSharpness, new GUIContent("Triplanar Sharpness", "Adjust the sharpness of the triplanar sampling."));
            materialEditor.ShaderProperty(_TriplanarQuality, new GUIContent("Triplanar Quality", "Adjust the quality of the triplanar coordinate generation."));
            materialEditor.ShaderProperty(_TriplanarBlendMode, new GUIContent("Triplanar Blend Mode", "Select the blending mode of the triplanar effect."));
            materialEditor.ShaderProperty(_TriplanarOpacity, new GUIContent("Triplanar Opacity", "Adjust how much of the triplanar effect is blended into the screen colors."));

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawDistortionParamters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayDistortionParameters = EditorGUILayout.Foldout(displayDistortionParameters, "Distortion Effects", true, scFoldoutStyle);

        if (displayDistortionParameters == true)
        {
            EditorGUI.indentLevel = 1;
            displayDistortionShink = EditorGUILayout.Foldout(displayDistortionShink, "Shrink", true, scFoldoutStyle);

            if (displayDistortionShink)
            {
                materialEditor.ShaderProperty(_ShrinkWidth, new GUIContent("Shrink Width", "Shrink or expand the width of the viewer's screen."));
                materialEditor.ShaderProperty(_ShrinkHeight, new GUIContent("Shrink Height", "Shrink or expand the height of the viewer's screen"));
            }

            displayDistortionRotation = EditorGUILayout.Foldout(displayDistortionRotation, "Screen Rotation", true, scFoldoutStyle);

            if (displayDistortionRotation)
            {
                materialEditor.ShaderProperty(_RotationX, new GUIContent("Pitch", "Pitch the screen down with positive values, and up with negative values."));
                materialEditor.ShaderProperty(_RotationY, new GUIContent("Yaw", "Yaw the screen left with positive values, and right with negative values."));
                materialEditor.ShaderProperty(_RotationZ, new GUIContent("Roll", "Roll the screen right with positive values, and left with negative values."));
            }

            displayDistortionMovement = EditorGUILayout.Foldout(displayDistortionMovement, "Screen Movement", true, scFoldoutStyle);

            if (displayDistortionMovement)
            {
                materialEditor.ShaderProperty(_MoveX, new GUIContent("Movement X", "Move the screen right with positive values, and left with negative values."));
                materialEditor.ShaderProperty(_MoveY, new GUIContent("Movement Y", "Move the screen down with positive values, and up with negative values."));
                materialEditor.ShaderProperty(_MoveZ, new GUIContent("Movement Z", "Move the screen backward with positive values, and forward with negative values."));
            }

            displayDistortionScreenShake = EditorGUILayout.Foldout(displayDistortionScreenShake, "Screen Shake", true, scFoldoutStyle);

            if (displayDistortionScreenShake)
            {
                materialEditor.ShaderProperty(_ScreenShakeSpeed, new GUIContent("Shake Time Scale", "Adjust how quickly the screen shakes over time."));
                materialEditor.ShaderProperty(_ScreenShakeXIntensity, new GUIContent("Horizontal Shake Speed", "Adjust how far the screen shakes horizontally."));
                materialEditor.ShaderProperty(_ScreenShakeXAmplitude, new GUIContent("Horizontal Shake Density", "Adjust how often horizontal screen shake changes direction."));
                materialEditor.ShaderProperty(_ScreenShakeYIntensity, new GUIContent("Vertical Shake Speed", "Adjust how far the screen shakes vertically."));
                materialEditor.ShaderProperty(_ScreenShakeYAmplitude, new GUIContent("Vertical Shake Density", "Adjust how often vertical screen shake changes direction."));
                materialEditor.ShaderProperty(_ScreenShakeZIntensity, new GUIContent("Forward Shake Speed", "Adjust how far the screen shakes forwards and backwards."));
                materialEditor.ShaderProperty(_ScreenShakeZAmplitude, new GUIContent("Forward Shake Density", "Adjust how often forwards and backwards screen shake changes direction."));
            }

            displayDistortionSplit = EditorGUILayout.Foldout(displayDistortionSplit, "Screen Split", true, scFoldoutStyle);

            if (displayDistortionSplit)
            {
                materialEditor.ShaderProperty(_SplitXAngle, new GUIContent("Horizontal Split Angle", "Adjust the angle of the horizontal screen split."));
                materialEditor.ShaderProperty(_SplitXDistance, new GUIContent("Horizontal Split Distance", "Push the sides of the screen apart with positive values, and together with negative values."));
                materialEditor.ShaderProperty(_SplitXHalf, new GUIContent("Horizontal Split Half", "Select 'Yes' if only half of the screen should be split apart. When enabled, positive values will split apart the right side, and negative values will split apart the left side."));
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_SplitYAngle, new GUIContent("Vertical Split Angle", "Adjust the angle of the vertical screen split."));
                materialEditor.ShaderProperty(_SplitYDistance, new GUIContent("Vertical Split Distance", "Push the sides of the screen apart with positive values, and together with negative values."));
                materialEditor.ShaderProperty(_SplitYHalf, new GUIContent("Vertical Split Half", "Select 'Yes' if only half of the screen should be split apart. When enabled, positive values will split apart the bottom side, and negative values will split apart the top side."));
            }

            displayDistortionSkew = EditorGUILayout.Foldout(displayDistortionSkew, "Alternating Skew", true, scFoldoutStyle);

            if (displayDistortionSkew)
            {
                materialEditor.ShaderProperty(_SkewXAngle, new GUIContent("Horizontal Skew Angle", "Adjust the angle of the horizontal screen skew."));
                materialEditor.ShaderProperty(_SkewXInterval, new GUIContent("Horizontal Skew Interval", "Adjust how often the skew flips from positive to negative values."));
                materialEditor.ShaderProperty(_SkewXDistance, new GUIContent("Horizontal Skew Distance", "Adjust the skewing distance."));
                materialEditor.ShaderProperty(_SkewXOffset, new GUIContent("Horizontal Skew Offset", "Adjust the offset of the horizontal skew."));
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_SkewYAngle, new GUIContent("Vertical Skew Angle", "Adjust the angle of the vertical screen skew."));
                materialEditor.ShaderProperty(_SkewYInterval, new GUIContent("Vertical Skew Interval", "Adjust how often the skew flips from positive to negative values."));
                materialEditor.ShaderProperty(_SkewYDistance, new GUIContent("Vertical Skew Distance", "Adjust the skewing distance."));
                materialEditor.ShaderProperty(_SkewYOffset, new GUIContent("Vertical Skew Offset", "Adjust the offset of the vertical skew."));
            }

            displayDistortionBar = EditorGUILayout.Foldout(displayDistortionBar, "Alternating Bar Shift", true, scFoldoutStyle);

            if (displayDistortionBar)
            {
                materialEditor.ShaderProperty(_BarXAngle, new GUIContent("Horizontal Bar Shift Angle", "Adjust the angle of the horizontal screen bars."));
                materialEditor.ShaderProperty(_BarXInterval, new GUIContent("Horizontal Bar Shift Interval", "Adjust how often the bars alternate from positive to negative values."));
                materialEditor.ShaderProperty(_BarXDistance, new GUIContent("Horizontal Bar Shift Distance", "Adjust the bar shifting distance."));
                materialEditor.ShaderProperty(_BarXOffset, new GUIContent("Horizontal Bar Shift Offset", "Adjust the offset of the alternating position."));
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_BarYAngle, new GUIContent("Vertical Bar Shift Angle", "Adjust the angle of the vertical screen bars."));
                materialEditor.ShaderProperty(_BarYInterval, new GUIContent("Vertical Bar Shift Interval", "Adjust how often the bars alternate from positive to negative values."));
                materialEditor.ShaderProperty(_BarYDistance, new GUIContent("Vertical Bar Shift Distance", "Adjust the bar shifting distance."));
                materialEditor.ShaderProperty(_BarYOffset, new GUIContent("Vertical Bar Shift Offset", "Adjust the offset of the alternating position."));
            }

            displayDistortionSinBar = EditorGUILayout.Foldout(displayDistortionSinBar, "Alternating Sin Bar Shift", true, scFoldoutStyle);

            if (displayDistortionSinBar)
            {
                materialEditor.ShaderProperty(_SinBarXAngle, new GUIContent("Horizontal Sin Bar Shift Angle", "Adjust the angle of the horizontal screen bars."));
                materialEditor.ShaderProperty(_SinBarXInterval, new GUIContent("Horizontal Sin Bar Shift Interval", "Adjust how often the bars alternate from positive to negative values."));
                materialEditor.ShaderProperty(_SinBarXDistance, new GUIContent("Horizontal Sin Bar Shift Distance", "Adjust the bar shifting distance."));
                materialEditor.ShaderProperty(_SinBarXOffset, new GUIContent("Horizontal Sin Bar Shift Offset", "Adjust the offset of the alternating position."));
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_SinBarYAngle, new GUIContent("Vertical Sin Bar Shift Angle", "Adjust the angle of the vertical screen bars."));
                materialEditor.ShaderProperty(_SinBarYInterval, new GUIContent("Vertical Sin Bar Shift Interval", "Adjust how often the bars alternate from positive to negative values."));
                materialEditor.ShaderProperty(_SinBarYDistance, new GUIContent("Vertical Sin Bar Shift Distance", "Adjust the bar shifting distance."));
                materialEditor.ShaderProperty(_SinBarYOffset, new GUIContent("Vertical Sin Bar Shift Offset", "Adjust the offset of the alternating position."));
            }

            displayDistortionMelt = EditorGUILayout.Foldout(displayDistortionMelt, "Melt", true, scFoldoutStyle);

            if (displayDistortionMelt)
            {
                materialEditor.ShaderProperty(_MeltAngle, new GUIContent("Melt Angle", "Adjust the angle of the melt."));
                materialEditor.ShaderProperty(_MeltInterval, new GUIContent("Melt Interval", "Adjust how often the melting changes direction."));
                materialEditor.ShaderProperty(_MeltVariance, new GUIContent("Melt Variance", "Adjust how much the distortion distance can vary between melting lines."));
                materialEditor.ShaderProperty(_MeltDistance, new GUIContent("Melt Distance", "Adjust the melting distance."));
                materialEditor.ShaderProperty(_MeltSeed, new GUIContent("Melt Seed", "Adjust to change the randomly generated melt directions."));
                materialEditor.ShaderProperty(_MeltBothDirections, new GUIContent("Melt Both Directions", "Select if the melting effect should melt positively and negatively or only positively."));
                
            }

            displayDistortionZigZag = EditorGUILayout.Foldout(displayDistortionZigZag, "Zigzag", true, scFoldoutStyle);

            if (displayDistortionZigZag)
            {
                materialEditor.ShaderProperty(_ZigZagXAngle, new GUIContent("Horizontal Zigzag Angle", "Adjust the angle of the horizontal screen zigzag."));
                materialEditor.ShaderProperty(_ZigZagXDensity, new GUIContent("Horizontal Zigzag Interval", "Adjust the distance between the zigzag direction changes."));
                materialEditor.ShaderProperty(_ZigZagXAmplitude, new GUIContent("Horizontal Zigzag Distance", "Adjust how far the zigzag shifts the screen."));
                materialEditor.ShaderProperty(_ZigZagXOffset, new GUIContent("Horizontal Zigzag Offset", "Adjust the offset of the zigzag points."));
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_ZigZagYAngle, new GUIContent("Vertical Zigzag Angle", "Adjust the angle of the vertical screen zigzag."));
                materialEditor.ShaderProperty(_ZigZagYDensity, new GUIContent("Vertical Zigzag Interval", "Adjust the distance between the zigzag direction changes."));
                materialEditor.ShaderProperty(_ZigZagYAmplitude, new GUIContent("Vertical Zigzag Distance", "Adjust how far the zigzag shifts the screen."));
                materialEditor.ShaderProperty(_ZigZagYOffset, new GUIContent("Vertical Zigzag Offset", "Adjust the offset of the zigzag points."));
            }

            displayDistortionSinWave = EditorGUILayout.Foldout(displayDistortionSinWave, "Sin Wave", true, scFoldoutStyle);

            if (displayDistortionSinWave)
            {
                materialEditor.ShaderProperty(_SinWaveAngle, new GUIContent("Sin Wave Angle", "Adjust the angle of the horizontal screen sin wave."));
                materialEditor.ShaderProperty(_SinWaveDensity, new GUIContent("Sin Wave Density", "Adjust the distance between the sin wave direction changes."));
                materialEditor.ShaderProperty(_SinWaveAmplitude, new GUIContent("Sin Wave Distance", "Adjust how far the sin wave shifts the screen."));
                materialEditor.ShaderProperty(_SinWaveOffset, new GUIContent("Sin Wave Offset", "Adjust the offset of the sin wave points."));
            }

            displayDistortionCosWave = EditorGUILayout.Foldout(displayDistortionCosWave, "Cos Wave", true, scFoldoutStyle);

            if (displayDistortionCosWave)
            {
                materialEditor.ShaderProperty(_CosWaveAngle, new GUIContent("Cos Wave Angle", "Adjust the angle of the horizontal screen cosine wave."));
                materialEditor.ShaderProperty(_CosWaveDensity, new GUIContent("Cos Wave Density", "Adjust the distance between the cosine wave direction changes."));
                materialEditor.ShaderProperty(_CosWaveAmplitude, new GUIContent("Cos Wave Distance", "Adjust how far the cosine wave shifts the screen."));
                materialEditor.ShaderProperty(_CosWaveOffset, new GUIContent("Cos Wave Offset", "Adjust the offset of the cosine wave points."));
            }

            displayDistortionSinCosWave = EditorGUILayout.Foldout(displayDistortionSinCosWave, "SinCos Wave", true, scFoldoutStyle);

            if (displayDistortionSinCosWave)
            {
                materialEditor.ShaderProperty(_SinCosWaveAngle, new GUIContent("SinCos Wave Angle", "Adjust the angle of the horizontal screen sincos wave."));
                materialEditor.ShaderProperty(_SinCosWaveSinDensity, new GUIContent("SinCos Wave Sin Density", "Adjust the distance between the sin portion of the sincos wave direction changes."));
                materialEditor.ShaderProperty(_SinCosWaveCosDensity, new GUIContent("SinCos Wave Cos Density", "Adjust the distance between the cos portion of the sincos wave direction changes."));
                materialEditor.ShaderProperty(_SinCosWaveAmplitude, new GUIContent("SinCos Wave Distance", "Adjust how far the sincos wave shifts the screen."));
                materialEditor.ShaderProperty(_SinCosWaveSinOffset, new GUIContent("SinCos Wave Sin Offset", "Adjust the offset of the sin portion of the wave points."));
                materialEditor.ShaderProperty(_SinCosWaveCosOffset, new GUIContent("SinCos Wave Cos Offset", "Adjust the offset of the cos portion of the wave points."));
            }

            displayDistortionTanWave = EditorGUILayout.Foldout(displayDistortionTanWave, "Tan Wave", true, scFoldoutStyle);

            if (displayDistortionTanWave)
            {
                materialEditor.ShaderProperty(_TanWaveAngle, new GUIContent("Tan Wave Angle", "Adjust the angle of the horizontal screen tangent wave."));
                materialEditor.ShaderProperty(_TanWaveDensity, new GUIContent("Tan Wave Density", "Adjust the distance between the tangent wave direction changes."));
                materialEditor.ShaderProperty(_TanWaveAmplitude, new GUIContent("Tan Wave Distance", "Adjust how far the tangent wave shifts the screen."));
                materialEditor.ShaderProperty(_TanWaveOffset, new GUIContent("Tan Wave Offset", "Adjust the offset of the tangent wave points."));
            }

            displayDistortionSlice = EditorGUILayout.Foldout(displayDistortionSlice, "Screen Slice", true, scFoldoutStyle);

            if (displayDistortionSlice)
            {
                materialEditor.ShaderProperty(_SliceAngle, new GUIContent("Slice Angle", "Adjust the angle of the screen slice."));
                materialEditor.ShaderProperty(_SliceOffset, new GUIContent("Slice Offset From Center", "Adjust the offset of the slice from the center of the screen. The slice angle controls which direction the offset pushes the slice."));
                materialEditor.ShaderProperty(_SliceWidth, new GUIContent("Slice Width", "Adjust the width of the screen slice."));
                materialEditor.ShaderProperty(_SliceDistance, new GUIContent("Slice Distance", "Adjust how far the screen slice shifts the screen."));
            }

            displayDistortionRipple = EditorGUILayout.Foldout(displayDistortionRipple, "Water Ripple", true, scFoldoutStyle);

            if (displayDistortionRipple)
            {
                materialEditor.ShaderProperty(_RippleInnerFalloff, new GUIContent("Ripple Inner Falloff", "Select an inner distance from the center of the screen to stop displaying the ripple effect."));
                materialEditor.ShaderProperty(_RippleOuterFalloff, new GUIContent("Ripple Outer Falloff", "Select an outer distance from the center of the screen to stop displaying the ripple effect."));
                materialEditor.ShaderProperty(_RippleDensity, new GUIContent("Ripple Density", "Adjust the distance between the screen water ripples."));
                materialEditor.ShaderProperty(_RippleAmplitude, new GUIContent("Ripple Distance", "Adjust the distance the ripples push the screen at the peaks."));
                materialEditor.ShaderProperty(_RippleOffset, new GUIContent("Ripple Offset", "Adjust the offset of the ripples away from the center of the screen."));
            }

            displayDistortionCheckerboard = EditorGUILayout.Foldout(displayDistortionCheckerboard, "Checkerboard", true, scFoldoutStyle);

            if (displayDistortionCheckerboard)
            {
                materialEditor.ShaderProperty(_CheckerboardAngle, new GUIContent("Checkerboard Angle", "Adjust the angle of the checkerboard grid."));
                materialEditor.ShaderProperty(_CheckerboardScale, new GUIContent("Checkerboard Scale", "Adjust the scale of the checkerboard grid."));
                materialEditor.ShaderProperty(_CheckerboardShift, new GUIContent("Checkerboard Shift Distance", "Adjust the distance that each of the checkerboard squares pushes the screen."));
            }

            displayDistortionQuantization = EditorGUILayout.Foldout(displayDistortionQuantization, "Quantization", true, scFoldoutStyle);
            
            if (displayDistortionQuantization)
            {
                materialEditor.ShaderProperty(_Quantization, new GUIContent("Quantization", "Adjust the level of quantization applied to the screen."));
            }

            displayDistortionRingRotation = EditorGUILayout.Foldout(displayDistortionRingRotation, "Alternating Ring Rotation", true, scFoldoutStyle);

            if (displayDistortionRingRotation)
            {
                materialEditor.ShaderProperty(_RingRotationInnerAngle, new GUIContent("Ring Rotation Inner-Angle", "Adjust the rotation for the 'inside' of each ring."));
                materialEditor.ShaderProperty(_RingRotationOuterAngle, new GUIContent("Ring Rotation Outer-Angle", "Adjust the rotation for the 'outside' of each ring."));
                materialEditor.ShaderProperty(_RingRotationRadius, new GUIContent("Ring Rotation Inner-Radius", "Adjust the radius of the 'inside' rings."));
                materialEditor.ShaderProperty(_RingRotationWidth, new GUIContent("Ring Rotation Outer-Radius", "Adjust the radius of the 'outside' rings."));
            }

            displayDistortionWarp = EditorGUILayout.Foldout(displayDistortionWarp, "Screen Warp", true, scFoldoutStyle);

            if (displayDistortionWarp)
            {
                materialEditor.ShaderProperty(_WarpAngle, new GUIContent("Warp Angle", "Adjust the angle of the screen warping."));
                materialEditor.ShaderProperty(_WarpIntensity, new GUIContent("Warp Distance", "Adjust the maximum distance of the screen warping."));
            }

            displayDistortionSpiral = EditorGUILayout.Foldout(displayDistortionSpiral, "Spiral", true, scFoldoutStyle);

            if (displayDistortionSpiral)
            {
                materialEditor.ShaderProperty(_SpiralIntensity, new GUIContent("Spiral Distance", "Adjust how quickly the screen spirals with respect to the distance from the center of the screen."));
            }

            displayDistortionPolarInversion = EditorGUILayout.Foldout(displayDistortionPolarInversion, "Polar Inversion", true, scFoldoutStyle);

            if (displayDistortionPolarInversion)
            {
                materialEditor.ShaderProperty(_PolarInversionIntensity, new GUIContent("Polar Inversion Distance", "Adjust how far the screen is pushed into or out of the center of the screen. Combine with 'Wrap' World Sampling Mode for maximum effect."));
            }

            displayDistortionFishEye = EditorGUILayout.Foldout(displayDistortionFishEye, "Fish Eye", true, scFoldoutStyle);

            if (displayDistortionFishEye)
            {
                materialEditor.ShaderProperty(_FishEyeIntensity, new GUIContent("Fish Eye Distance", "Adjust the distance of the fish eye effect."));
            }

            displayDistortionKaleidoscope = EditorGUILayout.Foldout(displayDistortionKaleidoscope, "Kaleidoscope", true, scFoldoutStyle);

            if (displayDistortionKaleidoscope)
            {
                materialEditor.ShaderProperty(_KaleidoscopeAngle, new GUIContent("Kaleidoscope Angle", "Adjust the angle used to sample the kaleidoscope effect from. Multiples of pi are recommended when simultaneously changing segment count."));
                materialEditor.ShaderProperty(_KaleidoscopeSegments, new GUIContent("Kaleidoscope Segments", "Adjust the number of segments in the kaleidoscope."));
            }

            displayDistortionBlockDisplacement = EditorGUILayout.Foldout(displayDistortionBlockDisplacement, "Block Displacement", true, scFoldoutStyle);

            if (displayDistortionBlockDisplacement)
            {
                materialEditor.ShaderProperty(_BlockDisplacementAngle, new GUIContent("Block Displacement Angle", "Adjust the angle of the block displacement grid."));
                materialEditor.ShaderProperty(_BlockDisplacementSize, new GUIContent("Block Displacement Size", "Adjust the size of the block displacement grid."));
                materialEditor.ShaderProperty(_BlockDisplacementMode, new GUIContent("Block Displacement Mode", "Select to have smooth changes in displacement over time or random displacement every frame."));
                materialEditor.ShaderProperty(_BlockDisplacementIntensity, new GUIContent("Block Displacement Distance", "Adjust the distance each block randomly displaces pixels."));
                materialEditor.ShaderProperty(_BlockDisplacementOffset, new GUIContent("Block Displacement Offset", "Adjust the offset into the selected displacement mode."));
            }

            displayDistortionGlitch = EditorGUILayout.Foldout(displayDistortionGlitch, "Glitch", true, scFoldoutStyle);

            if (displayDistortionGlitch)
            {
                materialEditor.ShaderProperty(_GlitchAngle, new GUIContent("Glitch Angle", "Adjust the angle of the glitches."));
                materialEditor.ShaderProperty(_GlitchCount, new GUIContent("Glitch Count", "Adjust the number of glitches."));
                materialEditor.ShaderProperty(_MinGlitchWidth, new GUIContent("Glitch Minimum Width", "Adjust the minimum width of the glitches"));
                materialEditor.ShaderProperty(_MinGlitchHeight, new GUIContent("Glitch Minimum Height", "Adjust the minimum height of the glitches."));
                materialEditor.ShaderProperty(_MaxGlitchWidth, new GUIContent("Glitch Maximum Width", "Adjust the maximum width of the glitches."));
                materialEditor.ShaderProperty(_MaxGlitchHeight, new GUIContent("Glitch Maximum Height", "Adjust the maximum height of the glitches."));

                GUILayout.Space(20);
                materialEditor.ShaderProperty(_GlitchIntensity, new GUIContent("Glitch Distance", "Adjust how far the glitches shift the screen."));
                materialEditor.ShaderProperty(_GlitchSeed, new GUIContent("Glitch Seed", "Adjust the random seed used for generating glitches."));
                materialEditor.ShaderProperty(_GlitchSeedInterval, new GUIContent("Glitch Seed Interval", "Adjust how far the seed must change before new glitches are generated."));
            }

            displayDistortionSimplexNoise = EditorGUILayout.Foldout(displayDistortionSimplexNoise, "Simplex Noise", true, scFoldoutStyle);

            if (displayDistortionSimplexNoise)
            {
                materialEditor.ShaderProperty(_NoiseScale, new GUIContent("Simplex Noise Scale", "Adjust the scale of the noise."));
                materialEditor.ShaderProperty(_NoiseStrength, new GUIContent("Simplex Noise Strength", "Adjust the distance the noise shifts the screen."));
                materialEditor.ShaderProperty(_NoiseOffset, new GUIContent("Simplex Noise Offset", "Adjust the offset into the noise used for shifting the screen."));
            }

            displayDistortionVoroniNoise = EditorGUILayout.Foldout(displayDistortionVoroniNoise, "Voroni Noise", true, scFoldoutStyle);

            if (displayDistortionVoroniNoise)
            {
                materialEditor.ShaderProperty(_VoroniNoiseScale, new GUIContent("Voroni Noise Scale", "Adjust the scale of the noise."));
                materialEditor.ShaderProperty(_VoroniNoiseBorderSize, new GUIContent("Voroni Noise Border Size", "Adjust the size of the voroni noise borders"));
                materialEditor.ShaderProperty(_VoroniNoiseBorderMode, new GUIContent("Voroni Noise Border Mode", "Adjust the mode of the voroni borders."));

                GUILayout.Space(20);
                materialEditor.ShaderProperty(_VoroniNoiseStrength, new GUIContent("Voroni Noise Strength", "Adjust the distance the noise shifts the screen."));
                materialEditor.ShaderProperty(_VoroniNoiseBorderStrength, new GUIContent("Voroni Noise Border Strength", "Adjust the distance the borders shift the screen."));
                materialEditor.ShaderProperty(_VoroniNoiseOffset, new GUIContent("Voroni Noise Offset", "Adjust the offset into the noise used for shifting the screen."));
            }

            displayDistortionFan = EditorGUILayout.Foldout(displayDistortionFan, "Fan", true, scFoldoutStyle);

            if (displayDistortionFan)
            {
                materialEditor.ShaderProperty(_FanScale, new GUIContent("Fan Scale", "Adjust the size of the fans."));
                materialEditor.ShaderProperty(_FanBlades, new GUIContent("Fan Blades", "Adjust the number of fan blades."));
                materialEditor.ShaderProperty(_FanDistance, new GUIContent("Fan Distance", "Adjust the distance the fans shift the screen."));
                materialEditor.ShaderProperty(_FanOffset, new GUIContent("Fan Offset", "Adjust the offset into the blade effect to create different patterns based on the 'Fan Distance'."));
            }

            displayDistortionGeometricDither = EditorGUILayout.Foldout(displayDistortionGeometricDither, "Geometric Dither", true, scFoldoutStyle);

            if (displayDistortionGeometricDither)
            {
                materialEditor.ShaderProperty(_GeometricDitherQuality, new GUIContent("Geometric Dither Quality", "Adjust the quality of the dither effect."));
                materialEditor.ShaderProperty(_GeometricDitherRandomization, new GUIContent("Geometric Dither Randomization", "Adjust how quickly the dither effect is randomly moved around."));
                materialEditor.ShaderProperty(_GeometricDitherDistance, new GUIContent("Geometric Dither Distance", "Adjust the distance the pixels are geometrically dithered away from their original position."));
            }

            displayDistortionColorDisplacement = EditorGUILayout.Foldout(displayDistortionColorDisplacement, "Color Displacement", true, scFoldoutStyle);

            if (displayDistortionColorDisplacement)
            {
                materialEditor.ShaderProperty(_ColorVectorDisplacementCoordinateSpace, new GUIContent("Color Displacement Coordinate Space", "Select between displacing the pixels along the view or in world space."));
                materialEditor.ShaderProperty(_ColorVectorDisplacementStrength, new GUIContent("Color Displacement Strength", "Adjust the strength of the displacement based on the color of the screen."));
            }

            displayDistortionNormalDisplacement = EditorGUILayout.Foldout(displayDistortionNormalDisplacement, "Normal Displacement (Requires Directional Light)", true, scFoldoutStyle);

            if (displayDistortionNormalDisplacement)
            {
                materialEditor.ShaderProperty(_NormalVectorDisplacementCoordinateSpace, new GUIContent("Normal Displacement Coordinate Space", "Select between displacing the pixels along the view or in world space."));
                materialEditor.ShaderProperty(_NormalVectorDisplacementQuality, new GUIContent("Normal Displacement Quality", "Adjust the quality of the surface normal reconstruction."));
                materialEditor.ShaderProperty(_NormalVectorDisplacementStrength, new GUIContent("Normal Displacement Strength", "Adjust the strength of the displacement based on the normal of the surface underneath each pixel."));
            }

            EditorGUI.indentLevel = 0;
        }
    }

    public void drawColorParamters(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        displayColorParameters = EditorGUILayout.Foldout(displayColorParameters, "Color Effects", true, scFoldoutStyle);

        if (displayColorParameters == true)
        {
            EditorGUI.indentLevel = 1;

            displayEmptySpace = EditorGUILayout.Foldout(displayEmptySpace, "Empty Space", true, scFoldoutStyle);

            if (displayEmptySpace)
            {
                materialEditor.ShaderProperty(_EmptySpaceColor, new GUIContent("Color", "Adjust the color used to fill in empty space."));
            }

            displaySignalNoise = EditorGUILayout.Foldout(displaySignalNoise, "Signal Noise", true, scFoldoutStyle);

            if (displaySignalNoise)
            {
                materialEditor.ShaderProperty(_SignalNoiseSize, new GUIContent("Signal Noise Size", "Adjust the scale of the signal noise."));
                materialEditor.ShaderProperty(_ColorizedSignalNoise, new GUIContent("Signal Noise Colorization", "Adjust the colorization of the signal noise."));
                materialEditor.ShaderProperty(_SignalNoiseOpacity, new GUIContent("Signal Noise Opacity", "Adjust the opacity of the signal noise."));
            }

            displayBlurMovement = EditorGUILayout.Foldout(displayBlurMovement, "Cancer Movement Blur", true, scFoldoutStyle);

            if (displayBlurMovement)
            {
                materialEditor.ShaderProperty(_BlurMovementSampleCount, new GUIContent("Movement Sample Count", "Adjust the amount of samples taken."));
                materialEditor.ShaderProperty(_BlurMovementTarget, new GUIContent("Movement Target Position", "Adjust the target position between the pixels starting and ending position."));
                materialEditor.ShaderProperty(_BlurMovementRange, new GUIContent("Movement Range", "Adjust how much of the pixels movement is blurred together."));
                materialEditor.ShaderProperty(_BlurMovementExtrapolation, new GUIContent("Movement Extrapolation", "Adjust how much movement of the pixel can be extrapolated past its starting or ending points."));
                materialEditor.ShaderProperty(_BlurMovementBlurIntensity, new GUIContent("Movement Blur Amount", "Adjust how much the samples are blurred together. Setting to 0 allows for immitating the classic PS2 era boss zoom blur."));
                materialEditor.ShaderProperty(_BlurMovementOpacity, new GUIContent("Movement Opacity", "Adjust how much the blur is blended onto the screen."));
                materialEditor.ShaderProperty(_BlurMovementBlend, new GUIContent("Movement Blend", "Adjust how much the blur is blended with the screen. Use values less than 1 to combine with Chromatic Aberration or RGB Distortion Desync."));
            }

            displayChromaticAberration = EditorGUILayout.Foldout(displayChromaticAberration, "Chromatic Aberration", true, scFoldoutStyle);

            if (displayChromaticAberration)
            {
                materialEditor.ShaderProperty(_ChromaticAberrationShape, new GUIContent("Chromatic Aberration Shape", "Select the shape of the chromatic aberration."));
                materialEditor.ShaderProperty(_ChromaticAberrationSeparation, new GUIContent("Chromatic Aberration Separation", "Adjust the separation between each color channel."));
                materialEditor.ShaderProperty(_ChromaticAberrationStrength, new GUIContent("Chromatic Aberration Strength", "Adjust the strength of the chromatic aberration."));
                materialEditor.ShaderProperty(_ChromaticAberrationBlend, new GUIContent("Chromatic Aberration Blend", "Adjust how much the chromatic aberration is blended with the screen. Use values less than 1 to combine with RGB Distortion Desync or Cancer Movement Blur."));
            }

            displayRGBDistortionDesync = EditorGUILayout.Foldout(displayRGBDistortionDesync, "RGB Distortion Desync", true, scFoldoutStyle);

            if (displayRGBDistortionDesync)
            {
                materialEditor.ShaderProperty(_DistortionDesyncR, new GUIContent("Red Channel Desync", "Adjust how much the red color channel distortion is desynchronized."));
                materialEditor.ShaderProperty(_DistortionDesyncG, new GUIContent("Green Channel Desync", "Adjust how much the green color channel distortion is desynchronized."));
                materialEditor.ShaderProperty(_DistortionDesyncB, new GUIContent("Blue Channel Desync", "Adjust how much the blue color channel distortion is desynchronized."));
                materialEditor.ShaderProperty(_DistortionDesyncBlend, new GUIContent("Distortion Desync Blend", "Adjust how much the desynced distortion is blended with the screen. Use values less than 1 to combine with Chromatic Aberration or Cancer Movement Blur."));
            }

            displayCircularVignette = EditorGUILayout.Foldout(displayCircularVignette, "Circular Vignette", true, scFoldoutStyle);

            if (displayCircularVignette)
            {
                materialEditor.ShaderProperty(_CircularVignetteMode, new GUIContent("Circular Vignette Function", "Adjust the function used to determine how quickly the vignette fades in between the beginning and ending distances."));
                materialEditor.ShaderProperty(_CircularVignetteRoundness, new GUIContent("Circular Vignette Roundness", "Adjust how round the vignette is, which can be used to create a blinking/eyes closing effect."));
                materialEditor.ShaderProperty(_CircularVignetteBegin, new GUIContent("Circular Vignette Begin Distance", "Adjust the distance that the vignette begins to blend in."));
                materialEditor.ShaderProperty(_CircularVignetteEnd, new GUIContent("Circular Vignette End Distance", "Adjust the distance that the vignette reaches maximum opacity."));
                materialEditor.ShaderProperty(_CircularVignetteScaleWithDistance, new GUIContent("Circular Vignette Scale With Distance", "Select if the vignette should be scaled with distance. Recommended when using coordinate space Centered On Object."));
                materialEditor.ShaderProperty(_CircularVignetteColor, new GUIContent("Circular Vignette Color", "Adjust the color of the vignette."));
                materialEditor.ShaderProperty(_CircularVignetteOpacity, new GUIContent("Circular Vignette Opacity", "Adjust the opacity of the vignette."));
            }

            displayFog = EditorGUILayout.Foldout(displayFog, "Fog (Requires Directional Light)", true, scFoldoutStyle);

            if (displayFog)
            {
                materialEditor.ShaderProperty(_FogType, new GUIContent("Fog Function", "Select the function used to detmine how quickly the fog reaches maximum opacity between the beginning and ending distances."));
                materialEditor.ShaderProperty(_FogBegin, new GUIContent("Fog Begin Distance", "Adjust the distance that the fog begins to blend in."));
                materialEditor.ShaderProperty(_FogEnd, new GUIContent("Fog End Distance", "Adjust the distance that the fog reaches maximum opacity."));
                materialEditor.ShaderProperty(_FogColor, new GUIContent("Fog Color", "Adjust the color of the fog."));
            }

            displayEdgelordStriples = EditorGUILayout.Foldout(displayEdgelordStriples, "Edgelord Stripes", true, scFoldoutStyle);

            if (displayEdgelordStriples)
            {
                materialEditor.ShaderProperty(_EdgelordStripeSize, new GUIContent("Stripe Size", "Adjust the size of the stripes."));
                materialEditor.ShaderProperty(_EdgelordStripeOffset, new GUIContent("Stripe Offset", "Adjust the vertical offset of the stripes."));
                materialEditor.ShaderProperty(_EdgelordStripeColor, new GUIContent("Stripe Color", "Adjust the color of the stripes."));
            }

            displayColorMask = EditorGUILayout.Foldout(displayColorMask, "Color Mask", true, scFoldoutStyle);

            if (displayColorMask)
            {
                materialEditor.ShaderProperty(_ColorMask, new GUIContent("Mask", "Apply a mask to the screen to remove unwanted colors. For example, a red mask will remove all green and blue colors."));
            }

            displayColorPalette = EditorGUILayout.Foldout(displayColorPalette, "Color Palettization (Requires Directional Light)", true, scFoldoutStyle);

            if (displayColorPalette)
            {
                materialEditor.ShaderProperty(_PaletteScale, new GUIContent("Scale", "Adjust the scale of the color palette in the world."));
                materialEditor.ShaderProperty(_PaletteOffset, new GUIContent("Offset", "Adjust the offset of the color palette."));
                materialEditor.ShaderProperty(_PalleteSource, new GUIContent("Control Source", "Select if the color palette should be automatically generated from the screen colors, or user specified."));
                materialEditor.ShaderProperty(_PaletteA, new GUIContent("Palette Bias A", "Adjust the contast and brightness of the color palette."));
                materialEditor.ShaderProperty(_PaletteB, new GUIContent("Palette Bias B", "Adjust the contast and brightness of the color palette."));
                materialEditor.ShaderProperty(_PaletteOscillation, new GUIContent("Palette Oscillation", "Adjust how quickly the palette color changes. Integer values should be used in order for offset to smoothly loop through the palette."));
                materialEditor.ShaderProperty(_PalettePhase, new GUIContent("Palette Phase", "Adjust how quickly the colors loop back around."));
                materialEditor.ShaderProperty(_PaletteOpacity, new GUIContent("Opacity", "Adjust how much of the color palette is blended into the screen color."));
            }

            displayColorInversion = EditorGUILayout.Foldout(displayColorInversion, "Color Inversion", true, scFoldoutStyle);

            if (displayColorInversion)
            {
                materialEditor.ShaderProperty(_ColorInversionR, new GUIContent("Red Color Channel Inversion", "Adjust how much the red color channel is inverted."));
                materialEditor.ShaderProperty(_ColorInversionG, new GUIContent("Green Color Channel Inversion", "Adjust how much the green color channel is inverted."));
                materialEditor.ShaderProperty(_ColorInversionB, new GUIContent("Blue Color Channel Inversion", "Adjust how much the blue color channel is inverted."));
            }

            displayColorModifier = EditorGUILayout.Foldout(displayColorModifier, "Color Modifiers", true, scFoldoutStyle);

            if (displayColorModifier)
            {
                materialEditor.ShaderProperty(_ColorModifierMode, new GUIContent("Color Modifier Function", "Select one of the many color modifier functions."));
                materialEditor.ShaderProperty(_ColorModifierStrength, new GUIContent("Color Modifier Strength", "Adjust how strength of the modifier function."));
                materialEditor.ShaderProperty(_ColorModifierBlend, new GUIContent("Color Modifier Blend", "Adjust how much of the modified color is blended into the screen color."));
            }

            displayHSV = EditorGUILayout.Foldout(displayHSV, "HSV Adjustment", true, scFoldoutStyle);

            if (displayHSV)
            {
                materialEditor.ShaderProperty(_Hue, new GUIContent("Hue", "Adjust the hue of the screen."));
                materialEditor.ShaderProperty(_Saturation, new GUIContent("Saturation", "Adjust the saturation of the screen."));
                materialEditor.ShaderProperty(_Value, new GUIContent("Value", "Adjust the value of the screen."));

                GUILayout.Space(20);
                materialEditor.ShaderProperty(_ClampSaturation, new GUIContent("Clamp Saturation", "Select if saturation should be clamped between 0 and 1. Useful for turning the screen black and white."));
                
            }
            
            displayImaginaryColor = EditorGUILayout.Foldout(displayImaginaryColor, "Imaginary Color", true, scFoldoutStyle);

            if (displayImaginaryColor)
            {
                materialEditor.ShaderProperty(_ImaginaryColorAngle, new GUIContent("Imaginary Color Angle", "Adjust the rotation of the color wheel."));
                materialEditor.ShaderProperty(_ImaginaryColorBlendMode, new GUIContent("Imaginary Color Blend Mode", "Adjust blend mode of the color wheel."));
                materialEditor.ShaderProperty(_ImaginaryColorOpacity, new GUIContent("Imaginary Color Opacity", "Adjust how much the imaginary colors are blended into the screen color."));
            }

            displaySobel = EditorGUILayout.Foldout(displaySobel, "Sobel Filter", true, scFoldoutStyle);

            if (displaySobel)
            {
                materialEditor.ShaderProperty(_SobelSearchDistance, new GUIContent("Sobel Search Distance", "Adjust how far each pixel searches for outlines."));
                materialEditor.ShaderProperty(_SobelQuality, new GUIContent("Sobel Quality", "Adjust the quality of the sobel filter. It's recommended that Projected Coordinate Space is used to further increase quality."));
                materialEditor.ShaderProperty(_SobelBlendMode, new GUIContent("Sobel Blend Mode", "Adjust the blend mode of the sobel filter."));
                materialEditor.ShaderProperty(_SobelOpacity, new GUIContent("Sobel Opacity", "Adjust how much the sobel filter is blended into the screen color."));
            }

            displayColorShift = EditorGUILayout.Foldout(displayColorShift, "Color Channel Shift", true, scFoldoutStyle);

            if (displayColorShift)
            {
                materialEditor.ShaderProperty(_colorSkewROverride, new GUIContent("Red Channel Shift Override", "Select between blending the shifted color or replacing the screen's color channel with the shifted version."));
                materialEditor.ShaderProperty(_colorSkewRAngle, new GUIContent("Red Channel Shift Angle", "Adjust the angle of the color shift."));
                materialEditor.ShaderProperty(_colorSkewRDistance, new GUIContent("Red Channel Shift Distance", "Adjust how far the color channel is shifted."));
                materialEditor.ShaderProperty(_colorSkewROpacity, new GUIContent("Red Channel Shift Opacity", "Adjust the opacity of the shifted color channel."));
                
                GUILayout.Space(20);
                materialEditor.ShaderProperty(_colorSkewGOverride, new GUIContent("Green Channel Shift Override", "Select between blending the shifted color or replacing the screen's color channel with the shifted version."));
                materialEditor.ShaderProperty(_colorSkewGAngle, new GUIContent("Green Channel Shift Angle", "Adjust the angle of the color shift."));
                materialEditor.ShaderProperty(_colorSkewGDistance, new GUIContent("Green Channel Shift Distance", "Adjust how far the color channel is shifted."));
                materialEditor.ShaderProperty(_colorSkewGOpacity, new GUIContent("Green Channel Shift Opacity", "Adjust the opacity of the shifted color channel."));

                GUILayout.Space(20);
                materialEditor.ShaderProperty(_colorSkewBOverride, new GUIContent("Blue Channel Shift Override", "Select between blending the shifted color or replacing the screen's color channel with the shifted version."));
                materialEditor.ShaderProperty(_colorSkewBAngle, new GUIContent("Blue Channel Shift Angle", "Adjust the angle of the color shift."));
                materialEditor.ShaderProperty(_colorSkewBDistance, new GUIContent("Blue Channel Shift Distance", "Adjust how far the color channel is shifted."));
                materialEditor.ShaderProperty(_colorSkewBOpacity, new GUIContent("Blue Channel Shift Opacity", "Adjust the opacity of the shifted color channel."));
            }

            EditorGUI.indentLevel = 0;
        }
    }
}
