# Hunspell Latin dictionary (Karl Zeiler & Jean-Pierre Sutto).
#
# 130 000+ words covering archaic, classical, medieval, ecclesiastical
# and New Latin.  Ships the "universal" affix rules (u=u, v=v, u=v,
# v=u), which is the most permissive spelling mode.
#
# Source: https://extensions.libreoffice.org/en/extensions/show/latin-spelling-and-hyphenation-dictionaries
# Licence: LGPL
{
  stdenvNoCC,
  fetchurl,
  unzip,
}:
stdenvNoCC.mkDerivation {
  pname = "hunspell-dict-la";
  version = "2013-03-31";

  src = fetchurl {
    url = "https://extensions.libreoffice.org/assets/downloads/z/dict-la-2013-03-31.oxt";
    hash = "sha256-2DDGbz6Fihz7ruGIoA2HZIL78XK7MgJr3UeeoaYywtI=";
  };

  nativeBuildInputs = [unzip];

  unpackPhase = ''
    unzip "$src"
  '';

  installPhase = ''
    runHook preInstall
    install -Dm644 la/universal/la.aff "$out/share/hunspell/la.aff"
    install -Dm644 la/universal/la.dic "$out/share/hunspell/la.dic"
    runHook postInstall
  '';

  meta = {
    description = "Hunspell Latin dictionary (130 000+ words, all historical periods)";
    homepage = "https://extensions.libreoffice.org/en/extensions/show/latin-spelling-and-hyphenation-dictionaries";
    license = {
      free = true;
      url = "https://www.gnu.org/licenses/lgpl-3.0.html";
    };
  };
}
