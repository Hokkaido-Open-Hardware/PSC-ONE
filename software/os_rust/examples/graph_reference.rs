//! Host oracle runner: model output input [reference tensor directory].
use psc_os::api::tflite::{tflite_graph::Graph, tflite_runtime::Backend, tflite_synap::Device};
use std::{env, fs, path::Path};
struct Host;
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
        _: Option<&mut psc_os::api::sa_transfer::Profile>,
    ) -> i32 {
        for row in 0..m {
            for col in 0..n {
                c[row * n + col] = (0..k)
                    .map(|j| a[row * k + j] as i32 * b[j * n + col] as i32)
                    .sum();
            }
        }
        0
    }
}
fn run() -> Result<(), String> {
    let args: Vec<_> = env::args().collect();
    if args.len() < 4 {
        return Err("usage: graph_reference model output input [reference-dir]".into());
    }
    let model = fs::read(&args[1]).map_err(|e| e.to_string())?;
    let input = fs::read(&args[3]).map_err(|e| e.to_string())?;
    let mut arena = vec![0; 768 * 1024];
    let mut graph = Box::new(Graph::new());
    graph
        .prepare(&model, &mut arena)
        .map_err(|e| format!("inspect={e} required={}", graph.required))?;
    let backend = match env::var("PSC_RUST_BACKEND").as_deref() {
        Ok("npu") => Backend::Synap,
        Ok("pulp") => Backend::Pulp,
        Ok("auto") => Backend::Auto,
        _ => Backend::Cpu,
    };
    graph.set_backend(backend);
    let dst = graph.input().map_err(|e| e.to_string())?;
    if dst.len() != input.len() {
        return Err("input size mismatch".into());
    }
    dst.copy_from_slice(&input);
    let mut mismatch = None;
    graph
        .invoke(&mut Host, |op, id, _kind, bytes| {
            if let Some(dir) = args.get(4) {
                let path = Path::new(dir).join(format!("tensor-{id}.bin"));
                let expected = fs::read(&path).unwrap_or_default();
                if expected != bytes {
                    mismatch = Some(format!(
                        "operator {op} tensor {id}: {} bytes, first difference {:?}",
                        bytes.len(),
                        expected.iter().zip(bytes).position(|(a, b)| a != b)
                    ));
                    return Err(-203);
                }
            }
            Ok(())
        })
        .map_err(|e| format!("invoke={e} {mismatch:?}"))?;
    fs::write(&args[2], graph.output().ok_or("missing output")?).map_err(|e| e.to_string())?;
    println!(
        "PASS {} operators; arena={}",
        graph.info.operators, graph.required
    );
    Ok(())
}
fn main() {
    if let Err(e) = run() {
        println!("{e}");
        std::process::exit(1)
    }
}
