# 開発メモ（Universal Render Pipeline/Litの変遷）
lilToonの開発に関わった部分のみメモ  
詳細は[Unity-Technologies / Graphics](https://github.com/Unity-Technologies/Graphics)を参照  
コンパイルエラー対策のマクロは[lil_common_macro.hlsl](https://github.com/lilxyzw/lilToon/blob/master/Assets/lilToon/Shader/Includes/lil_common_macro.hlsl)を参照

## 要約
SubShaderのTagsは`"RenderPipeline" = "UniversalPipeline"`。  
DOTS Instancing対応・非対応でSubShaderを分ける必要あり。  
トゥーンシェーダーとして実装するならForwardレンダリングなので、基本的に`UniversalGBuffer`は不要。  
必要なLightModeをまとめると以下の通り
- `UniversalForward`
- `ShadowCaster`
- `DepthOnly`
- `DepthNormals`
- `Meta`

アウトラインなどマルチパスしたい場合は`SRPDefaultUnlit`を利用可能。  
`Universal2D`は任意で追加。  
9.x.x以前は`_MIXED_LIGHTING_SUBTRACTIVE`というキーワードが使われていたので対応させたい場合は追加が必要。（ライトマップ用）

## [LightweightRP]
- 現在のパスに変更された
- SubShaderのTagsは`"RenderPipeline" = "LightweightPipeline"`
- LightModeとして`LightweightForward`、`ShadowCaster`、`DepthOnly`、`Meta`が存在する
- 6.8.0でLightModeに`Lightweight2D`が追加された

`LightweightForward`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile _ _SHADOWS_SOFT
#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

// -------------------------------------
// Unity defined keywords
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile_fog

//--------------------------------------
// GPU Instancing
#pragma multi_compile_instancing
```

`ShadowCaster`と`DepthOnly`のシェーダーキーワード
```HLSL
//--------------------------------------
// GPU Instancing
#pragma multi_compile_instancing
```

`Meta`と`Lightweight2D`はシェーダーキーワードなし

## [7.x.x]
- SubShaderのTagsが`"RenderPipeline" = "UniversalPipeline"`に変更された
- LightModeで`LightweightForward`が`UniversalForward`に変更された
- また、`Lightweight2D`が`Universal2D`に変更された

## [9.x.x]
- multi_compile_instancingしているパスに`#pragma multi_compile _ DOTS_INSTANCING_ON`が追加された
- SubShaderのTagsに`"ShaderModel"="4.5"`が追加され、DOTS Instancing非対応のプラットフォームではフォールバックされるようになった
- `"ShaderModel"="4.5"`のシェーダーのLightModeに`UniversalGBuffer`が追加された

`UniversalGBuffer`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT

// -------------------------------------
// Unity defined keywords
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

//--------------------------------------
// GPU Instancing
#pragma multi_compile_instancing
```

## [10.x.x]
- 一部がmulti_compile_fragmentになった
- LightModeに`DepthNormals`が追加された（シェーダーキーワードはDepthOnlyと同じ）
- `_MIXED_LIGHTING_SUBTRACTIVE`が削除され`_SCREEN_SPACE_OCCLUSION`と`LIGHTMAP_SHADOW_MIXING`と`SHADOWS_SHADOWMASK`が追加された

`UniversalForward`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile_fragment _ _SHADOWS_SOFT
#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
#pragma multi_compile _ SHADOWS_SHADOWMASK
```

`UniversalGBuffer`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
#pragma multi_compile _ _SHADOWS_SOFT
#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE

// -------------------------------------
// Unity defined keywords
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT
```

## [11.x.x]
- `_MAIN_LIGHT_SHADOWS_SCREEN`が追加された
- `_MAIN_LIGHT_SHADOWS`と`_MAIN_LIGHT_SHADOWS_CASCADE`と`_MAIN_LIGHT_SHADOWS_SCREEN`がひとまとめになった
- `ShadowCaster`に`_CASTING_PUNCTUAL_LIGHT_SHADOW`が追加された（ライトの種類に応じた切り分け用）

`UniversalForward`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile_fragment _ _SHADOWS_SOFT
#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
#pragma multi_compile _ SHADOWS_SHADOWMASK
```

`ShadowCaster`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
```

## [12.x.x]
- `_REFLECTION_PROBE_BLENDING`と`_REFLECTION_PROBE_BLENDING`の追加（Built-in RPにあったものと同じ？）
- `_DBUFFER_MRT1`と`_DBUFFER_MRT2`と`_DBUFFER_MRT3`の追加（デカール）
- `_LIGHT_LAYERS`の追加
- `_LIGHT_COOKIES`の追加
- `_CLUSTERED_RENDERING`の追加
- `DEBUG_DISPLAY`の追加
- `#pragma instancing_options renderinglayer`の追加

`UniversalForward`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
#pragma multi_compile_fragment _ _SHADOWS_SOFT
#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
#pragma multi_compile_fragment _ _LIGHT_LAYERS
#pragma multi_compile_fragment _ _LIGHT_COOKIES
#pragma multi_compile _ _CLUSTERED_RENDERING

// -------------------------------------
// Unity defined keywords
#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile_fog
#pragma multi_compile_fragment _ DEBUG_DISPLAY

//--------------------------------------
// GPU Instancing
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
```

`UniversalGBuffer`のシェーダーキーワード
```HLSL
// -------------------------------------
// Universal Pipeline keywords
#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
#pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
#pragma multi_compile_fragment _ _SHADOWS_SOFT
#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
#pragma multi_compile_fragment _ _LIGHT_LAYERS
#pragma multi_compile_fragment _ _RENDER_PASS_ENABLED

// -------------------------------------
// Unity defined keywords
#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

//--------------------------------------
// GPU Instancing
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
```