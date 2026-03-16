use serde::Serialize;

/// Encode data as a Base64 deep link for SMS delivery.
/// Used when drivers are offline and receive orders via SMS.
pub fn encode_deep_link<T: Serialize>(data: &T) -> Result<String, serde_json::Error> {
    let json = serde_json::to_string(data)?;
    use std::io::Write;
    let mut encoder = base64_writer(Vec::new());
    encoder.write_all(json.as_bytes()).expect("base64 write");
    let encoded = String::from_utf8(encoder.into_inner()).expect("valid utf8");
    Ok(encoded)
}

/// Simple base64 encoder (no external dependency needed for skeleton)
fn base64_writer(buf: Vec<u8>) -> Base64Writer {
    Base64Writer { inner: buf }
}

struct Base64Writer {
    inner: Vec<u8>,
}

impl std::io::Write for Base64Writer {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let encoded = base64_encode(buf);
        self.inner.extend_from_slice(encoded.as_bytes());
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl Base64Writer {
    fn into_inner(self) -> Vec<u8> {
        self.inner
    }
}

const BASE64_CHARS: &[u8] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

fn base64_encode(input: &[u8]) -> String {
    let mut result = String::new();
    for chunk in input.chunks(3) {
        let b0 = chunk[0] as u32;
        let b1 = if chunk.len() > 1 { chunk[1] as u32 } else { 0 };
        let b2 = if chunk.len() > 2 { chunk[2] as u32 } else { 0 };
        let triple = (b0 << 16) | (b1 << 8) | b2;

        result.push(BASE64_CHARS[((triple >> 18) & 0x3F) as usize] as char);
        result.push(BASE64_CHARS[((triple >> 12) & 0x3F) as usize] as char);
        if chunk.len() > 1 {
            result.push(BASE64_CHARS[((triple >> 6) & 0x3F) as usize] as char);
        } else {
            result.push('=');
        }
        if chunk.len() > 2 {
            result.push(BASE64_CHARS[(triple & 0x3F) as usize] as char);
        } else {
            result.push('=');
        }
    }
    result
}

/// Decode a Base64 deep link back to data.
pub fn decode_deep_link(encoded: &str) -> Result<String, String> {
    base64_decode(encoded).map_err(|e| format!("Base64 decode error: {e}"))
}

fn base64_decode(input: &str) -> Result<String, &'static str> {
    let mut bytes = Vec::new();
    let chars: Vec<u8> = input
        .bytes()
        .filter(|&b| b != b'\n' && b != b'\r')
        .collect();

    for chunk in chars.chunks(4) {
        if chunk.len() < 4 {
            return Err("Invalid base64 length");
        }
        let vals: Vec<u32> = chunk
            .iter()
            .map(|&c| {
                if c == b'=' {
                    0
                } else {
                    BASE64_CHARS.iter().position(|&b| b == c).unwrap_or(0) as u32
                }
            })
            .collect();
        let triple = (vals[0] << 18) | (vals[1] << 12) | (vals[2] << 6) | vals[3];
        bytes.push(((triple >> 16) & 0xFF) as u8);
        if chunk[2] != b'=' {
            bytes.push(((triple >> 8) & 0xFF) as u8);
        }
        if chunk[3] != b'=' {
            bytes.push((triple & 0xFF) as u8);
        }
    }

    String::from_utf8(bytes).map_err(|_| "Invalid UTF-8")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_base64_encode_decode_roundtrip() {
        let original = "Hello, mefali!";
        let encoded = base64_encode(original.as_bytes());
        let decoded = decode_deep_link(&encoded).unwrap();
        assert_eq!(decoded, original);
    }

    #[test]
    fn test_encode_deep_link_json() {
        let data = serde_json::json!({"order_id": "123", "action": "collect"});
        let encoded = encode_deep_link(&data).unwrap();
        let decoded = decode_deep_link(&encoded).unwrap();
        let parsed: serde_json::Value = serde_json::from_str(&decoded).unwrap();
        assert_eq!(parsed["order_id"], "123");
        assert_eq!(parsed["action"], "collect");
    }
}
