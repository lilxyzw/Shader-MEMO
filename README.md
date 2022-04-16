# Shader-MEMO
Unityでのシェーダー開発に関するメモです。
VR対応やSRPへの対応、その他ハマりやすい部分などを残しておきます。

## [GrabTest.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/GrabTest.shader)
VRでGrabPassを扱う際に壊れやすい部分をまとめています。  
シェーダー内のマクロを書き換えることで動作検証できます。  
既存のシェーダーを修正する場合は以下の通りです。
- 特定の条件下で上下が逆になる  
  `ComputeScreenPos()`を`ComputeGrabScreenPos()`に置き換えることで改善されます
- 片目に両目の映像が映る  
  UNITY_SINGLE_PASS_STEREOが宣言されているときにUV座標をx軸方向に0.5倍する必要があります。  
  修正例は以下の通り
  ```
  #if defined(UNITY_SINGLE_PASS_STEREO)
      uv.x *= 0.5;
  #endif
  ```
- Unity 2020以降から灰色になる  
  テクスチャを宣言している箇所を`UNITY_DECLARE_SCREENSPACE_TEXTURE(tex)`、サンプリングしている箇所を`UNITY_SAMPLE_SCREENSPACE_TEXTURE(tex,uv)`に置き換えることで改善されます。

## [Universal Render Pipeline Litの変遷.md](https://github.com/lilxyzw/Shader-MEMO/blob/main/Docs/Universal%20Render%20Pipeline%20Lit%E3%81%AE%E5%A4%89%E9%81%B7.md) / [HDRP Litの変遷.md](https://github.com/lilxyzw/Shader-MEMO/blob/main/Docs/HDRP%20Lit%E3%81%AE%E5%A4%89%E9%81%B7.md)
lilToonの開発に関わった箇所をまとめました。  
URP/HDRPのシェーダーを書けることが前提で、複数バージョンに対応させる際の資料です。  
流石に細かい変数・関数の変化までは追いきれておらず、シェーダーキーワードやLightModeなどざっくりした部分のみのまとめなので、各バージョンでテストしてエラーや不具合が出たらマクロで切り分ける必要があります。  
バージョンは`VERSION_GREATER_EQUAL(major, minor)`などのマクロで取れます。

## [SHLightTester.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/SHLightTester.shader)
SHライトの挙動や原理確認用のシェーダーです。  
通常はShadeSH9に法線を渡すだけで良いため詳しく理解する必要がないですが、トゥーンシェーダーではSHライトの陰影を付けたくない場合が多いためそのまま扱えません。  
そこで原理を知っておくことでSHライトをどうデフォルメするかを考える材料になるかもしれません。

## [GeomTest.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/GeomTest.shader)
ジオメトリシェーダーを使って1パスでアウトラインを描画したら逆に負荷が高くなったので色々テストしてみたシェーダーです。  
結論としては本体->アウトラインの順に描画していたためZTestが効き、アウトライン側のピクセルシェーダーの負荷が抑えられたことが大きそうでした。  
ここではGPU負荷のみ検証しているのと、（特にモバイルでは）環境による差がある可能性もあるため、実際の環境でテストして確認してください。  
適当なテクスチャを入れたマテリアルを作成してCubeメッシュに適用し、Profilerで測定した結果は以下の通りです。
- ジオメトリシェーダー方式: 0.11ms
- 2パス（アウトライン->本体）: 0.16ms
- 2パス（本体->アウトライン）: 0.06ms
- 本体のみ（ジオメトリシェーダー使用）: 0.05ms
- 本体のみ: 0.05ms

約56000 tris、SetPass Calls 4（アウトラインを含めると8）のキャラクターモデルをカメラを1.5m程離して測定した結果は以下の通りです。
- ジオメトリシェーダー方式: 0.31ms
- 2パス（アウトライン->本体）: 0.36ms
- 2パス（本体->アウトライン）: 0.26ms
- 本体のみ（ジオメトリシェーダー使用）: 0.19ms
- 本体のみ: 0.18ms

100m程離れ、ほぼピクセルシェーダーが実行されないような状態では以下の通りです。  
ピクセルシェーダー程ではありませんが、ジオメトリシェーダーもある程度負荷に影響があります。
- ジオメトリシェーダー方式: 0.08ms
- 2パス（アウトライン->本体）: 0.03ms
- 2パス（本体->アウトライン）: 0.03ms
- 本体のみ（ジオメトリシェーダー使用）: 0.05ms
- 本体のみ: 0.01ms

## [ステンシルについて.md](https://github.com/lilxyzw/Shader-MEMO/blob/main/Docs/ステンシルについて.md)
ステンシルについての簡単な解説です。

## [SPSITest.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/SPSITest.shader)
SPS-I（Single-Pass Stereo Instanced）対応についてまとめました。

## [84-Shader__VR Unlit Shader-NewUnlitShader.shader.txt](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/ScriptTemplates/84-Shader__VR%20Unlit%20Shader-NewUnlitShader.shader.txt)
新規作成したUnlit ShaderはSPS-I環境ではうまく動作せず書き換えが必要になります。そこで、SPS-I対応済みのUnlit Shaderのテンプレートを作りました。以下の手順で導入できます。
1. `Assets`直下に`ScriptTemplates`フォルダを作成
2. `ScriptTemplates`内にこのtxtファイルを配置
3. Unityを再起動
4. `Create - Shader - VR Unlit Shader`でこのテンプレートから作成可能になる

## [StencilChecker.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/StencilChecker.shader)
ステンシルバッファを可視化します。

## [DepthTex2PosWS.shader](https://github.com/lilxyzw/Shader-MEMO/blob/main/Assets/DepthTex2PosWS.shader)
`_CameraDepthTexture`と`SV_POSITION`からワールド座標を復元するシェーダーです。