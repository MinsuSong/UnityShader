Shader "Custom/ToonShading" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Cell ("Cell", Range(0, 10)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf CustomToonShading fullforwardshadows noambient
		/* unity 엔진에서 엠비언트 광에 대해서 자동으로 계산해줘서, 그 광원 안쓸꺼라고 noambient라고 한다. */

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};
		half _Cell;
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

		float4 LightingCustomToonShading(inout SurfaceOutput o, float3 lightDir, float atten) {
			/* 이제부터 ToonShading 계산할꺼야 */
			half NdotLvalue = dot(o.Normal, lightDir);
			NdotLvalue = max(0, NdotLvalue);
			//NdotLvalue = saturate(NdotLvalue);
			
			NdotLvalue = floor(NdotLvalue * _Cell) / (_Cell - 0.5);

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
