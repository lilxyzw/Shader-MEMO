Shader "Unlit/CustomSampler"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [ToggleUI] _IsCustom ("Use Custom Function", Int) = 1
        [Enum(Point,0, Bilinear,20, Trilinear,21)] _Filter ("Filter", Int) = 0
        [Enum(Wrap,1, Mirror,2, Clamp,3, Border,4, MirrorOnce,5)] _AddressU ("AddressU", Int) = 1
        [Enum(Wrap,1, Mirror,2, Clamp,3, Border,4, MirrorOnce,5)] _AddressV ("AddressV", Int) = 1
        //[Enum(Wrap,1, Mirror,2, Clamp,3, Border,4, MirrorOnce,5)] _AddressW ("[not yet] AddressW", Int) = 1
        _MipLODBias ("MipLODBias", Float) = 0
        //[IntRange] _MaxAnisotropy ("[not yet] MaxAnisotropy", Range(0,16)) = 1
        //_ComparisonFunc ("[not yet] ComparisonFunc", Int) = 1
        _BorderColor ("Border Color", Color) = (0,0,0,0)
        //_MinLOD ("[not yet] MipLODBias", Float) = 0
        //_MaxLOD ("[not yet] MipLODBias", Float) = 0
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            Texture2D _MainTex;
            SamplerState sampler_MainTex;
            float4 _MainTex_ST;
            bool _IsCustom;

            uint _Filter;
            uint _AddressU;
            uint _AddressV;
            uint _AddressW;
            float _MipLODBias;
            uint _MaxAnisotropy;
            uint _ComparisonFunc;
            float4 _BorderColor;
            float _MinLOD;
            float _MaxLOD;

            // enum はプリプロセッサで代用

            // [未使用] 補間の種類
            // minification、magnification、mip-levelでそれぞれ線形補間するか否かを決められるがUnityでは4つにまとめられている
            // 以下は推測で実際に確認したわけではないため注意
            // Point: D3D11_FILTER_MIN_MAG_MIP_POINT
            // Bilinear: D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT
            // Trilinear: D3D11_FILTER_MIN_MAG_MIP_LINEAR
            // Aniso Level > 0: D3D11_FILTER_ANISOTROPIC
            // https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_filter
            //typedef enum D3D11_FILTER {
                #define D3D11_FILTER_MIN_MAG_MIP_POINT 0
                #define D3D11_FILTER_MIN_MAG_POINT_MIP_LINEAR 0x1
                #define D3D11_FILTER_MIN_POINT_MAG_LINEAR_MIP_POINT 0x4
                #define D3D11_FILTER_MIN_POINT_MAG_MIP_LINEAR 0x5
                #define D3D11_FILTER_MIN_LINEAR_MAG_MIP_POINT 0x10
                #define D3D11_FILTER_MIN_LINEAR_MAG_POINT_MIP_LINEAR 0x11
                #define D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT 0x14
                #define D3D11_FILTER_MIN_MAG_MIP_LINEAR 0x15
                #define D3D11_FILTER_ANISOTROPIC 0x55
                #define D3D11_FILTER_COMPARISON_MIN_MAG_MIP_POINT 0x80
                #define D3D11_FILTER_COMPARISON_MIN_MAG_POINT_MIP_LINEAR 0x81
                #define D3D11_FILTER_COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT 0x84
                #define D3D11_FILTER_COMPARISON_MIN_POINT_MAG_MIP_LINEAR 0x85
                #define D3D11_FILTER_COMPARISON_MIN_LINEAR_MAG_MIP_POINT 0x90
                #define D3D11_FILTER_COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR 0x91
                #define D3D11_FILTER_COMPARISON_MIN_MAG_LINEAR_MIP_POINT 0x94
                #define D3D11_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR 0x95
                #define D3D11_FILTER_COMPARISON_ANISOTROPIC 0xd5
                #define D3D11_FILTER_MINIMUM_MIN_MAG_MIP_POINT 0x100
                #define D3D11_FILTER_MINIMUM_MIN_MAG_POINT_MIP_LINEAR 0x101
                #define D3D11_FILTER_MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT 0x104
                #define D3D11_FILTER_MINIMUM_MIN_POINT_MAG_MIP_LINEAR 0x105
                #define D3D11_FILTER_MINIMUM_MIN_LINEAR_MAG_MIP_POINT 0x110
                #define D3D11_FILTER_MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR 0x111
                #define D3D11_FILTER_MINIMUM_MIN_MAG_LINEAR_MIP_POINT 0x114
                #define D3D11_FILTER_MINIMUM_MIN_MAG_MIP_LINEAR 0x115
                #define D3D11_FILTER_MINIMUM_ANISOTROPIC 0x155
                #define D3D11_FILTER_MAXIMUM_MIN_MAG_MIP_POINT 0x180
                #define D3D11_FILTER_MAXIMUM_MIN_MAG_POINT_MIP_LINEAR 0x181
                #define D3D11_FILTER_MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT 0x184
                #define D3D11_FILTER_MAXIMUM_MIN_POINT_MAG_MIP_LINEAR 0x185
                #define D3D11_FILTER_MAXIMUM_MIN_LINEAR_MAG_MIP_POINT 0x190
                #define D3D11_FILTER_MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR 0x191
                #define D3D11_FILTER_MAXIMUM_MIN_MAG_LINEAR_MIP_POINT 0x194
                #define D3D11_FILTER_MAXIMUM_MIN_MAG_MIP_LINEAR 0x195
                #define D3D11_FILTER_MAXIMUM_ANISOTROPIC 0x1d5
            //};

            // ビット演算用メモ
            // Mip 000000001   1
            // Mag 000000100   4
            // Min 000010000  16
            // Ani 001010101  85
            // Com 010000000 128
            // Min 100000000 256
            // Max 110000000 384

            // タイリングの種類
            // https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_texture_address_mode
            //typedef enum D3D11_TEXTURE_ADDRESS_MODE {
                #define D3D11_TEXTURE_ADDRESS_WRAP 1
                #define D3D11_TEXTURE_ADDRESS_MIRROR 2
                #define D3D11_TEXTURE_ADDRESS_CLAMP 3
                #define D3D11_TEXTURE_ADDRESS_BORDER 4
                #define D3D11_TEXTURE_ADDRESS_MIRROR_ONCE 5
            //};

            // [未使用] 比較の種類
            // ComparisonFuncの型
            // https://learn.microsoft.com/en-us/windows/win32/api/d3d11/ne-d3d11-d3d11_comparison_func
            //typedef enum D3D11_COMPARISON_FUNC {
                #define D3D11_COMPARISON_NEVER 1
                #define D3D11_COMPARISON_LESS 2
                #define D3D11_COMPARISON_EQUAL 3
                #define D3D11_COMPARISON_LESS_EQUAL 4
                #define D3D11_COMPARISON_GREATER 5
                #define D3D11_COMPARISON_NOT_EQUAL 6
                #define D3D11_COMPARISON_GREATER_EQUAL 7
                #define D3D11_COMPARISON_ALWAYS 8
            //} ;

            // SamplerStateの代替
            // https://learn.microsoft.com/ja-jp/windows/win32/api/d3d11/ns-d3d11-d3d11_sampler_desc
            struct SamplerDesc
            {
                uint Filter;
                uint AddressU;
                uint AddressV;
                uint AddressW;
                float MipLODBias;
                uint MaxAnisotropy;
                uint ComparisonFunc;
                float4 BorderColor;
                float MinLOD;
                float MaxLOD;
            };

            // MipLevelの計算
            // GPUの設定依存で完全には一致しない
            // OpenGL 4.2 (Core Profile) - 3.9.11 Texture Minification
            // https://registry.khronos.org/OpenGL/specs/gl/glspec42.core.pdf
            float CalculateMipLevel(float2 uv, float2 size, uint levels, float bias = 0)
            {
                float2 dx = ddx(uv * size);
                float2 dy = ddy(uv * size);
                float dmax = max(dot(dx,dx), dot(dy,dy));
                float mip = log2(dmax) * 0.5 + 0.5 + bias;
                return clamp(mip, 0, levels - 0.5);
            }

            // AddressModeを適用したUVに変換
            float ApplyAddressMode(float uv, uint address, float maxcoord)
            {
                UNITY_FLATTEN
                switch(address)
                {
                    case D3D11_TEXTURE_ADDRESS_WRAP        : return clamp(frac(uv), 0, maxcoord);
                    case D3D11_TEXTURE_ADDRESS_MIRROR      : return clamp(abs(frac(uv * 0.5 + 0.5) * 2 - 1), 0, maxcoord);
                    case D3D11_TEXTURE_ADDRESS_CLAMP       : return clamp(uv, 0, maxcoord);
                    //case D3D11_TEXTURE_ADDRESS_BORDER      : return uv;
                    case D3D11_TEXTURE_ADDRESS_MIRROR_ONCE : return clamp(abs(uv), 0, maxcoord);
                    default                                : return uv;
                }
            }

            float2 ApplyAddressMode(SamplerDesc desc, float2 uv, float2 maxcoord)
            {
                uv.x = ApplyAddressMode(uv.x, desc.AddressU, maxcoord.x);
                uv.y = ApplyAddressMode(uv.y, desc.AddressV, maxcoord.y);
                return uv;
            }

            // 各FilterModeで使用するテクスチャのロード用の関数
            // UVが範囲外にならないようにAddressModeをここで適用する
            float4 SampleBase(Texture2D tex, SamplerDesc desc, float2 uv, uint mipI, float2 mipsize, float2 maxcoord)
            {
                float2 sampleUV = ApplyAddressMode(desc, uv, maxcoord);
                return
                    sampleUV.x < 0 | sampleUV.y < 0 | sampleUV.x > maxcoord.x | sampleUV.y > maxcoord.y ?
                    desc.BorderColor :
                    tex.mips[mipI][(uint2)(sampleUV * mipsize)];
            }

            // 最も近い1つのテクセルをサンプリング
            float4 SamplePoint(Texture2D tex, SamplerDesc desc, float2 uv, float mip, float2 size)
            {
                uint mipI = mip;
                float2 mipsize = size / pow(2,mipI);
                float2 texel = rcp(mipsize);
                float2 maxcoord = 1-texel;
                return SampleBase(tex, desc, uv, mipI, mipsize, maxcoord);
            }

            // 隣接する4つのテクセルをサンプリングして線形補間
            float4 SampleBilinear(Texture2D tex, SamplerDesc desc, float2 uv, float mip, float2 size)
            {
                uint mipI = mip;
                float2 mipsize = size / pow(2,mipI);
                float2 texel = rcp(mipsize);
                float2 maxcoord = 1-texel;
                float2 bary = frac(uv * mipsize - 0.5);
                float4 c00 = SampleBase(tex, desc, uv + texel * float2(-0.5,-0.5), mipI, mipsize, maxcoord);
                float4 c10 = SampleBase(tex, desc, uv + texel * float2( 0.5,-0.5), mipI, mipsize, maxcoord);
                float4 c01 = SampleBase(tex, desc, uv + texel * float2(-0.5, 0.5), mipI, mipsize, maxcoord);
                float4 c11 = SampleBase(tex, desc, uv + texel * float2( 0.5, 0.5), mipI, mipsize, maxcoord);
                return lerp(
                    lerp(c00, c10, bary.x),
                    lerp(c01, c11, bary.x),
                    bary.y
                );
            }

            // 2つのMipLevelでBilinearサンプリングして線形補間
            float4 SampleTrilinear(Texture2D tex, SamplerDesc desc, float2 uv, float mip, float2 size)
            {
                float bary = frac(mip - 0.5);
                float4 c0 = SampleBilinear(tex, desc, uv, mip - 0.5, size);
                float4 c1 = SampleBilinear(tex, desc, uv, mip + 0.5, size);
                return lerp(c0, c1, bary);
            }

            // tex.Sample(sampler,uv) の代替
            float4 CustomSample(Texture2D tex, SamplerDesc desc, float2 uv)
            {
                float2 size;
                uint NumberOfLevels;
                tex.GetDimensions(
                    0,
                    size.x,
                    size.y,
                    NumberOfLevels
                );

                float mip = CalculateMipLevel(uv, size, NumberOfLevels, desc.MipLODBias);

                UNITY_BRANCH
                switch(desc.Filter)
                {
                    //case D3D11_FILTER_MIN_MAG_MIP_POINT         : return SamplePoint(tex, desc, uv, mip, size);
                    case D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT  : return SampleBilinear(tex, desc, uv, mip, size);
                    case D3D11_FILTER_MIN_MAG_MIP_LINEAR        : return SampleTrilinear(tex, desc, uv, mip, size);
                    default                                     : return SamplePoint(tex, desc, uv, mip, size);
                }
            }

            // ここから下は普通のUnlitシェーダー
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                if(!_IsCustom) return _MainTex.SampleBias(sampler_MainTex, i.uv, _MipLODBias);

                SamplerDesc desc = (SamplerDesc)0;
                desc.Filter = _Filter;
                desc.AddressU = _AddressU;
                desc.AddressV = _AddressV;
                desc.AddressW = _AddressW;
                desc.MipLODBias = _MipLODBias;
                desc.MaxAnisotropy = _MaxAnisotropy;
                desc.ComparisonFunc = _ComparisonFunc;
                desc.BorderColor = _BorderColor;
                desc.MinLOD = _MinLOD;
                desc.MaxLOD = _MaxLOD;
                return CustomSample(_MainTex, desc, i.uv);
            }
            ENDCG
        }
    }
}
