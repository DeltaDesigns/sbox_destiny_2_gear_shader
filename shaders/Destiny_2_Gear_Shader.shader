//=========================================================================================================================
// Optional
//=========================================================================================================================
HEADER
{
	Description = "Destiny 2 Player Gear Shader";
	Version = 1;
}

FEATURES
{
	#include "common/features.hlsl"
}

//=========================================================================================================================
// Optional
//=========================================================================================================================
MODES
{
    VrForward();													// Indicates this shader will be used for main rendering
    Depth( "vr_depth_only.vfx" ); 									// Shader that will be used for shadowing and depth prepass
    ToolsVis( S_MODE_TOOLS_VIS ); 									// Ability to see in the editor
    ToolsWireframe( "vr_tools_wireframe.vfx" ); 					// Allows for mat_wireframe to work
	ToolsShadingComplexity( "vr_tools_shading_complexity.vfx" ); 	// Shows how expensive drawing is in debug view
	Reflection( "high_quality_reflections.vfx" );
}

//=========================================================================================================================

FEATURES
{
	Feature( F_HIGH_QUALITY_REFLECTIONS, 0..1, "Rendering" );

	Feature(F_VERTEX_ANIMATION, 0..1, "Animation");
	// Feature(F_VERTEXANIM_BLENDSHAPE, 0..1, "Animation");
	// Feature(F_VERTEXANIM_NORMALSPACE, 0..1, "Animation");
	// Feature(F_VERTEXANIM_OBJECTSPACE, 0..1, "Animation");
	// Feature(F_VERTEXANIM_OBJECTSPACEX, 0..1, "Animation");
	// Feature(F_VERTEXANIM_OBJECTSPACEY, 0..1, "Animation");
	// Feature(F_VERTEXANIM_OBJECTSPACEZ, 0..1, "Animation");

	Feature(F_DECAL, 0..1, "Blending");
	Feature(F_DYE_MAP, 0..1, "Dye Map");

	Feature(F_DIFFUSE_MAP, 0..1, "Debugs");
	Feature(F_NORMAL_MAP, 0..1, "Debugs");
	Feature(F_METAL_MAP, 0..1, "Debugs");
	//Feature(F_ROUGH_MAP, 0..1, "Debugs");
	Feature(F_IRIDESCENCE_MAP, 0..1, "Debugs");
	Feature(F_IRIDESCENCE_MASK_MAP, 0..1, "Debugs");
	Feature(F_EMISSION_MAP, 0..1, "Debugs");

	FeatureRule(Allow1(F_DIFFUSE_MAP, F_METAL_MAP, F_NORMAL_MAP, F_IRIDESCENCE_MAP, F_IRIDESCENCE_MASK_MAP, F_EMISSION_MAP), "");


}

COMMON
{
	#include "common/shared.hlsl"
	#define S_SPECULAR 1
    #define S_SPECULAR_CUBE_MAP 1
	#define USES_HIGH_QUALITY_REFLECTIONS
	#define D_NO_MODEL_TINT 1
}

//=========================================================================================================================

struct VertexInput
{
	#include "common/vertexinput.hlsl"
	
	float2 vSlots : TEXCOORD2 < Semantic( Texcoord2 ); >;
	float4 vVertexAnim	: COLOR0 < Semantic( Color ); >;
	float4 vColor	: COLOR1 < Semantic( Color1 ); >;	
};

//=========================================================================================================================

struct PixelInput
{
	#include "common/pixelinput.hlsl"
	float4 vColor	: COLOR0;
	float2 vSlots : TEXCOORD14;
};

//=========================================================================================================================

VS
{
	#include "common/vertex.hlsl"

	StaticCombo( S_VERTEX_ANIMATION, F_VERTEX_ANIMATION, Sys( PC ) );
	BoolAttribute( UsesHighQualityReflections, ( F_HIGH_QUALITY_REFLECTIONS > 0 ) );
	
	#if(S_VERTEX_ANIMATION)
		float fl_VertexAnim_Speed < Default( 1.0f ); Range(0, 10.0f); UiGroup( "Vertex Animation,0" ); >;
		FloatAttribute( fl_VertexAnim_Speed, fl_VertexAnim_Speed );

		float fl_VertexAnim_Scale < Default( 0.0f ); Range(0, 10.0f); UiGroup( "Vertex Animation,0" ); >;
		FloatAttribute( fl_VertexAnim_Scale, fl_VertexAnim_Scale );
	#endif
		

	//
	// Main
	//
	PixelInput MainVs( INSTANCED_SHADER_PARAMS( VS_INPUT i ) )
	{
		PixelInput o = ProcessVertex( i );
		const float PI = 3.14159265;


		#if(S_VERTEX_ANIMATION)

			uint nView = uint( 0 );
			uint nSubview = uint( 0 );
			#if ( D_MULTIVIEW_INSTANCING )
				GetViewAndSubview( i.nInstanceID, nView, nSubview );
				o.nView = nView;
			#endif

			float3x4 matObjectToWorld = CalculateInstancingObjectToWorldMatrix( INSTANCING_PARAMS( i ) );
			
			float4 vVertexAnim = i.vVertexAnim;
			//move the vertex around on the x axis
			float str = ((cos((vVertexAnim.g + vVertexAnim.b)*PI + g_flTime * fl_VertexAnim_Speed)) * fl_VertexAnim_Scale) * vVertexAnim.r;
			o.vPositionPs.x += str;

			// float3 vVertexPosWs = mul( matObjectToWorld, float4(i.vPositionOs, 1.0 ) );

			// o.vPositionPs.x = Vector3WsToVs(vVertexPosWs).x;



			// uint nView = uint( 0 );
			// uint nSubview = uint( 0 );
			// #if ( D_MULTIVIEW_INSTANCING )
			// 	GetViewAndSubview( i.nInstanceID, nView, nSubview );
			// 	o.nView = nView;
			// #endif

			// #if S_VERTEXANIM_BLENDSHAPE
			// 	o.vPositionPs = Position3WsToPsMultiview (nView, i.vPositionOs + ((i.vVertexAnim.gbr-0.5) * int3(-1,1,1) * cos(g_flTime) * fl_VertexAnim_Scale));
			// #elif S_VERTEXANIM_OBJECTSPACE
			// 	float str = ((cos((i.vVertexAnim.g + i.vVertexAnim.b)*PI + g_flTime * fl_VertexAnim_Speed)) * fl_VertexAnim_Scale) * i.vVertexAnim.r;
			// 	#if S_VERTEXANIM_OBJECTSPACEX
			// 		i.vPositionOs.x += str;
			// 	#endif
			// 	#if S_VERTEXANIM_OBJECTSPACEY
			// 		i.vPositionOs.y += str;
			// 	#endif
			// 	#if S_VERTEXANIM_OBJECTSPACEZ
			// 		i.vPositionOs.z += str;
			// 	#endif
			// 	o.vPositionPs = Position3WsToPsMultiview (nView, i.vPositionOs);
			// #elif S_VERTEXANIM_NORMALSPACE
			// 	o.vPositionPs = Position3WsToPsMultiview (nView, i.vPositionOs + (((cos((i.vVertexAnim.g + i.vVertexAnim.b)*PI + g_flTime * fl_VertexAnim_Speed)) * fl_VertexAnim_Scale + _VertexAnim_Scale) * i.vVertexAnim.r) * normalize(v.normal));
			// #else
			// 	o.vPositionPs = Position3WsToPsMultiview (nView, i.vPositionOs);
			// #endif
		#endif

		o.vColor = i.vColor;
		o.vSlots = i.vSlots;
		
		// Add your vertex manipulation functions here
		return FinalizeVertex( o );
	}
}

//=========================================================================================================================

PS
{
	#define CUSTOM_TEXTURE_FILTERING
	//Should be POINT instead of ANISOTROPIC for better accuracy, but POINT causes weird artifact type things 
    SamplerState TextureFiltering2 < Filter( ANISOTROPIC ); AddressU( BORDER ); AddressV( BORDER ); AddressW( BORDER ); MaxAniso( 8 ); >;
	SamplerState TextureFiltering < Filter( (F_TEXTURE_FILTERING == 0 ? ANISOTROPIC : ( F_TEXTURE_FILTERING == 1 ? BILINEAR : ( F_TEXTURE_FILTERING == 2 ? TRILINEAR : ( F_TEXTURE_FILTERING == 3 ? POINT : NEAREST ) ) ) ) ); MaxAniso( 8 ); >;

	//Includes
	#include "sbox_pixel.fxc"

	#include "common/pixel.config.hlsl"
	#include "common/pixel.material.structs.hlsl"
	#include "common/pixel.lighting.hlsl"
	#include "common/pixel.shading.hlsl"

	#include "common/pixel.material.helpers.hlsl"
	//---------------------------------------------------------------------------------------------
	
	StaticCombo( S_DECAL, F_DECAL, Sys( PC ) );
	StaticCombo( S_DYE_MAP, F_DYE_MAP, Sys( PC ) );

	//Debug/buffer view modes
	StaticCombo( S_DIFFUSE_MAP, F_DIFFUSE_MAP, Sys( PC ) );
	StaticCombo( S_NORMAL_MAP, F_NORMAL_MAP, Sys( PC ) );
	StaticCombo( S_METAL_MAP, F_METAL_MAP, Sys( PC ) );
	//StaticCombo( S_ROUGH_MAP, F_ROUGH_MAP, Sys( PC ) );
	StaticCombo( S_IRIDESCENCE_MAP, F_IRIDESCENCE_MAP, Sys( PC ) );
	StaticCombo( S_IRIDESCENCE_MASK_MAP, F_IRIDESCENCE_MASK_MAP, Sys( PC ) );
	StaticCombo( S_EMISSION_MAP, F_EMISSION_MAP, Sys( PC ) );

	//---------------------------------------------------------------------------------------------
	//Main texture inputs

	CreateInputTexture2D( TextureColor, Srgb, 8, "", "_Diffuse", "Material,10/19", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDiffuse ) < Channel( RGBA, Box( TextureColor ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDiffuse, g_tDiffuse );

	CreateInputTexture2D( TextureGStack, Linear, 8, "", "_GStack", "Material,10/20", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tGStack ) < Channel( RGBA, Box( TextureGStack ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tGStack, g_tGStack );

	CreateInputTexture2D( TextureNormal, Linear, 8, "NormalizeNormals", "_Normal", "Material,10/21", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tNormal ) < Channel( RGBA, Box( TextureNormal ), Linear ); OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tNormal, g_tNormal );

	CreateInputTexture2D( TextureDyeMap, Linear, 8, "", "_Dyemap", "Material,10/40", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDyeTex ) < Channel( RGBA, Box( TextureDyeMap ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDyeTex, g_tDyeTex );

	CreateInputTexture2D( TextureIridescence, Srgb, 8, "", "_lookup", "Material,10/40", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tIridescence ) < Channel( RGBA, Box( TextureIridescence ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tIridescence, g_tIridescence );

	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	//Detail Texture Inputs

	CreateInputTexture2D( TextureDetailDiffuse01, Srgb, 8, "", "", "Detail Textures,11/20", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse01 ) < Channel( RGBA, Box( TextureDetailDiffuse01 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse01, g_tDetailDiffuse01 );

	CreateInputTexture2D( TextureDetailNormal01, Linear, 8, "", "", "Detail Textures,11/20", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal01 ) < Channel( RGBA, Box( TextureDetailNormal01 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal01, g_tDetailNormal01 );

	CreateInputTexture2D( TextureDetailDiffuse02, Srgb, 8, "", "", "Detail Textures,11/20", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse02 ) < Channel( RGBA, Box( TextureDetailDiffuse02 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse02, g_tDetailDiffuse02 );

	CreateInputTexture2D( TextureDetailNormal02, Linear, 8, "", "", "Detail Textures,11/20", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal02 ) < Channel( RGBA, Box( TextureDetailNormal02 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal02, g_tDetailNormal02 );

	CreateInputTexture2D( TextureDetailDiffuse03, Srgb, 8, "", "", "Detail Textures,11/20", Default3( 1.0, 1.0, 1.0 ) );
	CreateTexture2DWithoutSampler( g_tDetailDiffuse03 ) < Channel( RGBA, Box( TextureDetailDiffuse03 ), Srgb ); OutputFormat( BC7 ); SrgbRead( true ); >;
	TextureAttribute( g_tDetailDiffuse03, g_tDetailDiffuse03 );

	CreateInputTexture2D( TextureDetailNormal03, Linear, 8, "", "", "Detail Textures,11/20", Default3( 0.5, 0.5, 1 ) );
	CreateTexture2DWithoutSampler( g_tDetailNormal03 ) < Channel( RGBA, Box( TextureDetailNormal03 ), Linear );  OutputFormat( BC7 ); SrgbRead( false ); >;
	TextureAttribute( g_tDetailNormal03, g_tDetailNormal03 );

	//End of Detail Textures
	//--------------------------------------------------------------------------------------------------------------------


	//SHADER INPUTS
	//---------------------------------------------------------------------------------------------------------------------
	float g_flMaskClipValue < Default( 0.5f ); Range(0, 1.0f); UiGroup( "Material,10/41" ); >;
	FloatAttribute( g_flMaskClipValue, g_flMaskClipValue );

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

	//--------------------------------------------------------------------------------------------------------------------

	//color space convert
	void ColorspaceConversion_RGB_Linear_float(float4 In, out float4 Out)
	{
		float4 linearRGBLo = In / 12.92;;
		float4 linearRGBHi = pow(max(abs((In + 0.055) / 1.055), 1.192092896e-07), float4(2.4, 2.4, 2.4, 1));
		Out = float4(In <= 0.04045) ? linearRGBLo : linearRGBHi;
	}
	
	void ColorspaceConversion_RGB_Linear_float(float In, out float Out)
	{
		float linearRGBLo = In / 12.92;;
		float linearRGBHi = pow(max(abs((In + 0.055) / 1.055), 1.192092896e-07), float3(2.4, 2.4, 2.4));
		Out = In <= 0.04045 ? linearRGBLo : linearRGBHi;
	}
	
	void ColorspaceConversion_Linear_RGB_float(float4 In, out float4 Out)
	{
		float4 sRGBLo = In * 12.92;
		float4 sRGBHi = (pow(max(abs(In), 1.192092896e-07), float4(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4, 1.0)) * 1.055) - 0.055;
		Out = float4(In <= 0.0031308) ? sRGBLo : sRGBHi;
	}
	
	void ColorspaceConversion_Linear_RGB_float(float In, out float Out)
	{
		float sRGBLo = In * 12.92;
		float sRGBHi = (pow(max(abs(In), 1.192092896e-07), float3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4)) * 1.055) - 0.055;
		Out = In <= 0.0031308 ? sRGBLo : sRGBHi;
	}

	//Blend modes
	float4 Overlay (float4 cBase, float4 cBlend, float fac)
	{
		float4 cNew = cBlend * saturate(cBase * 4.0f) + saturate(cBase - 0.25f);
		cNew.a = 1.0;
		return lerp(cBase, cNew, fac);
	}
	
	float4 HardLight (float4 cBase, float4 cBlend, float fac)
	{
		float4 cNew = cBase * saturate(cBlend * 4.0f) + saturate(cBlend - 0.25f);
		cNew.a = 1.0;
		return lerp(cBase, cNew, fac);
	}
	
	float4 BlendMode_Overlay(float4 cBase, float4 cBlend)
	{
		float isLessOrEq = step(cBase, .5);
		float4 cNew = lerp(2*cBlend*cBase, 1 - (1 - 2*(cBase - .5))*(1 - cBlend), isLessOrEq);
		return cNew;
	}
	////////////
	
	float Remap (float val, float4 remap)
	{
		return clamp( val * remap.y + remap.x, remap.z, remap.z + remap.w );
	}
	

	void NormalReconstructZ_float(float2 In, out float3 Out)
	{
		float reconstructZ = sqrt(1.0 - saturate(dot(In.xy, In.xy)));
		float3 normalVector = float3(In.x, In.y, reconstructZ);
		Out = normalize(normalVector);
	}

	class ShadingModelD2Gear : ShadingModel //just the valve shading model (just using here in case it gets removed at some point)
	{
		CombinerInput Input;
		LightingTerms_t lightingTerms;
		float3 specColor;
		float specStrength;

		CombinerInput MaterialToCombinerInput( PixelInput i, Material m )
		{
			CombinerInput o;

			o = PS_CommonProcessing( i );
			
			#if ( S_ALPHA_TEST )
			{
				// Clip first to try to kill the wave if we're in an area of all zero
				o.flOpacity = m.Opacity * o.flOpacity;
				clip( o.flOpacity - .001 );

				o.flOpacity = AdjustOpacityForAlphaToCoverage( o.flOpacity, g_flAlphaTestReference, g_flAntiAliasedEdgeStrength, i.vTextureCoords.xy );
				clip( o.flOpacity - 0.001 );
			}
			#elif ( S_TRANSLUCENT )
			{
				o.flOpacity *= m.Opacity * g_flOpacityScale;
			}
			#endif

			o = CalculateDiffuseAndSpecularFromAlbedoAndMetalness( o, m.Albedo.rgb, m.Metalness );

			o.vNormalWs = m.Normal;
			o.vNormalTs = 0.0f;
			o.vRoughness = m.Roughness.xx;
			o.vEmissive = m.Emission;
			o.flAmbientOcclusion = m.AmbientOcclusion.x;
			o.vTransmissiveMask = m.Transmission;

			return o;
		}

		void Init( const PixelInput pixelInput, const Material material )
		{
			lightingTerms = InitLightingTerms();
			Input = MaterialToCombinerInput( pixelInput, material );
			Input.vGeometricNormalWs.xyz = material.Normal;
			Input.vRoughness.xy = AdjustRoughnessByGeometricNormal( Input.vRoughness.xy, Input.vGeometricNormalWs.xyz );
		}
		
		LightShade Direct( const LightData light )
		{
			LightShade o;
			o.Diffuse = 0;
			o.Specular = 0;
			return o;
		}
		
		LightShade Indirect()
		{
			ComputeDirectLighting( lightingTerms, Input );
			CalculateIndirectLighting( lightingTerms, Input );

			float3 vDiffuseAO = CalculateDiffuseAmbientOcclusion( Input, lightingTerms );
			lightingTerms.vIndirectDiffuse.rgb *= vDiffuseAO.rgb;
			lightingTerms.vDiffuse.rgb *= lerp( float3( 1.0, 1.0, 1.0 ), vDiffuseAO.rgb, Input.flAmbientOcclusionDirectDiffuse );
			
			float3 vSpecularAO = CalculateSpecularAmbientOcclusion( Input, lightingTerms );
			lightingTerms.vIndirectSpecular.rgb *= vSpecularAO.rgb;
			lightingTerms.vSpecular.rgb *= lerp( float3( 1.0, 1.0, 1.0 ), vSpecularAO.rgb, Input.flAmbientOcclusionDirectSpecular );

			LightShade o;
			o.Diffuse = ( ( lightingTerms.vDiffuse.rgb + lightingTerms.vIndirectDiffuse.rgb ) * Input.vDiffuseColor.rgb ) + Input.vEmissive.rgb;
			o.Specular = (lightingTerms.vSpecular.rgb + lightingTerms.vIndirectSpecular.rgb);
			return o;
		}

		float4 PostProcess( float4 vColor )
		{
			//No post processing
			PixelOutput o;
			o.vColor = vColor;
			o = PS_FinalCombinerDoPostProcessing( Input, lightingTerms, o );
			return o.vColor;
		}
	};

	//-------------------------------------------------------------------------------------------------------------------------------------------------------------

	float4 MainPs( PixelInput i ) : SV_Target0
	{
		//Material m = GatherMaterial( i );

		float2 vUVs = i.vTextureCoords.xy;
		//float2 slots = float2(0,0);

		float4 diffusetex = Tex2DS(g_tDiffuse, TextureFiltering, vUVs );
		float4 flGStack = Tex2DS( g_tGStack, TextureFiltering, vUVs );
		float4 normaltex = Tex2DS(g_tNormal, TextureFiltering, vUVs );

		float4 flDyeMap = Tex2DS( g_tDyeTex, TextureFiltering, vUVs );
		flDyeMap = pow(flDyeMap, 2.233333333);
		ColorspaceConversion_Linear_RGB_float(flDyeMap, flDyeMap);

		// Alpha clipping is done as early as possible to minimize extraneous processing cycles
		float transparency = 1;
		if (i.vSlots.y < 0.5)
		{
			transparency = saturate(flGStack.b * 7.96875);
			clip(transparency - lerp(g_flMaskClipValue, 1, g_flMaskClipValue));
		}  
		#if(S_DECAL)
			transparency = diffusetex.a;
			clip(transparency - lerp(g_flMaskClipValue, 1, g_flMaskClipValue));
			flGStack = float4(0.5,0.5,0,0);
		#endif

		float flAmbientOcclusion = flGStack.r;
		float flRoughness = saturate(1 - flGStack.g);
		//
		
		#if (S_DYE_MAP)
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
		float metal = float(0.0f);;
		int iridescenceID = 0;
		float fuzz = float(0.0f);;
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
		float flEmit = saturate((flGStack.b - 0.15686274509) * 1.18604651163);
		float flUndyedmetal = saturate(flGStack.a * 7.96875);
		int inDyemask = step(0.15686274509, flGStack.a);
		float flWearmask = saturate((flGStack.a - 0.18823529411) * 1.23188405797);
		//float flMetal = saturate(flGStack.a * 7.96876f); //(Alpha Channel * 7.96876)
		
		//wear
		float mappedWear = Remap(flWearmask, wearRemap);
		float4 dyeColor = lerp(wornColor, color, mappedWear);		
		float dyeDiffuseBlend = lerp(wornDiffBlend, diffBlend, mappedWear);
		float dyeRoughBlend = lerp(wornRoughBlend, roughBlend, mappedWear);
		float dyeNormalBlend = lerp(wornNormBlend, normBlend, mappedWear);
		
		// Color
		float4 diffuse = Overlay(diffusetex, dyeColor, inDyemask);
		//diffuse = pow(diffuse, 2.233333333);
		//ColorspaceConversion_RGB_Linear_float(diffuse, diffuse);

		diffuse = HardLight(diffuse, detailDiff, inDyemask * dyeDiffuseBlend);
		//ColorspaceConversion_Linear_RGB_float(diffuse.rgba, diffuse.rgba);
	
		// Roughness
		float detailedRoughness = lerp(flGStack.g, Overlay(flGStack.g, detailDiff.a, inDyemask), dyeRoughBlend);
		float mainRough = Remap(detailedRoughness, roughnessRemap);
		float wornRough = Remap(detailedRoughness, wornRoughRemap);
		float dyeRoughness = lerp(wornRough, mainRough, mappedWear);
		dyeRoughness = dyeRoughness * lerp(0.86, fuzz * 2, step(dyeRoughness, 0));
		float roughness = 1 - lerp(flGStack.g, dyeRoughness, inDyemask);
		ColorspaceConversion_Linear_RGB_float(roughness, roughness);
		
		// Emission
		emission *= flEmit;
		
		// Normal maps
		float3 tnormal = saturate((lerp(normaltex, BlendMode_Overlay(normaltex, detailNorm), inDyemask * dyeNormalBlend)));
		float cavity = saturate(lerp(normaltex.z, normaltex.z * detailNorm.z, inDyemask * dyeNormalBlend));
		
		NormalReconstructZ_float(tnormal.xy, tnormal);

		//cavity = tnormal.z;
		//invert Y channel of the normal map
		tnormal.y = 1-tnormal.y;
	
		//Iridescence part 1
		float3 wearRemapB = float3(wearRemap.w, metal, wornMetal);
		float iridescenceMask = ((inDyemask-(float)color) - saturate(mad(wearRemapB.y, 10000.0, 0))) * ((iridescenceID > 0 ? 1 : 0) - saturate(frac((floor(iridescenceID) + 1) / 2) * 10));
		
		// Metalness
		float iridescenceMetalMask = ( ( saturate(mad(iridescenceID/128, 1000000, -249992)) * saturate(mad(iridescenceID/128, -1000000, 445312)) ) * (saturate(frac((floor(iridescenceID) + 1) / 2) * 10)) ) + ((saturate(frac((floor(iridescenceID) + 1) / 2) * 10))-(float)color);
		float dyeMetal = saturate( lerp(lerp(wornMetal, metal, mappedWear), 1, iridescenceMetalMask));
		float metalness = lerp(flUndyedmetal, dyeMetal, inDyemask);

		float3 PositionWs = i.vPositionWithOffsetWs + g_vCameraPositionWs;
		float viewDir = dot(TransformNormal( i, saturate(DecodeHemiOctahedronNormal( tnormal.xy ))), CalculatePositionToCameraDirWs( PositionWs ));
		
		float4 iridescenceColor = Tex2DS(g_tIridescence, TextureFiltering2, float2(viewDir, (0.5f + iridescenceID)/128.0f) ).rgba;
		float3 iridescenceCheck = lerp(float3(0.01, 0.01, 0.01), iridescenceColor.rgb, saturate(iridescenceMask));
		float iridescenceDiffuseCheck = ((saturate(frac((floor(iridescenceID) + 1) / 2) * 10))-(float)color) * inDyemask;

		//Finish up Iridescence
		diffuse = lerp(diffuse, saturate(iridescenceColor), iridescenceDiffuseCheck);
		float3 specColor = saturate(lerp(iridescenceCheck, diffuse.rgb, metalness)*pow(cavity, 0.4f));
		float specStrength = 0.25 * (1 - iridescenceMask);

		// Finish up AO
		flAmbientOcclusion = (diffuse * flGStack.r * (1 - flGStack.r) + flGStack.r);
		diffuse *= flAmbientOcclusion;

		float3 newDiffuse = diffuse.rgb * (lerp(lerp(float3(1,1,1), float3(0,0,0), saturate(metalness) ), (1-iridescenceColor.a), saturate(iridescenceMask)));
		
		/// Create material halfway to get the correct normal map
		Material material = ToMaterial(i, float4(saturate(newDiffuse+specColor), 1), float4(tnormal, 1), float4(roughness, metalness, flAmbientOcclusion, 1 ), float3( 1.0f, 1.0f, 1.0f ), emission);
		///

		if (iridescenceID % 2 != 0 && iridescenceID != -1) //Even iridescenceID
		{
			material.Metalness = 1;
		}

		//DONE!!!!?

		//////DEBUG OUTPUTS
		#if (S_DIFFUSE_MAP)
			material.Albedo = newDiffuse;
			material.Emission = newDiffuse;
		#elif (S_NORMAL_MAP)
			material.Albedo = tnormal;
			material.Emission = tnormal;
		#elif (S_METAL_MAP)
			material.Albedo = material.Metalness;
			material.Emission = material.Metalness;
		// #elif (S_ROUGH_MAP)
		// 	m.Albedo = roughness;
		#elif (S_IRIDESCENCE_MAP)
			material.Albedo = specColor;
			material.Emission = specColor;
		#elif (S_IRIDESCENCE_MASK_MAP)
			material.Albedo = iridescenceMask;
			material.Emission = iridescenceMask;
		#elif (S_EMISSION_MAP)
			material.Albedo = material.Emission;
			material.Emission = material.Emission;
		#endif

		//ShadingModelValveStandard sm;

		ShadingModelD2Gear sm;

		sm.Init(i, material);

		sm.specColor = specColor;
		sm.specStrength = specStrength;

		return FinalizePixelMaterial( i, material, sm );
	}
}