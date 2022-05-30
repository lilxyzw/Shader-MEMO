# SRPでのマルチパスシェーダー
SRPではマルチパスシェーダーの作成に制限がありますが、シェーダーのLightModeタグを複数組み合わせることでパイプラインの改造無しで擬似的に作成できます。

## HDRP
### 4.x.x - 14.x.x
1. `TransparentBackface`（Transparentのみ）
2. `ForwardOnly`
3. `Forward`（Transparentのみ）
4. `SRPDefaultUnlit`

```HLSL
Shader "Unlit/MultiPass"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        HLSLINCLUDE
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #define VERT(x,y,z,w) float4 vert(float4 vertex : POSITION) : SV_POSITION { return UnityObjectToClipPos(vertex + float4(x,y,z,w)); }
            #define FRAG(r,g,b,a) float4 frag() : SV_Target { return float4(r,g,b,a); }
        ENDHLSL

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "TransparentBackface"
            Tags {"LightMode"="TransparentBackface"}
            HLSLPROGRAM
            VERT(0,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "ForwardOnly"
            Tags {"LightMode"="ForwardOnly"}
            HLSLPROGRAM
            VERT(1,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "Forward"
            Tags {"LightMode"="Forward"}
            HLSLPROGRAM
            VERT(2,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "SRPDefaultUnlit"
            Tags {"LightMode"="SRPDefaultUnlit"}
            HLSLPROGRAM
            VERT(3,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }
    }
}
```

## URP
### 7.x.x
1. `UniversalForward`
2. `LightweightForward`
3. `SRPDefaultUnlit`

### 8.x.x
1. `SRPDefaultUnlit`
2. `UniversalForward`
3. `LightweightForward`

### 9.x.x - 11.x.x
1. `SRPDefaultUnlit`
2. `UniversalForward`
3. `UniversalForwardOnly`
4. `LightweightForward`

### 12.x.x - 14.x.x
1. `SRPDefaultUnlit`
2. `UniversalForward`
3. `UniversalForwardOnly`

```HLSL
Shader "Unlit/MultiPass"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Transparent" }
        HLSLINCLUDE
            #pragma vertex vert
            #pragma fragment frag
            float4x4 unity_MatrixVP;
            float4x4 unity_ObjectToWorld;
            #define VERT(x,y,z,w) float4 vert(float4 vertex : POSITION) : SV_POSITION { return mul(unity_MatrixVP, mul(unity_ObjectToWorld, float4(vertex.xyz, 1.0) + float4(x,y,z,w))); }
            #define FRAG(r,g,b,a) float4 frag() : SV_Target { return float4(r,g,b,a); }
        ENDHLSL

        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            Name "SRPDefaultUnlit"
            Tags {"LightMode"="SRPDefaultUnlit"}
            HLSLPROGRAM
            VERT(0,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "UniversalForward"
            Tags {"LightMode"="UniversalForward"}
            HLSLPROGRAM
            VERT(1,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "UniversalForwardOnly"
            Tags {"LightMode"="UniversalForwardOnly"}
            HLSLPROGRAM
            VERT(2,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }

        Pass
        {
            Name "LightweightForward"
            Tags {"LightMode"="LightweightForward"}
            HLSLPROGRAM
            VERT(3,0,0,0)
            FRAG(1,1,1,0.5)
            ENDHLSL
        }
    }
}
```