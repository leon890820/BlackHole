Shader "Hidden/Blackhole"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SkyboxCube ("Skybox Cubemap", CUBE) = "" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewVector : TEXCOORD1;
            };
            
            v2f vert (appdata v) {
                v2f output;
                output.pos = UnityObjectToClipPos(v.vertex);
                output.uv = v.uv;
                // Camera space matches OpenGL convention where cam forward is -z. In unity forward is positive z.
                // (https://docs.unity3d.com/ScriptReference/Camera-cameraToWorldMatrix.html)
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                output.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));
                return output;
            }

            sampler2D _MainTex;
            samplerCUBE _SkyboxCube;

            float4 blackholePosition;
            float stepSize;  
            int   maxSteps;     
            float _H2;  
            float innerRadius;
            float outerRadius;
            float density;
            float thickness;
            Texture3D<float4> NoiseTex;
            SamplerState samplerNoiseTex;
            float3 noiseScale;
            float u_time;
            float depth;
            
            float4 permute(float4 x) { return fmod(((x * 34.0) + 1.0) * x, 289.0); }
            float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }

            float map(float n,float x1,float x2,float y1,float y2){
                return (n - x1) * (y2 - y1) / (x2 - x1) + y1;
            }

            float random(in float2 _st) { 
                return frac(sin(dot(_st.xy, float2(12.9898,78.233)))* 43758.5453123); 
            } 
            // Based on Morgan McGuire @morgan3d // https://www.shadertoy.com/view/4dS3Wd 
            float noise (in float2 _st) { 
                float2 i = floor(_st); 
                float2 f = frac(_st); 
                // Four corners in 2D of a tile 
                float a = random(i); 
                float b = random(i + float2(1.0, 0.0)); 
                float c = random(i + float2(0.0, 1.0)); 
                float d = random(i + float2(1.0, 1.0)); 
                float2 u = f * f * (3.0 - 2.0 * f); 
                return lerp(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y; 
            } 
            #define NUM_OCTAVES 5 
            float fbm(in float2 _st) { 
                float v = 0.0; 
                float a = 0.5; 
                float2 shift = float2(100.0 , 100.0); 
                // Rotate to reduce axial bias 
                float2x2 rot = float2x2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50)); 
                for (int i = 0; i < NUM_OCTAVES; ++i) { 
                    v += a * noise(_st); 
                    _st = mul(rot, _st) * 2.0 + shift; a *= 0.5; 
                } 
                return v; 
            } 
            float3 snoise(float2 st){ 
                float3 color = float3(0.0,0.0,0.0); 
                float2 q = float2(0.0,0.0); 
                q.x = fbm( st + 0.00); 
                q.y = fbm( st + float2(1.0,1.0)); 
                float2 r = float2(0.0,0.0); 
                r.x = fbm( st + 1.0*q + float2(1.7,9.2)+ 0.15 * u_time); 
                r.y = fbm( st + 1.0*q + float2(8.3,2.8)+ 0.126 * u_time); 
                float f = fbm(st+r); 
                color = lerp(float3(0.1,0.1,0.1), float3(0.666667,0.666667,0.666667), clamp((f*f)*4.0,0.0,1.0)); 
                color = lerp(color, float3(0,0,0.0), clamp(length(q),0.0,1.0)); 
                color = lerp(color, float3(1.0,1.0,1.000), clamp(length(r.x),0.0,1.0)); 
                return (f*f*f+.6*f*f+.5*f)*color; 
            }

            // 3D random / hash
            float3 toSpherical(float3 p) {
              float rho = sqrt((p.x * p.x) + (p.y * p.y) + (p.z * p.z));
              float theta = atan2(p.z, p.x);
              float phi = asin(p.y / rho);
              return float3(rho, theta, phi);
            }

            float3 toSpherical2(float3 pos) {
              float3 radialCoords;
              radialCoords.x = length(pos) * 1.5 + 0.55;
              radialCoords.y = atan2(-pos.x, -pos.z) * 1.5;
              radialCoords.z = abs(pos.y);
              return radialCoords;
            }

            float3 GetAdiskColor(float3 pos){
                float3 bhPos = blackholePosition.xyz;
                float3 r = (pos - bhPos);
                float rad = r.x * r.x + r.z * r.z;
                float d = map(sqrt( rad) , innerRadius , outerRadius , 1 , 0);
                d = d*d;
                float3 uvw = pos * noiseScale; //+ float3(u_time * 0.02,u_time*0.03,u_time*0.05);
                uvw = toSpherical2(uvw);
                float shapeNoise = 1;
                for (int i = 1; i < 3; i++) {
                    shapeNoise *= 0.5 * snoise(uvw.xy * pow(i, 2)) + 0.5;
                    if (i % 2 == 0) {
                      uvw.y += u_time * 0.2;
                    } else {
                      uvw.y -= u_time * 0.2;
                    }
                }


                if(abs(r.y) < thickness && rad < outerRadius * outerRadius && rad > innerRadius * innerRadius){
                    return float3(1,1,1) * density * d * d * shapeNoise; // Red close to black hole    
                }

                return float3(0,0,0);
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 rayPos = _WorldSpaceCameraPos;
                float3 rayDir = normalize(i.viewVector);

                float3 bhPos = blackholePosition.xyz;
                float  r_s   = blackholePosition.w;   // 事件視界半徑
                //float  h2    = _H2;                   // 對應公式裡的 h^2，當成強度
                float3 h = cross(rayPos - bhPos, rayDir);
                float h2 = dot(h, h);
                float3 adiskColor;

                for (int step = 0; step < maxSteps; step++)
                {
                    // 1. 先往前走一步
                    rayPos += rayDir * stepSize;

                    float3 rVec = rayPos - bhPos;
                    float  r    = length(rVec);

                    // 掉進黑洞
                    if (r < r_s)
                        return float4(adiskColor,1.0);
                    
                    // 2. 用公式算加速度 a(r) = -(3/2) h^2 / r^4 * r^
                    float  invR = 1.0 / max(r, 1e-4);
                    float3 rHat = rVec * invR;

                    float  invR2   = invR * invR;
                    float  gravMag = 1.5 * h2 * invR2 * invR2;   // (3/2)*h^2*(1/r^4)

                    float3 acc = -rHat * gravMag;

                    // 3. 更新 ray 方向（被拉彎）
                    rayDir = normalize(rayDir + acc * stepSize);

                    adiskColor += GetAdiskColor(rayPos) * stepSize;
                }

               

                // 沒掉進黑洞 → 用最後的 rayDir 去 sample skybox
                float4 sky = texCUBE(_SkyboxCube, rayDir) + float4(adiskColor,0.0);
                return sky;
            }
            ENDCG
        }
    }
}
