#!/usr/bin/env bash
# Sets default applications on macOS using duti.
# DUTI_BIN must be set by the caller (home/macOS.nix activation snippet).
#
# Each association is attempted silently: if the target bundle is not yet
# installed, duti exits non-zero and we skip without aborting activation.

set_default() {
    $DRY_RUN_CMD "$DUTI_BIN" -s "$1" "$2" all 2>/dev/null || true
}

# Audio files -> VLC
for uti in \
    public.audio \
    public.mp3 \
    com.microsoft.waveform-audio \
    public.aiff-audio \
    public.mpeg-4-audio \
    public.flac-audio \
    org.xiph.flac \
    org.xiph.ogg-vorbis \
    com.apple.m4a-audio; do
    set_default org.videolan.vlc "$uti"
done

# Programming and prose files -> Emacs
for uti in \
    public.plain-text \
    public.source-code \
    public.python-script \
    public.shell-script \
    public.c-source \
    public.c-plus-plus-source \
    public.objective-c-source \
    public.swift-source \
    public.java-source \
    public.ruby-script \
    public.perl-script \
    public.json \
    public.xml \
    net.daringfireball.markdown; do
    set_default org.gnu.Emacs "$uti"
done

# Office documents -> LibreOffice
for uti in \
    org.openxmlformats.wordprocessingml.document \
    org.openxmlformats.spreadsheetml.sheet \
    org.openxmlformats.presentationml.presentation \
    com.microsoft.word.doc \
    com.microsoft.excel.xls \
    com.microsoft.powerpoint.ppt \
    org.oasis-open.opendocument.text \
    org.oasis-open.opendocument.spreadsheet \
    org.oasis-open.opendocument.presentation \
    org.oasis-open.opendocument.graphics; do
    set_default org.libreoffice.script "$uti"
done

# Default browser -> Firefox Developer Edition
for uti_or_scheme in \
    public.html \
    public.xhtml \
    http \
    https; do
    set_default org.mozilla.firefoxdeveloperedition "$uti_or_scheme"
done
