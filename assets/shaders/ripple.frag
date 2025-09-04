#version 460 core

// The final output color for the fragment.
out vec4 fragColor;

// Uniforms from Flutter (now much simpler)
uniform float u_time;
uniform vec2 u_resolution;

// --- UTILITY FUNCTIONS ---

// Generates a pseudo-random number from a 2D vector.
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// Creates a single, soft, expanding ring that loops over a set period.
float periodic_ripple(vec2 p, vec2 origin, float global_time) {
    float loop_duration = 8.0; // Ripple animation lasts 5 seconds
    float wave_speed = 0.6;    // Increased speed to travel further
    float max_fade = 0.9;      // Slower fade for longer visibility
    float spread = 0.09;       // Increased spread for a thicker, softer ripple

    float time = mod(global_time, loop_duration);
    float wave_front = time * wave_speed;
    float dist = length(p - origin);

    // Create a soft, Gaussian-like pulse instead of a hard ring
    float dist_from_wave = dist - wave_front;
    float ring = exp(-pow(dist_from_wave, 2.0) / (spread * spread));
    
    // Make the ring fade out as it expands
    float fade = pow(max_fade, time);

    return ring * fade;
}

void main() {
    // --- COORDINATE SYSTEM SETUP ---
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    float aspect_ratio = u_resolution.x / u_resolution.y;
    st.x *= aspect_ratio;
    
    // --- BASE COLOR & ANIMATION ---
    vec3 color = vec3(0.0, 0.5, 0.8);
    float displacement = 0.0;
    displacement += sin(st.x * 5.0 + u_time * 0.5) * 0.05;
    displacement += sin(st.y * 3.0 + u_time * 0.25) * 0.05;
    
    // --- DYNAMIC RIPPLE GENERATION ---
    const int NUM_RIPPLES = 1; // The number of ripples to render
    float total_ripple_effect = 0.0;

    for (int i = 0; i < NUM_RIPPLES; i++) {
        float i_float = float(i);
        // Create a unique seed for this ripple based on its index
        vec2 seed = vec2(i_float * 0.123, i_float * 0.456);

        // Create a random, slow-drifting velocity for each ripple
        vec2 velocity = vec2(random(seed) - 0.5, random(seed.yx) - 0.5) * 0.05;
        
        // Calculate a base position and let it drift with time, wrapping around the screen using fract()
        vec2 base_pos = vec2(random(seed * 2.0), random(seed.yx * 2.0));
        vec2 origin = fract(base_pos + u_time * velocity);
        
        // Correct the animated origin for the aspect ratio
        origin.x *= aspect_ratio;

        // Stagger the start time of each ripple's animation loop to prevent them from syncing up
        float staggered_time = u_time + random(seed * 3.0) * 10.0;
        
        // Add this ripple's effect to the total
        total_ripple_effect += periodic_ripple(st, origin, staggered_time);
    }
    
    // --- FINAL COLOR COMPOSITION ---
    color += displacement;
    color += total_ripple_effect * 0.25; // Control the overall intensity of the ripples
    
    fragColor = vec4(color, 1.0);
}

