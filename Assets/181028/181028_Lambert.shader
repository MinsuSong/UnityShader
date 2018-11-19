Shader "Custom/Lambert" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf CustomLambert fullforwardshadows noambient
		/* unity 엔진에서 엠비언트 광에 대해서 자동으로 계산해줘서, 그 광원 안쓸꺼라고 noambient라고 한다. */

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutput o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}

		/* Lighting model 만들때 Lighting이라는 구문을 적어줘야 unity가 조명함수라는 것을 알아듣는다. 
		함수 인자로 3개 넣을껀데, Standard 모델 안쓰니까 수정한다. 빛벡터는 월드좌표나, 방향벡터같이 등록 안해도 알아서 함.
		지맘대로임. */

		/* attenuation -> 빛과 조명을 받을 객체와의 거리에 따라 빛파동이 약해진 것 (빛의 량 감쇠) 
		Directional light는 태양광, 즉 일조량이 어느 지역 어디든 일정할 것이라고 가정하여 attenuation은 1로 고정되어 있다. */
		float4 LightingCustomLambert(inout SurfaceOutput o, float3 lightDir, float atten) {
			/* 이제부터 lambert 계산할꺼야 */
			half NdotLvalue = dot(o.Normal, lightDir);	/* 쉐이더 코드에서 지원하는 내적 함수 */
			/* 근데, 조명 계산할 때는 음수값이 나오면 안돼. 왜냐면 음수로 내려간 값도 처리해야할 필요가 있으니까. Clamp시켜줘야함 */
			NdotLvalue = max(0, NdotLvalue);
			//NdotLvalue = saturate(NdotLvalue);
			
			float3 diffuseColor = o.Albedo * _LightColor0 * NdotLvalue * atten;
			/* o.Albedo -> 표면의 색상, 단면의 색상 정보 */
			/* _LightColor0 -> 조명의 색상, 걍 암기하셈 불만갖지말고 */
			/* Albedo와 Diffuse 광의 차이가 뭘까? Diffuse는 광원과 계산된 결과. 즉 표면색에 음영까지 계산된 결과
			텍스쳐 얘기할 때, 디퓨즈 텍스쳐와 알비도 텍스쳐의 차이. 디퓨즈 텍스처(광원까지 그려넣음)는 모바일 겜에 보통 사용
			광원계산 = 무거운 연산 */
			return float4(diffuseColor, 1); /* (r,g,b,a) 할때, (float3, a)로 쓸 수 있는 것은 HLSL, GLSL, CG까지 쉐이더 프로그램
											공통적인 문법요소. 참고할 것. */
		
		
		}



		ENDCG
	}
	FallBack "Diffuse"
}
