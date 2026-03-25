{
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation {
  pname = "zapfino";
  version = "1";

  src = fetchurl {
    url = "https://font.download/dl/font/zapfino.zip";
    sha256 = "0dwbf21rmzvyzzpa110ipm8ain03vrawsngbg2qs0pnndn1mwsh6";
  };

  nativeBuildInputs = [unzip];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 *.ttf -t $out/share/fonts/truetype/zapfino
    runHook postInstall
  '';

  meta = {
    description = "Zapfino calligraphic typeface by Hermann Zapf";
    homepage = "https://font.download/font/zapfino";
  };
}
