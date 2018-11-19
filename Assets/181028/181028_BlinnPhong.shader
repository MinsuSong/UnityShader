Shader "Custom/BlinnPhong" {
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
		#pragma surface surf CustomBlinnPhong fullforwardshadows noambient
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

		float4 LightingCustomBlinnPhong(inout SurfaceOutput o, float3 lightDir, float3 viewDir, float atten) {
			/* 이제부터 BlinnPhong 계산할꺼야 */
			half NdotLvalue = dot(o.Normal, lightDir);	

			NdotLvalue = max(0, NdotLvalue);
			//NdotLvalue = saturate(NdotLvalue);
			
			//float3 reflectVector = 2 * o.Normal * NdotLvalue - lightDir;
			/* reflectVector 계산하는게 옛날에 비용이 많이 들어서, 개량된 L과 V의 합벡터인 H 벡터를 구한다. */
			float3 halfVector = normalize(lightDir + viewDir);
			half HdotNvalue = dot(halfVector, o.Normal);

			/* 마찬가지로 clamp 시켜준다. */

			HdotNvalue = max(0, HdotNvalue);

			float3 diffuseColor = o.Albedo * _LightColor0 * NdotLvalue * atten;
			float3 specularColor = _SpecularColor * pow (HdotNvalue, _SpecularPower);
			
			float3 finalColor = diffuseColor + specularColor;

			return float4(finalColor, 1);

			
		
		}



		ENDCG
	}
	FallBack "Diffuse"
}
