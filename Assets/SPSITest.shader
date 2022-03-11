Shader "SPSITest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }

        Pass
        {
            // 最低限の対応
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

                // SPS-I対応
                UNITY_VERTEX_INPUT_INSTANCE_ID // uint instanceID : SV_InstanceID;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;

                // SPS-I対応
                UNITY_VERTEX_OUTPUT_STEREO // uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o); // o = (v2g)0

                // SPS-I対応
                UNITY_SETUP_INSTANCE_ID(v);
                // UNITY_SETUP_INSTANCE_ID() を使うには入力の構造体に UNITY_VERTEX_INPUT_INSTANCE_ID が必要
                // 以下はマクロの中身
                // ----
                // unity_StereoEyeIndex = i.instanceID & 0x01;
                // unity_InstanceID = unity_BaseInstanceID + (i.instanceID >> 1);
                // void UnitySetupCompoundMatrices()
                // {
                //     unity_MatrixMVP_Instanced = mul(unity_MatrixVP, unity_ObjectToWorld);
                //     unity_MatrixMV_Instanced = mul(unity_MatrixV, unity_ObjectToWorld);
                //     unity_MatrixTMV_Instanced = transpose(unity_MatrixMV_Instanced);
                //     unity_MatrixITMV_Instanced = transpose(mul(unity_WorldToObject, unity_MatrixInvV));
                // }
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); // o.stereoTargetEyeIndex = unity_StereoEyeIndex

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }

        GrabPass { }

        Pass
        {
            // 全対応（ジオメトリシェーダー、GrabPass、_CameraDepthTexture）
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            // SPS-I対応
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture);
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;

                // SPS-I対応
                UNITY_VERTEX_INPUT_INSTANCE_ID  // uint instanceID : SV_InstanceID;
            };

            struct v2g
            {
                float4 vertex : TEXCOORD0;
                float2 uv : TEXCOORD1;
                float3 normal : TEXCOORD2;

                // SPS-I対応
                UNITY_VERTEX_INPUT_INSTANCE_ID  // uint instanceID : SV_InstanceID;
                UNITY_VERTEX_OUTPUT_STEREO      // uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
            };

            struct g2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;

                // SPS-I対応
                UNITY_VERTEX_INPUT_INSTANCE_ID  // uint instanceID : SV_InstanceID;
                UNITY_VERTEX_OUTPUT_STEREO      // uint stereoTargetEyeIndex : SV_RenderTargetArrayIndex;
            };

            v2g vert(appdata v)
            {
                v2g o;
                UNITY_INITIALIZE_OUTPUT(v2g, o); // o = (v2g)0

                // SPS-I対応
                UNITY_SETUP_INSTANCE_ID(v);
                // UNITY_SETUP_INSTANCE_ID() を使うには入力の構造体に UNITY_VERTEX_INPUT_INSTANCE_ID が必要
                // 以下はマクロの中身
                // ----
                // unity_StereoEyeIndex = i.instanceID & 0x01;
                // unity_InstanceID = unity_BaseInstanceID + (i.instanceID >> 1);
                // void UnitySetupCompoundMatrices()
                // {
                //     unity_MatrixMVP_Instanced = mul(unity_MatrixVP, unity_ObjectToWorld);
                //     unity_MatrixMV_Instanced = mul(unity_MatrixV, unity_ObjectToWorld);
                //     unity_MatrixTMV_Instanced = transpose(unity_MatrixMV_Instanced);
                //     unity_MatrixITMV_Instanced = transpose(mul(unity_WorldToObject, unity_MatrixInvV));
                // }
                UNITY_TRANSFER_INSTANCE_ID(v, o);         // o.instanceID = i.instanceID
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); // o.stereoTargetEyeIndex = unity_StereoEyeIndex

                o.vertex = v.vertex;
                o.vertex.x += 1.5;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = v.normal;
                return o;
            }

            [maxvertexcount(3)]
            void geom(triangle v2g i[3], inout TriangleStream<g2f> outStream)
            {
                g2f o[3];
                UNITY_INITIALIZE_OUTPUT(g2f, o[0]);
                UNITY_INITIALIZE_OUTPUT(g2f, o[1]);
                UNITY_INITIALIZE_OUTPUT(g2f, o[2]);

                // SPS-I対応
                UNITY_SETUP_INSTANCE_ID(i[0]);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i[0]); // unity_StereoEyeIndex = i.stereoTargetEyeIndex;
                                                                // UNITY_SETUP_INSTANCE_ID() があるのでおそらく不要ですが念の為
                UNITY_TRANSFER_INSTANCE_ID(i[0], o[0]);
                UNITY_TRANSFER_INSTANCE_ID(i[1], o[1]);
                UNITY_TRANSFER_INSTANCE_ID(i[2], o[2]);
                UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[0], o[0]); // o.stereoTargetEyeIndex = i.stereoTargetEyeIndex
                UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[1], o[1]); // UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO() でも多分OK
                UNITY_TRANSFER_VERTEX_OUTPUT_STEREO(i[2], o[2]);

                // ここで行列計算が発生するので UNITY_SETUP_INSTANCE_ID() が必要になる
                o[0].vertex = UnityObjectToClipPos(i[0].vertex);
                o[1].vertex = UnityObjectToClipPos(i[1].vertex);
                o[2].vertex = UnityObjectToClipPos(i[2].vertex);
                o[0].normal = UnityObjectToWorldNormal(i[0].normal);
                o[1].normal = UnityObjectToWorldNormal(i[1].normal);
                o[2].normal = UnityObjectToWorldNormal(i[2].normal);
                o[0].uv = i[0].uv;
                o[1].uv = i[1].uv;
                o[2].uv = i[2].uv;
                outStream.Append(o[0]);
                outStream.Append(o[1]);
                outStream.Append(o[2]);
            }

            fixed4 frag(g2f i) : SV_Target
            {
                // SPS-I対応
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 scnUV = i.vertex / _ScreenParams.xy;
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    scnUV.x *= 0.5;
                #endif

                // ここで行列計算が発生するので UNITY_SETUP_INSTANCE_ID() が必要になる
                i.normal = normalize(i.normal);
                float2 uvMatCap = mul((float3x3)UNITY_MATRIX_V, i.normal).xy * 0.5 + 0.5;

                // SPS-I対応
                float4 grabTex = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture, scnUV);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, scnUV);

                float4 col = tex2D(_MainTex, uvMatCap);
                depth = Linear01Depth(depth);
                col = lerp(col * grabTex, 1.0, depth);

                return col;
            }
            ENDCG
        }
    }
}
