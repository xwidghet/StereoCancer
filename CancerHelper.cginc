#ifndef CANCER_HELPERS_CGINC
#define CANCER_HELPERS_CGINC

// Hail bgolus
// https://forum.unity.com/threads/translating-a-glsl-shader-noise-algorithm-to-hlsl-cg.485750/
#define glsl_mod(x, y) (x - y * floor(x / y))

// iq is the man!
// https://iquilezles.org/www/articles/palettes/palettes.htm
// cosine based palette, 4 vec3 params
float3 paletteColor(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
{
	return a + b * cos(UNITY_TWO_PI*(c*t + d));
}

// http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
// Comment by user 'blarg'
float3x3 rotAxis(float3 axis, float a) 
{
		float s = sin(a);
		float c = cos(a);
		float oc = 1.0 - c;
		float3 as = axis * s;
		float3x3 p = float3x3(axis.x*axis, axis.y*axis, axis.z*axis);
		float3x3 q = float3x3(c, -as.z, as.y, as.z, c, -as.x, -as.y, as.x, c);
		return p * oc + q;
}

// begin https://gist.github.com/mattatz/86fff4b32d198d0928d0fa4ff32cf6fa

// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/
float4x4 axis_matrix(float3 right, float3 up, float3 forward)
{
	float3 xaxis = right;
	float3 yaxis = up;
	float3 zaxis = forward;
	return float4x4(
		xaxis.x, yaxis.x, zaxis.x, 0,
		xaxis.y, yaxis.y, zaxis.y, 0,
		xaxis.z, yaxis.z, zaxis.z, 0,
		0, 0, 0, 1
		);
}

float4x4 inverse(float4x4 m) {
	float n11 = m[0][0], n12 = m[1][0], n13 = m[2][0], n14 = m[3][0];
	float n21 = m[0][1], n22 = m[1][1], n23 = m[2][1], n24 = m[3][1];
	float n31 = m[0][2], n32 = m[1][2], n33 = m[2][2], n34 = m[3][2];
	float n41 = m[0][3], n42 = m[1][3], n43 = m[2][3], n44 = m[3][3];

	float t11 = n23 * n34 * n42 - n24 * n33 * n42 + n24 * n32 * n43 - n22 * n34 * n43 - n23 * n32 * n44 + n22 * n33 * n44;
	float t12 = n14 * n33 * n42 - n13 * n34 * n42 - n14 * n32 * n43 + n12 * n34 * n43 + n13 * n32 * n44 - n12 * n33 * n44;
	float t13 = n13 * n24 * n42 - n14 * n23 * n42 + n14 * n22 * n43 - n12 * n24 * n43 - n13 * n22 * n44 + n12 * n23 * n44;
	float t14 = n14 * n23 * n32 - n13 * n24 * n32 - n14 * n22 * n33 + n12 * n24 * n33 + n13 * n22 * n34 - n12 * n23 * n34;

	float det = n11 * t11 + n21 * t12 + n31 * t13 + n41 * t14;
	float idet = 1.0f / det;

	float4x4 ret;

	ret[0][0] = t11 * idet;
	ret[0][1] = (n24 * n33 * n41 - n23 * n34 * n41 - n24 * n31 * n43 + n21 * n34 * n43 + n23 * n31 * n44 - n21 * n33 * n44) * idet;
	ret[0][2] = (n22 * n34 * n41 - n24 * n32 * n41 + n24 * n31 * n42 - n21 * n34 * n42 - n22 * n31 * n44 + n21 * n32 * n44) * idet;
	ret[0][3] = (n23 * n32 * n41 - n22 * n33 * n41 - n23 * n31 * n42 + n21 * n33 * n42 + n22 * n31 * n43 - n21 * n32 * n43) * idet;

	ret[1][0] = t12 * idet;
	ret[1][1] = (n13 * n34 * n41 - n14 * n33 * n41 + n14 * n31 * n43 - n11 * n34 * n43 - n13 * n31 * n44 + n11 * n33 * n44) * idet;
	ret[1][2] = (n14 * n32 * n41 - n12 * n34 * n41 - n14 * n31 * n42 + n11 * n34 * n42 + n12 * n31 * n44 - n11 * n32 * n44) * idet;
	ret[1][3] = (n12 * n33 * n41 - n13 * n32 * n41 + n13 * n31 * n42 - n11 * n33 * n42 - n12 * n31 * n43 + n11 * n32 * n43) * idet;

	ret[2][0] = t13 * idet;
	ret[2][1] = (n14 * n23 * n41 - n13 * n24 * n41 - n14 * n21 * n43 + n11 * n24 * n43 + n13 * n21 * n44 - n11 * n23 * n44) * idet;
	ret[2][2] = (n12 * n24 * n41 - n14 * n22 * n41 + n14 * n21 * n42 - n11 * n24 * n42 - n12 * n21 * n44 + n11 * n22 * n44) * idet;
	ret[2][3] = (n13 * n22 * n41 - n12 * n23 * n41 - n13 * n21 * n42 + n11 * n23 * n42 + n12 * n21 * n43 - n11 * n22 * n43) * idet;

	ret[3][0] = t14 * idet;
	ret[3][1] = (n13 * n24 * n31 - n14 * n23 * n31 + n14 * n21 * n33 - n11 * n24 * n33 - n13 * n21 * n34 + n11 * n23 * n34) * idet;
	ret[3][2] = (n14 * n22 * n31 - n12 * n24 * n31 - n14 * n21 * n32 + n11 * n24 * n32 + n12 * n21 * n34 - n11 * n22 * n34) * idet;
	ret[3][3] = (n12 * n23 * n31 - n13 * n22 * n31 + n13 * n21 * n32 - n11 * n23 * n32 - n12 * n21 * n33 + n11 * n22 * n33) * idet;

	return ret;
}

float4 matrix_to_quaternion(float4x4 m)
{
    float tr = m[0][0] + m[1][1] + m[2][2];
    float4 q = float4(0, 0, 0, 0);

    if (tr > 0)
    {
        float s = sqrt(tr + 1.0) * 2; // S=4*qw 
        q.w = 0.25 * s;
        q.x = (m[2][1] - m[1][2]) / s;
        q.y = (m[0][2] - m[2][0]) / s;
        q.z = (m[1][0] - m[0][1]) / s;
    }
    else if ((m[0][0] > m[1][1]) && (m[0][0] > m[2][2]))
    {
        float s = sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2; // S=4*qx 
        q.w = (m[2][1] - m[1][2]) / s;
        q.x = 0.25 * s;
        q.y = (m[0][1] + m[1][0]) / s;
        q.z = (m[0][2] + m[2][0]) / s;
    }
    else if (m[1][1] > m[2][2])
    {
        float s = sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2; // S=4*qy
        q.w = (m[0][2] - m[2][0]) / s;
        q.x = (m[0][1] + m[1][0]) / s;
        q.y = 0.25 * s;
        q.z = (m[1][2] + m[2][1]) / s;
    }
    else
    {
        float s = sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2; // S=4*qz
        q.w = (m[1][0] - m[0][1]) / s;
        q.x = (m[0][2] + m[2][0]) / s;
        q.y = (m[1][2] + m[2][1]) / s;
        q.z = 0.25 * s;
    }

    return q;
}

float4x4 m_scale(float4x4 m, float3 v)
{
    float x = v.x, y = v.y, z = v.z;

    m[0][0] *= x; m[1][0] *= y; m[2][0] *= z;
    m[0][1] *= x; m[1][1] *= y; m[2][1] *= z;
    m[0][2] *= x; m[1][2] *= y; m[2][2] *= z;
    m[0][3] *= x; m[1][3] *= y; m[2][3] *= z;

    return m;
}

float4x4 quaternion_to_matrix(float4 quat)
{
    float4x4 m = float4x4(float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0), float4(0, 0, 0, 0));

    float x = quat.x, y = quat.y, z = quat.z, w = quat.w;
    float x2 = x + x, y2 = y + y, z2 = z + z;
    float xx = x * x2, xy = x * y2, xz = x * z2;
    float yy = y * y2, yz = y * z2, zz = z * z2;
    float wx = w * x2, wy = w * y2, wz = w * z2;

    m[0][0] = 1.0 - (yy + zz);
    m[0][1] = xy - wz;
    m[0][2] = xz + wy;

    m[1][0] = xy + wz;
    m[1][1] = 1.0 - (xx + zz);
    m[1][2] = yz - wx;

    m[2][0] = xz - wy;
    m[2][1] = yz + wx;
    m[2][2] = 1.0 - (xx + yy);

    m[3][3] = 1.0;

    return m;
}

float4x4 m_translate(float4x4 m, float3 v)
{
    float x = v.x, y = v.y, z = v.z;
    m[0][3] = x;
    m[1][3] = y;
    m[2][3] = z;
    return m;
}

float4x4 compose(float3 position, float4 quat, float3 scale)
{
    float4x4 m = quaternion_to_matrix(quat);
    m = m_scale(m, scale);
    m = m_translate(m, position);
    return m;
}

void decompose(in float4x4 m, out float3 position, out float4 rotation, out float3 scale)
{
    float sx = length(float3(m[0][0], m[0][1], m[0][2]));
    float sy = length(float3(m[1][0], m[1][1], m[1][2]));
    float sz = length(float3(m[2][0], m[2][1], m[2][2]));

    // if determine is negative, we need to invert one scale
    float det = determinant(m);
    if (det < 0) {
        sx = -sx;
    }

    position.x = m[3][0];
    position.y = m[3][1];
    position.z = m[3][2];

    // scale the rotation part

    float invSX = 1.0 / sx;
    float invSY = 1.0 / sy;
    float invSZ = 1.0 / sz;

    m[0][0] *= invSX;
    m[0][1] *= invSX;
    m[0][2] *= invSX;

    m[1][0] *= invSY;
    m[1][1] *= invSY;
    m[1][2] *= invSY;

    m[2][0] *= invSZ;
    m[2][1] *= invSZ;
    m[2][2] *= invSZ;

    rotation = matrix_to_quaternion(m);

    scale.x = sx;
    scale.y = sy;
    scale.z = sz;
}


// http://stackoverflow.com/questions/349050/calculating-a-lookat-matrix
float4x4 look_at_matrix(float3 forward, float3 up)
{
    float3 xaxis = normalize(cross(forward, up));
    float3 yaxis = up;
    float3 zaxis = forward;
    return axis_matrix(xaxis, yaxis, zaxis);
}

float4x4 look_at_matrix(float3 at, float3 eye, float3 up)
{
    float3 zaxis = normalize(at - eye);
    float3 xaxis = normalize(cross(up, zaxis));
    float3 yaxis = cross(zaxis, xaxis);
    return axis_matrix(xaxis, yaxis, zaxis);
}


float4x4 extract_rotation_matrix(float4x4 m)
{
    float sx = length(float3(m[0][0], m[0][1], m[0][2]));
    float sy = length(float3(m[1][0], m[1][1], m[1][2]));
    float sz = length(float3(m[2][0], m[2][1], m[2][2]));

    // if determine is negative, we need to invert one scale
    float det = determinant(m);
    if (det < 0) {
        sx = -sx;
    }

    float invSX = 1.0 / sx;
    float invSY = 1.0 / sy;
    float invSZ = 1.0 / sz;

    m[0][0] *= invSX;
    m[0][1] *= invSX;
    m[0][2] *= invSX;
    m[0][3] = 0;

    m[1][0] *= invSY;
    m[1][1] *= invSY;
    m[1][2] *= invSY;
    m[1][3] = 0;

    m[2][0] *= invSZ;
    m[2][1] *= invSZ;
    m[2][2] *= invSZ;
    m[2][3] = 0;

    m[3][0] = 0;
    m[3][1] = 0;
    m[3][2] = 0;
    m[3][3] = 1;

    return m;
}

// end https://gist.github.com/mattatz/86fff4b32d198d0928d0fa4ff32cf6fa

// https://answers.unity.com/questions/770838/how-can-i-extract-the-fov-information-from-the-pro.html
float getCameraFOV()
{
	float t = unity_CameraProjection._m11;
	const float Rad2Deg = 180 / UNITY_PI;
	float fov = atan(1.0f / t) * 2.0 * Rad2Deg;
	
	return fov;
}

// HSV functions from http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
float3 rgb2hsv(float3 c)
{
	float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	float4 p = c.g < c.b ? float4(c.bg, K.wz) : float4(c.gb, K.xy);
	float4 q = c.r < p.x ? float4(p.xyw, c.r) : float4(c.r, p.yzx);

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

float3 hsv2rgb(float3 c)
{
	float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// https://www.shadertoy.com/view/ltB3zD
// Gold Noise 2015 dcerisano@standard3d.com
//
// Slightly modified by xwidghet to resolve variable name collisions
float gold_noise(float2 coordinate, float seed)
{
	const float PHI = 1.61803398874989484820459; // Golden Ratio
	const float SRT = 1.41421356237309504880169;

	float2 temp = coordinate*float2((seed + PHI), (seed + PHI));
	const float2 temp2 = float2(PHI, UNITY_PI);
    return frac(sin(dot(temp, temp2))*SRT);
}

// https://catlikecoding.com/unity/tutorials/flow/looking-through-water/
float2 AlignWithGrabTexel(float4 texelSize, float2 uv) {
#if UNITY_UV_STARTS_AT_TOP
	if (texelSize.y < 0) {
		uv.y = 1 - uv.y;
	}
#endif

	return
		(floor(uv * texelSize.zw) + 0.5) *
		abs(texelSize.xy);
}

// Triangular probability distribution function
// Assumes input is between 0 and 1
//
// I'm pretty sure I wrote this, but since I'm not 100% sure
// and I can't find any sources by googling this, I'm going to
// leave this as a function from an 'unknown' source on the internet.
//	 -xwidghet
float tpdf(float x)
{
	float a = 0.0;
	float b = 0.5;
	float c = 1.0;

	float numerator = 2 * (x - a);
	float denominator = (c - a)*(b - a);

	return numerator / denominator;
}

// Begin xwidghet helpers
float intersectPlane(float3 planeOrigin, float3 planeNormal, float3 rayOrigin, float3 rayDir)
{
    const float denom = dot(planeNormal, rayDir);
    // Normally you would check if this is smaller than some value, but since I want backfaces I only avoid division by zero.
    if (denom != 0.0)
    {
        const float3 toPlane = planeOrigin - rayOrigin;
        return dot(toPlane, planeNormal) / denom;
    }

    return 0.0;
}

float angleToWorldCoordinate(float4 worldCoordinates, float3 camFront)
{
	float3 worldVector = normalize(worldCoordinates - _WorldSpaceCameraPos);

	return(acos(dot(worldVector, camFront)));
}

// Rotate 2D without hardcoded elements to allow for
// utilizing swizzling to rotate around various axis.
float2 rotate2D(float2 coordinates, float angle)
{
	// Angle is negative to retain the same rotation direction
	// as rotAxis.
	float tempX = coordinates.x;
	coordinates.x = cos(-angle)*tempX - sin(-angle)*coordinates.y;
	coordinates.y = sin(-angle)*tempX + cos(-angle)*coordinates.y;

	return coordinates;
}

float2 reverseTransformStereoScreenSpaceTex(float2 uv, float w)
{
	// Original forward version from UnityCG.cginc
	/*
	float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
	return uv.xy * scaleOffset.xy + scaleOffset.zw * w;
	*/
#ifdef UNITY_SINGLE_PASS_STEREO
	float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];

	uv -= (scaleOffset.zw * w);
	uv = (uv.xy / scaleOffset.xy);
#endif

	return uv;
}


float4 reverseComputeGrabScreenPos(float4 grabScreenPos)
{
	// Original forward version from UnityCG.cginc
	/*
#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
	#else
	float scale = 1.0;
	#endif
	float4 o = pos * 0.5f;
	o.xy = float2(o.x, o.y*scale) + o.w;
#ifdef UNITY_SINGLE_PASS_STEREO
	o.xy = TransformStereoScreenSpaceTex(o.xy, pos.w);
#endif
	o.zw = pos.zw;
	return o;
	*/

	float4 o = grabScreenPos;

#ifdef UNITY_SINGLE_PASS_STEREO
	o.xy = reverseTransformStereoScreenSpaceTex(o.xy, grabScreenPos.w);
#endif

#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
#else
	float scale = 1.0;
#endif

	o.xy -= o.w*0.5f;
	o.xy = float2(o.x, o.y/scale);

	o.xy *= 2;

	return o;
}

float4 reverseComputeNonStereoScreenPos(float4 pos) {
	// Original forward version from UnityCG.cginc
	/*
	float4 o = pos * 0.5f;
	o.xy = float2(o.x, o.y*_ProjectionParams.x) + o.w;
	o.zw = pos.zw;
	return o;
	*/
	
	float4 o = pos;

	o.xy -= o.w*0.5f;
	o.xy = float2(o.x, o.y / _ProjectionParams.x);

	o.xy *= 2.f;

	return o;
}

// End xwidghet helpers
#endif