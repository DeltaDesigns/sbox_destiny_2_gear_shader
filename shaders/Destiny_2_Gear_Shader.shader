//=========================================================================================================================
// Optional
//=========================================================================================================================
HEADER
{
	Description = "Destiny 2 Player Gear Shader";
	Version = 2;
}

//=========================================================================================================================

FEATURES
{
	#include "common/features.hlsl"
	//Feature(F_VERTEX_ANIMATION, 0..1, "Animation");
	Feature(F_DECAL, 0..1, "Blending");
	Feature(F_DYE_MAP, 0..1, "Dye Map");
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
MODES
{
	VrForward();

	Depth();

	ToolsVis( S_MODE_TOOLS_VIS );
	ToolsWireframe( "vr_tools_wireframe.shader" );
	ToolsShadingComplexity( "tools_shading_complexity.shader" );

	//Reflection( S_MODE_REFLECTIONS );
}

COMMON
{
	// #ifndef S_ALPHA_TEST
	// 	#define S_ALPHA_TEST 1
	// #endif
	// #ifndef S_TRANSLUCENT
	// 	#define S_TRANSLUCENT 0
	// #endif

	#define CUSTOM_MATERIAL_INPUTS
	#include "common/shared.hlsl"
}

//=========================================================================================================================

struct VertexInput
{
	#include "common/vertexinput.hlsl"
	
	float2 vSlots : TEXCOORD2 < Semantic( Texcoord2 ); >;
	//float4 vVertexAnim	: COLOR0 < Semantic( Color ); >;
	//float4 vColor	: COLOR1 < Semantic( Color1 ); >;	
};

//=========================================================================================================================

struct PixelInput
{
	#include "common/pixelinput.hlsl"
	//float4 vColor	: COLOR0;
	float2 vSlots : TEXCOORD14;
};

//=========================================================================================================================

VS
{
	#include "common/vertex.hlsl"
		
	//
	// Main
	//
	PixelInput MainVs( VertexInput i )
	{
		PixelInput o = ProcessVertex( i );

		//o.vColor = i.vColor;
		o.vSlots = i.vSlots;
		
		// Add your vertex manipulation functions here
		return FinalizeVertex( o );
	}
}

//=========================================================================================================================

PS
{
	#include "common/pixel.hlsl"

	#define CUSTOM_TEXTURE_FILTERING
    SamplerState TextureFiltering2 < Filter( NEAREST ); AddressU( BORDER ); AddressV( BORDER ); MaxAniso( 4 ); >;

	//---------------------------------------------------------------------------------------------
	StaticCombo( S_DECAL, F_DECAL, Sys( PC ) );
	StaticCombo( S_DYE_MAP, F_DYE_MAP, Sys( PC ) );

	// Additive Blending
	#if (S_DECAL)
        #define BLEND_MODE_ALREADY_SET
        RenderState(BlendEnable, true);
        RenderState(SrcBlend, SRC_COLOR);
        RenderState(DstBlend, INV_SRC_COLOR);
    #endif

	BoolAttribute(bWantsFBCopyTexture, S_DECAL);
    BoolAttribute(translucent, S_DECAL);
    CreateTexture2D( g_tFrameBufferCopyTexture ) < Attribute( "FrameBufferCopyTexture" ); SrgbRead( true ); Filter( MIN_MAG_MIP_LINEAR ); AddressU( CLAMP ); AddressV( CLAMP ); >;

	//---------------------------------------------------------------------------------------------
	//Main texture inputs

	CreateInputTexture2D( TextureColor, Srgb, 8, "", "_Diffuse", "Material,10/0", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDiffuse ) < Channel( RGBA, Box( TextureColor ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDiffuse, g_tDiffuse );

	CreateInputTexture2D( TextureGStack, Linear, 8, "", "_GStack", "Material,10/1", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tGStack ) < Channel( RGBA, Box( TextureGStack ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tGStack, g_tGStack );

	CreateInputTexture2D( TextureNormal, Linear, 8, "NormalizeNormals", "_Normal", "Material,10/2", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tNormal ) < Channel( RGBA, Box( TextureNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tNormal, g_tNormal );

	#if (S_DYE_MAP)
		CreateInputTexture2D( TextureDyeMap, Linear, 8, "", "_Dyemap", "Material,10/3", Default3( 1.0, 1.0, 1.0 ) );
		CreateTexture2DWithoutSampler( g_tDyeTex ) < Channel( RGBA, Box( TextureDyeMap ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
		TextureAttribute( g_tDyeTex, g_tDyeTex );
	#endif

	CreateInputTexture2D( TextureIridescence, Srgb, 8, "", "_lookup", "Material,10/4", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tIridescence ) < Channel( RGBA, None( TextureIridescence ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tIridescence, g_tIridescence );

	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	//Detail Texture Inputs

	CreateInputTexture2D( TextureDetailDiffuse01, Srgb, 8, "", "", "Detail Textures,11/1", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse01 ) < Channel( RGBA, Box( TextureDetailDiffuse01 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse01, g_tDetailDiffuse01 );

	CreateInputTexture2D( TextureDetailNormal01, Linear, 8, "", "", "Detail Textures,11/2", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal01 ) < Channel( RGBA, Box( TextureDetailNormal01 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal01, g_tDetailNormal01 );

	CreateInputTexture2D( TextureDetailDiffuse02, Srgb, 8, "", "", "Detail Textures,11/3", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse02 ) < Channel( RGBA, Box( TextureDetailDiffuse02 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse02, g_tDetailDiffuse02 );

	CreateInputTexture2D( TextureDetailNormal02, Linear, 8, "", "", "Detail Textures,11/4", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal02 ) < Channel( RGBA, Box( TextureDetailNormal02 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal02, g_tDetailNormal02 );

	CreateInputTexture2D( TextureDetailDiffuse03, Srgb, 8, "", "", "Detail Textures,11/5", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse03 ) < Channel( RGBA, Box( TextureDetailDiffuse03 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse03, g_tDetailDiffuse03 );

	CreateInputTexture2D( TextureDetailNormal03, Linear, 8, "", "", "Detail Textures,11/6", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal03 ) < Channel( RGBA, Box( TextureDetailNormal03 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal03, g_tDetailNormal03 );

	//End of Detail Textures
	//--------------------------------------------------------------------------------------------------------------------

	//SHADER INPUTS
	//---------------------------------------------------------------------------------------------------------------------

	//Tranforms for all slots
	float4 g_Armor_DetailDiffuseTransform < UiType( VectorText ); Default4(4, 4, 0, 0); UiGroup( "Armor,12/Transforms,12/1" ); >;
	Float4Attribute( g_Armor_DetailDiffuseTransform, g_Armor_DetailDiffuseTransform );

	float4 g_Armor_DetailNormalTransform < UiType( VectorText ); Default4(4, 4, 0, 0); UiGroup( "Armor,12/Transforms,12/2" ); >;
	Float4Attribute( g_Armor_DetailNormalTransform, g_Armor_DetailNormalTransform );

	float4 g_Cloth_DetailDiffuseTransform < UiType( VectorText ); Default4(4, 4, 0, 0); UiGroup( "Cloth,13/Transforms,13/3" ); >;
	Float4Attribute( g_Cloth_DetailDiffuseTransform, g_Cloth_DetailDiffuseTransform );

	float4 g_Cloth_DetailNormalTransform < UiType( VectorText ); Default4(4, 4, 0, 0); UiGroup( "Cloth,13/Transforms,13/4" ); >;
	Float4Attribute( g_Cloth_DetailNormalTransform, g_Cloth_DetailNormalTransform );

	float4 g_Suit_DetailDiffuseTransform < UiType( VectorText ); Default4(2, 2, 0, 0); UiGroup( "Suit,14/Transforms,14/5" ); >;
	Float4Attribute( g_Suit_DetailDiffuseTransform, g_Suit_DetailDiffuseTransform );

	float4 g_Suit_DetailNormalTransform < UiType( VectorText );Default4(2, 2, 0, 0); UiGroup( "Suit,14/Transforms,14/6" ); >;
	Float4Attribute( g_Suit_DetailNormalTransform, g_Suit_DetailNormalTransform );

	//--------------------------------------------------------------------------------------------------------------------



	//Armor Primary
	//--------------------------------------------------------------------------------------------------------------------
	//Colors
	float4 g_ArmorPrimary_Color < UiType( Color ); Default4( 1.0f, 0.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Primary,12/1" ); >;
	Float4Attribute( g_ArmorPrimary_Color, g_ArmorPrimary_Color ); 

	float4 g_WornArmorPrimary_Color < UiType( Color ); Default4( 1.0f, 0.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Primary,12/2" ); >;
	Float4Attribute( g_WornArmorPrimary_Color, g_WornArmorPrimary_Color );

	//remaps
	float4 g_ArmorPrimary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4(0, 1, 0, 1); UiGroup( "Armor,12/Primary Remaps,12/1" ); >;
	Float4Attribute( g_ArmorPrimary_WearRemap, g_ArmorPrimary_WearRemap );

	float4 g_ArmorPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4(0, 1, 0, 1); UiGroup( "Armor,12/Primary Remaps,12/2" ); >;
	Float4Attribute( g_ArmorPrimary_RoughnessRemap, g_ArmorPrimary_RoughnessRemap );

	float4 g_WornArmorPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Primary Remaps,12/3" ); >;
	Float4Attribute( g_WornArmorPrimary_RoughnessRemap, g_WornArmorPrimary_RoughnessRemap );

	//blends
	float g_ArmorPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Blends,12/1" ); >;
	FloatAttribute( g_ArmorPrimary_DetailDiffuseBlend, g_ArmorPrimary_DetailDiffuseBlend );

	float g_ArmorPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Blends,12/2" ); >;
	FloatAttribute( g_ArmorPrimary_DetailNormalBlend, g_ArmorPrimary_DetailNormalBlend );

	float g_ArmorPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Blends,12/3" ); >;
	FloatAttribute( g_ArmorPrimary_DetailRoughnessBlend, g_ArmorPrimary_DetailRoughnessBlend );

	//blends but for worn armor primary
	float g_WornArmorPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Worn Blends,12/1" ); >;
	FloatAttribute( g_WornArmorPrimary_DetailDiffuseBlend, g_WornArmorPrimary_DetailDiffuseBlend );

	float g_WornArmorPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Worn Blends,12/2" ); >;
	FloatAttribute( g_WornArmorPrimary_DetailNormalBlend, g_WornArmorPrimary_DetailNormalBlend );

	float g_WornArmorPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Worn Blends,12/3" ); >;
	FloatAttribute( g_WornArmorPrimary_DetailRoughnessBlend, g_WornArmorPrimary_DetailRoughnessBlend );
	
	//Other
	float g_ArmorPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Other,12/1" ); >;
	FloatAttribute( g_ArmorPrimary_Metalness, g_ArmorPrimary_Metalness );

	float g_WornArmorPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Other,12/2" ); >;
	FloatAttribute( g_WornArmorPrimary_Metalness, g_WornArmorPrimary_Metalness );

	int g_ArmorPrimary_Iridescence < UiType( Slider ); Default( -1 ); Range(-1, 128); UiGroup( "Armor,12/Primary Other,12/3" ); >;
	IntAttribute( g_ArmorPrimary_Iridescence, g_ArmorPrimary_Iridescence );

	float g_ArmorPrimary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Other,12/4" ); >;
	FloatAttribute( g_ArmorPrimary_Fuzz, g_ArmorPrimary_Fuzz );

	float g_ArmorPrimary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Primary Other,12/5" ); >;
	FloatAttribute( g_ArmorPrimary_Transmission, g_ArmorPrimary_Transmission );

	float4 g_ArmorPrimary_Emission < UiType( Color ); Default4( 1.0f, 0.0f, 0.0f, 0.0f ); UiGroup( "Armor,12/Primary Other,12/6" ); >;
	Float4Attribute( g_ArmorPrimary_Emission, g_ArmorPrimary_Emission );

	//End of Armor Primary
	//--------------------------------------------------------------------------------------------------------------------


	//Armor Secondary
	//--------------------------------------------------------------------------------------------------------------------
	//colors
	float4 g_ArmorSecondary_Color < UiType( Color ); Default4( 1.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary,12/1" ); >;
	Float4Attribute( g_ArmorSecondary_Color, g_ArmorSecondary_Color );

	float4 g_WornArmorSecondary_Color < UiType( Color ); Default4( 1.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary,12/2" ); >;
	Float4Attribute( g_WornArmorSecondary_Color, g_WornArmorSecondary_Color );

	//remaps
	float4 g_ArmorSecondary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary Remaps,12/1" ); >;
	Float4Attribute( g_ArmorSecondary_WearRemap, g_ArmorSecondary_WearRemap );

	float4 g_ArmorSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary Remaps,12/2" ); >;
	Float4Attribute( g_ArmorSecondary_RoughnessRemap, g_ArmorSecondary_RoughnessRemap );

	float4 g_WornArmorSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary Remaps,12/3" ); >;\
	Float4Attribute( g_WornArmorSecondary_RoughnessRemap, g_WornArmorSecondary_RoughnessRemap );

	//blends
	float g_ArmorSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Blends,12/1" ); >;
	FloatAttribute( g_ArmorSecondary_DetailDiffuseBlend, g_ArmorSecondary_DetailDiffuseBlend );

	float g_ArmorSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Blends,12/2" ); >;
	FloatAttribute( g_ArmorSecondary_DetailNormalBlend, g_ArmorSecondary_DetailNormalBlend );

	float g_ArmorSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Blends,12/3" ); >;
	FloatAttribute( g_ArmorSecondary_DetailRoughnessBlend, g_ArmorSecondary_DetailRoughnessBlend );

	//blends but for worn armor secondary
	float g_WornArmorSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Worn Blends,12/1" ); >;
	FloatAttribute( g_WornArmorSecondary_DetailDiffuseBlend, g_WornArmorSecondary_DetailDiffuseBlend );

	float g_WornArmorSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Worn Blends,12/2" ); >;
	FloatAttribute( g_WornArmorSecondary_DetailNormalBlend, g_WornArmorSecondary_DetailNormalBlend );

	float g_WornArmorSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Worn Blends,12/3" ); >;
	FloatAttribute( g_WornArmorSecondary_DetailRoughnessBlend, g_WornArmorSecondary_DetailRoughnessBlend );

	//Other
	float g_ArmorSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Other,12/1" ); >;
	FloatAttribute( g_ArmorSecondary_Metalness, g_ArmorSecondary_Metalness );

	float g_WornArmorSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Other,12/2" ); >;
	FloatAttribute( g_WornArmorSecondary_Metalness, g_WornArmorSecondary_Metalness );

	float g_ArmorSecondary_Iridescence < Default( -1.0f ); Range(-1, 128.0f); UiGroup( "Armor,12/Secondary Other,12/3" ); >;
	FloatAttribute( g_ArmorSecondary_Iridescence, g_ArmorSecondary_Iridescence );

	float g_ArmorSecondary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Other,12/4" ); >;
	FloatAttribute( g_ArmorSecondary_Fuzz, g_ArmorSecondary_Fuzz );

	float g_ArmorSecondary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Armor,12/Secondary Other,12/5" ); >;
	FloatAttribute( g_ArmorSecondary_Transmission, g_ArmorSecondary_Transmission );

	float4 g_ArmorSecondary_Emission < UiType( Color ); Default4( 1.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Armor,12/Secondary Other,12/6" ); >;
	Float4Attribute( g_ArmorSecondary_Emission, g_ArmorSecondary_Emission );

	//End of Armor Secondary
	//--------------------------------------------------------------------------------------------------------------------


	//Cloth Primary
	//--------------------------------------------------------------------------------------------------------------------
	//colors
	float4 g_ClothPrimary_Color < UiType( Color ); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary,13/1" ); >;
	Float4Attribute( g_ClothPrimary_Color, g_ClothPrimary_Color ); 
	float4 g_WornClothPrimary_Color < UiType( Color ); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary,13/2" ); >;
	Float4Attribute( g_WornClothPrimary_Color, g_WornClothPrimary_Color );

	//remaps
	float4 g_ClothPrimary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary Remaps,13/1" ); >;
	Float4Attribute( g_ClothPrimary_WearRemap, g_ClothPrimary_WearRemap );

	float4 g_WornClothPrimary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary Remaps,13/2" ); >;
	Float4Attribute( g_WornClothPrimary_WearRemap, g_WornClothPrimary_WearRemap );

	float4 g_ClothPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary Remaps,13/3" ); >;
	Float4Attribute( g_ClothPrimary_RoughnessRemap, g_ClothPrimary_RoughnessRemap );

	float4 g_WornClothPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary Remaps,13/4" ); >;
	Float4Attribute( g_WornClothPrimary_RoughnessRemap, g_WornClothPrimary_RoughnessRemap );

	//blends
	float g_ClothPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/1" ); >;
	FloatAttribute( g_ClothPrimary_DetailDiffuseBlend, g_ClothPrimary_DetailDiffuseBlend );

	float g_ClothPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/2" ); >;
	FloatAttribute( g_ClothPrimary_DetailNormalBlend, g_ClothPrimary_DetailNormalBlend );

	float g_ClothPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/3" ); >;
	FloatAttribute( g_ClothPrimary_DetailRoughnessBlend, g_ClothPrimary_DetailRoughnessBlend );

	float g_WornClothPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/4" ); >;
	FloatAttribute( g_WornClothPrimary_DetailDiffuseBlend, g_WornClothPrimary_DetailDiffuseBlend );

	float g_WornClothPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/5" ); >;
	FloatAttribute( g_WornClothPrimary_DetailNormalBlend, g_WornClothPrimary_DetailNormalBlend );

	float g_WornClothPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Blends,13/6" ); >;
	FloatAttribute( g_WornClothPrimary_DetailRoughnessBlend, g_WornClothPrimary_DetailRoughnessBlend );

	//other
	float g_ClothPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Other,13/1" ); >;
	FloatAttribute( g_ClothPrimary_Metalness, g_ClothPrimary_Metalness );

	float g_WornClothPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Other,13/2" ); >;
	FloatAttribute( g_WornClothPrimary_Metalness, g_WornClothPrimary_Metalness );

	float g_ClothPrimary_Iridescence < Default( -1.0f ); Range(-1, 128.0f); UiGroup( "Cloth,13/Primary Other,13/1" ); >;
	FloatAttribute( g_ClothPrimary_Iridescence, g_ClothPrimary_Iridescence );

	float g_ClothPrimary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Other,13/1" ); >;
	FloatAttribute( g_ClothPrimary_Fuzz, g_ClothPrimary_Fuzz );

	float g_ClothPrimary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Primary Other,13/1" ); >;
	FloatAttribute( g_ClothPrimary_Transmission, g_ClothPrimary_Transmission );

	float4 g_ClothPrimary_Emission < UiType( Color ); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Primary Other,13/1" ); >;
	Float4Attribute( g_ClothPrimary_Emission, g_ClothPrimary_Emission );

	//End of Cloth Primary
	//--------------------------------------------------------------------------------------------------------------------


	//Cloth Secondary
	//--------------------------------------------------------------------------------------------------------------------
	//colors
	float4 g_ClothSecondary_Color < UiType( Color ); Default4( 0.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Cloth,13/Secondary,13/1" ); >;
	Float4Attribute( g_ClothSecondary_Color, g_ClothSecondary_Color );

	float4 g_WornClothSecondary_Color < UiType( Color ); Default4( 0.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Cloth,13/Secondary,13/2" ); >;
	Float4Attribute( g_WornClothSecondary_Color, g_WornClothSecondary_Color );

	//remaps
	float4 g_ClothSecondary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Secondary Remaps,13/1" ); >;
	Float4Attribute( g_ClothSecondary_WearRemap, g_ClothSecondary_WearRemap );

	float4 g_WornClothSecondary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Secondary Remaps,13/2" ); >;
	Float4Attribute( g_WornClothSecondary_WearRemap, g_WornClothSecondary_WearRemap );

	float4 g_ClothSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Secondary Remaps,13/3" ); >;
	Float4Attribute( g_ClothSecondary_RoughnessRemap, g_ClothSecondary_RoughnessRemap );

	float4 g_WornClothSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Cloth,13/Secondary Remaps,13/4" ); >;
	Float4Attribute( g_WornClothSecondary_RoughnessRemap, g_WornClothSecondary_RoughnessRemap );

	//blends
	float g_ClothSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Blends,13/1" ); >;
	FloatAttribute( g_ClothSecondary_DetailDiffuseBlend, g_ClothSecondary_DetailDiffuseBlend );

	float g_ClothSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Blends,13/2" ); >;
	FloatAttribute( g_ClothSecondary_DetailNormalBlend, g_ClothSecondary_DetailNormalBlend );

	float g_ClothSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Blends,13/3" ); >;
	FloatAttribute( g_ClothSecondary_DetailRoughnessBlend, g_ClothSecondary_DetailRoughnessBlend );

	float g_WornClothSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Worn Blends,13/1" ); >;
	FloatAttribute( g_WornClothSecondary_DetailDiffuseBlend, g_WornClothSecondary_DetailDiffuseBlend );

	float g_WornClothSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Worn Blends,13/2" ); >;
	FloatAttribute( g_WornClothSecondary_DetailNormalBlend, g_WornClothSecondary_DetailNormalBlend );

	float g_WornClothSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Worn Blends,13/3" ); >;
	FloatAttribute( g_WornClothSecondary_DetailRoughnessBlend, g_WornClothSecondary_DetailRoughnessBlend );

	//other
	float g_ClothSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Other,13/1" ); >;
	FloatAttribute( g_ClothSecondary_Metalness, g_ClothSecondary_Metalness );

	float g_WornClothSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Other,13/2" ); >;
	FloatAttribute( g_WornClothSecondary_Metalness, g_WornClothSecondary_Metalness );

	float g_ClothSecondary_Iridescence < Default( -1.0f ); Range(-1, 128.0f); UiGroup( "Cloth,13/Secondary Other,13/3" ); >;
	FloatAttribute( g_ClothSecondary_Iridescence, g_ClothSecondary_Iridescence );

	float g_ClothSecondary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Other,13/4" ); >;
	FloatAttribute( g_ClothSecondary_Fuzz, g_ClothSecondary_Fuzz );

	float g_ClothSecondary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Cloth,13/Secondary Other,13/5" ); >;
	FloatAttribute( g_ClothSecondary_Transmission, g_ClothSecondary_Transmission );

	float4 g_ClothSecondary_Emission < UiType( Color ); Default4( 0.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Cloth,13/Secondary Other,13/6" ); >;
	Float4Attribute( g_ClothSecondary_Emission, g_ClothSecondary_Emission );


	//End of Cloth Secondary
	//--------------------------------------------------------------------------------------------------------------------


	//Suit Primary
	//--------------------------------------------------------------------------------------------------------------------
	//colors
	float4 g_SuitPrimary_Color < UiType( Color ); Default4( 0.08569f, 0.08569f, 0.08569f, 1.0f ); UiGroup( "Suit,14/Primary,14/1" ); >;
	Float4Attribute( g_SuitPrimary_Color, g_SuitPrimary_Color );
	float4 g_WornSuitPrimary_Color < UiType( Color ); Default4( 0.0f, 0.0f, 1.0f, 1.0f ); UiGroup( "Suit,14/Primary,14/2" ); >;
	Float4Attribute( g_WornSuitPrimary_Color, g_WornSuitPrimary_Color );

	//remaps
	float4 g_SuitPrimary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Primary Remaps,14/1" ); >;
	Float4Attribute( g_SuitPrimary_WearRemap, g_SuitPrimary_WearRemap );

	float4 g_WornSuitPrimary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Primary Remaps,14/2" ); >;
	Float4Attribute( g_WornSuitPrimary_WearRemap, g_WornSuitPrimary_WearRemap );

	float4 g_SuitPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Primary Remaps,14/3" ); >;
	Float4Attribute( g_SuitPrimary_RoughnessRemap, g_SuitPrimary_RoughnessRemap );

	float4 g_WornSuitPrimary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Primary Remaps,14/4" ); >;
	Float4Attribute( g_WornSuitPrimary_RoughnessRemap, g_WornSuitPrimary_RoughnessRemap );

	//blends
	float g_SuitPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Blends,14/1" ); >;
	FloatAttribute( g_SuitPrimary_DetailDiffuseBlend, g_SuitPrimary_DetailDiffuseBlend );

	float g_SuitPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Blends,14/2" ); >;
	FloatAttribute( g_SuitPrimary_DetailNormalBlend, g_SuitPrimary_DetailNormalBlend );

	float g_SuitPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Blends,14/3" ); >;
	FloatAttribute( g_SuitPrimary_DetailRoughnessBlend, g_SuitPrimary_DetailRoughnessBlend );

	float g_WornSuitPrimary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Worn Blends,14/1" ); >;
	FloatAttribute( g_WornSuitPrimary_DetailDiffuseBlend, g_WornSuitPrimary_DetailDiffuseBlend );

	float g_WornSuitPrimary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Worn Blends,14/2" ); >;
	FloatAttribute( g_WornSuitPrimary_DetailNormalBlend, g_WornSuitPrimary_DetailNormalBlend );

	float g_WornSuitPrimary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Worn Blends,14/3" ); >;
	FloatAttribute( g_WornSuitPrimary_DetailRoughnessBlend, g_WornSuitPrimary_DetailRoughnessBlend );

	//other
	float g_SuitPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_SuitPrimary_Metalness, g_SuitPrimary_Metalness );

	float g_SuitPrimary_Iridescence < Default( -1.0f ); Range(-1, 128.0f); UiGroup( "Suit,14/Primary Other,14/2" ); >;
	FloatAttribute( g_SuitPrimary_Iridescence, g_SuitPrimary_Iridescence );

	float g_SuitPrimary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/3" ); >;
	FloatAttribute( g_SuitPrimary_Fuzz, g_SuitPrimary_Fuzz );

	float g_SuitPrimary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/4" ); >;
	FloatAttribute( g_SuitPrimary_Transmission, g_SuitPrimary_Transmission );

	float4 g_SuitPrimary_Emission < UiType( Color ); Default4( 0.0f, 0.0f, 1.0f, 1.0f ); UiGroup( "Suit,14/Primary Other,14/5" ); >;
	Float4Attribute( g_SuitPrimary_Emission, g_SuitPrimary_Emission );

	float g_WornSuitPrimary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/6" ); >;
	FloatAttribute( g_WornSuitPrimary_Metalness, g_WornSuitPrimary_Metalness );

	//End of Suit Primary


	//Suit Secondary
	//--------------------------------------------------------------------------------------------------------------------
	//colors
	float4 g_SuitSecondary_Color < UiType( Color ); Default4( 1.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Suit,14/Secondary,14/1" ); >;
	Float4Attribute( g_SuitSecondary_Color, g_SuitSecondary_Color );
	float4 g_WornSuitSecondary_Color < UiType( Color ); Default4( 1.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Suit,14/Secondary,14/2" ); >;
	Float4Attribute( g_WornSuitSecondary_Color, g_WornSuitSecondary_Color );

	//remaps
	float4 g_SuitSecondary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Secondary Remaps,14/1" ); >;
	Float4Attribute( g_SuitSecondary_WearRemap, g_SuitSecondary_WearRemap );

	float4 g_WornSuitSecondary_WearRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Secondary Remaps,14/2" ); >;
	Float4Attribute( g_WornSuitSecondary_WearRemap, g_WornSuitSecondary_WearRemap );

	float4 g_SuitSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Secondary Remaps,14/3" ); >;
	Float4Attribute( g_SuitSecondary_RoughnessRemap, g_SuitSecondary_RoughnessRemap );

	float4 g_WornSuitSecondary_RoughnessRemap < UiType( VectorText ); Range4(-50.0f, -50.0f, -50.0f, -50.0f, 50.0f, 50.0f, 50.0f, 50.0f); Default4( 0.0f, 1.0f, 0.0f, 1.0f ); UiGroup( "Suit,14/Secondary Remaps,14/4" ); >;
	Float4Attribute( g_WornSuitSecondary_RoughnessRemap, g_WornSuitSecondary_RoughnessRemap );

	//blends
	float g_SuitSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/1" ); >;
	FloatAttribute( g_SuitSecondary_DetailDiffuseBlend, g_SuitSecondary_DetailDiffuseBlend );

	float g_SuitSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/2" ); >;
	FloatAttribute( g_SuitSecondary_DetailNormalBlend, g_SuitSecondary_DetailNormalBlend );

	float g_SuitSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/3" ); >;
	FloatAttribute( g_SuitSecondary_DetailRoughnessBlend, g_SuitSecondary_DetailRoughnessBlend );

	float g_WornSuitSecondary_DetailDiffuseBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/1" ); >;
	FloatAttribute( g_WornSuitSecondary_DetailDiffuseBlend, g_WornSuitSecondary_DetailDiffuseBlend );

	float g_WornSuitSecondary_DetailNormalBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/2" ); >;
	FloatAttribute( g_WornSuitSecondary_DetailNormalBlend, g_WornSuitSecondary_DetailNormalBlend );

	float g_WornSuitSecondary_DetailRoughnessBlend < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Secondary Blends,14/3" ); >;
	FloatAttribute( g_WornSuitSecondary_DetailRoughnessBlend, g_WornSuitSecondary_DetailRoughnessBlend );
	
	//other
	float g_SuitSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_SuitSecondary_Metalness, g_SuitSecondary_Metalness );

	float g_SuitSecondary_Iridescence < Default( -1.0f ); Range(-1, 128.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_SuitSecondary_Iridescence, g_SuitSecondary_Iridescence );
	
	float g_SuitSecondary_Fuzz < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_SuitSecondary_Fuzz, g_SuitSecondary_Fuzz );

	float g_SuitSecondary_Transmission < Default( 0.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_SuitSecondary_Transmission, g_SuitSecondary_Transmission );

	float4 g_SuitSecondary_Emission < UiType( Color ); Default4( 1.0f, 1.0f, 1.0f, 1.0f ); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	Float4Attribute( g_SuitSecondary_Emission, g_SuitSecondary_Emission );

	float g_WornSuitSecondary_Metalness < Default( 1.0f ); Range(0, 1.0f); UiGroup( "Suit,14/Primary Other,14/1" ); >;
	FloatAttribute( g_WornSuitSecondary_Metalness, g_WornSuitSecondary_Metalness );

	//End of Suit Secondary

	//--------------------------------------------------------------------------------------------------------------------

	//Helper functions
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

	float3 Bungie_Overlay (float3 cBase, float3 cBlend, float fac)
	{
		float3 cNew = cBlend * saturate(cBase * 4.0f) + saturate(cBase - 0.25f);
		return lerp(cBase, cNew, fac);
	}
	
	float3 Bungie_HardLight (float3 cBase, float3 cBlend, float fac)
	{
		float3 cNew = cBase * saturate(cBlend * 4.0f) + saturate(cBlend - 0.25f);
		return lerp(cBase, cNew, fac);
	}

	float Remap (float val, float4 remap)
	{
		return clamp( val * remap.y + remap.x, remap.z, remap.z + remap.w );
	}
	
	void NormalReconstructZ_float(float2 In, out float3 Out)
	{
		float3 normalVector = float3(In.x, In.y, 0);
		normalVector.x = mad(normalVector.x, 2, -1);
		normalVector.y = mad(normalVector.y, 2, -1);
		
		normalVector.z = sqrt(1-saturate(mad(normalVector.x, normalVector.x, normalVector.y)));

		normalVector = float3(normalVector.x, normalVector.y*-1, normalVector.z);
		Out = (normalize(normalVector) + 1) / 2;
	}

	//-------------------------------------------------------------------------------------------------------------------------------------------------------------

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		float2 vUVs = i.vTextureCoords.xy;

		float4 diffuseTex = Tex2DS(g_tDiffuse, TextureFiltering, vUVs );
		float4 gstackTex = Tex2DS( g_tGStack, TextureFiltering, vUVs );
		float4 normalTex = Tex2DS(g_tNormal, TextureFiltering, vUVs );

		// Alpha clipping is done as early as possible to minimize extraneous processing cycles
		float transparency = 1;
		if (i.vSlots.y < 0.5)
		{
			transparency = saturate(mad(gstackTex.b, 1000, -50));
			clip( transparency - .001 );
		}  
		#if(S_DECAL)
			transparency = saturate(mad(diffuseTex.a, 1000, -50));
			clip( transparency - .001 );
			gstackTex = float4(0.5,0.5,0,0);
		#endif

		float flAmbientOcclusion = pow(gstackTex.r, 2.2);
		float flRoughness = saturate(1 - gstackTex.g);
		//
		
		#if (S_DYE_MAP)
			float4 flDyeMap = Tex2DS( g_tDyeTex, TextureFiltering, vUVs );

			if (flDyeMap.a > 0.5f)
			{
				bool red = flDyeMap.r > 0.5;
				bool green = flDyeMap.g > 0.5;
				bool blue = flDyeMap.b > 0.5;
				
				if (red && green && blue)
					i.vSlots.x = 6;
				else if(!red && blue)
					i.vSlots.x = 5;
				else if(red && green && !blue)
					i.vSlots.x = 4;
				else if(!red && green && !blue)
					i.vSlots.x = 3;
				else if(red && !green)
					i.vSlots.x = 2;
				else if(red || green)
					i.vSlots.x = 1;
				else if (!red && !green && !blue)
					i.vSlots.x = 1;			
			}
		#endif

		float4 detailDiff = float4(0.5, 0.5, 0.5, 1);
		float4 detailNorm = float4(0.5, 0.5, 0.5, 1);
		float4 color = float4(1.0f, 1.0f, 1.0f, 1.0f);
		float4 wearRemap = float4(1.0f, 1.0f, 1.0f, 1.0f);
		float4 roughnessRemap = float4(1.0f, 1.0f, 1.0f, 1.0f);
		float diffBlend = float(0.0f);
		float normBlend = float(0.0f);
		float roughBlend = float(0.0f);
		float metal = float(0.0f);
		int iridescenceID = 0;
		float fuzz = float(0.0f);
		float transmission = float(0.0f);
		float4 emission = float(0.0f);
		float4 wornColor = float4(1.0f, 1.0f, 1.0f, 1.0f);
		float4 wornRoughRemap = float4(1.0f, 1.0f, 1.0f, 1.0f);
		float wornDiffBlend = float(0.0f);
		float wornNormBlend = float(0.0f);
		float wornRoughBlend = float(0.0f);
		float wornMetal = float(0.0f);

		//Where all the pain and suffering happens
		//switch(slots.x)
		[branch] switch(round(clamp(i.vSlots.x,1,6)))
		{
			case(1): //Armor Primary
				detailDiff = Tex2DS(g_tDetailDiffuse01, TextureFiltering, (vUVs*5.0) * g_Armor_DetailDiffuseTransform.xy + g_Armor_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal01, TextureFiltering, (vUVs*5.0) * g_Armor_DetailNormalTransform.xy + g_Armor_DetailNormalTransform.zw);
				color = g_ArmorPrimary_Color;
				wearRemap = g_ArmorPrimary_WearRemap;
				roughnessRemap = g_ArmorPrimary_RoughnessRemap;
				diffBlend = g_ArmorPrimary_DetailDiffuseBlend;
				normBlend = g_ArmorPrimary_DetailNormalBlend;
				roughBlend = g_ArmorPrimary_DetailRoughnessBlend;
				metal = g_ArmorPrimary_Metalness;
				iridescenceID = g_ArmorPrimary_Iridescence;
				fuzz = g_ArmorPrimary_Fuzz;
				transmission = g_ArmorPrimary_Transmission;
				emission = g_ArmorPrimary_Emission;
				wornColor = g_WornArmorPrimary_Color;
				wornRoughRemap = g_WornArmorPrimary_RoughnessRemap;
				wornDiffBlend = g_WornArmorPrimary_DetailDiffuseBlend;
				wornNormBlend = g_WornArmorPrimary_DetailNormalBlend;
				wornRoughBlend = g_WornArmorPrimary_DetailRoughnessBlend;
				wornMetal = g_WornArmorPrimary_Metalness;
	
				break;
			case(2): //Armor Secondary
				detailDiff = Tex2DS(g_tDetailDiffuse01, TextureFiltering, (vUVs*5.0) * g_Armor_DetailDiffuseTransform.xy + g_Armor_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal01, TextureFiltering, (vUVs*5.0) * g_Armor_DetailNormalTransform.xy + g_Armor_DetailNormalTransform.zw);
				color = g_ArmorSecondary_Color;
				wearRemap = g_ArmorSecondary_WearRemap;
				roughnessRemap = g_ArmorSecondary_RoughnessRemap;
				diffBlend = g_ArmorSecondary_DetailDiffuseBlend;
				normBlend = g_ArmorSecondary_DetailNormalBlend;
				roughBlend = g_ArmorSecondary_DetailRoughnessBlend;
				metal = g_ArmorSecondary_Metalness;
				iridescenceID = g_ArmorSecondary_Iridescence;
				fuzz = g_ArmorSecondary_Fuzz;
				transmission = g_ArmorSecondary_Transmission;
				emission = g_ArmorSecondary_Emission;
				wornColor = g_WornArmorSecondary_Color;
				wornRoughRemap = g_WornArmorSecondary_RoughnessRemap;	
				wornDiffBlend = g_WornArmorSecondary_DetailDiffuseBlend;
				wornNormBlend = g_WornArmorSecondary_DetailNormalBlend;
				wornRoughBlend = g_WornArmorSecondary_DetailRoughnessBlend;
				wornMetal = g_WornArmorSecondary_Metalness;
				break;
			case(3): //cloth primary
				detailDiff = Tex2DS(g_tDetailDiffuse02, TextureFiltering, (vUVs*5.0) * g_Cloth_DetailDiffuseTransform.xy + g_Cloth_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal02, TextureFiltering, (vUVs*5.0) * g_Cloth_DetailNormalTransform.xy + g_Cloth_DetailNormalTransform.zw);
				color = g_ClothPrimary_Color;
				wearRemap = g_ClothPrimary_WearRemap;
				roughnessRemap = g_ClothPrimary_RoughnessRemap;
				diffBlend = g_ClothPrimary_DetailDiffuseBlend;
				normBlend = g_ClothPrimary_DetailNormalBlend;
				roughBlend = g_ClothPrimary_DetailRoughnessBlend;
				metal = g_ClothPrimary_Metalness;
				iridescenceID = g_ClothPrimary_Iridescence;
				fuzz = g_ClothPrimary_Fuzz;
				transmission = g_ClothPrimary_Transmission;
				emission = g_ClothPrimary_Emission;
				wornColor = g_WornClothPrimary_Color;
				wornRoughRemap = g_WornClothPrimary_RoughnessRemap;
				wornDiffBlend = g_WornClothPrimary_DetailDiffuseBlend;
				wornNormBlend = g_WornClothPrimary_DetailNormalBlend;
				wornRoughBlend = g_WornClothPrimary_DetailRoughnessBlend;
				wornMetal = g_WornClothPrimary_Metalness;
				break;
			case(4): //cloth secondary
				detailDiff = Tex2DS(g_tDetailDiffuse02, TextureFiltering, (vUVs*5.0) * g_Cloth_DetailDiffuseTransform.xy + g_Cloth_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal02, TextureFiltering, (vUVs*5.0) * g_Cloth_DetailNormalTransform.xy + g_Cloth_DetailNormalTransform.zw);
				color = g_ClothSecondary_Color;
				wearRemap = g_ClothSecondary_WearRemap;
				roughnessRemap = g_ClothSecondary_RoughnessRemap;
				diffBlend = g_ClothSecondary_DetailDiffuseBlend;
				normBlend = g_ClothSecondary_DetailNormalBlend;
				roughBlend = g_ClothSecondary_DetailRoughnessBlend;
				metal = g_ClothSecondary_Metalness;
				iridescenceID = g_ClothSecondary_Iridescence;
				fuzz = g_ClothSecondary_Fuzz;
				transmission = g_ClothSecondary_Transmission;
				emission = g_ClothSecondary_Emission;
				wornColor = g_WornClothSecondary_Color;
				wornRoughRemap = g_WornClothSecondary_RoughnessRemap;
				wornDiffBlend = g_WornClothSecondary_DetailDiffuseBlend;
				wornNormBlend = g_WornClothSecondary_DetailNormalBlend;
				wornRoughBlend = g_WornClothSecondary_DetailRoughnessBlend;
				wornMetal = g_WornClothSecondary_Metalness;
				break;
			case(5): //suit primary
				detailDiff = Tex2DS(g_tDetailDiffuse03, TextureFiltering, (vUVs*5.0) * g_Suit_DetailDiffuseTransform.xy + g_Suit_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal03, TextureFiltering, (vUVs*5.0) * g_Suit_DetailNormalTransform.xy + g_Suit_DetailNormalTransform.zw);
				color = g_SuitPrimary_Color;
				wearRemap = g_SuitPrimary_WearRemap;
				roughnessRemap = g_SuitPrimary_RoughnessRemap;
				diffBlend = g_SuitPrimary_DetailDiffuseBlend;
				normBlend = g_SuitPrimary_DetailNormalBlend;
				roughBlend = g_SuitPrimary_DetailRoughnessBlend;
				metal = g_SuitPrimary_Metalness;
				iridescenceID = g_SuitPrimary_Iridescence;
				fuzz = g_SuitPrimary_Fuzz;
				transmission = g_SuitPrimary_Transmission;
				emission = g_SuitPrimary_Emission;
				wornColor = g_WornSuitPrimary_Color;
				wornRoughRemap = g_WornSuitPrimary_RoughnessRemap;
				wornDiffBlend = g_WornSuitPrimary_DetailDiffuseBlend;
				wornNormBlend = g_WornSuitPrimary_DetailNormalBlend;
				wornRoughBlend = g_WornSuitPrimary_DetailRoughnessBlend;
				wornMetal = g_WornSuitPrimary_Metalness;
				break;
			case(6): //suit secondary
				detailDiff = Tex2DS(g_tDetailDiffuse03, TextureFiltering, (vUVs*5.0) * g_Suit_DetailDiffuseTransform.xy + g_Suit_DetailDiffuseTransform.zw);
				detailNorm = Tex2DS(g_tDetailNormal03, TextureFiltering, (vUVs*5.0) * g_Suit_DetailNormalTransform.xy + g_Suit_DetailNormalTransform.zw);
				color = g_SuitSecondary_Color;
				wearRemap = g_SuitSecondary_WearRemap;
				roughnessRemap = g_SuitSecondary_RoughnessRemap;
				diffBlend = g_SuitSecondary_DetailDiffuseBlend;
				normBlend = g_SuitSecondary_DetailNormalBlend;
				roughBlend = g_SuitSecondary_DetailRoughnessBlend;
				metal = g_SuitSecondary_Metalness;
				iridescenceID = g_SuitSecondary_Iridescence;
				fuzz = g_SuitSecondary_Fuzz;
				transmission = g_SuitSecondary_Transmission;
				emission = g_SuitSecondary_Emission;
				wornColor = g_WornSuitSecondary_Color;
				wornRoughRemap = g_WornSuitSecondary_RoughnessRemap;
				wornDiffBlend = g_WornSuitSecondary_DetailDiffuseBlend;
				wornNormBlend = g_WornSuitSecondary_DetailNormalBlend;
				wornRoughBlend = g_WornSuitSecondary_DetailRoughnessBlend;
				wornMetal = g_WornSuitSecondary_Metalness;
				break;
		}


		//Finish GStack splitting
		float flEmit = saturate((gstackTex.b - 0.15686274509) * 1.18604651163);
		float flUndyedmetal = saturate(gstackTex.a * 7.96875);
		int inDyemask = step(0.15686274509, gstackTex.a);
		float flWearmask = saturate(mad(gstackTex.a, 1.186, -0.186));
		//float flMetal = saturate(gstackTex.a * 7.96876f); //(Alpha Channel * 7.96876)
		
		//wear
		float mappedWear = Remap(flWearmask, wearRemap);
		float4 dyeColor = lerp(wornColor, color, mappedWear);		
		float dyeDiffuseBlend = lerp(wornDiffBlend, diffBlend, mappedWear);
		float dyeRoughBlend = lerp(wornRoughBlend, roughBlend, mappedWear);
		float dyeNormalBlend = lerp(wornNormBlend, normBlend, mappedWear);
		
		// Color
		float3 diffuse = Bungie_Overlay(diffuseTex.rgb, dyeColor.rgb, inDyemask);
		diffuse = Bungie_HardLight(diffuse, detailDiff.rgb, inDyemask * dyeDiffuseBlend);
	
		// Roughness
		float detailedRoughness = lerp(gstackTex.g, Bungie_Overlay(gstackTex.g, detailDiff.a, inDyemask), dyeRoughBlend);
		float mainRough = Remap(detailedRoughness, roughnessRemap);
		float wornRough = Remap(detailedRoughness, wornRoughRemap);
		float dyeRoughness = lerp(wornRough, mainRough, mappedWear);
		dyeRoughness = dyeRoughness * lerp(0.86, fuzz * 2, step(dyeRoughness, 0));
		float roughness = 1 - lerp(gstackTex.g, dyeRoughness, inDyemask);
		
		// Emission
		emission *= flEmit;
		
		// Normal maps
		float3 tnormal = saturate((lerp(normalTex.xyz, Overlay_blend(normalTex.xyz, detailNorm.xyz), inDyemask * dyeNormalBlend)));
		float cavity = saturate(lerp(normalTex.z, normalTex.z * detailNorm.z, inDyemask * dyeNormalBlend));
		NormalReconstructZ_float(tnormal.xy, tnormal);

		//Iridescence part 1
		float iridescenceDiffuseCheck = iridescenceID != -1 ? saturate(frac((round(iridescenceID) + 1) / 2)*10) : 0;
		float colorAsFloat = (color.r + color.g + color.b) / 3.0;
		float iridescenceMask = 0;
		
		// Metalness
		float iridescenceMetalMask = saturate(mad(iridescenceID/128, 1000000, -249992)) * saturate(mad(iridescenceID/128, -1000000, 445312));
		iridescenceMetalMask *= iridescenceDiffuseCheck;
		iridescenceMetalMask = iridescenceMetalMask + (iridescenceDiffuseCheck-colorAsFloat);

		float dyeMetal = lerp(lerp(wornMetal, metal, mappedWear), 1, iridescenceMetalMask);
		float metalness = lerp(flUndyedmetal, dyeMetal, inDyemask);

		//Even and odd iridescence ids affect diffuse differently but always(?) makes metalness 1
		if (iridescenceID % 2 != 0 && iridescenceID != -1) 
		{
			iridescenceMask = saturate(1 - colorAsFloat);
		}

		//--Iridescence part 2: Fresnel boogaloo
		// Get the world space position of our point
        float3 vPositionWs = i.vPositionWithOffsetWs.xyz + g_vHighPrecisionLightingOffsetWs.xyz;
        
        // Get our camera direction
        float3 vPositionToCameraDirWs = CalculatePositionToCameraDirWs( vPositionWs );
        
        // View Dot Normal
        float flVDotN =  dot( vPositionToCameraDirWs.xyz, TransformNormal( DecodeNormal( tnormal.xyz ), i.vNormalWs, i.vTangentUWs, i.vTangentVWs ));	
		///

		float4 iridescenceColor = Tex2DS(g_tIridescence, TextureFiltering2, float2(flVDotN, (0.5f + iridescenceID)/128.0f) ).rgba;
		iridescenceDiffuseCheck = (iridescenceDiffuseCheck-colorAsFloat) * inDyemask;

		//Finish up diffuse
		diffuse = lerp(diffuse.rgb, iridescenceColor.rgb, saturate(iridescenceDiffuseCheck));
		//diffuse *= flAmbientOcclusion;

		//*pow(cavity, 0.4f))
		float3 specColor = (lerp(float3(0,0,0), diffuse, metalness)) + (lerp(lerp(float3(0,0,0), iridescenceColor.rgb, iridescenceMask), float3(0,0,0), metalness));
		float3 diffuseColor = lerp(diffuse, float3(0,0,0), metalness);
		
		Material material = Material::From(i, 
						float4(saturate(diffuseColor+specColor), transparency), 
						float4(tnormal.xyz, 1), 
						float4(saturate(roughness), saturate(metalness+iridescenceMask), saturate(flAmbientOcclusion), 1), 
						float3( 1.0f, 1.0f, 1.0f ), 
						emission);

        material.Transmission = transmission;

		#if S_DECAL
			//material.Albedo = Overlay_blend(material.Albedo, g_tFrameBufferCopyTexture.Sample(TextureFiltering, i.vPositionSs.xy * g_vFrameBufferCopyInvSizeAndUvScale.xy) );
			material.Albedo += g_tFrameBufferCopyTexture.Sample(TextureFiltering, i.vPositionSs.xy * g_vFrameBufferCopyInvSizeAndUvScale.xy);
		#endif

		return ShadingModelStandard::Shade(i, material);
	}
}