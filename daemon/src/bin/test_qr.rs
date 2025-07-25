// src/bin/test_qr.rs
// Display a QR code for eff.org on first button press, then exit

use qrcode::QrCode;
use image::{Luma, DynamicImage, imageops::FilterType};
use std::fs::{File, write};
use std::io::Read;
use std::thread;
use std::time::{Duration, Instant};

const INPUT_EVENT_SIZE: usize = 32;
const FB_PATH: &str = "/dev/fb0";

#[derive(Debug, PartialEq)]
enum Event {
    KeyDown,
    KeyUp,
}

#[derive(Copy, Clone)]
struct Dimensions {
    height: u32,
    width: u32,
}

// Simple framebuffer for Orbic device
struct OrbicFramebuffer {
    dimensions: Dimensions,
}

impl OrbicFramebuffer {
    fn new() -> Self {
        Self {
            dimensions: Dimensions {
                height: 128,
                width: 128,
            }
        }
    }

    fn dimensions(&self) -> Dimensions {
        self.dimensions
    }

    fn write_buffer(&mut self, buffer: &[(u8, u8, u8)]) {
        let mut fb_data = Vec::new();
        for &(r, g, b) in buffer {
            // Convert RGB to RGB565 little-endian for Orbic
            let rgb565 = ((r as u16 & 0xF8) << 8) | ((g as u16 & 0xFC) << 3) | ((b as u16 & 0xF8) >> 3);
            fb_data.push((rgb565 & 0xFF) as u8);  // Low byte first (little-endian)
            fb_data.push((rgb565 >> 8) as u8);    // High byte second
        }
        
        write("/dev/fb0", &fb_data).expect("Failed to write to framebuffer");
    }
}

fn parse_event(input: [u8; INPUT_EVENT_SIZE]) -> Event {
    if input[12] == 0 {
        Event::KeyUp
    } else {
        Event::KeyDown
    }
}

fn clear_display(fb: &mut OrbicFramebuffer) {
    fb.write_buffer(&vec![(0, 0, 0); (fb.dimensions().width * fb.dimensions().height) as usize]);
}

fn restore_system_display(fb: &mut OrbicFramebuffer) {
    // Clear to black first
    clear_display(fb);
    
    // Add a small delay to allow system processes to potentially reclaim display
    thread::sleep(Duration::from_millis(100));
    
    // Write a neutral gray pattern that might encourage system redraw
    let dimensions = fb.dimensions();
    let gray_buffer = vec![(32, 32, 32); (dimensions.width * dimensions.height) as usize];
    fb.write_buffer(&gray_buffer);
    
    // Brief delay then clear again
    thread::sleep(Duration::from_millis(50));
    clear_display(fb);
}

fn main() {
    let mut fb = OrbicFramebuffer::new();
    let qr_text = "https://eff.org";
    let mut event_buffer = [0u8; INPUT_EVENT_SIZE];
    let mut file = File::open("/dev/input/event0").expect("Failed to open /dev/input/event0");
    let mut button_down_time: Option<Instant> = None;
    let mut quick_press_count = 0;
    let mut last_quick_press_time = Instant::now();
    
    println!("Press button to display QR code for {} ...", qr_text);
    println!("Press button 3 times quickly (within 2 seconds) to exit app");
    
    loop {
        file.read_exact(&mut event_buffer).expect("Failed to read event");
        let event = parse_event(event_buffer);
        
        match event {
            Event::KeyDown => {
                button_down_time = Some(Instant::now());
            }
            Event::KeyUp => {
                if let Some(down_time) = button_down_time {
                    let hold_duration = down_time.elapsed();
                    
                    // Any press shorter than 1 second triggers QR code
                    if hold_duration < Duration::from_millis(1000) {
                        // Check for triple press exit first
                        let now = Instant::now();
                        if now.duration_since(last_quick_press_time) < Duration::from_secs(2) {
                            quick_press_count += 1;
                            println!("Quick press {} of 3", quick_press_count);
                        } else {
                            quick_press_count = 1;
                            println!("Quick press 1 of 3");
                        }
                        last_quick_press_time = now;
                        
                        if quick_press_count >= 3 {
                            println!("Triple press detected - exiting app gracefully");
                            clear_display(&mut fb);
                            return;
                        }
                        
                        // Display QR code on single press
                        println!("Button press detected! Displaying QR code...");
                        
                        // Clear display first
                        println!("Clearing display...");
                        clear_display(&mut fb);
                        thread::sleep(Duration::from_millis(500));
                        
                        // Generate and display QR code
                        println!("Generating QR code for: {}", qr_text);
                        match QrCode::new(qr_text) {
                            Ok(code) => {
                                println!("QR code generated successfully");
                                
                                // Create a simple black and white QR code
                                println!("Creating QR image...");
                                let qr_image = code.render::<Luma<u8>>()
                                    .max_dimensions(fb.dimensions().width, fb.dimensions().height)
                                    .min_dimensions(fb.dimensions().width, fb.dimensions().height)
                                    .dark_color(Luma([0u8]))    // Black
                                    .light_color(Luma([255u8])) // White
                                    .build();
                                
                                println!("QR code image created: {}x{}", qr_image.width(), qr_image.height());
                                
                                // Convert to framebuffer format manually for better control
                                println!("Converting to framebuffer format...");
                                let dimensions = fb.dimensions();
                                println!("Framebuffer dimensions: {}x{}", dimensions.width, dimensions.height);
                                let mut buffer = Vec::new();
                                
                                for y in 0..dimensions.height {
                                    for x in 0..dimensions.width {
                                        if x < qr_image.width() && y < qr_image.height() {
                                            let pixel = qr_image.get_pixel(x, y);
                                            let intensity = pixel[0];
                                            buffer.push((intensity, intensity, intensity));
                                        } else {
                                            // Fill remaining area with white
                                            buffer.push((255, 255, 255));
                                        }
                                    }
                                }
                                
                                println!("Buffer created with {} pixels", buffer.len());
                                println!("Writing QR code to framebuffer...");
                                fb.write_buffer(&buffer);
                                println!("QR code displayed for 10 seconds...");
                                
                                // Display QR code for exactly 10 seconds, refreshing every 500ms
                                let display_duration = Duration::from_secs(10);
                                let refresh_interval = Duration::from_millis(500);
                                let start_time = Instant::now();
                                
                                while start_time.elapsed() < display_duration {
                                    // Refresh QR code display to overwrite system text
                                    fb.write_buffer(&buffer);
                                    
                                    // Sleep for refresh interval or remaining time, whichever is shorter
                                    let remaining_time = display_duration.saturating_sub(start_time.elapsed());
                                    let sleep_time = std::cmp::min(refresh_interval, remaining_time);
                                    thread::sleep(sleep_time);
                                }
                                
                                println!("10 seconds elapsed - restoring system display");
                                restore_system_display(&mut fb);
                                println!("Display restored. Ready for next button press...");
                            }
                            Err(e) => {
                                println!("Failed to generate QR code: {}", e);
                                println!("Displaying test pattern instead...");
                                // Display a simple test pattern to verify framebuffer works
                                let dimensions = fb.dimensions();
                                let mut test_buffer = Vec::new();
                                for y in 0..dimensions.height {
                                    for x in 0..dimensions.width {
                                        if (x / 8 + y / 8) % 2 == 0 {
                                            test_buffer.push((255, 0, 0)); // Red
                                        } else {
                                            test_buffer.push((0, 255, 0)); // Green
                                        }
                                    }
                                }
                                fb.write_buffer(&test_buffer);
                                thread::sleep(Duration::from_secs(5));
                                restore_system_display(&mut fb);
                                println!("Test pattern cleared. Ready for next button press...");
                            }
                        }
                    } else {
                        println!("Long press detected ({:.1}s) - ignoring to avoid device shutdown", hold_duration.as_secs_f32());
                    }
                }
                button_down_time = None;
            }
        }
    }
}

