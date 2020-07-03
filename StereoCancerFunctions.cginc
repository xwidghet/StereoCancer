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

#ifndef STEREO_CANCER_FUNCTIONS_CGINC
#define STEREO_CANCER_FUNCTIONS_CGINC

  ///////////////////////////
 // Distortion functions ///
///////////////////////////

float4 computeStereoUV(float4 worldCoordinates)
{
	float4 screenCoords = mul(UNITY_MATRIX_VP, worldCoordinates);
	return ComputeGrabScreenPos(screenCoords);
}

float2 screenToEyeUV(float2 screenUV)
{
#ifdef UNITY_SINGLE_PASS_STEREO
	// Convert UV coordinates to eye-specific 0-1 coordiantes
	float offset = 0.5 * step(1, unity_StereoEyeIndex);
	float min = offset;
	float max = 0.5 + offset;

	float uvDist = max - min;
	screenUV.x = (screenUV.x - min) / uvDist;
#endif

	return screenUV;
}

float2 EyeUVToScreen(float2 screenUV)
{
#ifdef UNITY_SINGLE_PASS_STEREO
	float _offset = 0.5 * step(1, unity_StereoEyeIndex);
	float _min = _offset;
	float _max = 0.5 + _offset;

	float _uvDist = _max - _min;

	// Convert the eye-specific 0-1 coordinates back to 0-1 UV coordinates
	screenUV.x = (screenUV.x * _uvDist) + _min;
#endif

	return screenUV;
}

float4 clampUVCoordinates(float4 stereoCoordinates)
{
	float2 stereoUVPos = (stereoCoordinates.xy / stereoCoordinates.w);

	stereoUVPos = screenToEyeUV(stereoUVPos);
	stereoUVPos = clamp(stereoUVPos, 0, 1);
	stereoUVPos = EyeUVToScreen(stereoUVPos);

	stereoCoordinates.xy = stereoUVPos * stereoCoordinates.w;

	return stereoCoordinates;
}

float4 wrapUVCoordinates(float4 stereoCoordinates)
{
	float2 stereoUVPos = stereoCoordinates.xy / stereoCoordinates.w;

	// Wrap around by grabbing the fractional part of the UV
	// and convert back to stereo coordinates.
	stereoUVPos = frac(stereoUVPos);

	stereoCoordinates.xy = stereoUVPos * stereoCoordinates.w;

	return stereoCoordinates;
}

float4 shrink(float3 view, float3 axis, float4 worldPos, float intensity)
{
	float angle = acos(dot(view, axis));
	float interpolation = abs(UNITY_PI / 2 - angle);
	float dir = 1 + -2 * step(UNITY_PI / 2, angle);

	worldPos.xyz += dir * axis*intensity*interpolation;

	return worldPos;
}

float4 stereoRotate(float4 worldCoordinates, float3 axis, float angle)
{
	worldCoordinates.xyz = mul(rotAxis(axis, fmod(angle, UNITY_PI * 2)), worldCoordinates);

	return worldCoordinates;
}

float4 stereoMove(float4 worldPos, float3 camFront, float3 camRight, float angle, float distance)
{
	float3 movedPos = mul(rotAxis(camFront, angle), camRight);

	worldPos.xyz += movedPos * distance;

	return worldPos;
}

float4 stereoSplitX(float4 worldPos, float3 axis, float distance, float oneSide, inout bool clearPixel)
{
	if (oneSide != 0)
	{
		if (sign(distance) == -sign(worldPos.x))
		{
			if (abs(worldPos.x) < abs(distance))
				clearPixel = true;
			else
				worldPos.xyz += axis * distance * -sign(worldPos.x) * sign(distance);
		}
	}
	else
	{
		if(abs(worldPos.x) < distance)
			clearPixel = true;
		else
			worldPos.xyz += axis * distance * -sign(worldPos.x);
	}

	return worldPos;
}

float4 stereoSplitY(float4 worldPos, float3 axis, float distance, float oneSide, inout bool clearPixel)
{
	if (oneSide != 0)
	{
		if (sign(distance) == -sign(worldPos.y))
		{
			if (abs(worldPos.y) < abs(distance))
				clearPixel = true;
			else
				worldPos.xyz += axis * distance * -sign(worldPos.y) * sign(distance);
		}
	}
	else
	{
		if (abs(worldPos.y) < distance)
			clearPixel = true;
		else
			worldPos.xyz += axis * distance * -sign(worldPos.y);
	}

	return worldPos;
}

float4 stereoBarX(float4 worldPos, float3 camFront, float3 camRight, float angle, float interval, float offset, float distance) {
	float flipPoint = worldPos.y;
	if(angle != 0)
		flipPoint = stereoRotate(worldPos, camFront, angle).y;

	float dir = fmod(abs(flipPoint) + interval / 2 + offset, interval*2) < interval ? -1 : 1;

	worldPos.xyz += dir * camRight * distance;

	return worldPos;
}

float4 stereoBarY(float4 worldPos, float3 camFront, float3 camUp, float angle, float interval, float offset, float distance) {
	float flipPoint = worldPos.x;
	if (angle != 0)
		flipPoint = stereoRotate(worldPos, camFront, angle).x;

	float dir = fmod(abs(flipPoint) + interval / 2 + offset, interval * 2) < interval ? -1 : 1;

	worldPos.xyz += dir * camUp * distance;

	return worldPos;
}

float4 stereoSinBarX(float4 worldPos, float3 camFront, float3 camRight, float angle, float interval, float offset, float distance) {
	float flipPoint = floor(worldPos.y / interval);
	if (angle != 0)
		flipPoint = floor(stereoRotate(worldPos, camFront, angle).y / interval);

	float dir = sin(flipPoint + offset);

	worldPos.xyz += dir * camRight * distance;

	return worldPos;
}

float4 stereoSinBarY(float4 worldPos, float3 camFront, float3 camUp, float angle, float interval, float offset, float distance) {
	float flipPoint = floor(worldPos.x / interval);
	if (angle != 0)
		flipPoint = floor(stereoRotate(worldPos, camFront, angle).x / interval);

	float dir = sin(flipPoint + offset);

	worldPos.xyz += dir * camUp * distance;

	return worldPos;
}

float4 stereoWarp(float4 worldPos, float3 camFront, float angle, float intensity)
{
	float3 rotatedPos = mul(rotAxis(normalize(camFront), angle), normalize(worldPos.xyz));
	float3 delta = rotatedPos - normalize(worldPos.xyz);

	worldPos.xyz += delta * intensity;

	return worldPos;
}

// Useful for world coordinates which are not axis-aligned.
float4 stereoZoom(float4 worldCoordinates, float3 camFront, float distance)
{
	worldCoordinates.xyz += camFront * distance;

	float4 screenCoords = mul(UNITY_MATRIX_VP, worldCoordinates);
	return ComputeGrabScreenPos(screenCoords);
}

float4 stereoSkewX(float4 worldCoordinates, float3 camRight, float interval, float distance, float offset)
{
	float intPosY = floor(abs(worldCoordinates.y));
	float skewDir = -1 + 2 * step(1, (intPosY % 2));

	float skewVal = fmod(abs(worldCoordinates.y + offset), interval) / interval - 0.5;
	skewVal *= skewDir;

	skewVal *= distance;

	worldCoordinates.xyz += camRight * skewVal;

	return worldCoordinates;
}

float4 stereoSkewY(float4 worldCoordinates, float3 camUp, float interval, float distance, float offset)
{
	float intPosX = floor(abs(worldCoordinates.x));
	float skewDir = -1 + 2 * step(1, (intPosX % 2));

	float skewVal = fmod(abs(worldCoordinates.x + offset), interval) / interval - 0.5;
	skewVal *= skewDir;

	skewVal *= distance;

	worldCoordinates.xyz += camUp * skewVal;

	return worldCoordinates;
}

float4 geometricDither(float4 worldCoordinates, float3 camRight, float3 camUp, float distance, float quality, float randomization)
{
	worldCoordinates *= 10;
	float offset = 0;

	// This could be done every loop, but it doesn't increase
	// quality enough to be worth the performance hit
	if (randomization != 0)
		offset = gold_noise(_Time.z, _Time.y)*randomization;

	// There's probably a way more efficient way to do this,
	// but it's good enough for now and allows for
	// user-configurable performance vs quality trading.
	//
	// (Though users are most likely to just crank quality to the max)
	const float ditherInterval = 1;
	for (int i = 0; i < quality; i++)
	{
		worldCoordinates = stereoSkewX(worldCoordinates, camRight, ditherInterval, distance, offset);
		worldCoordinates = stereoSkewY(worldCoordinates, camUp, ditherInterval, distance, offset);

		worldCoordinates = stereoSkewX(worldCoordinates, camRight, -ditherInterval, -distance, -offset);
		worldCoordinates = stereoSkewY(worldCoordinates, camUp, -ditherInterval, -distance, -offset);
	}

	return worldCoordinates / 10;
}

float4 stereoCheckerboard(float4 coordinates, float scale, float shiftDistance)
{
	float2 intPos = floor(coordinates.xy / scale + 0.5);

	float offset = 1 + -2 * step(1, (abs(intPos.y) % 2));
	float dir = 1 + -2 * step(1, (abs(intPos.x) % 2));

	float2 integerOffset = float2(dir * shiftDistance * offset, 0);

	coordinates.xy += float2(integerOffset);

	return coordinates;
}

float4 stereoQuantization(float4 worldCoordinates, float scale)
{
	// Add 0.5 to make it so that the center of the screen is on
	// the center of a quantization square, rather than the corner
	// between 4 squares.
	float2 intPos = floor(worldCoordinates.xy * scale + 0.5);
	worldCoordinates.xy = (intPos / scale);

	return worldCoordinates;
}

float4 stereoRingRotation(float4 worldCoordinates,float3 camFront, float angle, float ringRadius, float ringWidth)
{
	// Not sure of what the best way is to make this intuitive to new users to use.
	// If the user only changes ringWidth and not radius then their screen will be
	// flipped upside-down.
	float3 toWorldVector = normalize(worldCoordinates);
	float AngleToFront = acos(dot(toWorldVector, camFront));

	if (fmod(abs(AngleToFront), ringRadius - ringWidth) > ringRadius)
		worldCoordinates = stereoRotate(worldCoordinates, camFront, angle);

	return worldCoordinates;
}

float4 stereoSpiral(float4 worldCoordinates, float3 camFront, float intensity)
{
	float3 worldVector = worldCoordinates - _WorldSpaceCameraPos;
	float dist = length(worldVector);
	worldVector = normalize(worldVector);

	float angleToWorldVector = acos(dot(worldVector, camFront));

	worldCoordinates.xyz = mul(rotAxis(camFront, dist*angleToWorldVector*intensity), worldCoordinates.xyz);

	return worldCoordinates;
}

float4 stereoFishEye(float4 worldCoordinates, float3 camFront, float intensity)
{
	float3 worldVector = worldCoordinates - _WorldSpaceCameraPos;
	float dist = length(worldVector);
	worldVector = normalize(worldVector);

	float angleToWorldVector = acos(dot(worldVector, camFront));

	worldCoordinates.xyz += camFront *(abs(angleToWorldVector) / UNITY_PI) * intensity;

	return worldCoordinates;
}

float4 stereoSinWave(float4 worldCoordinates, float3 camRight, float density, float amplitude, float offset)
{
	worldCoordinates.xyz += camRight * sin((worldCoordinates.y + offset) * density) * amplitude;

	return worldCoordinates;
}

float4 stereoTanWave(float4 worldCoordinates, float3 camRight, float density, float amplitude, float offset)
{
	worldCoordinates.xyz += camRight * tan((worldCoordinates.y + offset) * density) * amplitude;

	return worldCoordinates;
}

float4 stereoSlice(float4 worldCoordinates, float3 axis, float angle, float width, float distance, float offset)
{
	
	worldCoordinates.xyz = mul(rotAxis(float3(0, 0, 1), angle), worldCoordinates.xyz);
	worldCoordinates.xyz.x += offset;

	if (abs(worldCoordinates.x) <= width)
		worldCoordinates.xyz += axis*distance;

	worldCoordinates.xyz.x -= offset;
	worldCoordinates.xyz = mul(rotAxis(float3(0, 0, 1), -angle), worldCoordinates.xyz);

	return worldCoordinates;
}

float4 stereoRipple(float4 worldCoordinates, float3 axis, float density, float amplitude, float offset, float falloff)
{
	float dist = length(worldCoordinates.xy);

	// Allows the user to create a water droplet effect by increasing falloff and offset
	// together.
	if (falloff != 0)
		amplitude *= clamp((falloff - dist) / falloff, 0, 1);

	worldCoordinates.xyz += axis * amplitude * sin(dist * density - offset);

	return worldCoordinates;
}

float4 stereoZigZagX(float4 worldCoordinates, float3 camRight, float density, float amplitude, float offset)
{
	float effectVal = (worldCoordinates.y / density + offset);
	effectVal = fmod(abs(effectVal), 2.0);

	if (effectVal > 1)
		effectVal = 2.0 - effectVal;

	worldCoordinates.xyz += camRight * tpdf(effectVal) * amplitude;

	return worldCoordinates;
}

float4 stereoZigZagY(float4 worldCoordinates, float3 camRight, float density, float amplitude, float offset)
{
	float effectVal = (worldCoordinates.x / density + offset);
	effectVal = fmod(abs(effectVal), 2.0);

	if (effectVal > 1)
		effectVal = 2.0 - effectVal;

	worldCoordinates.xyz += camRight * tpdf(effectVal) * amplitude;

	return worldCoordinates;
}

float4 stereoGlitch(float4 worldCoordinates, float3 camFront, float3 camRight, float3 camUp, int glitchCount,
	float maxGlitchWidth, float maxGlitchHeight, float glitchIntensity, float seed,
	float seedInterval)
{
	seed = floor(seed / seedInterval);

	for (int i = 0; i < glitchCount; i++)
	{
		// minX, maxX, minY, maxY
		float4 boundingBox;
		
		boundingBox.y = gold_noise(seed + 2, seed + 3) * 100 - 50;
		boundingBox.x = boundingBox.y - gold_noise(seed, seed + 1) * maxGlitchWidth;
		
		boundingBox.w = gold_noise(seed + 6, seed + 7) * 100 - 50;
		boundingBox.z = boundingBox.w - gold_noise(seed + 4, seed + 5) * maxGlitchHeight;

		if (worldCoordinates.x >= boundingBox.x && worldCoordinates.x <= boundingBox.y
			&& worldCoordinates.y >= boundingBox.z && worldCoordinates.y <= boundingBox.w)
		{
			worldCoordinates.xyz += camFront * (gold_noise(seed + 8, seed + 9) - 0.5) * glitchIntensity;
			worldCoordinates.xyz += camRight * (gold_noise(seed + 10, seed + 11) - 0.5) * glitchIntensity;
			worldCoordinates.xyz += camUp * (gold_noise(seed + 12, seed + 13) - 0.5) * glitchIntensity;
		}

		// Don't share random values between glitch boxes
		seed += 14;
	}

	return worldCoordinates;
}

float4 stereoKaleidoscope(float4 worldCoordinates, float3 camFront, float angle, float segments)
{
	float segmentOffset = clamp(UNITY_PI / segments, 0, UNITY_PI);

	// Store i outside so we can use it later to fold the last
	// partial segment (if any) without executing a conditional
	// every loop.
	int i = 0;
	for (; i < segments; i++)
	{
		worldCoordinates.x = abs(worldCoordinates.x);
		worldCoordinates = stereoRotate(worldCoordinates, camFront, angle);
		worldCoordinates.x = abs(worldCoordinates.x);
		worldCoordinates = stereoRotate(worldCoordinates, camFront, -angle);

		angle += segmentOffset;
	}

	// Fold left-overs to create smooth transitions.
	// Note: This is slightly incorrect for the transitions
	//		 0.99 -> 1.01 and 1.99 -> 2.01
	angle += (segments - i) * segmentOffset;

	worldCoordinates.x = abs(worldCoordinates.x);
	worldCoordinates = stereoRotate(worldCoordinates, camFront, angle);
	worldCoordinates.x = abs(worldCoordinates.x);
	worldCoordinates = stereoRotate(worldCoordinates, camFront, -angle);

	return worldCoordinates;
}

// This effect is pretty performance heavy in VR, so I may need to implement something which creates
// the same effect without requiring calculating 3D voroni noise
float4 stereoVoroniNoise(float4 worldCoordinates, float scale, float offset, float strength, float borderSize)
{
	float3 samplePoint = worldCoordinates.xyz / scale;
	samplePoint.z += offset / 10;

	// voronoiNoise returns float3(minDistToCell, random, minEdgeDistance)
	float3 vNoise = voronoiNoise(samplePoint);

	// Turn what would normally be used for color into a directional vector
	float3 cellVector = normalize(rand1dTo3d(vNoise.y) - 0.5);
	cellVector *= strength;

	// Disable voroni distortion inside the borders
	if (borderSize != 0)
	{
		float valueChange = fwidth(samplePoint.z) * borderSize;
		float halfSize = borderSize / 2;

		float isBorder = 1 - smoothstep(halfSize - valueChange, halfSize + valueChange, vNoise.z);
		cellVector = lerp(cellVector, float3(0, 0, 0), isBorder);
	}

	worldCoordinates.xyz += cellVector;
	return worldCoordinates;
}

  /////////////////////
 // Color functions //
/////////////////////

// I wonder if this naming scheme will trigger any shader 'edgelords'
half4 edgelordStripes(float2 uv, half4 bgColor, float4 stripeColor, float stripeSize, float offset)
{
	float y = uv.y + offset;

	// Should implement SDF anti-aliasing if I add stripe rotation
	if (fmod(y, stripeSize) < stripeSize / 2.f)
		bgColor *= half4(stripeColor.rgb * stripeColor.a, 1.0);

	return bgColor;
}

half4 chromaticAbberation(sampler2D abberationTexture, float4 worldCoordinates, float3 camFront, float strength)
{
	float3 abberationVector = worldCoordinates.xyz - _WorldSpaceCameraPos;
	abberationVector = normalize(abberationVector);

	float angleToWorldVector = acos(dot(abberationVector, camFront));
	angleToWorldVector = abs(angleToWorldVector) / UNITY_PI;
	
	float4 redAbberationPos = worldCoordinates;
	float4 greenAbberationPos = worldCoordinates;
	float4 blueAbberationPos = worldCoordinates;

	// Emulate camera lense distortion by applying different fish-eye lense intensity
	// effects to each channel. Doesn't utilize stereoFishEye to avoid redundant work.
	redAbberationPos.xyz += camFront * (angleToWorldVector * 10.02 * strength);
	greenAbberationPos.xyz += camFront * (angleToWorldVector * 11.52 * strength);
	blueAbberationPos.xyz += camFront * (angleToWorldVector * 13.02 * strength);

	redAbberationPos = computeStereoUV(redAbberationPos);
	greenAbberationPos = computeStereoUV(greenAbberationPos);
	blueAbberationPos = computeStereoUV(blueAbberationPos);

	return half4(tex2Dproj(abberationTexture, redAbberationPos).r, tex2Dproj(abberationTexture, greenAbberationPos).g,
		tex2Dproj(abberationTexture, blueAbberationPos).b, 0);
}


half3 colorShift(sampler2D colorShiftTexture, float3 camFront, float3 camRight, float skewAngle, float skewDistance, float opacity, float4 grabPos)
{
	grabPos = stereoMove(grabPos, camFront, camRight, skewAngle, skewDistance);

	half3 color = tex2Dproj(colorShiftTexture, grabPos).xyz;
	color *= opacity;

	return color;
}

half3 signalNoise(float4 worldPos, float scale, float colorization, float opacity)
{
	// Only seed noise with time to allow for
	// custom noise size via world coordinates
	//
	// Rotate randomly really fast to hide moire artifacts
	// when small noise size (less than 5) is used
	//
	// Values chosen have no mathmatical significance, they're just arbitrary values
	// to attempt to make it difficult to percieve any pattern in the movement
	float3 randomAxis1 = normalize(float3(2 + gold_noise(_Time.z, _Time.y - 1),
		-4 + 3 * gold_noise(_Time.x, _Time.x),
		6 - 5 * gold_noise(_Time.w, _Time.z)));

	// TODO: Verify if high scene times (read: sitting in worlds for 5+ hours)
	//		 results in 'low fps' noise due to floating point inaccuracy
	//
	//		 Though lets be real here...even if this is an issue
	//		 it'll likely be hidden by VRChat running at cinematic
	//		 framerates.
	float3 noisePos = worldPos.xyz;
	noisePos.z += gold_noise(_Time.z, _Time.y) * 10000;
	noisePos = mul(rotAxis(randomAxis1, _Time.y * 1000), noisePos);

	if (colorization != 0)
	{
		half4 noisecolor = half4(
			snoise(noisePos.xyz / scale),
			snoise(noisePos.yzx / scale),
			snoise(noisePos.zxy / scale),
			0);
		noisecolor *= opacity;

		// Scale the HSV value with _ColorizedSignalNoise to allow the user
		// to decide how much color they want in the noise.
		half3 hsvColor = rgb2hsv(noisecolor.xyz);
		hsvColor.y = clamp(colorization, 0, 1);

		return hsv2rgb(hsvColor);
	}
	else
	{
		return snoise(noisePos / scale) * opacity;
	}
}

half3 applyHSV(half4 bgcolor, float hue, float saturation, float value)
{
	half3 hsvColor = rgb2hsv(bgcolor.xyz);
	hsvColor.x += hue;
	hsvColor.y = clamp(hsvColor.y + saturation, 0, 1);

	hsvColor.z = clamp(hsvColor.z + value, 0, 1);

	return hsv2rgb(hsvColor);
}

#endif