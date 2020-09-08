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

// Returns true when the vertex or fragment should not be visible
bool mirrorCheck(float cancerDisplayMode)
{
	// Disable for mirrors so effects like Swirl don't get unwrapped by mirrors.
	// Check shamelessly copy-pasted from CancerSpace, shout outs to AkaiMage.
	// https://github.com/AkaiMage/VRC-Cancerspace
	//
	// Note: Does not contain the additional checks CancerSpace includes,
	//		 such as Per-Eye exclusion, but is otherwise unmodified.
	bool isMirror = unity_CameraProjection[2][0] != 0 || unity_CameraProjection[2][1] != 0;
	
	// cancerDisplayMode == 0: Display on screen only
	// cancerDisplayMode == 1: Display on mirror only
	// cancerDisplayMode >= 2: Display on both mirror and screen.
	return (cancerDisplayMode == 1 && !isMirror) || (cancerDisplayMode == 0 && isMirror);
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
	float offset = separation - 2* step(1, unity_StereoEyeIndex)*separation;
	worldCoordinates.xyz += axisRight * offset;

	return worldCoordinates;
}

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

float4 stereoBar(float4 worldPos, float3 camFront, float3 moveAxis, float flipPoint, float interval, float offset, float distance)
{
	float dir = fmod(abs(flipPoint) + interval / 2 + offset, interval * 2) < interval ? -1 : 1;

	worldPos.xyz += dir * moveAxis * distance;

	return worldPos;
}

float4 stereoSinBar(float4 worldPos, float3 camFront, float3 moveAxis, float flipPoint, float interval, float offset, float distance) 
{
	flipPoint = floor(flipPoint / interval);
	float dir = sin(flipPoint + offset);

	worldPos.xyz += dir * moveAxis * distance;

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

float4 stereoSkew(float4 worldCoordinates, float3 moveAxis, float flipPoint, float interval, float distance, float offset)
{
	float intPosY = floor(abs(flipPoint));
	float skewDir = -1 + 2 * step(1, (intPosY % 2));

	float skewVal = fmod(abs(flipPoint + offset), interval) / interval - 0.5;
	skewVal *= skewDir;

	skewVal *= distance;

	worldCoordinates.xyz += moveAxis * skewVal;

	return worldCoordinates;
}

float4 geometricDither(float4 worldCoordinates, float3 camRight, float3 camUp, float distance, float quality, float randomization)
{
	worldCoordinates *= 10;
	float offset = 0;

	// This could be done every loop, but it doesn't increase
	// quality enough to be worth the performance hit
	UNITY_BRANCH
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
		worldCoordinates = stereoSkew(worldCoordinates, camRight, worldCoordinates.y, ditherInterval, distance, offset);
		worldCoordinates = stereoSkew(worldCoordinates, camUp, worldCoordinates.x, ditherInterval, distance, offset);

		worldCoordinates = stereoSkew(worldCoordinates, camRight, worldCoordinates.y, -ditherInterval, -distance, -offset);
		worldCoordinates = stereoSkew(worldCoordinates, camUp, worldCoordinates.x, -ditherInterval, -distance, -offset);
	}

	return worldCoordinates / 10;
}

float4 stereoCheckerboard(float4 coordinates, float3 axis, float angle, float scale, float shiftDistance)
{
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

float4 stereoRingRotation(float4 worldCoordinates,float3 camFront, float angle, float ringRadius, float ringWidth)
{
	// Not sure of what the best way is to make this intuitive to new users to use.
	// If the user only changes ringWidth and not radius then their screen will be
	// flipped upside-down.
	float3 toWorldVector = normalize(worldCoordinates);
	float AngleToFront = acos(dot(toWorldVector, camFront));

	UNITY_BRANCH
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

float4 stereoSinWave(float4 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	worldCoordinates.xyz += axis * sin((worldCoordinates.y + offset) * density) * amplitude;

	return worldCoordinates;
}

float4 stereoCosWave(float4 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	worldCoordinates.xyz += axis * cos((worldCoordinates.x + offset) * density) * amplitude;

	return worldCoordinates;
}

float4 stereoTanWave(float4 worldCoordinates, float3 axis, float density, float amplitude, float offset)
{
	worldCoordinates.xyz += axis * tan((worldCoordinates.y + offset) * density) * amplitude;

	return worldCoordinates;
}

float4 stereoSlice(float4 worldCoordinates, float3 axis, float angle, float width, float distance, float offset)
{
	worldCoordinates.xyz = mul(rotAxis(float3(0, 0, 1), angle), worldCoordinates.xyz);
	worldCoordinates.xyz.x += offset;

	UNITY_BRANCH
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
	UNITY_BRANCH
	if (falloff != 0)
		amplitude *= clamp((falloff - dist) / falloff, 0, 1);

	worldCoordinates.xyz += axis * amplitude * sin(dist * density - offset);

	return worldCoordinates;
}

float4 stereoZigZag(float4 worldCoordinates, float3 moveAxis, float flipPoint, float density, float amplitude, float offset)
{
	float effectVal = (flipPoint / density + offset);
	effectVal = fmod(abs(effectVal), 2.0);

	UNITY_BRANCH
	if (effectVal > 1)
		effectVal = 2.0 - effectVal;

	worldCoordinates.xyz += moveAxis * tpdf(effectVal) * amplitude;

	return worldCoordinates;
}

float4 stereoBlockDisplacement(float4 worldCoordinates, float blockSize, float intensity, float displacementMode, float seed, inout bool clearPixel)
{
	// HACK: snoise is not continous at exact intervals of 1, so I skip
	//		 over the issue with an imperceptible jump.
	seed = seed == 0 ? 0.001 : seed;

	float seedCheck = fmod(seed, 10);
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

	worldCoordinates.xy += (scale - blockSize / 2)*intensity;

	return worldCoordinates;
}

float4 stereoGlitch(float4 worldCoordinates, float3 camFront, float3 camRight, float3 camUp, int glitchCount,
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

float3 colorVectorDisplacement(sampler2D textureHandle, float4 stereoPosition, float displacementStrength)
{
	float3 colorDirectionVector = tex2Dproj(textureHandle, stereoPosition).rgb;

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
float3 normalVectorDisplacement(sampler2D textureHandle, float4 texelSize, float4 stereoPosition, float4 worldCoordinates, float4 startingWorldPos, float3 cameraPosition, float3 axisRight, float3 axisUp,
	float coordinateSpace, float displacementStrength, float quality)
{
	float3 normal = float3(0, 0, 0);

	UNITY_BRANCH
	// High
	if (quality == 1)
	{
		// Running distortion effects before this runs will shift the world position
		// away from texel centers, resulting in wildly incorrect triangle normals being
		// generated when multiple samples sample the same depth point.
		//
		// Solution: Texel-aligned world positons combined with world position derivatives.
		float4 centerPos = worldCoordinates;
		
		centerPos = mul(UNITY_MATRIX_VP, centerPos);
		centerPos = ComputeGrabScreenPos(centerPos);
	
		centerPos.xy = AlignWithGrabTexel(texelSize, centerPos.xy / centerPos.w);
		centerPos.xy *= centerPos.w;

		centerPos = reverseComputeGrabScreenPos(centerPos);
		centerPos = mul(inverse(UNITY_MATRIX_VP), centerPos);

		// Utilize the world position derivative to calculate nearby positions to sample depth
		float2 worldPosDerivative = float2(-ddx(startingWorldPos.x), ddy(startingWorldPos.y));

		float4 leftPos = float4(centerPos.xyz - axisRight * worldPosDerivative.x, centerPos.w);
		float4 rightPos = float4(centerPos.xyz + axisRight * worldPosDerivative.x, centerPos.w);

		float4 upPos = float4(centerPos.xyz + axisUp * worldPosDerivative.y, centerPos.w);
		float4 downPos = float4(centerPos.xyz - axisUp * worldPosDerivative.y, centerPos.w);

		float centerDepth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, computeStereoUV(centerPos));

		float leftDepth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, computeStereoUV(leftPos));
		float rightDepth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, computeStereoUV(rightPos));

		float upDepth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, computeStereoUV(upPos));
		float downDepth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, computeStereoUV(downPos));

		centerDepth = DECODE_EYEDEPTH(centerDepth);
		leftDepth = DECODE_EYEDEPTH(leftDepth);
		rightDepth = DECODE_EYEDEPTH(rightDepth);
		upDepth = DECODE_EYEDEPTH(upDepth);
		downDepth = DECODE_EYEDEPTH(downDepth);

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
		float depth = SAMPLE_DEPTH_TEXTURE_PROJ(textureHandle, stereoPosition);
		depth = DECODE_EYEDEPTH(depth);

		float3 toWorldPosDir = normalize(worldCoordinates.xyz - cameraPosition);
		float3 depthWorldPos = cameraPosition + toWorldPosDir * depth;

		// View Space
		UNITY_BRANCH
		if (coordinateSpace == 0)
			depthWorldPos = mul(UNITY_MATRIX_V, depthWorldPos);
		
		normal = normalize(cross(ddx(depthWorldPos), ddy(depthWorldPos)));
	}
	
	normal *= displacementStrength;

	return normal;
}

  /////////////////////
 // Color functions //
/////////////////////

half4 stereoImageOverlay(float4 axisCoordinates, float3 cameraPosition, float3 camFront,
	sampler2D memeImage, float4 memeImage_ST, float4 memeImage_TexelSize, 
	float opacity, float clampUV, float cutoutUV, float screenOverrideMode, inout bool dropMemePixels)
{
	// Apply Tiling
	axisCoordinates.xy *= memeImage_ST.xy;

	// Stretch our coordinates to match the aspect ratio of the image
	// being overlayed.
	axisCoordinates.x *= memeImage_TexelSize.w / memeImage_TexelSize.z;

	// Interpret axis-aligned coordinates as UV coordinates
	float2 uv = axisCoordinates.xy / 50.0;

	uv.x = -uv.x;
	uv += 0.5;

	// Apply Offset
	uv += memeImage_ST.zw / 100;

	dropMemePixels = false;
	if (cutoutUV)
	{
		float2 pxCoordinates = uv * memeImage_TexelSize.zw;
		if (pxCoordinates.x > memeImage_TexelSize.z-1 || pxCoordinates.x < 1 || pxCoordinates.y > memeImage_TexelSize.w-1 || pxCoordinates.y < 1)
			dropMemePixels = true;
	}
	if (clampUV)
	{
		uv = clamp(uv, 0, 1);
	}

	return tex2D(memeImage, uv.xy) * opacity;
}

// I wonder if this naming scheme will trigger any shader 'edgelords'
half4 edgelordStripes(float2 uv, half4 bgColor, float4 stripeColor, float stripeSize, float offset)
{
	float y = uv.y + offset;

	// Should implement SDF anti-aliasing if I add stripe rotation
	UNITY_BRANCH
	if (fmod(y, stripeSize) < stripeSize / 2.f)
		bgColor *= half4(stripeColor.rgb * stripeColor.a, 1.0);

	return bgColor;
}

half3 blurMovement(sampler2D backgroundTexture, float4 startingWorldCoordinates, float4 finalWorldCoordinates, int sampleCount, float targetPoint, float opacity)
{
	float3 color = float3(0, 0, 0);

	float3 blurMove = finalWorldCoordinates.xyz - startingWorldCoordinates.xyz;
	float movementDistance = length(blurMove);

	float3 centerPoint = lerp(startingWorldCoordinates.xyz, finalWorldCoordinates.xyz, targetPoint);

	// Convert movement vector to sample step distance.
	blurMove /= sampleCount;

	half3 backgroundColor = tex2Dproj(backgroundTexture, computeStereoUV(finalWorldCoordinates)).rgb;

	UNITY_BRANCH
	// No point sampling up to 42 times if the result is the same as just sampling the screen once.
	if (movementDistance < 0.0000001)
		return backgroundColor;

	// Accumulate attenuation to separate movement distance
	// and sample count from effect brightness.
	float accumulatedAttenuation = 0;

	UNITY_LOOP
	for (int q = 0; q < sampleCount; q++)
	{
		float4 samplePos = startingWorldCoordinates + float4(blurMove, 0)*q;
		float attenuation = 0;
		
		// Todo: Figure out an algorithm to avoid needing to fallback to vector math
		//       for targets closer to the starting position than the halfway point.
		if(targetPoint >= 0.5)
			attenuation = 1.0 - abs(targetPoint - (float)q / sampleCount) / targetPoint;
		else
			attenuation = (1.0 - targetPoint) - clamp(length(samplePos.xyz - centerPoint) / (movementDistance), 0, 1);

		color.rgb += tex2Dproj(backgroundTexture, computeStereoUV(samplePos)).rgb*attenuation;
		accumulatedAttenuation += attenuation;
	}

	return lerp(backgroundColor, (color.rgb) / accumulatedAttenuation, opacity);
}

half4 chromaticAbberation(sampler2D abberationTexture, float4 worldCoordinates, float3 camFront, float strength, float separation, float shape)
{
	float4 redAbberationPos = worldCoordinates;
	float4 greenAbberationPos = worldCoordinates;
	float4 blueAbberationPos = worldCoordinates;

	// Spherical
	if (shape == 0)
	{
		// Emulate camera lense distortion by applying different fish-eye lense intensity
		// effects to each channel. Doesn't utilize stereoFishEye to avoid redundant work.
		float3 abberationVector = worldCoordinates.xyz - _WorldSpaceCameraPos;
		abberationVector = normalize(abberationVector);

		float angleToWorldVector = acos(dot(abberationVector, camFront));
		angleToWorldVector = abs(angleToWorldVector) / UNITY_PI;

		redAbberationPos.xyz += camFront * (angleToWorldVector * 10.0 * strength);
		greenAbberationPos.xyz += camFront * (angleToWorldVector * (10.0 + separation) * strength);
		blueAbberationPos.xyz += camFront * (angleToWorldVector * (10.0 + separation * 2) * strength);
	}
	// Flat
	else
	{
		greenAbberationPos.xyz -= camFront * (separation) * strength;
		blueAbberationPos.xyz += camFront * (separation) * strength;
	}

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

	UNITY_BRANCH
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

half3 applyHSV(half4 bgcolor, float hue, float saturation, float value)
{
	half3 hsvColor = rgb2hsv(bgcolor.xyz);
	hsvColor.x += hue;
	hsvColor.y = clamp(hsvColor.y + saturation, 0, 1);

	hsvColor.z = clamp(hsvColor.z + value, 0, 1);

	return hsv2rgb(hsvColor);
}

// This function isn't very good, but it's good enough for now
// as it does generate a similar effect to what I'm going for.
half3 imaginaryColors(float3 worldVector, float angle)
{
#ifdef UNITY_SINGLE_PASS_STEREO
	// Flip the color wheel for the other eye to generate 'imaginary' colors
	angle += (UNITY_PI/2) * step(1, unity_StereoEyeIndex);
#endif

	worldVector = mul(rotAxis(float3(0, 0, 1), angle), worldVector);

	// Don't worry about it :>)
	worldVector.xyz *= worldVector.zxy;
	worldVector *= 1.0/rcp(worldVector);

	return worldVector.xyz;
}

#endif