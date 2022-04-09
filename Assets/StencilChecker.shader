Shader "StencilChecker"
{
    HLSLINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
        struct appdata
        {
            float4 vertex : POSITION;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert(appdata v)
        {
            v2f o;
            UNITY_SETUP_INSTANCE_ID(v);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            o.vertex = UnityObjectToClipPos(v.vertex);
            return o;
        }

        #define FRAG(r,g,b) float4 frag() : SV_Target { return float4( GammaToLinearSpace(float3(r,g,b)/7.0), 1 ); }
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Overlay" "Queue"="Overlay" "IgnoreProjector"="True" "VRCFallback"="Hidden" }
        ZWrite Off
        Blend Zero Zero, Zero One
        Pass{ HLSLPROGRAM FRAG(0,0,0) ENDHLSL }

        Stencil { Comp Equal }
        Blend One One, Zero One

        Stencil { ReadMask 7 }
        Pass{ Stencil{ Ref   1 } HLSLPROGRAM FRAG(0,0,1) ENDHLSL }
        Pass{ Stencil{ Ref   2 } HLSLPROGRAM FRAG(0,0,2) ENDHLSL }
        Pass{ Stencil{ Ref   3 } HLSLPROGRAM FRAG(0,0,3) ENDHLSL }
        Pass{ Stencil{ Ref   4 } HLSLPROGRAM FRAG(0,0,4) ENDHLSL }
        Pass{ Stencil{ Ref   5 } HLSLPROGRAM FRAG(0,0,5) ENDHLSL }
        Pass{ Stencil{ Ref   6 } HLSLPROGRAM FRAG(0,0,6) ENDHLSL }
        Pass{ Stencil{ Ref   7 } HLSLPROGRAM FRAG(0,0,7) ENDHLSL }

        Stencil { ReadMask 56 }
        Pass{ Stencil{ Ref   8 } HLSLPROGRAM FRAG(0,1,0) ENDHLSL }
        Pass{ Stencil{ Ref  16 } HLSLPROGRAM FRAG(0,2,0) ENDHLSL }
        Pass{ Stencil{ Ref  24 } HLSLPROGRAM FRAG(0,3,0) ENDHLSL }
        Pass{ Stencil{ Ref  32 } HLSLPROGRAM FRAG(0,4,0) ENDHLSL }
        Pass{ Stencil{ Ref  40 } HLSLPROGRAM FRAG(0,5,0) ENDHLSL }
        Pass{ Stencil{ Ref  48 } HLSLPROGRAM FRAG(0,6,0) ENDHLSL }
        Pass{ Stencil{ Ref  56 } HLSLPROGRAM FRAG(0,7,0) ENDHLSL }

        Stencil { ReadMask 192 }
        Pass{ Stencil{ Ref  64 } HLSLPROGRAM FRAG(1,0,0) ENDHLSL }
        Pass{ Stencil{ Ref 128 } HLSLPROGRAM FRAG(2,0,0) ENDHLSL }
        Pass{ Stencil{ Ref 192 } HLSLPROGRAM FRAG(3,0,0) ENDHLSL }
    }
}