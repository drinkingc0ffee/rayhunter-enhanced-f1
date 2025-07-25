// test_qr.rs
// Test: Display and clear QR code on button press

use qrcode::QrCode;
use image::{Luma, DynamicImage};
use daemon::display::generic_framebuffer::{GenericFramebuffer, Color};
use daemon::key_input::{Event, run_key_input_thread};

// Dummy framebuffer for testing
struct DummyFramebuffer {
    width: u32,
    height: u32,
}

impl GenericFramebuffer for DummyFramebuffer {
    fn dimensions(&self) -> daemon::display::generic_framebuffer::Dimensions {
        daemon::display::generic_framebuffer::Dimensions {
            width: self.width,
            height: self.height,
        }
    }
    fn write_buffer(&mut self, buffer: &[(u8, u8, u8)]) {
        println!("Framebuffer updated: {} pixels", buffer.len());
    }
}

fn display_qr(fb: &mut impl GenericFramebuffer, text: &str) {
    let code = QrCode::new(text).unwrap();
    let image = code.render::<Luma<u8>>().max_dimensions(fb.dimensions().width, fb.dimensions().height).build();
    let dyn_img = DynamicImage::ImageLuma8(image);
    fb.write_dynamic_image(dyn_img);
}

fn clear_display(fb: &mut impl GenericFramebuffer) {
    fb.write_buffer(&vec![(0, 0, 0); (fb.dimensions().width * fb.dimensions().height) as usize]);
}

fn main() {
    let mut fb = DummyFramebuffer { width: 128, height: 128 };
    let mut qr_displayed = false;
    let test_text = "https://example.com/test";
    println!("Press button to toggle QR code display...");
    // Simulate button events
    for event in [Event::KeyDown, Event::KeyDown] {
        match event {
            Event::KeyDown => {
                if !qr_displayed {
                    display_qr(&mut fb, test_text);
                    qr_displayed = true;
                    println!("QR code displayed");
                } else {
                    clear_display(&mut fb);
                    qr_displayed = false;
                    println!("Display cleared");
                }
            }
            _ => {}
        }
    }
}
