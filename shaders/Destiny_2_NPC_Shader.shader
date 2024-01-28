
HEADER
{
	Description = "";
}

FEATURES
{
	#include "common/features.hlsl"
}

MODES
{
	VrForward();
	Depth(); 
	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "tools_shading_complexity.shader" );
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
	#include "procedural.hlsl"

	#define S_UV2 1
	#define CUSTOM_MATERIAL_INPUTS
}

struct VertexInput
{
	#include "common/vertexinput.hlsl"
	float4 vColor : COLOR0 < Semantic( Color ); >;
};

struct PixelInput
{
	#include "common/pixelinput.hlsl"
	float3 vPositionOs : TEXCOORD14;
	float3 vNormalOs : TEXCOORD15;
	float4 vTangentUOs_flTangentVSign : TANGENT	< Semantic( TangentU_SignV ); >;
	float4 vColor : COLOR0;
};

VS
{
	#include "common/vertex.hlsl"

	PixelInput MainVs( VertexInput v )
	{
		PixelInput i = ProcessVertex( v );
		i.vPositionOs = v.vPositionOs.xyz;
		i.vColor = v.vColor;

		VS_DecodeObjectSpaceNormalAndTangent( v, i.vNormalOs, i.vTangentUOs_flTangentVSign );

		return FinalizeVertex( i );
	}
}

PS
{
	#include "common/pixel.hlsl"
	
	SamplerState g_sSampler0 < Filter( ANISO ); AddressU( WRAP ); AddressV( WRAP ); >;
	CreateInputTexture2D( Diffuse, Srgb, 8, "None", "_color", "Textures,0/,0/0", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( EmissionMap, Srgb, 8, "None", "_color", "Textures,0/,0/4", Default4( 0.00, 0.00, 0.00, 1.00 ) );
	CreateInputTexture2D( AlphaMask, Srgb, 8, "None", "_color", "Textures,0/,0/5", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	CreateInputTexture2D( Normal, Linear, 8, "None", "_normal", "Textures,0/,0/2", Default4( 0.50, 0.50, 1.00, 1.00 ) );
	CreateInputTexture2D( DetailNormal, Linear, 8, "None", "_normal", "Textures,0/,0/3", Default4( 0.50, 0.50, 1.00, 1.00 ) );
	CreateInputTexture2D( MRC, Linear, 8, "None", "_color", "Textures,0/,0/1", Default4( 1.00, 1.00, 1.00, 1.00 ) );
	Texture2D g_tDiffuse < Channel( RGBA, Box( Diffuse ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	Texture2D g_tEmissionMap < Channel( RGBA, Box( EmissionMap ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	Texture2D g_tAlphaMask < Channel( RGBA, Box( AlphaMask ), Srgb ); OutputFormat( BC7 ); SrgbRead( True ); >;
	Texture2D g_tNormal < Channel( RGBA, Box( Normal ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	Texture2D g_tDetailNormal < Channel( RGBA, Box( DetailNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	Texture2D g_tMRC < Channel( RGBA, Box( MRC ), Linear ); OutputFormat( BC7 ); SrgbRead( False ); >;
	float4 g_vEmissionColor < UiType( Color ); UiGroup( "Parameters,0/Emission,0/0" ); Default4( 0.00, 0.00, 0.00, 1.00 ); >;
	float g_flEmissionStrength < UiGroup( "Parameters,0/Emission,0/0" ); Default1( 1 ); Range1( 0, 10 ); >;
	bool g_bUseDiffuseAlpha < UiGroup( "Parameters,0/Alpha,0/0" ); Default( 0 ); >;
	float g_flDetailNormalScale < UiGroup( "Parameters,0/Normal,0/0" ); Default1( 5 ); Range1( 0, 100 ); >;
	float g_flDetailNormalFactor < UiGroup( "Parameters,0/Normal,0/0" ); Default1( 0 ); Range1( 0, 1 ); >;
		
	float Overlay_blend( float a, float b )
	{
	    if ( a <= 0.5f )
	        return 2.0f * a * b;
	    else
	        return 1.0f - 2.0f * ( 1.0f - a ) * ( 1.0f - b );
	}
	
	float3 Overlay_blend( float3 a, float3 b )
	{
	    return float3(
	        Overlay_blend( a.r, b.r ),
	        Overlay_blend( a.g, b.g ),
	        Overlay_blend( a.b, b.b )
		);
	}
	
	float4 Overlay_blend( float4 a, float4 b, bool blendAlpha = false )
	{
	    return float4(
	        Overlay_blend( a.rgb, b.rgb ).rgb,
	        blendAlpha ? Overlay_blend( a.a, b.a ) : max( a.a, b.a )
	    );
	}
	
	float4 MainPs( PixelInput i ) : SV_Target0
	{
		Material m = Material::Init();
		m.Albedo = float3( 1, 1, 1 );
		m.Normal = float3( 0, 0, 1 );
		m.Roughness = 1;
		m.Metalness = 0;
		m.AmbientOcclusion = 1;
		m.TintMask = 1;
		m.Opacity = 1;
		m.Emission = float3( 0, 0, 0 );
		m.Transmission = 0;
		
		float2 l_0 = i.vTextureCoords.xy * float2( 1, 1 );
		float4 l_1 = Tex2DS( g_tDiffuse, g_sSampler0, l_0 );
		float4 l_2 = g_vEmissionColor;
		float l_3 = g_flEmissionStrength;
		float4 l_4 = Tex2DS( g_tEmissionMap, g_sSampler0, l_0 );
		float l_5 = l_4.x;
		float l_6 = l_3 * l_5;
		float4 l_7 = l_2 * float4( l_6, l_6, l_6, l_6 );
		float4 l_8 = l_7 * float4( 10, 10, 10, 10 );
		float4 l_9 = Tex2DS( g_tAlphaMask, g_sSampler0, l_0 );
		float l_10 = l_9.x;
		float l_11 = g_bUseDiffuseAlpha ? l_1.a : l_10;
		float4 l_12 = Tex2DS( g_tNormal, g_sSampler0, l_0 );
		float l_13 = g_flDetailNormalScale;
		float2 l_14 = TileAndOffsetUv( l_0, float2( l_13, l_13 ), float2( 0, 0 ) );
		float4 l_15 = Tex2DS( g_tDetailNormal, g_sSampler0, l_14 );
		float l_16 = g_flDetailNormalFactor;
		float4 l_17 = saturate( lerp( l_12, Overlay_blend( l_12, l_15 ), l_16 ) );
		float l_18 = l_17.x;
		float l_19 = l_17.y;
		float l_20 = 1 - l_19;
		float l_21 = l_17.z;
		float l_22 = l_17.w;
		float4 l_23 = float4( l_18, l_20, l_21, l_22 );
		float3 l_24 = DecodeNormal( l_23.xyz );
		float4 l_25 = Tex2DS( g_tMRC, g_sSampler0, l_0 );
		float l_26 = l_25.y;
		float l_27 = 1 - l_26;
		float l_28 = l_25.x;
		float l_29 = l_25.z;
		
		m.Albedo = l_1.xyz;
		m.Emission = l_8.xyz;
		m.Opacity = l_11;
		m.Normal = l_24;
		m.Roughness = l_27;
		m.Metalness = l_28;
		m.AmbientOcclusion = l_29;
		
		m.AmbientOcclusion = saturate( m.AmbientOcclusion );
		m.Roughness = saturate( m.Roughness );
		m.Metalness = saturate( m.Metalness );
		m.Opacity = saturate( m.Opacity );

		// Result node takes normal as tangent space, convert it to world space now
		m.Normal = TransformNormal( m.Normal, i.vNormalWs, i.vTangentUWs, i.vTangentVWs );

		// for some toolvis shit
		m.WorldTangentU = i.vTangentUWs;
		m.WorldTangentV = i.vTangentVWs;
        m.TextureCoords = i.vTextureCoords.xy;
		
		return ShadingModelStandard::Shade( i, m );
	}
}
