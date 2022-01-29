# Shader-MEMO
Unityでのシェーダー開発に関するメモです。
VR対応やSRPへの対応、その他ハマりやすい部分などを残しておきます。

## [GrabTest.shader](https://github.com/lilxyzw/Shader-MEMO/blob/master/Assets/GrabTest.shader)
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