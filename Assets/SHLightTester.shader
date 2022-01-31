Shader "SHLightTester"
{
    Properties
    {
        [KeywordEnum(L0, x, y, z, xy, yz, zz, xz, xx_yy, L1, L2, FULL)] _SHType ("SH Type", Int) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            // SHライトプレビュー用のパス
            // SHライトは LightMode が ForwardBase のときに取れる
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 normal : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            int _SHType;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = mul((float3x3)UNITY_MATRIX_M, v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = float4(1,1,1,1);
                i.normal = normalize(i.normal);

                // SHライトについて
                // https://docs.unity3d.com/ja/2020.3/Manual/LightProbes-TechnicalInformation.html
                // Light Probe や Skybox のライティング、その他の Important ではないライトはSHライトで計算される
                // ベースとなる明るさに加えて、各方向への明るさの偏りを計算することで大まかに環境光を表現している

                // L0: ベースとなる明るさ
                //     unity_SHA のw成分に格納
                col.r = unity_SHAr.w;
                col.g = unity_SHAg.w;
                col.b = unity_SHAb.w;

                // L1: xyz方向への明るさの偏りを表現
                //     unity_SHA のxyz成分に格納
                if(_SHType >= 1 && _SHType <= 3)
                {
                    col.r += unity_SHAr[_SHType-1] * i.normal[_SHType-1];
                    col.g += unity_SHAg[_SHType-1] * i.normal[_SHType-1];
                    col.b += unity_SHAb[_SHType-1] * i.normal[_SHType-1];
                }

                // L2: xy、yz、zz、xz、xx-yy方向への偏りを表現
                //     unity_SHB のxyzw成分にxy、yz、zz、xz
                //     unity_SHC のxyz成分にxx-yyを格納（SHCのxyzがrgbそれぞれのxx-yyに対応）
                float4 vB = i.normal.xyzz * i.normal.yzzx;
                float vC = i.normal.x*i.normal.x - i.normal.y*i.normal.y;
                if(_SHType >= 4 && _SHType <= 7)
                {
                    col.r += unity_SHBr[_SHType-4] * vB[_SHType-4];
                    col.g += unity_SHBg[_SHType-4] * vB[_SHType-4];
                    col.b += unity_SHBb[_SHType-4] * vB[_SHType-4];
                }
                if(_SHType == 8)
                {
                    col.rgb += unity_SHC.rgb * vC;
                }

                // テスト用 L1L2それぞれを合算した結果
                // _SHType == 11 のとき ShadeSH9(float4(i.normal,1)) と同等
                if(_SHType == 9 || _SHType == 11)
                {
                    col.r += dot(unity_SHAr.xyz, i.normal);
                    col.g += dot(unity_SHAg.xyz, i.normal);
                    col.b += dot(unity_SHAb.xyz, i.normal);
                }
                if(_SHType >= 10)
                {
                    col.r += dot(unity_SHBr, vB);
                    col.g += dot(unity_SHBg, vB);
                    col.b += dot(unity_SHBb, vB);
                    col.rgb += unity_SHC.rgb * vC;
                }

                #if defined(UNITY_COLORSPACE_GAMMA)
                    col.rgb = LinearToGammaSpace (col.rgb);
                #endif

                return col;
            }
            ENDCG
        }

        Pass
        {
            // SHの軸のプレビュー
            // 赤がプラス、青がマイナス方向
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "Lighting.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float3 normal : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            int _SHType;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = mul(UNITY_MATRIX_M, v.vertex);
                o.vertex.x += 1.5;
                o.vertex = UnityWorldToClipPos(o.vertex);
                o.normal = mul((float3x3)UNITY_MATRIX_M, v.normal);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = float4(1,0,0,1);
                i.normal = normalize(i.normal);

                float4 vB = i.normal.xyzz * i.normal.yzzx;
                float vC = i.normal.x*i.normal.x - i.normal.y*i.normal.y;
                if(_SHType >= 1 && _SHType <= 3)
                {
                    col.r = saturate(0.5 + i.normal[_SHType-1] * 0.5);
                    col.b = saturate(0.5 - i.normal[_SHType-1] * 0.5);
                }
                if(_SHType == 4 || _SHType == 5 || _SHType == 7)
                {
                    col.r = saturate(0.5 + vB[_SHType-4]);
                    col.b = saturate(0.5 - vB[_SHType-4]);
                }
                if(_SHType == 6)
                {
                    col.r = saturate(0.5 + vB[_SHType-4] * 0.5);
                    col.b = saturate(0.5 - vB[_SHType-4] * 0.5);
                }
                if(_SHType == 8)
                {
                    col.r = saturate(0.5 + vC * 0.5);
                    col.b = saturate(0.5 - vC * 0.5);
                }

                #if !defined(UNITY_COLORSPACE_GAMMA)
                    col.rgb = GammaToLinearSpace(col.rgb);
                #endif

                return col;
            }
            ENDCG
        }
    }
}
