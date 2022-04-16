Shader "DepthTex2PosWS"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Overlay" }

        Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off
            CGPROGRAM
            #pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            struct appdata
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 OptimizedMul(float4x4 mat, float3 vec)
            {
                //return mul(mat, float4(vec, 1));
                return mat._m00_m10_m20_m30 * vec.x + (mat._m01_m11_m21_m31 * vec.y + (mat._m02_m12_m22_m32 * vec.z + mat._m03_m13_m23_m33));
            }

            v2f vert(appdata i)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.positionCS = float4(i.vertexID / 2 ? 1 : -1, i.vertexID % 2 ? 1 : -1, 1, 1);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 scnUV = i.positionCS.xy / _ScreenParams.xy;
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    scnUV.x *= 0.5;
                #endif
                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, scnUV));

                float4 positionCS = float4(
                    (scnUV * 2.0 - 1.0) * depth,
                    1,
                    depth
                );
                #if UNITY_UV_STARTS_AT_TOP
                    positionCS.y = -positionCS.y;
                #endif
                float3 positionVS = positionCS.xyw / UNITY_MATRIX_P._m00_m11_m32;
                float3 positionWS = OptimizedMul(UNITY_MATRIX_I_V, positionVS).xyz;

                return float4(saturate(1 - abs(frac(positionWS) - 0.5) * 8), 1);
            }
            ENDCG
        }
    }
}
