use std::fs::File;
use std::io::Read;
use std::thread;
use std::time::Duration;

const INPUT_EVENT_SIZE: usize = 16;

#[derive(Debug, PartialEq)]
enum Event {
    KeyDown,
    KeyUp,
}

fn parse_event(input: &[u8]) -> Option<Event> {
    if input.len() < 16 {
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

fn test_input_device(device_path: &str) -> Result<(), std::io::Error> {
    println!("Testing {}...", device_path);
    
    let mut file = File::open(device_path)?;
    let mut buffer = Vec::new();
    let mut temp_buf = [0u8; 1];
    let mut event_count = 0;
    
    // Test for 5 seconds
    let start_time = std::time::Instant::now();
    
    while start_time.elapsed() < Duration::from_secs(5) {
        match file.read(&mut temp_buf) {
            Ok(bytes_read) if bytes_read > 0 => {
                buffer.push(temp_buf[0]);
                
                if buffer.len() >= INPUT_EVENT_SIZE {
                    if let Some(event) = parse_event(&buffer[buffer.len()-INPUT_EVENT_SIZE..]) {
                        event_count += 1;
                        println!("  {}: {:?}", device_path, event);
                    }
                    
                    // Prevent buffer overflow
                    if buffer.len() > INPUT_EVENT_SIZE * 2 {
                        buffer.drain(0..INPUT_EVENT_SIZE);
                    }
                }
            }
            Ok(_) => {
                thread::sleep(Duration::from_millis(10));
            }
            Err(e) => {
                println!("  {}: Error reading: {}", device_path, e);
                return Err(e);
            }
        }
    }
    
    if event_count == 0 {
        println!("  {}: No events detected", device_path);
    } else {
        println!("  {}: {} events detected", device_path, event_count);
    }
    
    Ok(())
}

fn main() {
    println!("Input Device Test - Press the menu button during this test");
    println!("Testing each input device for 5 seconds...");
    println!("");
    
    for i in 0..4 {
        let device_path = format!("/dev/input/event{}", i);
        if let Err(e) = test_input_device(&device_path) {
            println!("Failed to test {}: {}", device_path, e);
        }
        println!("");
    }
    
    println!("Test complete. Check which device generated events when you pressed the menu button.");
} 