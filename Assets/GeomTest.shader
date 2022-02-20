Shader "GeomTest"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _Cull ("Cull", Int) = 2
        [Space]
        _OutlineColor ("Outline Color", Color) = (1,1,1,1)
        _OutlineTex ("Texture", 2D) = "white" {}
        _OLCull ("Cull", Int) = 1
    }

    // 1 pass outline (geometry shader)
    /*SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                bool isOutline : TEXCOORD2;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _OutlineTex;
            float4 _MainTex_ST;
            float4 _OutlineTex_ST;
            float4 _Color;
            float4 _OutlineColor;
            uint _Cull;
            uint _OLCull;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToClipPos(float4(v.normal, 0)).xyz;
                o.isOutline = false;
                return o;
            }

            [maxvertexcount(12)]
            void geom(triangle v2f i[3], inout TriangleStream<v2f> outStream)
            {
                v2f o[3];
                o[0] = i[0];
                o[1] = i[1];
                o[2] = i[2];

                if(_Cull != 1)
                {
                    outStream.Append(o[0]);
                    outStream.Append(o[1]);
                    outStream.Append(o[2]);
                    outStream.RestartStrip();
                }

                if(_Cull != 2)
                {
                    outStream.Append(o[2]);
                    outStream.Append(o[1]);
                    outStream.Append(o[0]);
                    outStream.RestartStrip();
                }

                o[0].isOutline = true;
                o[1].isOutline = true;
                o[2].isOutline = true;
                o[0].vertex.xy += o[0].normal.xy * 0.01;
                o[1].vertex.xy += o[1].normal.xy * 0.01;
                o[2].vertex.xy += o[2].normal.xy * 0.01;
                if(_OLCull != 1)
                {
                    outStream.Append(o[0]);
                    outStream.Append(o[1]);
                    outStream.Append(o[2]);
                    outStream.RestartStrip();
                }

                if(_OLCull != 2)
                {
                    outStream.Append(o[2]);
                    outStream.Append(o[1]);
                    outStream.Append(o[0]);
                    outStream.RestartStrip();
                }
            }

            //[earlydepthstencil]
            float4 frag (v2f i) : SV_Target
            {
                float4 col;
                if(i.isOutline)
                {
                    col = tex2D(_OutlineTex, i.uv) * _OutlineColor;
                }
                else
                {
                    col = tex2D(_MainTex, i.uv) * _Color;
                }
                //col = i.isOutline ? tex2D(_OutlineTex, i.uv) : tex2D(_MainTex, i.uv);
                return col;
            }
            ENDCG
        }
    }*/

    // 2-pass outline
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull [_Cull]
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _OutlineTex;
            float4 _MainTex_ST;
            float4 _OutlineTex_ST;
            float4 _Color;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToClipPos(float4(v.normal, 0)).xyz;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_MainTex, i.uv) * _Color;
                return col;
            }
            ENDCG
        }

        Pass
        {
            Tags {"LightMode" = "ForwardBase"}
            Cull [_OLCull]
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            sampler2D _OutlineTex;
            float4 _MainTex_ST;
            float4 _OutlineTex_ST;
            float4 _Color;
            float4 _OutlineColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToClipPos(float4(v.normal, 0)).xyz;
                o.vertex.xy += o.normal.xy * 0.01;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                float4 col = tex2D(_OutlineTex, i.uv) * _OutlineColor;
                return col;
            }
            ENDCG
        }
    }
}
