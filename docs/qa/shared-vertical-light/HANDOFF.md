# 저수지·계곡·타일 세로 빛 본편 적용
2026-11-08 KST. 사용자 stage9빛확정/3지역본편교체 승인, 배포없음.

공통 vertical_water_light.gdshader: 절차2Dfbm세로빛결/불규칙폭·간격/깊이감쇠/해방향shear. 저수지는기존803x820수중quad에새재질,계곡은nativeplate1080소스수면1492/깊이1009,타일은nativeplate801소스수면980/깊이750. 두native지역은공통컨트롤러사용. 기존계곡valley_layer/valley_life두곳의사선광원모두제거. 원본배경3장·아트·다른장식·UI·게임난이도·세이브변경없음. 타일의다른미통합시안장식은이번승인범위밖으로유지.

최종75개전체headless검사75통과(새테스트데이터분리),새shared_vertical_light검사추가통과:3화면높이/3지역/정오·야간/메뉴숨김/native수명해제/낚시RNG보존. 실제OpenGL3지역캡처·빛비활성기준비교에서수중만바뀌며HUD보존. 우편별도재접속통과. VERIFICATION.json/FULL_CHECKS.json/SCREEN_VERIFICATION.json/SOURCE_MANIFEST.json. 재검사때이전테스트세이브재사용으로2개실패했고새격리에서해결,사용자세이브아님.

work/*원격에소스저장. 새shared_vertical_light검사를기존verify-work suite에등록. 로컬동일검사중복방지를위해checkpoint는skip ci,CI미실행을성공으로표시하지않음. 운영v1.09유지,배포/휴대폰적용미진행. 기존1.10후보는소스변경전파일이므로재사용불가,향후배포승인시새후보생성·필수검증필요. 새게임버전/소스ZIP/PCK/manifest공개없음.
