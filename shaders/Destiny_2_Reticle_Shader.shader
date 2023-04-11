//=========================================================================================================================
// Optional
//=========================================================================================================================
HEADER
{
	Description = "Destiny 2 Reticle Shader";
	Version = 1;
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
FEATURES
{
    #include "common/features.hlsl"
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
MODES
{
	VrForward();

	Depth( "depth_only.shader" ); 

	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "tools_shading_complexity.shader" );

	Reflection( "high_quality_reflections.shader" );
}

//=========================================================================================================================
COMMON
{
	#include "common/shared.hlsl"

	#define S_TRANSLUCENT 1
}

//=========================================================================================================================

struct VertexInput
{
	#include "common/vertexinput.hlsl"
};

//=========================================================================================================================

struct PixelInput
{
	#include "common/pixelinput.hlsl"
};

//=========================================================================================================================

VS
{
	#include "common/vertex.hlsl" 
	//
	// Main
	//
	PixelInput MainVs( INSTANCED_SHADER_PARAMS( VS_INPUT i ) )
	{
		PixelInput o = ProcessVertex( i );
		// Add your vertex manipulation functions here
		return FinalizeVertex( o );
	}
}

//=========================================================================================================================

PS
{
	//Includes
	#include "sbox_pixel.fxc"

	#include "common/pixel.config.hlsl"
	#include "common/pixel.material.structs.hlsl"
	#include "common/pixel.lighting.hlsl"
	#include "common/pixel.shading.hlsl"

	#include "common/pixel.material.helpers.hlsl"
	
	//
	// Main
	//
	
	//Creates texture inputs
	CreateInputTexture2D( TextureDiffuse, Srgb,   8, "", "_diffuse",  "Material,10/10", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDiffuse ) < Channel( RGBA, Box( TextureDiffuse ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDiffuse, g_tDiffuse );

	CreateInputTexture2D( TextureGStack, Linear, 8, "", "_GStack", "Material,10/20", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tGStack ) < Channel( RGBA, Box( TextureGStack ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tGStack, g_tGStack );
	
	CreateInputTexture2D( TextureNormal, Linear, 8, "NormalizeNormals", "_normal", "Material,10/30", Default3( 0.5, 0.5, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tNormal ) < Channel( RGBA, Box( TextureNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tNormal, g_tNormal );

	//Creates color inputs
	float4 g_ReticleColor1 < UiType( Color ); Default4( 1.0f, 0.0f, 0.0f, 1.0f ); UiGroup( "Color,10/Primary,10/1" ); >;
	Float4Attribute( g_ReticleColor1, g_ReticleColor1 );

	float4 g_ReticleColor2 < UiType( Color ); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Color,10/Primary,10/2" ); >;
	Float4Attribute( g_ReticleColor2, g_ReticleColor2 );

	float4 g_ReticleColor3 < UiType( Color ); Default4( 0.0f, 0.0f, 1.0f, 1.0f ); UiGroup( "Color,10/Primary,10/3" ); >;
	Float4Attribute( g_ReticleColor3, g_ReticleColor3 );

	float g_flEmitScale< Default( 5.0 ); Range( 0.0, 100.0 ); UiGroup( "Reticle Properties,10" ); >;
	float g_flSpecularScale< Default( 0.0 ); Range( 0.0, 1 ); UiGroup( "Reticle Properties,10" ); >;

	//
	// Main
	//
	float4 MainPs( PixelInput i ) : SV_Target0
	{
		//PixelOutput o;
		float2 vUV = i.vTextureCoords.xy;

		//Overlays the colors on the material based on rgb channels
		float3 diffuse = Tex2DS( g_tDiffuse, TextureFiltering, vUV );
		float3 gstack = Tex2DS( g_tGStack, TextureFiltering, vUV );

		float3 color1 = lerp( 0, g_ReticleColor1, diffuse.r );
		float3 color2 = lerp( 0, g_ReticleColor2, diffuse.g );
		float3 color3 = lerp( 0, g_ReticleColor3, diffuse.b );

		//Adds the colors together
		float4 colorFinal = float4( color1 + color2 + color3, 1 );

		//Main material properties
		Material m = ToMaterial(i, float4(0,0,0,1), Tex2DS( g_tNormal, TextureFiltering, vUV ), float4( 0.0f, 0.0f, 1.0f, 0.0f ) );
		m.Opacity = gstack.g;
		m.Emission = colorFinal * g_flEmitScale;
	
		if(g_flSpecularScale > 0)
		{
			m.Opacity = saturate(m.Opacity + g_flSpecularScale);
			m.Albedo = g_flSpecularScale;
			m.Metalness = 1;
			m.Roughness = 0.04;
		}

		ShadingModelValveStandard sm;
		
		return FinalizePixelMaterial( i, m, sm );
	}

}