{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "tw-moe-fonts";
  version = "2020-11-14";

  src = fetchFromGitHub {
    owner = "Jiehong";
    repo = "TW-fonts";
    rev = "2020-11-14";
    sha256 = "1b8wgbbky9vz5jmqphk8c53l4xbd0gnpcdcqk87j4mkpxz2bq37n";
  };

  installPhase = ''
    runHook preInstall
    install -Dm644 *.ttf -t $out/share/fonts/truetype/tw-moe
    runHook postInstall
  '';

  meta = {
    description = "Taiwan Ministry of Education standard Kai and Sung fonts (教育部標準楷書/宋體)";
    homepage = "https://language.moe.gov.tw/";
    license = {
      # Open Government Data License v1.0 (≈ CC-BY 4.0)
      free = true;
      url = "https://data.gov.tw/license";
    };
  };
}
