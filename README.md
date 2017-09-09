This repo contains user shaders for prescaling in [mpv](https://mpv.io/).

For the scripts generating these user shaders, check the [source
branch](https://github.com/bjin/mpv-prescalers/tree/source). For comparison of
prescalers, check the [Comparison wiki](https://github.com/bjin/mpv-prescalers/wiki/Comparison).

Shaders in [`gather/` directory](https://github.com/bjin/mpv-prescalers/tree/master/gather)
and [`compute/` directory](https://github.com/bjin/mpv-prescalers/tree/master/compute)
are **generally faster** but requires recent version of OpenGL.
Use these shaders only if they actually work (i.e. no blue screen and no noticeable distortion).

# Usage

You only need to download shaders you actually use. The following part of this
section assumes that they are in `shaders` directory in the `mpv` configure
folder (usually `~/.config/mpv/shaders` on Linux).

Use `opengl-shaders="prescaler.hook"` option to load those shaders. (This will
override other user shaders, use `opengl-shaders-append` in that case)

```
opengl-shaders="~~/shaders/ravu-r3.hook"
```

All shaders are for one pass only. If you want to have `4x` upscaling, trigger
the same shader twice. All the shaders here are generated with
`max-downscaling-ratio` set to `1.6`. They will be disabled if upscaling is not necessary.

```
opengl-shaders-append="~~/shaders/ravu-r3.hook"
opengl-shaders-append="~~/shaders/ravu-r3.hook"
```

Suffix in the filename indicates the planes that the prescaler will upscale.

* Without any suffix: Works on `YUV` video, upscale only luma plane. (like the old `prescale-luma=...` option in `mpv`).
* `-chroma*`: Works on `YUV` video, upscale only chroma plane.
* `-yuv`: Works on `YUV` video, upscale all planes after they are merged.
  (If you really want to use these shaders for `RGB` video, you can use `--vf-add format=fmt=yuv444p16`.
  But be aware that there is no guarantee of colorspace/depth conversion
  correctness from `mpv` then.)
* `-rgb`: Works on all video, upscale all planes after they are merged and
  converted to `RGB`.

For `nnedi3` prescaler, `neurons` and `window` settings are indicated in the
filename.

For `ravu` prescaler, `radius` setting is indicated in the filename.

`ravu-*-chroma-{center,left}` are implementations of `ravu`, that
will use downscaled luma plane to calculate gradient and guide chroma planes
upscaling. Due to current limitation of `mpv`'s hook system, there are some
caveats for using those shaders:

1. It works with `YUV 4:2:0` format only, and will disable itself if size is not
   matched exactly, this includes odd width/height of luma plane.
2. It will **NOT** work with luma prescalers (for example `ravu-r3.hook`).
   You should use `rgb` and `yuv` shaders for further upscaling.
3. You need to explicitly state the chroma location, by choosing one of those
   `chroma-left` and `chroma-center` shaders. If you don't know how to/don't
   bother to check chroma location of video, or don't watch ancient videos,
   just choose `chroma-left`. If you are using [auto-profiles.lua](https://github.com/wm4/mpv-scripts/blob/master/auto-profiles.lua),
   you can use `cond:get('video-params/chroma-location','unknown')=='mpeg2/4/h264'`
   for `chroma-left` shader and `cond:get('video-params/chroma-location','unknown')=='mpeg1/jpeg'`
   for `chroma-center` shader.
4. `cscale` will still be used to correct minor offset. An EWA scaler like
   `haasnsoft` is recommended for the `cscale` setting.

# Known Issue

1. `ravu-lite` is incompatible with `--opengl-fbo-format=rgb10_a2` (default
   for some OpenGL ES implementation). Use `rgba16f` or `rgba16` if available.
2. `ravu-r4-{rgb,yuv}` causes distortion with lower-end intel card.
3.  All `ravu` and `ravu-lite` shaders are generated with `rgba16f` LUT.
    However, while it's a safe fallback choice, it's not universally
    available as well. Generate shaders without `--use-float16` option to use
    `rgba32f` LUT in those cases.

# About RAVU

RAVU is an experimental prescaler based on RAISR (Rapid and Accurate Image Super
Resolution). It adopts the core idea of RAISR for upscaling, without adopting
any further refinement RAISR used for post-processing, including blending and
sharpening.

RAVU is a convolution kernel based upscaling algorithm. The kernels are trained
from large amount of pictures with a straightforward linear regression model.
From a high level view, it's kind of similar to EWA scalers, but more adaptive
to local gradient features, and would produce lesser aliasing. Like EWA scalers,
currently, plain RAVU would also produce noticeable ringings.

RAVU-Lite is a faster, slightly-lower-quality and luma-only variant of RAVU.

# License

Shaders in this repo are licensed under terms of LGPLv3. Check the header of
each file for details.
