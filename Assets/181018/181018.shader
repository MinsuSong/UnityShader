Shader "Custom/181018" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
	SubShader {
		/* MEMO
		게임 화면에 오브젝트들을 렌더링할 때 어떤 순서에 의해서 그릴 것인가? 어떻게 앞에 있고 뒤에 있고를 판단할 것인가? - Painter's Algorithm
		뒤에 있는 풍경부터, 가까운 객체로 그려나간다. xy평면인 2차원 스크린에서 어떻게 이격되어있는가를 검사할까?
		Z 값, Z-buffer, 0에서부터 1까지 얼마나 이격되어 있는가를 판단하여 Z-컬링(Z값 비교, 깊이 검사)을 통해 픽셀값을 덮어쓴다. (필요없는 Z값 버림)
		
		모니터가 출력하는 화면은, 픽셀 배열로 구성되어 있고, 몇 번째 위치의 픽셀이 하나의 색을 출력하는 방식이다. 즉, 2개의 색상을 출력할 순 없다.
		우리는 반투명한 객체를 투과하여 뒤에 불투명 객체가 그려질 경우를 위해 그 색상들을 적절히 혼합하여 마치 투명도를 준 것과 같은 효과를 낼 수 있다.

		위의 내용들을 위해서 버퍼의 경우에는 2 개의 버퍼를 사용하며, 하나는 색상 (R,G,B,A) 버퍼, 다른 하나는 깊이값(Z) 버퍼 이다. 

		불투명한 객체는? 서로 깊이 검사를 실시한 후 Z 버퍼에서 Z 값을 갱신
		투명하거나 반투명한 객체는? 뒤에 있는 객체를 그려줘야함. 즉 투과율이나 반사상태, 투명객체의 고유 색상에 따라서 뒤에 있는 색과 Blend 되어야함.
		그래서 앞에 있냐 뒤에 있냐를 판단하기 위해 깊이 검사는 실시하되, Z 버퍼를 갱신하지 않고 최소 Z 값만 가지고 있으면, Z 값 비교에 의한 컬러버퍼를 
		버리는 행위를 하지 않아 Blend 할 수 있게 됨.

		만약에 투명 객체를 그린 후, 불투명객체를 그리면 Z-컬링에 의해 뒤에 있는 불투명객체가 지워지게 됨. 그래서 불투명한 객체를 먼저 그리고, 투명한
		객체를 그려야 알파블렌딩으로 뒤에 있던 불투명객체와 투명객체의 중간값 색으로 적절히 Blend 된 색상으로 대체될 수 있는 것임.

		이와 같이 렌더링에는 그리는 순서가 매우 중요. 따라서 Unity에서 이런 순서에 맞는 렌더링을 처리해주기 위하여 '큐' 자료구조를 사용한다.
		렌더링 큐는 unity에서 지원하는 자료구조로 0~5000까지 총 5001개의 객체들의 순서를 정해줄 수 있다.
		하나의 쉐이더당 하나의 렌더링 순서를 정의할 수 있다. 렌더링 순서를 미리 정의(약속)한 것이 대하여
		1000:Background, 2000:Geometry, 2450:Alphatest(혼합객체, ex- 불투명한 것도 있는), 3000:Transparent(반투명), 4000:overlay(ex- Sunlight overlay)
			순서를 임의로 정의할 수 도 있는데 "기준값 - 상수" 형태로 설정할 수 있다.
		*/

		Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
		/* 위에 기술한 키워드에 대하여 RenderType에 쓰이면 범위값으로, Queue에 쓰이면 고정상수 값으로 쓰인다. 
		그리고 Tag { } 안에 컴마 , 절대 넣지 마시오. 오류 일어남. */
		LOD 200

		/* Alphablending → SrcColor * SrcFactor (+/-/Min/Max..etc) DstColor * DstFactor
		Blend 코드를 적어보자. SrcColor랑 DstColor는 생략하고 SrcFactor와 DstFactor를 적는다. 
		연산자를 생략하면 + 연산으로 들어감. SrcFactor는 바로 그 Source의 Alpha값임 OneMinusSrcAlpha는 DstFactor를 1-SrcAlpha란 의미.
		Factor에 Color를 넣을 수 있다. 
		쉐이더 코드이기 때문에 CG 코드 위에 적어줘야함. 
		*/

		//Blend One One
		//Blend DstColor Zero	
		//Blend DstColor SrcColor
		//Blend SrcAlpha One
		Blend SrcAlpha OneMinusSrcAlpha
		/* AlphaBlend는 해상도에 대해 모든 픽셀을 계산하니까 굉장히 무거운 연산이고 남발하지말고 필요한 곳에서만 적용할 것 */
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows keepalpha

			/* keepalpha - 디폴트로 불투명 표면 셰이더는 출력 구조의 Alpha 안의 출력이 무엇이건, 또는 조명 함수가 무엇을 반환하건 간에
			1.0(흰색)을 알파 채널에 씁니다. 이 옵션을 사용하면 불투명 표면 셰이더에도 조명 함수의 알파 값을 유지할 수 있습니다.
			출처 : https://docs.unity3d.com/kr/2018.1/Manual/SL-SurfaceShaders.html
			*/

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

			/*
			SurfaceOutput 은 기본적으로 표면의 프로퍼티를 기술합니다(알베도 컬러, 노멀, 이미션, 반사도 등). 이 코드는 HLSL 로 작성합니다.
			struct SurfaceOutput
			{
			    fixed3 Albedo;  // diffuse color
			    fixed3 Normal;  // tangent space normal, if written
			    fixed3 Emission;
			    half Specular;  // specular power in 0..1 range
			    fixed Gloss;    // specular intensity
			    fixed Alpha;    // alpha for transparencies
			}; 로 구성되어 있다.

			Unity 5 에서 표면 셰이더는 물리 기반 조명 모델을 사용할 수도 있습니다. 내장된 Standard 및 StandardSpecular 조명 모델(아래 참조)은 각각 아래와 같은 출력 구조를 사용합니다.

			struct SurfaceOutputStandard
			{
			fixed3 Albedo;      // base (diffuse or specular) color
			fixed3 Normal;      // tangent space normal, if written
			half3 Emission;
			half Metallic;      // 0=non-metal, 1=metal
			half Smoothness;    // 0=rough, 1=smooth
			half Occlusion;     // occlusion (default 1)
			fixed Alpha;        // alpha for transparencies
			};
			출처:https://docs.unity3d.com/kr/2018.1/Manual/SL-SurfaceShaders.html
			*/

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
