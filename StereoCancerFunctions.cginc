// UNITY_SHADER_NO_UPGRADE

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
// LICENSE: This shader is licensed under GPL V3.
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

// For SPS-I macros, such as UNITY_SAMPLE_TEX2DARRAY
#include "HLSLSupport.cginc"

// Returns true when the vertex or fragment should not be visible
bool mirrorCheck(float cancerDisplayMode)
{
	// https://docs.vrchat.com/docs/vrchat-202231
	// 1 is Mirror VR and 2 is Mirror Desktop.
	bool isMirror = _VRChatMirrorMode > 0;

	// cancerDisplayMode == 0: Display on screen only
	// cancerDisplayMode == 1: Display on mirror only
	// cancerDisplayMode >= 2: Display on both mirror and screen.
	return (cancerDisplayMode == 1 && !isMirror) || (cancerDisplayMode == 0 && isMirror);
}

// Expects stereo UV coordinates and depth to have been divided by w
float4 viewPosFromDepth(float4x4 invProj, float2 uv, float depth)
{
#ifdef UNITY_SINGLE_PASS_STEREO
	// Ensure both eye UVs are in the range of 0-1 for reverse projection later
	uv.x *= 2;
	uv.x -= step(1, unity_StereoEyeIndex);
#endif

	// Convert UV to clip space and retrieve the view position using inverse
	// matrix multiplication.
	// https://stackoverflow.com/questions/32227283/getting-world-position-from-depth-buffer-value
	float4 viewPos = mul(invProj, float4(uv.xy*2.0 - 1.0, depth, 1.0));

	return viewPos / viewPos.w;
}

float3 worldPosFromDepth(float4 depthSamplePos, float3 camPos, float4 worldCoordinates)
{
	float sampleDepth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, depthSamplePos);
	sampleDepth = DECODE_EYEDEPTH(sampleDepth);

	// https://gamedev.stackexchange.com/questions/131978/shader-reconstructing-position-from-depth-in-vr-through-projection-matrix
	float3 viewDirection = (worldCoordinates.xyz - camPos) / (-mul(UNITY_MATRIX_V, worldCoordinates).z);

	return camPos + viewDirection * sampleDepth;
}

  //////////////////////////////
 // Virtual Reality Effects ///
//////////////////////////////

float4 stereoEyeConvergence(float4 worldCoordinates, float3 axisUp, float convergence)
{
	float angle = convergence - 2 * step(1, unity_StereoEyeIndex)*convergence;
	worldCoordinates.xyz = mul(rotAxis(axisUp, angle), worldCoordinates.xyz);

	return worldCoordinates;
}

float4 stereoEyeSeparation(float4 worldCoordinates, float3 axisRight, float separation)
{
	float offset = separation - 2 * step(1, unity_StereoEyeIndex)*separation;
	worldCoordinates.xyz += axisRight * offset;

	return worldCoordinates;
}

  ///////////////////////////
 // Distortion functions ///
///////////////////////////

float4 computeWorldPositionFromAxisPosition(float4 worldCoordinates)
{
	// Need to unflip our x coordinate. This is because the normal screen-space
	// coordinate system is backwards compared to world coordinates.
	worldCoordinates.x *= -1;
	return mul(UNITY_MATRIX_I_V, worldCoordinates);
}

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

float4 wrapWorldCoordinates(float4 worldCoordinates, float wrapValue)
{
	wrapValue *= 200;
	float2 signs = sign(worldCoordinates.xy);

	// Adjust wrap value based on the Z coordinate to constrain
	// the pixels within the wrapValue bounds when Z-Axis movement
	// occurs. Ex. Move Z, Ripple, and Simplex/Voroni noise effects.
	wrapValue -= (abs(worldCoordinates.z - 100) / 100)*wrapValue;
	wrapValue = abs(wrapValue);

	// Shift all coordinates past the wrapping point to resolve
	// a discontinuity in the range (wrapValue/2, wrapValue).
	worldCoordinates.xy += signs.xy*wrapValue;

	// Finally wrap coordinates around.
	worldCoordinates.xy = frac(abs(worldCoordinates.xy) / wrapValue / 2)*signs.xy*wrapValue * 2 - signs.xy*wrapValue;

	return worldCoordinates;
}

float4 projectCoordinates(float4 worldCoordinates, float3 camPos, float3 viewVector)
{
	// Convert from world-axis aligned coordinates to world space coordinates.
	worldCoordinates.xyz = computeWorldPositionFromAxisPosition(worldCoordinates);

	// Reconstruct view coordinates from depth
	float4 uv = computeStereoUV(worldCoordinates);
	float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, uv);

	// Use the length of the reconstructed view ray to adjust our position
	// and retain the custom world-axis aligned coordinate system.
	depth = length(viewPosFromDepth(inverse(UNITY_MATRIX_P), uv.xy / uv.w, depth / uv.w));
	worldCoordinates.xyz = viewVector.xyz * depth;

	return worldCoordinates;
}

float4 stereoRotate(float4 worldCoordinates, float3 axis, float angle)
{
	worldCoordinates.xyz = mul(rotAxis(axis, glsl_mod(angle, UNITY_TWO_PI)), worldCoordinates);

	return worldCoordinates;
}

float4 stereoShake(float4 worldPos, float shakeSpeed, float shakeXIntensity, float shakeXAmplitude, float shakeYIntensity, float shakeYAmplitude,
	float shakeZIntensity, float shakeZAmplitude)
{
	float shakeTime = _Time.y * shakeSpeed;
	float3 randomAxis1 = float3(shakeTime,
		shakeTime + 17,
		shakeTime + 29);

	float3 noisePos = float3(
		snoise(randomAxis1.xyz / shakeXAmplitude),
		snoise(randomAxis1.yzx / shakeYAmplitude),
		snoise(randomAxis1.zxy / shakeZAmplitude));

	worldPos.xyz += noisePos * float3(shakeXIntensity, shakeYIntensity, shakeZIntensity);

	return worldPos;
}

float4 stereoSplit(float4 worldPos, float3 axis, float splitPoint, float distance, float oneSide, inout bool clearPixel)
{
	UNITY_BRANCH
	if (oneSide != 0)
	{
		if (sign(distance) == -sign(splitPoint))
		{
			if (abs(splitPoint) < abs(distance))
				clearPixel = true;
			else
				worldPos.xyz += axis * distance * -sign(splitPoint) * sign(distance);
		}
	}
	else
	{
		if (abs(splitPoint) < distance)
			clearPixel = true;
		else
			worldPos.xyz += axis * distance * -sign(splitPoint);
	}

	return worldPos;
}

float3 stereoBar(float3 moveAxis, float flipPoint, float interval, float offset, float distance)
{
	float quantizedPoint = fmod(abs(flipPoint) + interval / 2 + offset, interval * 2);
	float dir = quantizedPoint < interval ? -1 : 1;

	return dir * moveAxis * distance;
}

float3 stereoSinBar(float3 moveAxis, float flipPoint, float interval, float offset, float distance)
{
	// Ensure the effect doesn't disappear for one frame when interpolating the interval parameter
	// across zero.
	interval = abs(interval) > 0.00001 ? interval : 0.00001;

	flipPoint = floor(flipPoint / interval);
	float dir = sin(flipPoint + offset);

	return dir * moveAxis * distance;
}

float stereoMelt(float2 worldPos, float interval, float variance, float seed, float distance, float bothDirections)
{
	float displacement = floor(worldPos.x / interval);
	displacement = rand1dTo1d(displacement + seed);

	displacement -= bothDirections;

	// Sign of 0 is 0, which will lead to bars which don't move and stick out.
	float dir = sign(displacement);
	dir = dir != 0 ? dir : 1;

	displacement = displacement * variance + dir*(1.0 - variance)*0.5;
	
	return displacement * distance;
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

float3 stereoSkew(float2 worldCoordinates, float3 moveAxis, float flipPoint, float interval, float distance, float offset)
{
	// Ensure the effect doesn't disappear for one frame when interpolating the interval parameter
	// across zero.
	interval = abs(interval) > 0.00001 ? interval : 0.00001;

	float intPosY = floor(abs(flipPoint));
	float skewDir = -1 + 2 * step(1, (intPosY % 2));

	float skewVal = glsl_mod(abs(flipPoint + offset), interval) / interval - 0.5;
	skewVal *= skewDir;

	skewVal *= distance;

	return moveAxis * skewVal;
}

float4 fan(float4 worldCoordinates, float3 camRight, float3 camUp, float scale, float distance, float bladeCount, float offset)
{
	worldCoordinates /= scale;
	const float skewInterval = 1;

	UNITY_LOOP
	for (int i = 0; i < bladeCount; i++)
	{
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camRight, worldCoordinates.y, skewInterval, distance, offset);
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camUp, worldCoordinates.x, skewInterval, distance, offset);

		worldCoordinates.xyz += stereoSkew(worldCoordinates, camRight, worldCoordinates.y, -skewInterval, -distance, -offset);
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camUp, worldCoordinates.x, -skewInterval, -distance, -offset);
	}

	return worldCoordinates * scale;
}

float4 geometricDither(float4 worldCoordinates, float3 camRight, float3 camUp, float distance, float quality, float randomization)
{
	worldCoordinates *= 10;
	float offset = 0;

	// This could be done every loop, but it doesn't increase
	// quality enough to be worth the performance hit
	UNITY_BRANCH
	if (randomization != 0)
		offset = gold_noise(glsl_mod(_Time.z, 1), glsl_mod(_Time.y, 1))*randomization;

	// There's probably a way more efficient way to do this,
	// but it's good enough for now and allows for
	// user-configurable performance vs quality trading.
	//
	// (Though users are most likely to just crank quality to the max)
	const float ditherInterval = 1;
	UNITY_LOOP
	for (int i = 0; i < quality; i++)
	{
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camRight, worldCoordinates.y, ditherInterval, distance, offset);
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camUp, worldCoordinates.x, ditherInterval, distance, offset);

		worldCoordinates.xyz += stereoSkew(worldCoordinates, camRight, worldCoordinates.y, ditherInterval, -distance * 4, -offset);
		worldCoordinates.xyz += stereoSkew(worldCoordinates, camUp, worldCoordinates.x, ditherInterval, -distance * 4, -offset);
	}

	return worldCoordinates / 10;
}

float4 stereoCheckerboard(float4 coordinates, float3 axis, float angle, float scale, float shiftDistance)
{
	// Ensure the effect doesn't disappear for one frame when interpolating the scale parameter
	// across zero.
	scale = abs(scale) > 0.00001 ? scale : 0.00001;

	float4 localCoordinates = coordinates;

	UNITY_BRANCH
	if (angle != 0)
		localCoordinates = stereoRotate(localCoordinates, axis, angle);

	float2 intPos = floor(localCoordinates.xy / scale + 0.5);

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

float4 stereoRingRotation(float4 worldCoordinates, float innerAngle, float outerAngle, float ringRadius, float ringWidth)
{
	// Not sure of what the best way is to make this intuitive to new users to use.
	// If the user only changes ringWidth and not radius then their screen will be
	// flipped upside-down.
	float3 toWorldVector = normalize(worldCoordinates);
	float AngleToFront = acos(dot(toWorldVector, float3(0, 0, -1)));

	UNITY_BRANCH
	if (fmod(abs(AngleToFront), ringRadius - ringWidth) > ringRadius)
		worldCoordinates.xy = rotate2D(worldCoordinates.xy, outerAngle);
	else
		worldCoordinates.xy = rotate2D(worldCoordinates.xy, innerAngle);

	return worldCoordinates;
}

float4 stereoSpiral(float4 worldCoordinates, float intensity)
{
	float3 worldVector = worldCoordinates.xyz;
	float dist = length(worldVector);
	worldVector = normalize(worldVector);

	float angleToWorldVector = acos(dot(worldVector, float3(0, 0, -1)));

	worldCoordinates.xy = rotate2D(worldCoordinates.xy, dist*angleToWorldVector*intensity);

	return worldCoordinates;
}

// rotAxis version of spiral for usage in effects such as
// freedom color modifier.
float4 stereoSpiralAxis(float4 worldCoordinates, float3 axis, float intensity)
{
	float3 worldVector = worldCoordinates.xyz;
	float dist = length(worldVector);
	worldVector = normalize(worldVector);

	float angleToWorldVector = acos(dot(worldVector, axis));

	worldCoordinates.xyz = mul(rotAxis(axis, dist*angleToWorldVector*intensity), worldCoordinates.xyz);

	return worldCoordinates;
}

float4 stereoPolarInversion(float4 worldCoordinates, float intensity)
{
	worldCoordinates.xy -= normalize(worldCoordinates.xy)*intensity;

	return worldCoordinates;
}

float3 stereoFishEye(float4 worldCoordinates, float3 camFront, float intensity)
{
	float3 worldVector = normalize(worldCoordinates.xyz);
	float3 angleToWorldVector = acos(dot(worldVector, camFront));

	return camFront * (abs(angleToWorldVector) / UNITY_PI) * intensity;
}

float3 stereoSinWave(float2 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	return axis * sin((worldCoordinates.y + offset) * density) * amplitude;
}

float3 stereoCosWave(float2 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	return axis * cos((worldCoordinates.x + offset) * density) * amplitude;
}

float3 stereoSinCosWave(float2 worldCoordinates, float3 axis, float densitySin, float densityCos, float amplitude, float sinOffset, float cosOffset)
{
	return axis * sin((worldCoordinates.x + sinOffset) * densitySin) * cos((worldCoordinates.y + cosOffset) * densityCos) * amplitude;
}

float3 stereoTanWave(float2 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	return axis * tan((worldCoordinates.y + offset) * density) * amplitude;
}

float4 stereoSlice(float4 worldCoordinates, float3 axis, float angle, float width, float distance, float offset)
{
	worldCoordinates.xy = rotate2D(worldCoordinates.xy, -angle);
	worldCoordinates.x += offset;

	worldCoordinates.xyz += (abs(worldCoordinates.x) <= width) * axis * distance;

	worldCoordinates.x -= offset;
	worldCoordinates.xy = rotate2D(worldCoordinates.xy, angle);

	return worldCoordinates;
}

float4 stereoRipple(float4 worldCoordinates, float3 axis, float density, float amplitude, float offset, float innerFalloff, float outerFalloff)
{
	float dist = length(worldCoordinates.xy);

	// Allows the user to create a water droplet effect by increasing falloff and offset
	// together.
	UNITY_BRANCH
	if (innerFalloff != 0)
		amplitude *= clamp((dist - innerFalloff) / innerFalloff, 0, 1);

	UNITY_BRANCH
	if (outerFalloff != 0)
		amplitude *= clamp((outerFalloff - dist) / outerFalloff, 0, 1);

	worldCoordinates.xyz += axis * amplitude * sin(dist * density - offset);

	return worldCoordinates;
}

float4 stereoZigZag(float4 worldCoordinates, float3 moveAxis, float flipPoint, float density, float amplitude, float offset)
{
	// Well hello there magic constant values. Please feel enjoy.
	float effectVal = frac(flipPoint * density * 0.001 + offset * 0.01);

	float intPos = floor(abs(effectVal) * 10);
	float skewDir = -1 + 2 * step(1, (intPos % 2));

	float skewVal = glsl_mod(abs(effectVal), 0.1) / 0.1 - 0.5;
	skewVal *= skewDir * amplitude;

	worldCoordinates.xyz += moveAxis * skewVal;

	return worldCoordinates;
}

float2 stereoBlockDisplacement(float2 worldCoordinates, float blockSize, float intensity, float displacementMode, float seed, inout bool clearPixel)
{
	// HACK: snoise is not continous at exact intervals of 1, so I skip
	//		 over the issue with an imperceptible jump.
	seed = seed == 0 ? 0.001 : seed;

	float seedCheck = glsl_mod(seed, 10);
	UNITY_BRANCH
	if (seedCheck <= 0.001)
		seed += sign(seed)*0.0001;
	else if (seedCheck >= 9.999)
		seed -= sign(seed)*0.0001;

	// Add 0.5 to make the center of the screen in a block rather than
	// the corner between blocks
	float2 block = floor(worldCoordinates.xy / blockSize + 0.5);
	float2 scale = float2(0, 0);

	UNITY_BRANCH
	if (displacementMode == 0)
		scale = float2(snoise(float3(block, seed / 10)), snoise(float3(block, -seed / 10)))*0.5 + 0.5;
	else
		scale = float2(rand2dTo1d(block + seed), rand2dTo1d(block - seed));

	scale *= blockSize;

	return (scale - blockSize / 2) * intensity;
}

float3 stereoGlitch(float3 worldCoordinates, float3 camFront, float3 camRight, float3 camUp, int glitchCount,
	float minGlitchWidth, float minGlitchHeight, float maxGlitchWidth, float maxGlitchHeight, float glitchIntensity,
	float seed, float seedInterval)
{
	seed = floor(seed / seedInterval);

	float distWidth = maxGlitchWidth - minGlitchWidth;
	float distHeight = maxGlitchHeight - minGlitchHeight;

	float spawnRangeX = 100 + (minGlitchWidth + distWidth / 2);
	float halfSpawnRangeX = spawnRangeX * 0.5;

	float spawnRangeY = 100 + (minGlitchHeight + distHeight / 2);
	float halfSpawnRangeY = spawnRangeY * 0.5;

	float3 startingPos = worldCoordinates;

	UNITY_LOOP
	for (int i = 0; i < glitchCount; i++)
	{
		// minX, maxX, minY, maxY
		float4 boundingBox;

		boundingBox.y = gold_noise(seed + 2, seed + 3) * spawnRangeX - halfSpawnRangeX;
		boundingBox.x = boundingBox.y - (minGlitchWidth + gold_noise(seed, seed + 1) * distWidth);

		boundingBox.w = gold_noise(seed + 6, seed + 7) * spawnRangeY - halfSpawnRangeY;
		boundingBox.z = boundingBox.w - (minGlitchHeight + gold_noise(seed + 4, seed + 5) * distHeight);

		UNITY_BRANCH
		if (worldCoordinates.x >= boundingBox.x && worldCoordinates.x <= boundingBox.y
			&& worldCoordinates.y >= boundingBox.z && worldCoordinates.y <= boundingBox.w)
		{
			worldCoordinates += camFront * (gold_noise(seed + 8, seed + 9) - 0.5) * glitchIntensity;
			worldCoordinates += camRight * (gold_noise(seed + 10, seed + 11) - 0.5) * glitchIntensity;
			worldCoordinates += camUp * (gold_noise(seed + 12, seed + 13) - 0.5) * glitchIntensity;
		}

		// Don't share random values between glitch boxes
		seed += 14;
	}

	return worldCoordinates - startingPos;
}

float4 stereoKaleidoscope(float4 worldCoordinates, float angle, float segments)
{
	float segmentOffset = clamp(UNITY_PI / segments, 0, UNITY_PI);

	// Store i outside so we can use it later to fold the last
	// partial segment (if any) without executing a conditional
	// every loop.
	int i = 0;

	UNITY_LOOP
	for (; i < segments; i++)
	{
		worldCoordinates.x = abs(worldCoordinates.x);
		worldCoordinates.xy = rotate2D(worldCoordinates.xy, angle);
		worldCoordinates.x = abs(worldCoordinates.x);
		worldCoordinates.xy = rotate2D(worldCoordinates.xy, -angle);

		angle += segmentOffset;
	}

	// Fold left-overs to create smooth transitions.
	// Note: This is slightly incorrect for the transitions
	//		 0.99 -> 1.01 and 1.99 -> 2.01
	angle += (segments - i) * segmentOffset;

	worldCoordinates.x = abs(worldCoordinates.x);
	worldCoordinates.xy = rotate2D(worldCoordinates.xy, angle);
	worldCoordinates.x = abs(worldCoordinates.x);
	worldCoordinates.xy = rotate2D(worldCoordinates.xy, -angle);

	return worldCoordinates;
}

// This effect is pretty performance heavy in VR, so I may need to implement something which creates
// the same effect without requiring calculating 3D voroni noise
float4 stereoVoroniNoise(float4 worldCoordinates, float scale, float offset, float strength, float borderSize, float borderMode, float borderStrength, inout bool clearPixel)
{
	float3 samplePoint = worldCoordinates.xyz / scale;
	samplePoint.z += offset / 10;

	// voronoiNoise returns float3(minDistToCell, random, minEdgeDistance)
	float3 vNoise = voronoiNoise(samplePoint);

	// Turn what would normally be used for color into a directional vector
	float3 cellVector = normalize(rand1dTo3d(vNoise.y) - 0.5);

	UNITY_BRANCH
	if (borderSize != 0)
	{
		float valueChange = fwidth(samplePoint.z) * borderSize;
		float halfSize = borderSize / 2;

		float isBorder = 1 - smoothstep(halfSize - valueChange, halfSize + valueChange, vNoise.z);

		// No Effect
		if (borderMode == 0)
		{
			cellVector *= strength;
			cellVector = lerp(cellVector, float3(0, 0, 0), isBorder);
		}
		// Multiply
		else if (borderMode == 1)
		{
			if (isBorder > 0.001)
			{
				isBorder *= borderStrength;
				cellVector = lerp(cellVector, float3(0, 0, 0), isBorder);
			}
			else
			{
				cellVector *= strength;
			}
		}
		// Empty Space
		else
		{
			if (isBorder > 0.5)
				clearPixel = true;

			cellVector *= strength;
		}
	}
	else
	{
		cellVector *= strength;
	}

	worldCoordinates.xyz += cellVector;
	return worldCoordinates;
}

float3 colorVectorDisplacement(float4 stereoPosition, float displacementStrength)
{
	float3 colorDirectionVector = UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, stereoPosition.xy / stereoPosition.w).rgb;

	// Apply reinhard tonemapping so that bright lighting and avatars
	// don't ruin the effect
	colorDirectionVector /= (colorDirectionVector + 1);

	// Turn screen color into a directional vector
	colorDirectionVector -= 0.5;

	return colorDirectionVector * displacementStrength;
}

// A world-space implementation of the solutions described from the following link
// for computing normal vectors in screen-space using depth:
// https://wickedengine.net/2019/09/22/improved-normal-reconstruction-from-depth/
//
// This is a workaround for not having _CameraDepthNormalsTexture in forward rendering.
float3 normalVectorDisplacement(float4 stereoPosition, float4 worldCoordinates, float3 cameraPosition, float3 axisRight, float3 axisUp,
	float coordinateSpace, float quality)
{
	float3 normal = float3(0, 0, 0);

	UNITY_BRANCH
	// High
	if (quality == 1)
	{
		// Running distortion effects before this runs will shift the world position
		// away from texel centers, resulting in wildly incorrect triangle normals being
		// generated when multiple samples sample the same depth point.
		float4 centerPos = stereoPosition;

		centerPos.xy = AlignWithGrabTexel(_CameraDepthTexture_TexelSize, centerPos.xy / centerPos.w);

		float4 leftPos = centerPos;
		float4 rightPos = centerPos;
		float4 upPos = centerPos;
		float4 downPos = centerPos;

		leftPos.xy = centerPos.xy + float2(-1, 0) * _CameraDepthTexture_TexelSize.xy;
		rightPos.xy = centerPos.xy + float2(1, 0) * _CameraDepthTexture_TexelSize.xy;
		upPos.xy = centerPos.xy + float2(0, 1) * _CameraDepthTexture_TexelSize.xy;
		downPos.xy = centerPos.xy + float2(0, -1) * _CameraDepthTexture_TexelSize.xy;

		// Store our aligned UVs so we don't have to recalculate them.
		float4 centerUV = centerPos;
		float4 leftUV = leftPos;
		float4 rightUV = rightPos;
		float4 upUV = upPos;
		float4 downUV = downPos;

		// Calculate all of the world positions for aligned UVs
		// for usage in calculating normals later.
		centerPos.xy *= centerPos.w;
		leftPos.xy *= centerPos.w;
		rightPos.xy *= centerPos.w;
		upPos.xy *= centerPos.w;
		downPos.xy *= centerPos.w;

		centerPos = reverseComputeGrabScreenPos(centerPos);
		leftPos = reverseComputeGrabScreenPos(leftPos);
		rightPos = reverseComputeGrabScreenPos(rightPos);
		upPos = reverseComputeGrabScreenPos(upPos);
		downPos = reverseComputeGrabScreenPos(downPos);

		float4x4 invVP = inverse(UNITY_MATRIX_VP);

		centerPos = mul(invVP, centerPos);
		leftPos = mul(invVP, leftPos);
		rightPos = mul(invVP, rightPos);
		upPos = mul(invVP, upPos);
		downPos = mul(invVP, downPos);

		// Calculate a perspective-correct depth for all 5 samples
		float centerDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, centerUV);
		float leftDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, leftUV);
		float rightDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, rightUV);
		float upDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, upUV);
		float downDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, downUV);

		float4x4 invProj = inverse(UNITY_MATRIX_P);

		centerDepth = length(viewPosFromDepth(invProj, centerUV.xy, centerDepth / centerUV.w));
		leftDepth = length(viewPosFromDepth(invProj, leftUV.xy, leftDepth / centerUV.w));
		rightDepth = length(viewPosFromDepth(invProj, rightUV.xy, rightDepth / centerUV.w));
		upDepth = length(viewPosFromDepth(invProj, upUV.xy, upDepth / centerUV.w));
		downDepth = length(viewPosFromDepth(invProj, downUV.xy, downDepth / centerUV.w));

		// Solve for the triangle which is the best fit
		bool reverseOrder = false;

		float3 toWorldPosDir = normalize(centerPos.xyz - cameraPosition);
		float3 toPos1 = normalize(leftPos.xyz - cameraPosition);
		float3 toPos2 = normalize(upPos.xyz - cameraPosition);

		float3 p0 = cameraPosition + toWorldPosDir * centerDepth;
		float3 p1 = cameraPosition + toPos1 * leftDepth;
		float3 p2 = cameraPosition + toPos2 * upDepth;

		if (abs(rightDepth - centerDepth) < abs(leftDepth - centerDepth))
		{
			toPos1 = normalize(rightPos.xyz - cameraPosition);
			p1 = cameraPosition + toPos1 * rightDepth;

			reverseOrder = true;
		}

		if (abs(downDepth - centerDepth) < abs(upDepth - centerDepth))
		{
			toPos2 = normalize(downPos.xyz - cameraPosition);
			p2 = cameraPosition + toPos2 * downDepth;

			// When we have flipped only the up vertex we need reverse order
			// and when we half flipped both left and up vertices we need normal order
			reverseOrder = !reverseOrder;
		}

		// Need to correct the triangle vertex order if we have swapped
		// the positions of the vertices
		if (reverseOrder)
		{
			float3 tmp = p1;
			p1 = p2;
			p2 = tmp;
		}

		// View Space
		UNITY_BRANCH
		if (coordinateSpace == 0)
		{
			p0 = mul(UNITY_MATRIX_V, p0);
			p1 = mul(UNITY_MATRIX_V, p1);
			p2 = mul(UNITY_MATRIX_V, p2);
		}

		normal = normalize(cross(p2 - p0, p1 - p0));
	}
	// Low
	else
	{
		float depth = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, stereoPosition);
		depth = length(viewPosFromDepth(inverse(UNITY_MATRIX_P), stereoPosition.xy / stereoPosition.w, depth / stereoPosition.w));

		float3 toWorldPosDir = normalize(worldCoordinates.xyz - cameraPosition);
		float3 depthWorldPos = cameraPosition + toWorldPosDir * depth;

		// View Space
		UNITY_BRANCH
		if (coordinateSpace == 0)
			depthWorldPos = mul(UNITY_MATRIX_V, depthWorldPos);

		normal = normalize(cross(ddx(depthWorldPos), ddy(depthWorldPos)));
	}

	return normal;
}

  /////////////////////
 // Color functions //
/////////////////////

float2 calculateUVFromAxisCoordinates(float4 axisCoordinates, float4 texture_ST, float4 texture_TexelSize)
{
	// Apply Tiling
	axisCoordinates.xy *= texture_ST.xy;

	// Stretch our coordinates to match the aspect ratio of the image
	// being overlayed.
	axisCoordinates.x *= texture_TexelSize.w / texture_TexelSize.z;

	// Interpret axis-aligned coordinates as UV coordinates
	float2 uv = axisCoordinates.xy / 50.0;

	uv.x = -uv.x;
	uv += 0.5;

	// Apply Offset
	uv += texture_ST.zw / 100;

	return uv;
}

float4 stereoImageOverlay(float4 axisCoordinates, float4 startingAxisAlignedPos,
	sampler2D memeImage, float4 memeImage_ST, float4 memeImage_TexelSize,
	int memeColumns, int memeRows, int memeCount, int memeIndex,
	float clampUV, float cutoutUV, inout bool dropMemePixels)
{
	float2 uv = calculateUVFromAxisCoordinates(axisCoordinates, memeImage_ST, memeImage_TexelSize);
	float2 startingUV = calculateUVFromAxisCoordinates(startingAxisAlignedPos, memeImage_ST, memeImage_TexelSize);
	float2 imageSizeScaler = rcp(float2(memeColumns, memeRows));

	dropMemePixels = false;
	if (cutoutUV)
	{
		// Adjust texture size to match the final image size when texture atlases are in use.
		memeImage_TexelSize.zw *= imageSizeScaler;

		float2 pxCoordinates = uv * memeImage_TexelSize.zw;
		if (pxCoordinates.x > memeImage_TexelSize.z - 1 || pxCoordinates.x < 0 || pxCoordinates.y > memeImage_TexelSize.w - 1 || pxCoordinates.y < 0)
			dropMemePixels = true;
	}
	if (clampUV)
	{
		uv = clamp(uv, 0, 1);
	}

	float2 ddScaler = float2(1.0, 1.0);

	// Flipbook
	if (memeColumns > 1 || memeRows > 1)
	{
		memeIndex = memeIndex % memeCount;

		float2 imageStartingOffset = float2(memeIndex % memeColumns, 0);
		imageStartingOffset.y = (memeRows - 1) - (memeIndex - (memeIndex % memeColumns)) / memeColumns;

		uv = imageStartingOffset * imageSizeScaler + imageSizeScaler * uv;
		ddScaler *= imageSizeScaler;
	}

	// Utilize ddx and ddy from the starting axis aligned coordiantes to resolve sampling artifacts when the texture wraps around.
	return tex2D(memeImage, uv.xy, ddx(startingUV.x)*ddScaler.x, ddy(startingUV.y)*ddScaler.y);
}

half3 fog(float3 bgcolor, float3 worldPosition, float fogMode, float4 fogColor, float fogBegin, float fogEnd)
{
	float fogDistance = length(worldPosition.xyz);

	fogDistance = clamp(fogDistance - fogBegin, 0, 3.402823466e+38);
	float fogRange = (fogEnd - fogBegin);
	float fogAlpha = fogDistance / fogRange;

	// Linear
	if (fogMode == 1)
		bgcolor.rgb = lerp(bgcolor.rgb, bgcolor.rgb*fogColor, clamp(fogAlpha, 0, 1));
	// Squared
	else if (fogMode == 2)
		bgcolor.rgb = lerp(bgcolor.rgb, bgcolor.rgb*fogColor, clamp(fogAlpha*(fogAlpha + 1), 0, 1));
	// Log2
	else if (fogMode == 3)
		bgcolor.rgb = lerp(bgcolor.rgb, bgcolor.rgb*fogColor, clamp(log2(1 + fogAlpha), 0, 1));
	// Exponential
	else
		bgcolor.rgb = lerp(bgcolor.rgb, bgcolor.rgb*fogColor, clamp(1.0 - exp(-fogAlpha), 0, 1));

	return bgcolor;
}

// I wonder if this naming scheme will trigger any shader 'edgelords'
half4 edgelordStripes(float2 uv, half4 bgColor, float4 stripeColor, float stripeSize, float offset)
{
	float y = (uv.y + offset) * rcp(stripeSize);
	y = abs(0.5 - frac(y));

	y = -10 + 10 * (y / 0.125 - 0.875);
	y = clamp(y, 0, 1);

	return lerp(bgColor, half4(stripeColor.rgb, 1.0), y*stripeColor.a);
}

half3 blurMovement(float4 startingWorldCoordinates, float4 finalWorldCoordinates, int sampleCount,
	float targetPoint, float pointAdjustmentStrength, float extrapolation, float blur, float opacity)
{
	float3 color = float3(0, 0, 0);

	float startingAdjustment = clamp(targetPoint - pointAdjustmentStrength, -extrapolation, 1.0 + extrapolation);
	float endingAdjustment = clamp(targetPoint + pointAdjustmentStrength, -extrapolation, 1.0 + extrapolation);

	float4 startingPoint = lerp(startingWorldCoordinates, finalWorldCoordinates, startingAdjustment);
	float4 endingPoint = lerp(startingWorldCoordinates, finalWorldCoordinates, endingAdjustment);

	float3 targetPosition = lerp(startingPoint.xyz, endingPoint.xyz, targetPoint);

	float3 blurMovementVec = endingPoint.xyz - startingPoint.xyz;
	float totalMovementDistance = length(blurMovementVec);

	// Convert movement vector to sample step distance.
	blurMovementVec /= sampleCount;

	float4 finalStereoUV = computeStereoUV(finalWorldCoordinates);
	half3 backgroundColor = UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, finalStereoUV.xy / finalStereoUV.w).rgb;

	UNITY_BRANCH
	// No point sampling up to 42 times if the result is the same as just sampling the screen once.
	if (totalMovementDistance < 0.000001)
		return backgroundColor;

	// Accumulate attenuation to separate movement distance
	// and sample count from effect brightness.
	float accumulatedAttenuation = 0;

	UNITY_LOOP
	for (int q = 0; q < sampleCount; q++)
	{
		float4 samplePos = float4(startingPoint.xyz + blurMovementVec * q, startingPoint.w);
		float attenuation = 1.0 - (blur * distance(targetPosition.xyz, samplePos.xyz)) / totalMovementDistance;

		samplePos = computeStereoUV(samplePos);
		color.rgb += UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, samplePos.xy / samplePos.w).rgb*attenuation;
		accumulatedAttenuation += attenuation;
	}

	return lerp(backgroundColor, (color.rgb) / accumulatedAttenuation, opacity);
}

half4 chromaticAberration(float4 worldCoordinates, float3 camFront, float strength, float separation, float shape)
{
	// Adjust for world scale coordinates being backwards when moving stereo coordinates.
	camFront *= -1;

	float4 redAberrationPos = worldCoordinates;
	float4 greenAberrationPos = worldCoordinates;
	float4 blueAberrationPos = worldCoordinates;

	// Spherical
	if (shape == 0)
	{
		// Emulate camera lense distortion by applying different fish-eye lense intensity
		// effects to each channel. Doesn't utilize stereoFishEye to avoid redundant work.
		float3 abberationVector = worldCoordinates.xyz;
		abberationVector = normalize(abberationVector);

		float angleToWorldVector = acos(dot(abberationVector, camFront));
		angleToWorldVector = abs(angleToWorldVector) / UNITY_PI;

		redAberrationPos.xyz += camFront * (angleToWorldVector * 10.0 * strength);
		greenAberrationPos.xyz += camFront * (angleToWorldVector * (10.0 + separation) * strength);
		blueAberrationPos.xyz += camFront * (angleToWorldVector * (10.0 + separation * 2) * strength);
	}
	// Flat
	else
	{
		greenAberrationPos.xyz += camFront * (separation)* strength;
		blueAberrationPos.xyz += camFront * (separation * 2) * strength;
	}
		
	redAberrationPos = computeStereoUV(redAberrationPos);
	greenAberrationPos = computeStereoUV(greenAberrationPos);
	blueAberrationPos = computeStereoUV(blueAberrationPos);

	return half4(UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, redAberrationPos.xy / redAberrationPos.w).r,
		UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, greenAberrationPos.xy / greenAberrationPos.w).g,
		UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, blueAberrationPos.xy / blueAberrationPos.w).b, 0);
}

half3 rgbColorDesync(float4 startingWorldPos, float4 finishedWorldPos, float redDsync, float greenDsync, float blueDsync)
{
	float3x4 colorPositions =
	{
		lerp(finishedWorldPos, startingWorldPos, redDsync),
		lerp(finishedWorldPos, startingWorldPos, greenDsync),
		lerp(finishedWorldPos, startingWorldPos, blueDsync)
	};

	colorPositions[0] = computeStereoUV(colorPositions[0]);
	colorPositions[1] = computeStereoUV(colorPositions[1]);
	colorPositions[2] = computeStereoUV(colorPositions[2]);

	colorPositions /= colorPositions[0].w;

	return half3
	(
		UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, colorPositions[0]).r,
		UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, colorPositions[1]).g,
		UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, colorPositions[2]).b
	);
}

half3 stereoTriplanarMappping(sampler2D triplanarMap, float4 triplanarMap_ST, float4 depthSamplePos, float3 camPos, float3 normal, float4 worldCoordinates, float4 axisAlignedPos,
	float offsetX, float offsetY, float offsetZ, float coordinateSource, float scale, float sharpness, float uvRange, bool sampleScreen)
{
	float3 samplePosition = worldPosFromDepth(depthSamplePos, camPos, worldCoordinates);

	// World Normal or View Normal
	if (coordinateSource != 0)
		samplePosition.xyz = mul(rotAxis(normal, UNITY_HALF_PI), samplePosition.xyz);

	samplePosition.xyz += float3(offsetX, offsetY, offsetZ);
	samplePosition /= scale;

	// Weighting function from https://www.martinpalko.com/triplanar-mapping/
	float3 blendWeights = pow(abs(normal), sharpness);
	blendWeights = normalize(blendWeights);

	// Center the UV coordinates based on the range requested
	float offset = (1.0 - uvRange) * 0.5;
	float2 uvOffset = float2(offset, offset);
	float2 uvRangeMultiplier = float2(uvRange, uvRange);

#ifdef UNITY_SINGLE_PASS_STEREO
	// Squish and center the UVs in the left eye
	if (sampleScreen)
	{
		uvRangeMultiplier.x *= 0.5;
		uvOffset.x *= 0.5;
	}
#endif

	// Note: Tiling and offset break hiding the VR Mask, but I see no reason
	//		 to limit the user's 'artistic' design choices.

	// Apply tiling
	uvRangeMultiplier *= triplanarMap_ST.xy;

	// Apply offset
	uvOffset += triplanarMap_ST.zw;

	// Use our (World Position or Normal) coordinates as UV coordinates, and swizzle them in an
	// order which keeps the texture oriented right-side up on vertical walls.

	half3 colorX, colorY, colorZ;
	samplePosition.xyz = frac(samplePosition.xyz);

	if (sampleScreen)
	{
#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
		// SPS-I uses a Texture2D array to store the eye textures, so we need to steal the left eye texture from the array instead of simply sampling the left half of the screen texture
		colorX = UNITY_SAMPLE_TEX2DARRAY(SCREEN_SPACE_TEXTURE_NAME, float3(samplePosition.zy * uvRangeMultiplier + uvOffset, 0.0));
		colorY = UNITY_SAMPLE_TEX2DARRAY(SCREEN_SPACE_TEXTURE_NAME, float3(samplePosition.xz * uvRangeMultiplier + uvOffset, 0.0));
		colorZ = UNITY_SAMPLE_TEX2DARRAY(SCREEN_SPACE_TEXTURE_NAME, float3(samplePosition.xy * uvRangeMultiplier + uvOffset, 0.0));
#else
		colorX = tex2D(SCREEN_SPACE_TEXTURE_NAME, samplePosition.zy * uvRangeMultiplier + uvOffset);
		colorY = tex2D(SCREEN_SPACE_TEXTURE_NAME, samplePosition.xz * uvRangeMultiplier + uvOffset);
		colorZ = tex2D(SCREEN_SPACE_TEXTURE_NAME, samplePosition.xy * uvRangeMultiplier + uvOffset);
#endif
	}
	else
	{
		// ddx and ddy are used to resolve mipmap sampling artifacts when the texture wraps around.
		colorX = tex2D(triplanarMap, samplePosition.zy * uvRangeMultiplier + uvOffset, ddx(samplePosition.z), ddy(samplePosition.y));
		colorY = tex2D(triplanarMap, samplePosition.xz * uvRangeMultiplier + uvOffset, ddx(samplePosition.x), ddy(samplePosition.z));
		colorZ = tex2D(triplanarMap, samplePosition.xy * uvRangeMultiplier + uvOffset, ddx(samplePosition.x), ddy(samplePosition.y));
	}

	return colorX * blendWeights.x + colorY * blendWeights.y + colorZ * blendWeights.z;
}


half3 colorShift(float skewAngle, float skewDistance, float opacity, float4 grabPos)
{
	grabPos.xy += rotate2D(float2(-1, 0), -skewAngle) * skewDistance;

	half3 color = UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, grabPos.xy / grabPos.w).xyz;
	color *= opacity;

	return color;
}

half3 signalNoise(float4 worldPos, float scale, float colorization, float opacity)
{
	// Only seed noise with time to allow for
	// custom noise size via world coordinates
	float time = frac(_Time.x);
	float3 randomOffset = float3(gold_noise(time, time + 1),
		 gold_noise(time + 2, time + 3),
		gold_noise(time + 4, time + 5)) - 0.5;

	float3 noisePos = worldPos.xyz + randomOffset * (10000 * scale);
	noisePos = mul(rotAxis(float3(0.70710678, 0.70710678, 0), UNITY_PI/4), noisePos);

	noisePos /= scale;

	int channelCount = colorization != 0 ? 3 : 1;
	float noiseArray[3];

	UNITY_LOOP
	for (int i = 0; i < channelCount; i++)
	{
		noiseArray[i] = snoise(noisePos.xyz);
		noisePos.xyz = noisePos.yzx;
	}

	half3 noiseColor = half3(noiseArray);
	noiseColor *= opacity;

	return lerp(noiseColor.xxx, noiseColor.xyz, colorization);
}

half3 circularVignette(half4 bgcolor, float4 worldPos, float4 color, float opacity, float roundness, float fallOffMode, float begin, float end)
{
	worldPos.y /= roundness;
	float vignetteDist = length(worldPos.xy);

	float falloffDist = end - begin;
	vignetteDist = (vignetteDist - begin) / falloffDist;

	float vignetteFallOffAlpha = clamp(1.0 - vignetteDist, 0, 1);

	// Linear by default
	// Squared
	UNITY_BRANCH
	if (fallOffMode == 1)
		vignetteFallOffAlpha *= vignetteFallOffAlpha;
	// Log2
	else
		vignetteFallOffAlpha = log2(1 + vignetteFallOffAlpha);

	bgcolor.rgb = lerp(bgcolor.rgb*(1 - opacity), bgcolor.rgb, vignetteFallOffAlpha);
	bgcolor.rgb += color * (opacity * (1 - vignetteFallOffAlpha));

	return bgcolor.rgb;
}

half3 colorModifier(half3 bgcolor, float mode, float strength, float blend)
{
	float3 modifiedColor = float3(0, 0, 0);

	// RCP
	if (mode == 1)
		modifiedColor = lerp(bgcolor.rgb, bgcolor.rgb - bgcolor.rgb / rcp(bgcolor.rgb), strength);
	// Square
	else if (mode == 2)
		modifiedColor = pow(bgcolor.rgb, 2 * strength);
	// Freedom :)
	else if (mode == 3)
		modifiedColor = stereoSpiralAxis(float4(bgcolor.rgb, 1), normalize(float3(67, -71, 73)), strength);
	// Acid AKA (Polar Inversion) X (Tan)
	else if (mode == 4)
	{
		modifiedColor = tan(bgcolor.rgb - normalize(bgcolor.rgb)*strength);
		modifiedColor *= length(bgcolor.rgb) / length(modifiedColor);
	}
	// Quantization
	else
	{
		modifiedColor.rgb = bgcolor.rgb;

		float quantization = length(modifiedColor.rgb) * (1.0 - strength * 0.01);
		modifiedColor.rgb = lerp(bgcolor.rgb, floor(modifiedColor.rgb * quantization) / quantization, strength * 0.1);
	}

	return lerp(bgcolor.rgb, modifiedColor, blend);
}

half3 applyHSV(half4 bgcolor, float hue, float saturation, float value, float _ClampSaturation)
{
	half3 hsvColor = rgb2hsv(bgcolor.xyz);

	hsvColor.xyz += float3(hue, saturation, value);
	if (_ClampSaturation != 0)
		hsvColor.y = clamp(hsvColor.y, 0, 1);

	return hsv2rgb(hsvColor);
}

// This function isn't very good, but it's good enough for now
// as it does generate a similar effect to what I'm going for.
half3 imaginaryColors(float3 worldVector, float angle)
{
#ifdef UNITY_SINGLE_PASS_STEREO
	// Flip the color wheel for the other eye to generate 'imaginary' colors
	angle += (UNITY_HALF_PI)* step(1, unity_StereoEyeIndex);
#endif

	worldVector.xy = rotate2D(worldVector.xy, -angle);

	// Don't worry about it :>)
	worldVector.xyz *= worldVector.zxy;
	worldVector *= 1.0 / rcp(worldVector);

	return worldVector.xyz;
}

float3 sampleSobel(float3 camRight, float3 camUp, float4 worldCoordinates, float searchDistance)
{
	static const float3x3 sobelXWeight = {
		1, 0, -1,
		2, 0, -2,
		1, 0, -1
	};
	static const float3x3 sobelYWeight = {
		1, 2, 1,
		0, 0, 0,
		-1, -2, -1
	};

	float3 Gx = float3(0, 0, 0);
	float3 Gy = float3(0, 0, 0);

	UNITY_LOOP
	for (int x = 0; x < 3; x++)
		UNITY_LOOP
		for (int y = 0; y < 3; y++)
		{
			// Skip center sample since the weight is 0 for both kernels
			UNITY_BRANCH
			if (!(x == 1 && y == 1))
			{
				float2 sampleOffset = float2(x - 1, y - 1) * searchDistance;
				float4 samplePos = worldCoordinates;
				samplePos.xyz += sampleOffset.x * camRight + sampleOffset.y * camUp;
				
				float4 stereoUV = computeStereoUV(samplePos);
				float3 cancerColor = UNITY_SAMPLE_SCREENSPACE_TEXTURE(SCREEN_SPACE_TEXTURE_NAME, stereoUV.xy / stereoUV.w);

				Gx += sobelXWeight[x][y] * cancerColor;
				Gy += sobelYWeight[x][y] * cancerColor;
			}
		}

	return -sqrt(Gx*Gx + Gy * Gy);
}

float sobelFilter(float3 camRight, float3 camUp, float4 worldCoordinates, float searchDistance, float quality)
{
	float3 sobelMag = sampleSobel(camRight, camUp, worldCoordinates, searchDistance);

	// High quality, sample the surrounding pixels to smooth out the outlines
	if (quality != 0)
	{
		float4x3 sobelMagMat;
		float subSampleOffset = searchDistance / 2;

		float4x4 samplePositions = {
			float4(worldCoordinates + float4((-camRight - camUp) * subSampleOffset, 0)),
			float4(worldCoordinates + float4((camRight - camUp) * subSampleOffset, 0)),
			float4(worldCoordinates + float4((camRight + camUp) * subSampleOffset, 0)),
			float4(worldCoordinates + float4((-camRight + camUp) * subSampleOffset, 0))
		};

		UNITY_LOOP
		for (int i = 0; i < 4; i++)
		{
			float3 result = sampleSobel(camRight, camUp, samplePositions[i], subSampleOffset);

			// Hack to force the shader compiler to let me loop this constant-length loop.
			switch (i)
			{
			case 0:
				sobelMagMat[0] = result;
				break;
			case 1:
				sobelMagMat[1] = result;
				break;
			case 2:
				sobelMagMat[2] = result;
				break;
			case 3:
				sobelMagMat[3] = result;
				break;
			}
		}

		sobelMag = (sobelMag + (sobelMagMat[0] + sobelMagMat[1] + sobelMagMat[2] + sobelMagMat[3]) / 4) / 2;
	}

	return -max(sobelMag.r, max(sobelMag.g, sobelMag.b));
}

half3 palletization(float3 worldPosition, half4 bgcolor, bool colorSource, float paletteScale, float paletteOffset, float4 a, float4 b, float4 c, float4 d)
{
	worldPosition *= paletteScale;

	// Screen color control
	if (colorSource == 0)
		bgcolor.rgb *= paletteColor(length(paletteOffset + sin(worldPosition)), bgcolor.brg*bgcolor.brg, bgcolor.brg*bgcolor.brg, bgcolor.brg, bgcolor.rgb);
	else
		bgcolor.rgb *= paletteColor(length(paletteOffset + sin(worldPosition.xyz)), a.rgb, b.rgb, c.rgb, d.rgb);

	return bgcolor;
}

#endif