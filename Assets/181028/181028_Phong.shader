Shader "Custom/Phong" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_SpecularColor("Color", Color) = (1,1,1,1)
		_SpecularPower("SpecularPower", Range(0,100)) = 1.0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf CustomPhong fullforwardshadows noambient
		/* unity 엔진에서 엠비언트 광에 대해서 자동으로 계산해줘서, 그 광원 안쓸꺼라고 noambient라고 한다. */

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		fixed4 _Color;
		float4 _SpecularColor;
		half _SpecularPower;

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

		float4 LightingCustomPhong(inout SurfaceOutput o, float3 lightDir, float3 viewDir, float atten) {
			/* 이제부터 Phong 계산할꺼야 */
			half NdotLvalue = dot(o.Normal, lightDir);	

			NdotLvalue = max(0, NdotLvalue);
			//NdotLvalue = saturate(NdotLvalue);
			
			/* R(reflect) 벡터 계산하는 것. 겜수 참고 2*N * (N*L) - L */
			float3 reflectVector = 2 * o.Normal * NdotLvalue - lightDir;

			/* R과 viewDir을 내적한다. (왜냐면 하이라이트의 크기와 광원 밝기정도는 시선에 따라 달라질테니까 */
			float RdotVvalue = dot(reflectVector, viewDir);

			/* 마찬가지로 clamp해준다. */
			RdotVvalue = max(0, RdotVvalue);

			float3 diffuseColor = o.Albedo * _LightColor0 * NdotLvalue * atten;
			
			/* Phong = specular + diffuse */
			
			float3 specularColor = _SpecularColor * pow ( RdotVvalue, _SpecularPower) * _LightColor0 * atten;
			/* pow ( r*vVector, specularPower) 한 이유는 r*vVector가 0~1 정규화된 벡터라서 거듭제곱꼴 취해주면 점점 분모가 커져서
			숫자는 작아지고 그래서 하이라이트도 작아짐 */
			
			float3 finalColor = diffuseColor + specularColor;

			return float4(finalColor, 1);

			
		
		}



		ENDCG
	}
	FallBack "Diffuse"
}
