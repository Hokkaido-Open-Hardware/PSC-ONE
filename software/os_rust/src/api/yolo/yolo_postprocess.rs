//! Stable per-class NMS before inverse letterbox and image clipping.
use super::*;
pub struct Workspace {
    candidates: [Detection; ANCHORS],
    suppressed: [bool; ANCHORS],
}
impl Workspace {
    pub const fn new() -> Self {
        Self {
            candidates: [Detection::ZERO; ANCHORS],
            suppressed: [false; ANCHORS],
        }
    }
    pub fn process(
        &mut self,
        output: &[u8],
        g: Geometry,
        result: &mut YoloResult,
    ) -> Result<(), i32> {
        *result = YoloResult::new();
        if output.len() != OUTPUT_BYTES
            || g.width == 0
            || g.width > 480
            || g.height == 0
            || g.height > 320
            || g.resized_width == 0
            || g.resized_width > SIDE as u32
            || g.resized_height == 0
            || g.resized_height > SIDE as u32
            || g.left > SIDE as u32 - g.resized_width
            || g.top > SIDE as u32 - g.resized_height
            || !g.scale.is_finite()
            || g.scale <= 0.0
        {
            return Err(ARGUMENT);
        }
        result.geometry = g;
        let value = |c: usize, i: usize| {
            let at = (c * ANCHORS + i) * 4;
            f32::from_le_bytes(output[at..at + 4].try_into().unwrap())
        };
        let mut n = 0;
        for i in 0..ANCHORS {
            let (cx, cy, w, h) = (
                value(0, i) * SIDE as f32,
                value(1, i) * SIDE as f32,
                value(2, i) * SIDE as f32,
                value(3, i) * SIDE as f32,
            );
            if ![cx, cy, w, h].iter().all(|v| v.is_finite()) || w <= 0.0 || h <= 0.0 {
                continue;
            }
            let (mut score, mut cls, mut valid) = (-1.0, 0, true);
            for c in 0..CLASSES {
                let s = value(4 + c, i);
                if !s.is_finite() || !(0.0..=1.0).contains(&s) {
                    valid = false;
                    break;
                }
                if s > score {
                    score = s;
                    cls = c;
                }
            }
            if !valid || score <= 0.25 {
                continue;
            }
            let d = Detection {
                x1: cx - w / 2.0,
                y1: cy - h / 2.0,
                x2: cx + w / 2.0,
                y2: cy + h / 2.0,
                score,
                class_id: cls as u16,
                anchor: i as u16,
            };
            if ![d.x1, d.y1, d.x2, d.y2].iter().all(|v| v.is_finite())
                || d.x2 <= d.x1
                || d.y2 <= d.y1
                || !area(d).is_finite()
            {
                continue;
            }
            let mut pos = n;
            while pos != 0 && self.candidates[pos - 1].score < score {
                self.candidates[pos] = self.candidates[pos - 1];
                pos -= 1;
            }
            self.candidates[pos] = d;
            n += 1;
        }
        result.candidates = n as u32;
        self.suppressed.fill(false);
        for i in 0..n {
            if self.suppressed[i] {
                continue;
            }
            result.nms_count += 1;
            for j in i + 1..n {
                if !self.suppressed[j]
                    && self.candidates[i].class_id == self.candidates[j].class_id
                    && overlap(self.candidates[i], self.candidates[j])
                {
                    self.suppressed[j] = true;
                }
            }
            let mut d = self.candidates[i];
            d.x1 = ((d.x1 - g.left as f32) / g.scale).clamp(0.0, g.width as f32);
            d.x2 = ((d.x2 - g.left as f32) / g.scale).clamp(0.0, g.width as f32);
            d.y1 = ((d.y1 - g.top as f32) / g.scale).clamp(0.0, g.height as f32);
            d.y2 = ((d.y2 - g.top as f32) / g.scale).clamp(0.0, g.height as f32);
            if d.x2 <= d.x1 || d.y2 <= d.y1 {
                continue;
            }
            if result.count < (MAX_DETECTIONS as u32) {
                result.detections[result.count as usize] = d;
                result.count += 1;
            } else {
                result.truncated += 1;
            }
        }
        Ok(())
    }
}
impl Default for Workspace {
    fn default() -> Self {
        Self::new()
    }
}
fn area(d: Detection) -> f32 {
    (d.x2 - d.x1) * (d.y2 - d.y1)
}
fn overlap(a: Detection, b: Detection) -> bool {
    let w = (a.x2.min(b.x2) - a.x1.max(b.x1)).max(0.0);
    let h = (a.y2.min(b.y2) - a.y1.max(b.y1)).max(0.0);
    let intersection = w * h;
    let total = area(a) + area(b) - intersection;
    total > 0.0 && total.is_finite() && intersection / total > 0.45
}

const NAMES: [&str; CLASSES] = [
    "person",
    "bicycle",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "fire hydrant",
    "stop sign",
    "parking meter",
    "bench",
    "bird",
    "cat",
    "dog",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "backpack",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "bottle",
    "wine glass",
    "cup",
    "fork",
    "knife",
    "spoon",
    "bowl",
    "banana",
    "apple",
    "sandwich",
    "orange",
    "broccoli",
    "carrot",
    "hot dog",
    "pizza",
    "donut",
    "cake",
    "chair",
    "couch",
    "potted plant",
    "bed",
    "dining table",
    "toilet",
    "tv",
    "laptop",
    "mouse",
    "remote",
    "keyboard",
    "cell phone",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "book",
    "clock",
    "vase",
    "scissors",
    "teddy bear",
    "hair drier",
    "toothbrush",
];
pub fn class_name(id: usize) -> &'static str {
    NAMES.get(id).copied().unwrap_or("unknown")
}
