#!/bin/sh

set -e

DIR="$(dirname "$0")"

max_downscaling_ratio=1.414213

for nns in 16 32 64 128 256; do
    for win in 8x4 8x6; do
        file_name="nnedi3-nns$nns-win$win.hook"
        "$DIR/nnedi3.py" --nns "$nns" --win "$win" --max-downscaling-ratio "$max_downscaling_ratio" > "$file_name"
        if [ -d gather ]; then
            "$DIR/nnedi3.py" --nns "$nns" --win "$win" --max-downscaling-ratio "$max_downscaling_ratio" --use-gather > "gather/$file_name"
        fi
        if [ -d compute ]; then
            "$DIR/nnedi3.py" --nns "$nns" --win "$win" --max-downscaling-ratio "$max_downscaling_ratio" --use-compute-shader > "compute/$file_name"
        fi
    done
done

for target in luma yuv rgb; do
    suffix="-$target"
    [ "$target" = "luma" ] && suffix=""
    file_name="superxbr$suffix.hook"
    "$DIR/superxbr.py" --target "$target" > "$file_name"
done

gen_ravu() {
    float_format="$1"
    for target in luma chroma-left chroma-center yuv rgb; do
        suffix="-$target"
        [ "$target" = "luma" ] && suffix=""
        for radius in 2 3 4; do
            file_name="ravu-r$radius$suffix.hook"
            weights_file="$DIR/weights/ravu_weights-r$radius.py"
            "$DIR/ravu.py" --target "$target" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" > "$file_name"
            if [ -d gather ]; then
                "$DIR/ravu.py" --target "$target" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" --use-gather > "gather/$file_name"
            fi
            if [ -d compute ]; then
                "$DIR/ravu.py" --target "$target" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" --use-compute-shader > "compute/$file_name"
            fi
        done
    done

    for radius in 2 3 4; do
        file_name="ravu-lite-r$radius.hook"
        weights_file="$DIR/weights/ravu-lite_weights-r$radius.py"
        "$DIR/ravu-lite.py" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" > "$file_name"
        if [ -d gather ]; then
            "$DIR/ravu-lite.py" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" --use-gather > "gather/$file_name"
        fi
        if [ -d compute ]; then
            "$DIR/ravu-lite.py" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" --use-compute-shader > "compute/$file_name"
        fi
    done

    if [ -d compute ]; then
        for target in luma yuv rgb; do
            suffix="-$target"
            [ "$target" = "luma" ] && suffix=""
            for radius in 2 3 4; do
                file_name="ravu-3x-r$radius$suffix.hook"
                weights_file="$DIR/weights/ravu-3x_weights-r$radius.py"
                "$DIR/ravu-3x.py" --target "$target" --weights-file "$weights_file" --max-downscaling-ratio "$max_downscaling_ratio" --float-format "$float_format" > "compute/$file_name"
            done
        done
    fi
}

gen_ravu float16gl
if [ -d vulkan ]; then
    cd vulkan
    gen_ravu float16vk
fi
