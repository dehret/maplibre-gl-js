uniform float u_fade_t;
uniform float u_opacity;
uniform sampler2D u_image0;
uniform sampler2D u_image1;
uniform sampler2D u_color_ramp;

in vec2 v_pos0;
in vec2 v_pos1;

uniform float u_brightness_low;
uniform float u_brightness_high;

uniform float u_saturation_factor;
uniform float u_contrast_factor;
uniform vec3 u_spin_weights;
uniform float u_color_channel;
uniform float u_is_using_color_ramp;

void main() {

    // read and cross-fade colors from the main and parent tiles
    vec4 color0 = texture(u_image0, v_pos0);
    vec4 color1 = texture(u_image1, v_pos1);
    if (color0.a > 0.0) {
        color0.rgb = color0.rgb / color0.a;
    }
    if (color1.a > 0.0) {
        color1.rgb = color1.rgb / color1.a;
    }
    vec4 color = mix(color0, color1, u_fade_t);
    color.a *= u_opacity;
    vec3 rgb = color.rgb;

    // spin
    rgb = vec3(
        dot(rgb, u_spin_weights.xyz),
        dot(rgb, u_spin_weights.zxy),
        dot(rgb, u_spin_weights.yzx));

    // saturation
    float average = (color.r + color.g + color.b) / 3.0;
    rgb += (average - rgb) * u_saturation_factor;

    // contrast
    rgb = (rgb - 0.5) * u_contrast_factor + 0.5;

    // brightness
    vec3 u_high_vec = vec3(u_brightness_low, u_brightness_low, u_brightness_low);
    vec3 u_low_vec = vec3(u_brightness_high, u_brightness_high, u_brightness_high);

    // full pixel color, excluding opacity
    vec4 pixel_color = vec4(mix(u_high_vec, u_low_vec, rgb), 1.0);

    // perform interpolation
    vec2 texelSize = 1.0 / vec2(textureSize(u_image0, 0));
    vec4 colorSum = vec4(0.0);

    // Loop through the 3x3 grid surrounding the current pixel
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            // Calculate the texture coordinates for the neighboring pixels
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            colorSum += texture(u_image0, v_pos0 + offset);
        }
    }

    // Calculate the mean color value
    pixel_color = colorSum / 9.0;
    pixel_color.a = 1.0;

    // color channel
    if (u_color_channel >= 0.0) {
      float channel_value = pixel_color.r;

      if (u_color_channel == 1.0) {
        channel_value = pixel_color.g;
      } else if (u_color_channel == 2.0) {
        channel_value = pixel_color.b;
      } else if (u_color_channel == 3.0) {
        channel_value = pixel_color.a;
      }

      if (u_is_using_color_ramp == 1.0) {
        pixel_color = texture(u_color_ramp, vec2(channel_value, 0.5));
        pixel_color *= u_opacity;
      } else {
        pixel_color = vec4(channel_value * u_opacity, channel_value * u_opacity, channel_value * u_opacity, u_opacity);
      }
    } else {
      // add opacity
      pixel_color = vec4(pixel_color.rgb * color.a, color.a);
    }

    fragColor = pixel_color;

#ifdef OVERDRAW_INSPECTOR
    fragColor = vec4(1.0);
#endif
}
