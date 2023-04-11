
HEADER
{
	Description = "";
}

FEATURES
{
	#include "vr_common_features.fxc"
	Feature( F_ADDITIVE_BLEND, 0..1, "Blending" );
}

COMMON
{
#ifndef S_ALPHA_TEST
#define S_ALPHA_TEST 1
#endif
#ifndef S_TRANSLUCENT
#define S_TRANSLUCENT 0
#endif

	#include "common/shared.hlsl"

	#define S_UV2 1
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );
		return FinalizeVertex( o );
	}
}

PS
{
	#include "sbox_pixel.fxc"
	#include "common/pixel.material.structs.hlsl"
	#include "common/pixel.lighting.hlsl"
	#include "common/pixel.shading.hlsl"
	#include "common/pixel.material.helpers.hlsl"
	#include "common/pixel.color.blending.hlsl"
	#include "common/proceedural.hlsl"

	SamplerState g_sSampler0 < Filter( ANISO ); AddressU( WRAP ); AddressV( WRAP ); >;
	CreateInputTexture2D( Diffuse, Srgb, 8, "None", "_color", "Textures,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( EmissionMap, Srgb, 8, "None", "_color", "Textures,0/,0/4", Default4( 0.00, 0.00, 0.00, 1.00 ) );
	CreateInputTexture2D( AlphaMask, Srgb, 8, "None", "_color", "Textures,0/,0/5", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Normal, Linear, 8, "None", "_normal", "Textures,0/,0/2", Default4( 0.50, 0.50, 1.00, 1.00 ) );
	CreateInputTexture2D( DetailNormal, Linear, 8, "None", "_normal", "Textures,0/,0/3", Default4( 0.50, 0.50, 1.00, 1.00 ) );
	CreateInputTexture2D( MRC, Linear, 8, "None", "_color", "Textures,0/,0/1", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateTexture2DWithoutSampler( g_tDiffuse ) < Channel( RGBA, Box( Diffuse ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	CreateTexture2DWithoutSampler( g_tEmissionMap ) < Channel( RGBA, Box( EmissionMap ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	CreateTexture2DWithoutSampler( g_tAlphaMask ) < Channel( RGBA, Box( AlphaMask ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	CreateTexture2DWithoutSampler( g_tNormal ) < Channel( RGBA, Box( Normal ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	CreateTexture2DWithoutSampler( g_tDetailNormal ) < Channel( RGBA, Box( DetailNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	CreateTexture2DWithoutSampler( g_tMRC ) < Channel( RGBA, Box( MRC ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	float4 g_vEmissionColor < UiType( Color ); UiGroup( "Parameters,0/Emission,0/0" ); Default4( 0.00, 0.00, 0.00, 1.00 ); >;
	float g_flEmissionStrength < UiGroup( "Parameters,0/Emission,0/0" ); Default1( 1 ); Range1( 0, 10 ); >;
	bool g_bUseDiffuseAlpha < UiGroup( "Parameters,0/Alpha,0/0" ); Default( 0 ); >;
	float g_flDetailNormalScale < UiGroup( "Parameters,0/Normal,0/0" ); Default1( 5 ); Range1( 0, 100 ); >;
	float g_flDetailNormalFactor < UiGroup( "Parameters,0/Normal,0/0" ); Default1( 0 ); Range1( 0, 1 ); >;

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m;
		m.Albedo = float3( 1, 1, 1 );
		m.Normal = TransformNormal( i, float3( 0, 0, 1 ) );
		m.Roughness = 1;
		m.Metalness = 0;
		m.AmbientOcclusion = 1;
		m.TintMask = 1;
		m.Opacity = 1;
		m.Emission = float3( 0, 0, 0 );
		m.Transmission = 0;

		float2 local0 = i.vTextureCoords.xy * float2( 1, 1 );
		float4 local1 = Tex2DS( g_tDiffuse, g_sSampler0, local0 );
		float4 local2 = g_vEmissionColor;
		float local3 = g_flEmissionStrength;
		float4 local4 = Tex2DS( g_tEmissionMap, g_sSampler0, local0 );
		float local5 = local4.x;
		float local6 = local3 * local5;
		float4 local7 = local2 * float4( local6, local6, local6, local6 );
		float4 local8 = local7 * float4( 10, 10, 10, 10 );
		float4 local9 = Tex2DS( g_tAlphaMask, g_sSampler0, local0 );
		float local10 = local9.x;
		float local11 = g_bUseDiffuseAlpha ? local1.a : local10;
		float4 local12 = Tex2DS( g_tNormal, g_sSampler0, local0 );
		float local13 = g_flDetailNormalScale;
		float2 local14 = TileAndOffsetUv( local0, float2( local13, local13 ), float2( 0, 0 ) );
		float4 local15 = Tex2DS( g_tDetailNormal, g_sSampler0, local14 );
		float local16 = g_flDetailNormalFactor;
		float4 local17 = saturate( lerp( local12, Overlay_blend( local12, local15 ), local16 ) );
		float local18 = local17.x;
		float local19 = local17.y;
		float local20 = 1 - local19;
		float local21 = local17.z;
		float local22 = local17.w;
		float4 local23 = float4( local18, local20, local21, local22 );
		float3 local24 = TransformNormal( i, DecodeNormal( local23.xyz ) );
		float4 local25 = Tex2DS( g_tMRC, g_sSampler0, local0 );
		float local26 = local25.y;
		float local27 = 1 - local26;
		float local28 = local25.x;
		float local29 = local25.z;

		m.Albedo = local1.xyz;
		m.Emission = local8.xyz;
		m.Opacity = local11;
		m.Normal = local24;
		m.Roughness = local27;
		m.Metalness = local28;
		m.AmbientOcclusion = local29;

		m.AmbientOcclusion = saturate( m.AmbientOcclusion );
		m.Roughness = saturate( m.Roughness );
		m.Metalness = saturate( m.Metalness );
		m.Opacity = saturate( m.Opacity );
		
		ShadingModelValveStandard sm;
		return FinalizePixelMaterial( i, m, sm );
	}
}
