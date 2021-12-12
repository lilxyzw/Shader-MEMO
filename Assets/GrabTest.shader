Shader "GrabTest"
{
    SubShader
    {
        Tags {"RenderType"="Transparent" "Queue"="Transparent"}

        GrabPass {"_BackgroundTexture"}
        Pass
        {
            CGPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #if 1
                // UNITY_STEREO_INSTANCING_ENABLED または UNITY_STEREO_MULTIVIEW_ENABLED が宣言されているとテクスチャ配列化される
                #define DECLARE_GRABTEX(tex)     UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)
                #define SAMPLE_GRABTEX(tex,uv)   UNITY_SAMPLE_SCREENSPACE_TEXTURE(tex,uv)
            #else
                // Single Pass Instancedで壊れるパターン
                // 左右の目別々の画像がテクスチャ配列として渡されるため、うまくサンプリングできなくなるように見える
                #define DECLARE_GRABTEX(tex)     UNITY_DECLARE_TEX2D(tex)
                #define SAMPLE_GRABTEX(tex,uv)   UNITY_SAMPLE_TEX2D(tex,uv)
            #endif

            // 左目・右目の映像が1枚にまとまっているため、そのままVPOSを使うのではなくx座標を0.5倍する必要あり
            #define GRAB_TEXTURE_TYPE 3
            #if GRAB_TEXTURE_TYPE == 0
                // _ProjectionParams.xの値の異常で壊れるパターン (https://feedback.vrchat.com/bug-reports/p/incorrect-rendering-issue-with-my-shader)
                // ComputeScreenPos()で計算
                // 上限反転するか否かを _ProjectionParams.x で決める
                // しかしこの値が不安定で、VRC Scene DescriptorのReference Cameraを適切に指定してやらないと上下逆の映像になってしまうことがある
                #define CALC_GRABUV(uv) float2 uv = i.ScreenPos.xy / i.ScreenPos.w
            #elif GRAB_TEXTURE_TYPE == 1
                // ComputeGrabScreenPos()で計算
                // 上限反転するか否かを UNITY_UV_STARTS_AT_TOP で決める
                #define CALC_GRABUV(uv) float2 uv = i.GrabScreenPos.xy / i.GrabScreenPos.w
            #elif GRAB_TEXTURE_TYPE == 2
                // Single Pass Stereo (VRChat)で壊れるパターン (https://docs.unity3d.com/ja/2019.4/Manual/SinglePassStereoRendering.html)
                // VPOSを元に計算
                // 左目・右目の映像が1枚にまとまっているため、そのままVPOSを使うのではなくx座標を0.5倍する必要あり
                #define CALC_GRABUV(uv) float2 uv = vpos.xy / _ScreenParams.xy
            #elif GRAB_TEXTURE_TYPE == 3
                // VPOSを元に計算
                // Single Pass Stereo用にVPOSに補正を加えたもの
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    #define CALC_GRABUV(uv) float2 uv = vpos.xy / _ScreenParams.xy * float2(0.5,1.0)
                #else
                    #define CALC_GRABUV(uv) float2 uv = vpos.xy / _ScreenParams.xy
                #endif
            #endif

            // GrabPassのテクスチャ
            DECLARE_GRABTEX(_BackgroundTexture);

            struct appdata
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID  // Single Pass Instanced対応用
            };

            struct v2f
            {
                float4 ScreenPos : TEXCOORD0;
                float4 GrabScreenPos : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID  // Single Pass Instanced対応用
                UNITY_VERTEX_OUTPUT_STEREO      // Single Pass Instanced対応用
            };

            // 頂点シェーダー
            v2f vert(appdata v, out float4 vertex : SV_POSITION)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);

                // Single Pass Instanced対応用
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // 行列計算
                vertex = UnityObjectToClipPos(v.vertex);

                // スクリーン座標の計算
                // UNITY_UV_STARTS_AT_TOPマクロを用いるか_ProjectionParams.xを用いるかという違いがある
                // 基本的には同じ結果になる
                o.ScreenPos = ComputeScreenPos(vertex);
                o.GrabScreenPos = ComputeGrabScreenPos(vertex);
                return o;
            }

            // フラグメントシェーダー
            // VPOSは基本的にSV_POSITIONと同じっぽい
            // UNITY_VPOS_TYPEも現在はfloat4固定 (D3D9時代にfloat2が使われていた)
            float4 frag(v2f i, UNITY_VPOS_TYPE vpos : VPOS) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // 画面座標の計算
                // 屈折を扱う場合に注意すべきポイントですが、Single Pass Stereoでは左右の目の映像を一枚のテクスチャにまとめているためUVの操作で隣の目の映像にはみ出す場合があります。
                // そのためUnityStereoClamp()などを用いてUV座標を制限する必要があります。
                CALC_GRABUV(grabUV);

                // サンプリング
                float4 col = SAMPLE_GRABTEX(_BackgroundTexture, grabUV);
                col.rgb *= float3(1.0,0.5,0.5);
                return col;
            }
            ENDCG
        }
    }
}
