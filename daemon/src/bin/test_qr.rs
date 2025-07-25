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

fn get_wifi_credentials() -> (String, String, String) {
    println!("Searching for WiFi configuration...");
    
    // Try multiple configuration sources in order of preference
    
    // 1. Try reading from hostapd config (most common for hotspots)
    if let Ok(hostapd_content) = std::fs::read_to_string("/etc/hostapd/hostapd.conf") {
        println!("Found hostapd config file");
        let mut ssid = String::new();
        let mut password = String::new();
        
        for line in hostapd_content.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("ssid=") {
                ssid = trimmed[5..].to_string();
            } else if trimmed.starts_with("wpa_passphrase=") {
                password = trimmed[14..].to_string();
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using hostapd config - SSID: {}, Encryption: WPA", ssid);
            return (ssid, password, "WPA".to_string());
        }
    }
    
    // 2. Try reading from wpa_supplicant config
    if let Ok(wpa_content) = std::fs::read_to_string("/etc/wpa_supplicant/wpa_supplicant.conf") {
        println!("Found wpa_supplicant config file");
        let mut ssid = String::new();
        let mut password = String::new();
        let mut in_network = false;
        
        for line in wpa_content.lines() {
            let trimmed = line.trim();
            if trimmed == "network={" {
                in_network = true;
            } else if trimmed == "}" {
                in_network = false;
                if !ssid.is_empty() && !password.is_empty() {
                    break;
                }
            } else if in_network {
                if trimmed.starts_with("ssid=") {
                    // Remove quotes if present
                    let value = &trimmed[5..];
                    ssid = if value.starts_with('"') && value.ends_with('"') {
                        value[1..value.len()-1].to_string()
                    } else {
                        value.to_string()
                    };
                } else if trimmed.starts_with("psk=") {
                    // Remove quotes if present
                    let value = &trimmed[4..];
                    password = if value.starts_with('"') && value.ends_with('"') {
                        value[1..value.len()-1].to_string()
                    } else {
                        value.to_string()
                    };
                }
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using wpa_supplicant config - SSID: {}, Encryption: WPA", ssid);
            return (ssid, password, "WPA".to_string());
        }
    }
    
    // 3. Try reading from NetworkManager config
    if let Ok(nm_content) = std::fs::read_to_string("/etc/NetworkManager/system-connections/default") {
        println!("Found NetworkManager config file");
        let mut ssid = String::new();
        let mut password = String::new();
        let mut encryption = "WPA".to_string();
        
        for line in nm_content.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("ssid=") {
                ssid = trimmed[5..].to_string();
            } else if trimmed.starts_with("psk=") {
                password = trimmed[4..].to_string();
            } else if trimmed.starts_with("key-mgmt=") {
                let key_mgmt = &trimmed[9..];
                if key_mgmt == "none" {
                    encryption = "nopass".to_string();
                }
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using NetworkManager config - SSID: {}, Encryption: {}", ssid, encryption);
            return (ssid, password, encryption);
        }
    }
    
    // 4. Try reading from systemd-networkd config
    if let Ok(network_content) = std::fs::read_to_string("/etc/systemd/network/25-wireless.network") {
        println!("Found systemd-networkd config file");
        let mut ssid = String::new();
        let mut password = String::new();
        
        for line in network_content.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("Name=") {
                ssid = trimmed[5..].to_string();
            } else if trimmed.starts_with("Password=") {
                password = trimmed[9..].to_string();
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using systemd-networkd config - SSID: {}, Encryption: WPA", ssid);
            return (ssid, password, "WPA".to_string());
        }
    }
    
    // 5. Try reading from iwd config (Intel Wireless Daemon)
    if let Ok(iwd_content) = std::fs::read_to_string("/var/lib/iwd/network.psk") {
        println!("Found iwd config file");
        let mut ssid = String::new();
        let mut password = String::new();
        
        for line in iwd_content.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("[Security]") {
                // This is a section marker, continue to next lines
            } else if trimmed.starts_with("Passphrase=") {
                password = trimmed[11..].to_string();
            } else if trimmed.starts_with("Name=") {
                ssid = trimmed[5..].to_string();
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using iwd config - SSID: {}, Encryption: WPA", ssid);
            return (ssid, password, "WPA".to_string());
        }
    }
    
    // 6. Try reading from environment variables (for containerized deployments)
    if let Ok(ssid) = std::env::var("WIFI_SSID") {
        if let Ok(password) = std::env::var("WIFI_PASSWORD") {
            let encryption = std::env::var("WIFI_ENCRYPTION").unwrap_or_else(|_| "WPA".to_string());
            println!("Using environment variables - SSID: {}, Encryption: {}", ssid, encryption);
            return (ssid, password, encryption);
        }
    }
    
    // 7. Try reading from a custom config file
    if let Ok(custom_content) = std::fs::read_to_string("/etc/wifi-config.conf") {
        println!("Found custom wifi config file");
        let mut ssid = String::new();
        let mut password = String::new();
        let mut encryption = "WPA".to_string();
        
        for line in custom_content.lines() {
            let trimmed = line.trim();
            if trimmed.starts_with("SSID=") {
                ssid = trimmed[5..].to_string();
            } else if trimmed.starts_with("PASSWORD=") {
                password = trimmed[9..].to_string();
            } else if trimmed.starts_with("ENCRYPTION=") {
                encryption = trimmed[10..].to_string();
            }
        }
        
        if !ssid.is_empty() && !password.is_empty() {
            println!("Using custom config - SSID: {}, Encryption: {}", ssid, encryption);
            return (ssid, password, encryption);
        }
    }
    
    // If no configuration found, return error information
    println!("WARNING: No WiFi configuration found in any of the expected locations:");
    println!("  - /etc/hostapd/hostapd.conf");
    println!("  - /etc/wpa_supplicant/wpa_supplicant.conf");
    println!("  - /etc/NetworkManager/system-connections/default");
    println!("  - /etc/systemd/network/25-wireless.network");
    println!("  - /var/lib/iwd/network.psk");
    println!("  - Environment variables (WIFI_SSID, WIFI_PASSWORD)");
    println!("  - /etc/wifi-config.conf");
    println!("Using fallback values - please configure WiFi credentials");
    
    // Return a clearly marked fallback that indicates configuration is needed
    ("CONFIGURE_WIFI_SSID".to_string(), "CONFIGURE_WIFI_PASSWORD".to_string(), "WPA".to_string())
}

fn generate_wifi_qr_code(ssid: &str, password: &str, encryption: &str) -> String {
    // Generate WiFi QR code in the standard format
    // Format: WIFI:S:<SSID>;T:<WPA|WEP|nopass>;P:<password>;;
    
    let qr_data = format!("WIFI:S:{};T:{};P:{};;", ssid, encryption, password);
    println!("Generated WiFi QR code data: {}", qr_data);
    qr_data
}

fn display_qr_code(fb: &mut OrbicFramebuffer, qr_text: &str) -> Result<Vec<(u8, u8, u8)>, Box<dyn std::error::Error>> {
    println!("Generating QR code for WiFi connection...");
    
    // Try to create a smaller QR code with lower error correction
    let code = match QrCode::new(qr_text) {
        Ok(code) => code,
        Err(_) => {
            // If that fails, try with minimal error correction
            QrCode::with_error_correction_level(qr_text, qrcode::EcLevel::L)?
        }
    };
    
    let dimensions = fb.dimensions();
    
    // Calculate a smaller size that will fit well on the screen
    // Leave some margin around the edges
    let margin = 8u32;
    let max_qr_size = dimensions.width.min(dimensions.height) - (2 * margin);
    
    // Render QR code with margins
    let qr_image = code.render::<Luma<u8>>()
        .max_dimensions(max_qr_size, max_qr_size)
        .min_dimensions(max_qr_size, max_qr_size)
        .dark_color(Luma([0u8]))    // Black
        .light_color(Luma([255u8])) // White
        .build();
    
    println!("QR code image created: {}x{} for {}x{} screen (with {}px margins)", 
             qr_image.width(), qr_image.height(), dimensions.width, dimensions.height, margin);
    
    let mut buffer = Vec::new();
    
    // Create buffer with white background and centered QR code
    for y in 0..dimensions.height {
        for x in 0..dimensions.width {
            // Calculate QR code position (centered)
            let qr_x = x as i32 - margin as i32;
            let qr_y = y as i32 - margin as i32;
            
            if qr_x >= 0 && qr_x < qr_image.width() as i32 && 
               qr_y >= 0 && qr_y < qr_image.height() as i32 {
                // Inside QR code area
                let pixel = qr_image.get_pixel(qr_x as u32, qr_y as u32);
                let intensity = pixel[0];
                buffer.push((intensity, intensity, intensity));
            } else {
                // Outside QR code area - white background
                buffer.push((255, 255, 255));
            }
        }
    }
    
    println!("Writing WiFi QR code to framebuffer...");
    fb.write_buffer(&buffer);
    println!("WiFi QR code displayed successfully");
    
    Ok(buffer)
}

fn display_qr_code_for_duration(fb: &mut OrbicFramebuffer, qr_text: &str, duration: Duration) -> Result<(), Box<dyn std::error::Error>> {
    println!("Displaying WiFi QR code for {:?}...", duration);
    
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
    
    // Get WiFi credentials
    let (ssid, password, encryption) = get_wifi_credentials();
    let wifi_qr_data = generate_wifi_qr_code(&ssid, &password, &encryption);
    
    println!("WiFi Hotspot QR Code Display App");
    println!("Network: {} ({})", ssid, encryption);
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
                                    println!("Valid press duration! Displaying WiFi QR code...");
                                    match display_qr_code_for_duration(&mut fb, &wifi_qr_data, Duration::from_secs(30)) {
                                        Ok(_) => {
                                            println!("WiFi QR code display completed. Ready for next button press.");
                                        }
                                        Err(e) => {
                                            println!("Failed to display WiFi QR code: {}", e);
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

