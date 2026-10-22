//! shell/elf_command.c. Read the complete image before the synchronous ELF call.
use crate::{
    api::user::*,
    fs::fat32_stream::File,
    kernel::{elf_loader::FILE_MAX, syscall::SYS_ELF_RUN},
};
/// Keep the image on the shell stack until the synchronous ELF syscall has returned.
pub fn cmd_run_elf(name: &str) -> Result<i32, i32> {
    let mut image = [0u8; FILE_MAX];
    let mut file = File::default();
    file.open(&mut UserSd, name)?;
    if file.file_size as usize > image.len() {
        file.close();
        return Err(-7);
    }
    let size = file.file_size as usize;
    let mut actual = 0;
    let result = file.read(&mut UserSd, &mut image[..size], &mut actual);
    file.close();
    result?;
    if actual as usize != size {
        return Err(-4);
    }
    let (status, exit) =
        unsafe { syscall(SYS_ELF_RUN, [image.as_ptr() as u32, actual, 0, 0, 0, 0]) };
    if status == 0 {
        Ok(exit as i32)
    } else {
        Err(status as i32)
    }
}
