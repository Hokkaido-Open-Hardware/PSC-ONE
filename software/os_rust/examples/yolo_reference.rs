//! Production JPEG/preprocess/inference/NMS/display replay against C/PC artifacts.
use psc_os::{
    api::{
        jpeg::{
            jpeg_view::{decode_with_device, probe_with_device},
            RgbSink,
        },
        tflite::{tflite_graph::Graph, tflite_runtime::Backend, tflite_synap::Device},
        yolo::{yolo_display::*, yolo_postprocess::class_name, *},
    },
    fs::{fat32::BlockDevice, fat32_stream::short_name},
};
use std::{env, fmt::Write, fs, path::Path};
struct Disk(Vec<[u8; 512]>);
impl BlockDevice for Disk {
    fn read(&mut self, lba: u32, b: &mut [u8; 512]) -> Result<(), i32> {
        *b = *self.0.get(lba as usize).ok_or(-4)?;
        Ok(())
    }
    fn write(&mut self, _: u32, _: &[u8; 512]) -> Result<(), i32> {
        Err(-4)
    }
}
fn word(b: &mut [u8], at: usize, v: u32) {
    b[at..at + 4].copy_from_slice(&v.to_le_bytes());
}
fn disk(bytes: &[u8]) -> Disk {
    let n = bytes.len().div_ceil(512);
    let fats = (n + 3).div_ceil(128);
    let data = 2 + fats;
    let mut d = Disk(vec![[0; 512]; data + n + 1]);
    d.0[0][510..].copy_from_slice(&[0x55, 0xaa]);
    word(&mut d.0[0], 0x1c6, 1);
    let b = &mut d.0[1];
    b[11..13].copy_from_slice(&512u16.to_le_bytes());
    b[13] = 1;
    b[14] = 1;
    b[16] = 1;
    word(b, 32, (data + n) as u32);
    word(b, 36, fats as u32);
    word(b, 44, 2);
    b[510..].copy_from_slice(&[0x55, 0xaa]);
    word(&mut d.0[2], 8, 0x0fff_ffff);
    for i in 0..n {
        let c = i + 3;
        word(
            &mut d.0[2 + c / 128],
            (c % 128) * 4,
            if i + 1 == n {
                0x0fff_ffff
            } else {
                c as u32 + 1
            },
        );
    }
    let b = &mut d.0[data];
    b[..11].copy_from_slice(&short_name("IMAGE.JPG").unwrap());
    b[11] = 0x20;
    b[26] = 3;
    word(b, 28, bytes.len() as u32);
    for (i, chunk) in bytes.chunks(512).enumerate() {
        d.0[data + 1 + i][..chunk.len()].copy_from_slice(chunk);
    }
    d
}
struct Screen {
    pixels: Vec<u8>,
    rectangles: Vec<[u32; 4]>,
    fail: bool,
}
impl Screen {
    fn new() -> Self {
        Self {
            pixels: vec![0; 480 * 320 * 3],
            rectangles: vec![],
            fail: false,
        }
    }
}
impl Lcd for Screen {
    fn begin(&mut self) -> Result<(), i32> {
        if self.fail {
            Err(-104)
        } else {
            Ok(())
        }
    }
    fn rect(&mut self, x: u32, y: u32, w: u32, h: u32, rgb: &[u8]) -> Result<(), i32> {
        if self.fail {
            return Err(-104);
        }
        assert!(w > 0 && w <= 16 && h > 0 && h <= 16 && x + w <= 480 && y + h <= 320);
        assert_eq!(rgb.len(), (w * h * 3) as usize);
        self.rectangles.push([x, y, w, h]);
        for row in 0..h {
            let at = ((y + row) * 480 + x) as usize * 3;
            let src = (row * w * 3) as usize;
            self.pixels[at..at + w as usize * 3].copy_from_slice(&rgb[src..src + w as usize * 3]);
        }
        Ok(())
    }
}
struct Host {
    calls: u32,
    fail_at: Option<u32>,
}
impl Device for Host {
    fn clock_us(&mut self) -> i32 {
        0
    }
    fn tile(
        &mut self,
        a: &[i8],
        b: &[i8],
        c: &mut [i32],
        m: usize,
        k: usize,
        n: usize,
        p: Option<&mut psc_os::api::sa_transfer::Profile>,
    ) -> i32 {
        self.calls += 1;
        if self.fail_at == Some(self.calls) {
            return -2;
        }
        for row in 0..m {
            for col in 0..n {
                c[row * n + col] = (0..k)
                    .map(|j| a[row * k + j] as i32 * b[j * n + col] as i32)
                    .sum();
            }
        }
        if let Some(p) = p {
            p.valid = 1;
        }
        0
    }
}
fn result_json(r: &YoloResult) -> String {
    let g = r.geometry;
    let mut s=format!("{{\"geometry\":[{},{},{},{},{},{}],\"scale\":{},\"candidates\":{},\"nms_count\":{},\"truncated\":{},\"detections\":[",g.width,g.height,g.resized_width,g.resized_height,g.left,g.top,g.scale,r.candidates,r.nms_count,r.truncated);
    for (i, d) in r.detections[..r.count as usize].iter().enumerate() {
        if i != 0 {
            s.push(',');
        }
        write!(
            &mut s,
            "{{\"anchor\":{},\"class\":{},\"name\":\"{}\",\"score\":{},\"xyxy\":[{},{},{},{}]}}",
            d.anchor,
            d.class_id,
            class_name(d.class_id as usize),
            d.score,
            d.x1,
            d.y1,
            d.x2,
            d.y2
        )
        .unwrap();
    }
    s.push_str("]}\n");
    s
}
fn geometry() -> Geometry {
    Geometry {
        width: 480,
        height: 320,
        resized_width: 160,
        resized_height: 107,
        left: 0,
        top: 26,
        scale: 0.5 / 1.5,
    }
}
fn main() {
    let a: Vec<_> = env::args().collect();
    match a[1].as_str() {
        "raw" => {
            let rgb = fs::read(&a[2]).unwrap();
            let w: u32 = a[3].parse().unwrap();
            let h: u32 = a[4].parse().unwrap();
            let bw: u32 = a[5].parse().unwrap();
            let bh: u32 = a[6].parse().unwrap();
            let mut input = vec![0; INPUT_BYTES];
            let mut work = Box::new(Workspace::new());
            let mut stream = work.pre().stream(&mut input);
            stream.begin(w, h).unwrap();
            for y in (0..h).step_by(bh as usize) {
                for x in (0..w).step_by(bw as usize) {
                    let ww = bw.min(w - x);
                    let hh = bh.min(h - y);
                    let mut tile = vec![];
                    for row in 0..hh {
                        let at = ((y + row) * w + x) as usize * 3;
                        tile.extend_from_slice(&rgb[at..at + ww as usize * 3]);
                    }
                    stream.rect(x, y, ww, hh, &tile).unwrap();
                }
            }
            stream.finish().unwrap();
            fs::write(&a[7], input).unwrap();
        }
        "post" => {
            let output = fs::read(&a[2]).unwrap();
            let mut w = Box::new(Workspace::new());
            let mut r = YoloResult::new();
            w.post().process(&output, geometry(), &mut r).unwrap();
            fs::write(&a[3], result_json(&r)).unwrap();
        }
        "display" => {
            let jpg = fs::read(&a[2]).unwrap();
            let fixture = fs::read_to_string(&a[3]).unwrap();
            let mut values = fixture.split_whitespace();
            let mut r = YoloResult::new();
            r.geometry.width = values.next().unwrap().parse().unwrap();
            r.geometry.height = values.next().unwrap().parse().unwrap();
            r.count = values.next().unwrap().parse().unwrap();
            for d in &mut r.detections[..r.count as usize] {
                d.x1 = values.next().unwrap().parse().unwrap();
                d.y1 = values.next().unwrap().parse().unwrap();
                d.x2 = values.next().unwrap().parse().unwrap();
                d.y2 = values.next().unwrap().parse().unwrap();
                d.score = values.next().unwrap().parse().unwrap();
                d.class_id = values.next().unwrap().parse().unwrap();
            }
            Renderer::validate(&r).unwrap();
            let mut screen = Screen::new();
            decode_with_device(
                "IMAGE.JPG",
                &mut disk(&jpg),
                &mut ImageSink {
                    lcd: &mut screen,
                    geometry: r.geometry,
                },
            )
            .unwrap();
            let mut renderer = Renderer::new();
            renderer.overlays(&mut screen, &r).unwrap();
            if a[5] == "long" {
                renderer
                    .label(&mut screen, 479, 319, &"W".repeat(200), 1.0)
                    .unwrap();
            }
            fs::write(Path::new(&a[4]).join("overlay.rgb"), screen.pixels).unwrap();
        }
        "image" => {
            let model = fs::read(&a[2]).unwrap();
            let jpg = fs::read(&a[3]).unwrap();
            let out = Path::new(&a[4]);
            fs::create_dir_all(out).unwrap();
            let backend = match a[5].as_str() {
                "npu" => Backend::Synap,
                "pulp" => Backend::Pulp,
                "auto" => Backend::Auto,
                _ => Backend::Cpu,
            };
            let mut arena = vec![0; 768 * 1024];
            let mut graph = Box::new(Graph::new());
            graph.prepare(&model, &mut arena).unwrap();
            assert!(profile_ok(&graph));
            graph.set_backend(backend);
            graph.profiling = true;
            let mut work = Box::new(Workspace::new());
            let header = probe_with_device("IMAGE.JPG", &mut disk(&jpg)).unwrap();
            let input = graph.input().unwrap();
            let mut stream = work.pre().stream(input);
            decode_with_device("IMAGE.JPG", &mut disk(&jpg), &mut stream).unwrap();
            let g = stream.finish().unwrap();
            assert_eq!(
                (g.width, g.height),
                (header.width as u32, header.height as u32)
            );
            fs::write(out.join("input.bin"), &*input).unwrap();
            let saved = input.to_vec();
            let mut host = Host {
                calls: 0,
                fail_at: None,
            };
            let mut progress = vec![];
            graph
                .invoke_traced(
                    &mut host,
                    |op, id, _, bytes| {
                        assert_eq!(
                            fs::read(Path::new(&a[6]).join(format!("tensor-{id}.bin"))).unwrap(),
                            bytes,
                            "operator {op}"
                        );
                        Ok(())
                    },
                    |i, b| progress.push((i, b)),
                )
                .unwrap();
            assert_eq!(progress.len(), 578);
            assert_eq!(progress[0], (0, true));
            assert_eq!(progress[577], (288, false));
            assert_eq!(graph.execution.completed, 289);
            let expected = if backend == Backend::Cpu {
                [289, 0, 0]
            } else if backend == Backend::Synap {
                [225, 64, 0]
            } else {
                [225, 0, 64]
            };
            assert_eq!(graph.execution.operators, expected);
            assert_eq!(
                host.calls,
                if backend == Backend::Synap { 10642 } else { 0 }
            );
            assert_eq!(graph.profile.tiles, host.calls);
            assert!(graph.profile.valid);
            for i in 0..289 {
                assert!(graph.operator_reason(i).is_some());
            }
            assert!(graph.operator_reason(289).is_none());
            let output = graph.output().unwrap();
            fs::write(out.join("output.bin"), output).unwrap();
            let expected_output = output.to_vec();
            let mut r = YoloResult::new();
            work.post().process(output, g, &mut r).unwrap();
            fs::write(out.join("result.json"), result_json(&r)).unwrap();
            let mut screen = Screen::new();
            let mut renderer = Renderer::new();
            renderer.clear(&mut screen).unwrap();
            decode_with_device(
                "IMAGE.JPG",
                &mut disk(&jpg),
                &mut ImageSink {
                    lcd: &mut screen,
                    geometry: g,
                },
            )
            .unwrap();
            renderer.overlays(&mut screen, &r).unwrap();
            fs::write(out.join("overlay.rgb"), &screen.pixels).unwrap();
            // Failed begun NPU calls preserve successful tile counts and invalidate output.
            if backend == Backend::Synap {
                graph.input().unwrap().copy_from_slice(&saved);
                host.calls = 0;
                host.fail_at = Some(3);
                assert_eq!(graph.invoke(&mut host, |_, _, _, _| Ok(())), Err(-207));
                assert!(graph.output().is_none());
                assert_eq!(host.calls, 3);
                assert_eq!(graph.profile.tiles, 2);
                assert!(!graph.profile.valid);
                assert_eq!(graph.profile.device_status, -2);
                let stopped = graph.execution.completed as usize;
                assert_eq!(graph.records[stopped].status, -207);
                assert_eq!(graph.records[stopped].tiles, 2);
                assert!(graph.operator_reason(stopped).is_none());
                graph.input().unwrap().copy_from_slice(&saved);
                host.calls = 0;
                host.fail_at = None;
                graph.invoke(&mut host, |_, _, _, _| Ok(())).unwrap();
                assert_eq!(graph.output().unwrap(), expected_output);
            }
            // Decoder callback failures and missing EOI must propagate before commit.
            let mut invalid = vec![0; INPUT_BYTES];
            let mut stream = work.pre().stream(&mut invalid);
            assert!(
                decode_with_device("IMAGE.JPG", &mut disk(&jpg[..jpg.len() - 2]), &mut stream)
                    .is_err()
            );
            let mut stream = work.pre().stream(&mut invalid);
            decode_with_device("IMAGE.JPG", &mut disk(&jpg), &mut stream).unwrap();
            assert_eq!(stream.finish().unwrap(), g);
            assert_eq!(invalid, saved);
            struct Reject(i32);
            impl RgbSink for Reject {
                fn begin(&mut self, _: u32, _: u32) -> Result<(), i32> {
                    Err(self.0)
                }
                fn rect(&mut self, _: u32, _: u32, _: u32, _: u32, _: &[u8]) -> Result<(), i32> {
                    panic!("begin failed")
                }
            }
            assert_eq!(
                decode_with_device("IMAGE.JPG", &mut disk(&jpg), &mut Reject(-302)),
                Err(-302)
            );
            assert_eq!(
                decode_with_device("IMAGE.JPG", &mut disk(&jpg), &mut Reject(1)),
                Err(-100)
            );
            screen.fail = true;
            assert_eq!(
                decode_with_device(
                    "IMAGE.JPG",
                    &mut disk(&jpg),
                    &mut ImageSink {
                        lcd: &mut screen,
                        geometry: g
                    }
                ),
                Err(-104)
            );
            assert_eq!(graph.output().unwrap(), expected_output);
            println!(
                "PASS JPEG + 289 tensors + NMS/LCD + recovery backend={:?}",
                backend
            );
        }
        _ => panic!("raw/post/display/image"),
    }
}
