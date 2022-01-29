# 開発メモ（HDRP/Litの変遷）
lilToonの開発に関わった部分のみメモ  
詳細は[Unity-Technologies / Graphics](https://github.com/Unity-Technologies/Graphics)を参照  
コンパイルエラー対策のマクロは[lil_common_macro.hlsl](https://github.com/lilxyzw/lilToon/blob/master/Assets/lilToon/Shader/Includes/lil_common_macro.hlsl)を参照

## 要約
トゥーンシェーダーとして実装するならForwardレンダリング、つまり`DepthForwardOnly`、`ForwardOnly`を使用すれば良い。
必要なLightModeをまとめると以下の通り
- `ForwardOnly`
- `DepthForwardOnly`
- `ShadowCaster`
- `MotionVectors`
- `Meta`
アウトラインなどマルチパスしたい場合は`SRPDefaultUnlit`を利用可能。
`SceneSelectionPass`、`Picking`、`DistortionVectors`は任意で実装で良さそう。
レイトレーシングはトゥーンシェーダーとの親和性が悪そうなのでUnlitにフォールバックするといいかもしれない。

## [4.x.x]
- 現在のパスに変更された
- SubShaderのTagsは`"RenderPipeline" = "HDRenderPipeline"`と`"RenderType" = "HDLitShader"`
- Lit・Unlit共通のLightModeとして`SceneSelectionPass`、`MotionVectors`、`Meta`、`DistortionVectors`が存在する
- Unlit特有のLightModeとしては`DepthForwardOnly`、`ForwardOnly`が存在する
- Lit特有のLightModeとして`GBuffer`、`ShadowCaster`、`DepthOnly`、`TransparentDepthPrepass`、`TransparentBackface`、`Forward`、`TransparentDepthPostpass`が存在する

共通のシェーダーキーワード
```HLSL
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
```

`SceneSelectionPass`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#define SCENESELECTIONPASS
```

`GBuffer`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_GBUFFER
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile _ LIGHT_LAYERS
```

`Meta`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_LIGHT_TRANSPORT
```

`ShadowCaster`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_SHADOWS
#define USE_LEGACY_UNITY_MATRIX_VARIABLES
```

`DepthOnly`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile _ WRITE_MSAA_DEPTH
```

`MotionVectors`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_VELOCITY
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile _ WRITE_MSAA_DEPTH
```

`DistortionVectors`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DISTORTION
```

`TransparentDepthPrepass`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#define CUTOFF_TRANSPARENT_DEPTH_PREPASS
```

`TransparentBackface`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define LIGHTLOOP_TILE_PASS
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
#pragma multi_compile DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
#pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
```

`Forward`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define LIGHTLOOP_TILE_PASS
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile PUNCTUAL_SHADOW_LOW PUNCTUAL_SHADOW_MEDIUM PUNCTUAL_SHADOW_HIGH
#pragma multi_compile DIRECTIONAL_SHADOW_LOW DIRECTIONAL_SHADOW_MEDIUM DIRECTIONAL_SHADOW_HIGH
#pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
```

`TransparentDepthPostpass`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#define CUTOFF_TRANSPARENT_DEPTH_POSTPASS
```

`DepthForwardOnly`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#pragma multi_compile _ WRITE_MSAA_DEPTH
```

`ForwardOnly`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD_UNLIT
#pragma multi_compile _ DEBUG_DISPLAY
```

## [5.x.x]
- DXR（レイトレーシング）対応が追加された
- それに伴ってLightModeに`IndirectDXR`、`ForwardDXR`、`VisibilityDXR`が追加された
- シェーダーキーワードの`PUNCTUAL_SHADOW_`と`DIRECTIONAL_SHADOW_`が`SHADOW_`に統合された、また`VERY_HIGH`が追加された
- レイトレーシングシェーダーは`#pragma raytracing Raytracing`のような形で記述する

`TransparentBackface`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH
#define USE_CLUSTERED_LIGHTLIST
```

`Forward`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH
#pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
```

`IndirectDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_INDIRECT
#define SKIP_RASTERIZED_SHADOWS
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ DIFFUSE_LIGHTING_ONLY
```

`ForwardDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_FORWARD
#define SKIP_RASTERIZED_SHADOWS
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
```

`VisibilityDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_VISIBILITY
```

## [6.x.x]
- `SceneSelectionPass`に`#pragma editor_sync_compilation`が追加された

## [7.x.x]
- `#pragma multi_compile_instancing`と`#pragma instancing_options renderinglayer`が各パスごとになる
- Unlitにも`ShadowCaster`が追加された
- LightModeに`GBufferDXR`、`SubSurfaceDXR`、`PathTracingDXR`が追加された（`SubSurfaceDXR`はLitのみ）
- DXRシェーダーのシェーダーキーワードに`DEBUG_DISPLAY`、`MULTI_BOUNCE_INDIRECT`が追加された

`IndirectDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_INDIRECT
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ DIFFUSE_LIGHTING_ONLY
#pragma multi_compile _ MULTI_BOUNCE_INDIRECT
```

`ForwardDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_FORWARD
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
```

`GBufferDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_GBUFFER
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ DIFFUSE_LIGHTING_ONLY
```

`VisibilityDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_VISIBILITY
#pragma multi_compile _ TRANSPARENT_COLOR_SHADOW
```

`SubSurfaceDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_SUB_SURFACE
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ DIFFUSE_LIGHTING_ONLY
```

`PathTracingDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_PATH_TRACING
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
```

## [9.x.x]
- multi_compile_instancingしているパスに`#pragma multi_compile _ DOTS_INSTANCING_ON`が追加された
- LightModeに`RayTracingPrepass`が追加された
- DXRシェーダーから`DYNAMICLIGHTMAP_ON`と`DIFFUSE_LIGHTING_ONLY`が削除された

`PathTracingDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_CONSTANT
```

`IndirectDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_INDIRECT
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ MULTI_BOUNCE_INDIRECT
```

`ForwardDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_FORWARD
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
```

`GBufferDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_GBUFFER
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
```

`SubSurfaceDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_SUB_SURFACE
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
```

## [10.x.x]
- LightModeに`Picking`が追加された
- シェーダーキーワードに`WRITE_DECAL_BUFFER`、`SCREEN_SPACE_SHADOWS_OFF`、`SCREEN_SPACE_SHADOWS_ON`、`MINIMAL_GBUFFER`が追加された

`Picking`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#define SCENEPICKINGPASS
#pragma editor_sync_compilation
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
```

`DepthOnly`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile _ WRITE_DECAL_BUFFER
#pragma multi_compile _ WRITE_MSAA_DEPTH
```

`MotionVectors`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_MOTION_VECTORS
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile _ WRITE_DECAL_BUFFER
#pragma multi_compile _ WRITE_MSAA_DEPTH
```

`TransparentDepthPrepass`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_TRANSPARENT_DEPTH_PREPASS
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
```

`TransparentBackface`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define HAS_LIGHTLOOP
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile SCREEN_SPACE_SHADOWS_OFF SCREEN_SPACE_SHADOWS_ON
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH
#define USE_CLUSTERED_LIGHTLIST
```

`Forward`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define HAS_LIGHTLOOP
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile _ SHADOWS_SHADOWMASK
#pragma multi_compile SCREEN_SPACE_SHADOWS_OFF SCREEN_SPACE_SHADOWS_ON
#pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH
#pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
```

`FullScreenDebug`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FULL_SCREEN_DEBUG
```

`GBufferDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_GBUFFER
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ MINIMAL_GBUFFER
```

## [12.x.x]
- 一部がmulti_compile_fragmentになった
- シェーダーキーワードに`PROBE_VOLUMES_OFF`、`PROBE_VOLUMES_L1`、`PROBE_VOLUMES_L2`、`DECAL_SURFACE_GRADIENT`が追加された
- DXRシェーダーの`DYNAMICLIGHTMAP_ON`が復活

`GBuffer`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_GBUFFER
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile_fragment _ SHADOWS_SHADOWMASK
#pragma multi_compile_fragment PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile_fragment DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile_fragment _ DECAL_SURFACE_GRADIENT
#pragma multi_compile_fragment _ LIGHT_LAYERS
```

`DepthOnly`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_DEPTH_ONLY
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile_fragment _ WRITE_MSAA_DEPTH
#pragma multi_compile _ WRITE_DECAL_BUFFER
```

`MotionVectors`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_MOTION_VECTORS
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ WRITE_NORMAL_BUFFER
#pragma multi_compile_fragment _ WRITE_MSAA_DEPTH
#pragma multi_compile _ WRITE_DECAL_BUFFER
```

`TransparentBackface`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define HAS_LIGHTLOOP
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile_fragment _ SHADOWS_SHADOWMASK
#pragma multi_compile_fragment PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile_fragment SCREEN_SPACE_SHADOWS_OFF SCREEN_SPACE_SHADOWS_ON
#pragma multi_compile_fragment DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile_fragment _ DECAL_SURFACE_GRADIENT
#pragma multi_compile_fragment SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH
#ifndef SHADER_STAGE_FRAGMENT
    #define SHADOW_LOW
#endif
```

`Forward`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_FORWARD
#define HAS_LIGHTLOOP
#pragma multi_compile_instancing
#pragma instancing_options renderinglayer
#pragma multi_compile _ DOTS_INSTANCING_ON
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile_fragment _ SHADOWS_SHADOWMASK
#pragma multi_compile_fragment PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile_fragment SCREEN_SPACE_SHADOWS_OFF SCREEN_SPACE_SHADOWS_ON
#pragma multi_compile_fragment DECALS_OFF DECALS_3RT DECALS_4RT
#pragma multi_compile_fragment _ DECAL_SURFACE_GRADIENT
#pragma multi_compile_fragment SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH
#pragma multi_compile_fragment USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST
#ifndef SHADER_STAGE_FRAGMENT
    #define SHADOW_LOW
    #define USE_FPTL_LIGHTLIST
#endif
```

`IndirectDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_INDIRECT
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile _ MULTI_BOUNCE_INDIRECT
```

`ForwardDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_FORWARD
#define SHADOW_LOW
#define HAS_LIGHTLOOP
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
```

`GBufferDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_GBUFFER
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
#pragma multi_compile _ MINIMAL_GBUFFER
```

`SubSurfaceDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_RAYTRACING_SUB_SURFACE
#pragma multi_compile _ DEBUG_DISPLAY
#pragma multi_compile _ LIGHTMAP_ON
#pragma multi_compile _ DYNAMICLIGHTMAP_ON
#pragma multi_compile PROBE_VOLUMES_OFF PROBE_VOLUMES_L1 PROBE_VOLUMES_L2
#pragma multi_compile _ DIRLIGHTMAP_COMBINED
```

`PathTracingDXR`のシェーダーキーワード
```HLSL
#define SHADERPASS SHADERPASS_PATH_TRACING
#pragma multi_compile _ DEBUG_DISPLAY
```