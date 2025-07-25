// src/bin/test_qr.rs
// Display a QR code for eff.org on first button press, then exit

use qrcode::QrCode;
use image::Luma;
use std::fs::File;
use std::io::Read;
use std::thread;
use std::time::{Duration, Instant};

// Linux input_event structure size (16 bytes on 32-bit systems)
const INPUT_EVENT_SIZE: usize = 16;

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

// Based on the working Orbic framebuffer code
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

    // Based on daemon/src/display/orbic.rs write_buffer implementation
    fn write_buffer(&mut self, buffer: &[(u8, u8, u8)]) {
        let mut raw_buffer = Vec::new();
        for (r, g, b) in buffer {
            let mut rgb565: u16 = (*r as u16 & 0b11111000) << 8;
            rgb565 |= (*g as u16 & 0b11111100) << 3;
            rgb565 |= (*b as u16) >> 3;
            raw_buffer.extend(rgb565.to_le_bytes());
        }
        std::fs::write("/dev/fb0", &raw_buffer).expect("Failed to write to framebuffer");
    }
}

fn parse_event(input: &[u8]) -> Option<Event> {
    if input.len() < INPUT_EVENT_SIZE {
        return None;
    }
    
    let event_type = u16::from_le_bytes([input[8], input[9]]);
    let event_value = i32::from_le_bytes([input[12], input[13], input[14], input[15]]);
    
    // EV_KEY = 1
    if event_type == 1 {
        if event_value == 1 {
            Some(Event::KeyDown)
        } else if event_value == 0 {
            Some(Event::KeyUp)
        } else {
            None
        }
    } else {
        None
    }
}

fn clear_display(fb: &mut OrbicFramebuffer) {
    let dimensions = fb.dimensions();
    let buffer = vec![(0, 0, 0); (dimensions.width * dimensions.height) as usize];
    fb.write_buffer(&buffer);
}

fn display_qr_code(fb: &mut OrbicFramebuffer, qr_text: &str) -> Result<Vec<(u8, u8, u8)>, Box<dyn std::error::Error>> {
    println!("Generating QR code for: {}", qr_text);
    let code = QrCode::new(qr_text)?;
    
    let qr_image = code.render::<Luma<u8>>()
        .max_dimensions(fb.dimensions().width, fb.dimensions().height)
        .min_dimensions(fb.dimensions().width, fb.dimensions().height)
        .dark_color(Luma([0u8]))    // Black
        .light_color(Luma([255u8])) // White
        .build();
    
    println!("QR code image created: {}x{}", qr_image.width(), qr_image.height());
    
    let dimensions = fb.dimensions();
    let mut buffer = Vec::new();
    
    for y in 0..dimensions.height {
        for x in 0..dimensions.width {
            if x < qr_image.width() && y < qr_image.height() {
                let pixel = qr_image.get_pixel(x, y);
                let intensity = pixel[0];
                buffer.push((intensity, intensity, intensity));
            } else {
                buffer.push((255, 255, 255)); // White background
            }
        }
    }
    
    println!("Writing QR code to framebuffer...");
    fb.write_buffer(&buffer);
    println!("QR code displayed successfully");
    
    Ok(buffer)
}

fn display_qr_code_for_duration(fb: &mut OrbicFramebuffer, qr_text: &str, duration: Duration) -> Result<(), Box<dyn std::error::Error>> {
    println!("Displaying QR code for {:?}...", duration);
    
    // Generate the QR code buffer once
    let qr_buffer = display_qr_code(fb, qr_text)?;
    
    let start_time = Instant::now();
    let refresh_interval = Duration::from_millis(100); // Refresh every 100ms
    
    while start_time.elapsed() < duration {
        // Continuously refresh the framebuffer to prevent overwrites
        fb.write_buffer(&qr_buffer);
        
        // Sleep for a short interval before next refresh
        thread::sleep(refresh_interval);
    }
    
    println!("Display duration completed - clearing display");
    clear_display(fb);
    println!("Display cleared");
    
    Ok(())
}

fn main() {
    let mut fb = OrbicFramebuffer::new();
    let qr_text = "https://eff.org";
    
    println!("QR Code Test App - Event1 Button Press Detection");
    println!("QR code links to: {}", qr_text);
    println!("Press and hold the WPS reset button (event1) for 1.5-3 seconds to display QR code");
    println!("Presses shorter than 1.5s or longer than 3s will be ignored");
    
    // Open event1 for button monitoring
    let mut file = match File::open("/dev/input/event1") {
        Ok(f) => {
            println!("Successfully opened /dev/input/event1");
            f
        }
        Err(e) => {
            println!("Failed to open /dev/input/event1: {}", e);
            println!("Make sure you're running with root privileges via /bin/rootshell");
            return;
        }
    };
    
    let mut button_pressed = false;
    let mut press_start_time = Instant::now();
    let mut read_count = 0;
    
    // Timing constraints
    let min_press_duration = Duration::from_millis(1500); // 1.5 seconds
    let max_press_duration = Duration::from_secs(3);      // 3 seconds
    
    println!("Monitoring /dev/input/event1 for button presses...");
    println!("Debug: Starting read loop with {} byte events...", INPUT_EVENT_SIZE);
    
    loop {
        read_count += 1;
        if read_count % 1000 == 0 {
            println!("Debug: Read count: {}", read_count);
        }
        
        // Read complete input_event structure
        let mut event_buffer = [0u8; INPUT_EVENT_SIZE];
        match file.read_exact(&mut event_buffer) {
            Ok(_) => {
                if let Some(event) = parse_event(&event_buffer) {
                    println!("Debug: Parsed event: {:?}", event);
                    match event {
                        Event::KeyDown => {
                            if !button_pressed {
                                button_pressed = true;
                                press_start_time = Instant::now();
                                println!("Button pressed - timing started");
                            }
                        }
                        Event::KeyUp => {
                            if button_pressed {
                                button_pressed = false;
                                let press_duration = press_start_time.elapsed();
                                println!("Button released after {:?}", press_duration);
                                
                                // Check if press duration is within valid range
                                if press_duration >= min_press_duration && press_duration <= max_press_duration {
                                    println!("Valid press duration! Displaying QR code...");
                                    match display_qr_code_for_duration(&mut fb, qr_text, Duration::from_secs(10)) {
                                        Ok(_) => {
                                            println!("QR code display completed. Ready for next button press.");
                                        }
                                        Err(e) => {
                                            println!("Failed to display QR code: {}", e);
                                        }
                                    }
                                } else if press_duration < min_press_duration {
                                    println!("Press too short ({:?} < {:?}) - ignored", press_duration, min_press_duration);
                                } else {
                                    println!("Press too long ({:?} > {:?}) - ignored", press_duration, max_press_duration);
                                }
                            }
                        }
                    }
                }
            }
            Err(e) => {
                println!("Failed to read input event: {} (read count: {})", e, read_count);
                // Don't sleep too long on error to avoid missing events
                thread::sleep(Duration::from_millis(50));
            }
        }
    }
}

