Shader "Custom/RimLight" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		_RimPower("RimPower", Range(0,5)) = 0.0
		_RimColor("RimColor", Color) = (1,1,1,1)
	}
		/* 자, RimLight를 만들어보자. RimLight는 테두리 빛이란 말로 경계에만 빛나고 나머지는 어두운 것을 의미한다. */
	SubShader {
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		
		/* 테투리 빛 효과를 어떻게 구현할 것인가? 조명에 대해 구 객체가 얼만큼의 빛을 받고 있는지 생각해보자. 
		조명의 광자 입사벡터의 음수값와 구 객체의 표면 노멀벡터를 내적하여 그 사잇각을 구해 빛을 얼만큼 받는지 알아낼 수 있다.
		수직일때는 빛과 그림자의 경계선이 될 것이요, 둔각일 때는 그림자부분이 점점 더 짙어질 것이다. 
		이를 이용해서 빛과 그림자를 역전시켜준다면? 그리고 광원자체가 바로 카메라라면? 객체가 카메라를 바라보는 방향과 평행할 경우에는 그림자가 질 것이고
		그 경계부분과 뒷 부분은 빛이 나는 효과, 즉 Rim Light 효과가 될 것이다! */

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Standard fullforwardshadows keepalpha

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;

		/* 카메라 벡터를 구하기 위해서?

		입력 구조 Input에는 일반적으로 셰이더가 필요로 하는 텍스처 좌표가 있습니다. 텍스처 좌표의 이름은 텍스처 이름 앞에 “uv”가 붙는 형식으로 
		지어야 합니다. 다음 값을 입력 구조에 추가할 수 있습니다.

		float3 viewDir - 뷰 방향을 포함합니다. 패럴랙스 이펙트, 림 조명 등의 컴퓨팅에 사용합니다.
		float3 worldPos - 월드 공간 포지션을 포함합니다.

		*/
		struct Input {
			float2 uv_MainTex;
			float3 viewDir;
			float3 worldPos;	/* 해당 버텍스의 월드 좌표 */
		};

		half _Glossiness;
		half _Metallic;

		/* 인자를 추가해줬으니 CG코드에도 추가해준다. */
		half _RimPower;
		float4 _RimColor;

		fixed4 _Color;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_CBUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_CBUFFER_END

		void surf (Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;

			float rim = dot(o.Normal, IN.viewDir);
			//rim = 1 - rim;
			/* 여기까지는 rim 함수를 선형적인 1차 함수로 구성하였고, 이것의 의미는 알파값으로 활용할 때, 가장 외곽선부분은 1 - 0 = 1이 되어 블렌딩할 때
			정점의 고유색만 나오고, 카메라와 거리가 가깝다면 1 - 1 = 0이 되어, 뒷배경색으로 블렌딩된다. 
			이때, 선형 함수의 경우에는 증가치가 선형적이니까, 우리가 원하는 홀로그램효과 즉 테두리 빛이 아주 극단적인 경우를 만들기 위해 함수를 비선형적
			으로 만들어준다. 그걸 위해 _RimPower와 pow(거듭제곱연산)을 이용한다. */
			rim = pow(1 - rim, _RimPower);

			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = rim;

			/* frac(x) 함수는? x의 소수부를 반환한다. ret값는 0보다 크거나 같고 1보다 작다. */

			o.Emission = _RimColor.rgb * frac(IN.worldPos.y * 10 - _Time.x * 10);
			/* 깜빡이는 효과를 내기 위해서 스스로 발광하는 Emission광을 적용할 것. Eimission은 float3의 데이터. 
			Emission의 광원색을 정하기 위해 _RimColor를 이용하였다. 만약 rgb의 색채 변화가 선형적 그래프라면 계속 그 색값으로 증가할 텐데
			frac 함수를 통해서 0~1 사이의 소수점 그래프들의 반복구조로 변형시켜 홀로그램 효과를 구현한 것이다. 이때, 그 원본인 선형 그래프의 기울기값
			여기서는 10 이 상수값을 조정해 기울기를 y축에 근사하게 편향시킬 수 있고 그럼으로써 frac을 적용했을 때, 반복되는 수가 증가하게 되는 것이다.
			해당 버텍스의 월드좌표 위치벡터에서 하나의 축원소를 택하여 그 축의 방향으로 unity 엔진 내에 흐르는 시간만큼(+) 
			에미션광을 이동시키는 의미가 된다. 이때 시간값을 더하냐 빼느냐에 따라 광의 이동방향이 정해진다.
			*/

			/* o.Emission = frac(IN.worldPos.y - _Time); 는 왜 무지개 모양으로 나올까? _Time은 float4 데이터고 이런
			(t/20, t, t*2, t*3) 구조를 가지고 있다. 그래서 각각 더해지고 곱해지는 가중치가 틀리게 되어서 rgb값이 스펙트럼처럼 편향되게 된다.  
			*/

			/* 왜 프로퍼티를 쓸까? Unity 엔진에 적용해서 일일히 상수를 더해주는 것보다 훨씬 더 능률적으로 쉐이더 코드를 작성할 수 있다. */

		}
		ENDCG
	}
	FallBack "Diffuse"
}
