Shader "Custom/181104newSoldierHead" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_Amount ("AmountofPushing", Range(-0.0001, 0.0001)) = 0.0
	}
	SubShader {
			/* 버텍스 쉐이더 할 거임. 버텍스를 직접 이동시키는 연산을 하기 위해서 */
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows vertex:vert
			/* surface 쉐이더에게 추가 연산을 하고자 버텍스 쉐이더를 사용할 때, "vertex"는 버텍스 쉐이더
			vert는 유니티 쉐이더에게 함수명 알려준거. */

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Amount;

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END
			/* 메시 필터에서 연산된게 들어오니까 IN , appdata 3종류있음*/
		void vert(inout appdata_full v) {
			v.vertex.xyz += v.normal.xyz * _Amount; /* 포지션 정보, float4 정보임, v.normal.xyz는 float3 */
		}
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
