// Turini Assistance : fenêtre affichée pendant que le lanceur prépare l'application (premier
// lancement et après une mise à jour). Remplace libs/portable/src/ui.rs de RustDesk au moment de la
// compilation (turini/personnaliser.py) : la voiture Turini parcourt le logo au lieu de « Loading... ».
// L'animation est rendue d'avance (turini/lanceur/demarrage.gif), chaque image couvrant toute la fenêtre.

use native_windows_gui as nwg;
use nwg::NativeUi;
use std::cell::RefCell;

const GIF_DATA: &[u8] = include_bytes!("./res/turini-demarrage.gif");
const LARGEUR: i32 = 480;
const HAUTEUR: i32 = 320;
const GIF_DELAY: u64 = 66;

#[derive(Default)]
pub struct BasicApp {
    window: nwg::Window,
    gif_image: nwg::ImageFrame,
    timer: nwg::AnimationTimer,
    decoder: nwg::ImageDecoder,
    gif_index: RefCell<usize>,
    gif_images: RefCell<Vec<nwg::Bitmap>>,
}

impl BasicApp {
    fn exit(&self) {
        self.timer.stop();
        nwg::stop_thread_dispatch();
    }

    fn load_gif(&self) -> Result<(), nwg::NwgError> {
        let image_source = self.decoder.from_stream(GIF_DATA)?;
        for frame_index in 0..image_source.frame_count() {
            let bmp = image_source.frame(frame_index)?.as_bitmap()?;
            self.gif_images.borrow_mut().push(bmp);
        }
        Ok(())
    }

    fn update_gif(&self) -> Result<(), nwg::NwgError> {
        let images = self.gif_images.borrow();
        if images.len() == 0 {
            return Err(nwg::NwgError::ImageDecoderError(
                -1,
                "no gif images".to_string(),
            ));
        }
        let image_index = *self.gif_index.borrow() % images.len();
        self.gif_image.set_bitmap(Some(&images[image_index]));
        *self.gif_index.borrow_mut() = (image_index + 1) % images.len();
        Ok(())
    }

    fn start_timer(&self) {
        self.timer.start();
    }
}

mod basic_app_ui {
    use super::*;
    use native_windows_gui as nwg;
    use nwg::Event;
    use std::cell::RefCell;
    use std::ops::Deref;
    use std::rc::Rc;

    pub struct BasicAppUi {
        inner: Rc<BasicApp>,
        default_handler: RefCell<Vec<nwg::EventHandler>>,
    }

    impl nwg::NativeUi<BasicAppUi> for BasicApp {
        fn build_ui(mut data: BasicApp) -> Result<BasicAppUi, nwg::NwgError> {
            data.decoder = nwg::ImageDecoder::new()?;

            nwg::Window::builder()
                .flags(nwg::WindowFlags::POPUP | nwg::WindowFlags::VISIBLE)
                .size((LARGEUR, HAUTEUR))
                .center(true)
                .build(&mut data.window)?;

            nwg::ImageFrame::builder()
                .parent(&data.window)
                .size((LARGEUR, HAUTEUR))
                .background_color(Some([255, 255, 255]))
                .build(&mut data.gif_image)?;

            nwg::AnimationTimer::builder()
                .parent(&data.window)
                .interval(std::time::Duration::from_millis(GIF_DELAY))
                .build(&mut data.timer)?;

            let ui = BasicAppUi {
                inner: Rc::new(data),
                default_handler: Default::default(),
            };

            let evt_ui = Rc::downgrade(&ui.inner);
            let handle_events = move |evt, _evt_data, _handle| {
                if let Some(evt_ui) = evt_ui.upgrade().as_mut() {
                    match evt {
                        Event::OnWindowClose => {
                            evt_ui.exit();
                        }
                        Event::OnTimerTick => {
                            if let Err(e) = evt_ui.update_gif() {
                                eprintln!("{:?}", e);
                            }
                        }
                        _ => {}
                    }
                }
            };

            ui.default_handler
                .borrow_mut()
                .push(nwg::full_bind_event_handler(
                    &ui.window.handle,
                    handle_events,
                ));

            return Ok(ui);
        }
    }

    impl Drop for BasicAppUi {
        fn drop(&mut self) {
            let mut handlers = self.default_handler.borrow_mut();
            for handler in handlers.drain(0..) {
                nwg::unbind_event_handler(&handler);
            }
        }
    }

    impl Deref for BasicAppUi {
        type Target = BasicApp;

        fn deref(&self) -> &BasicApp {
            &self.inner
        }
    }
}

fn ui() -> Result<(), nwg::NwgError> {
    nwg::init()?;
    let app = BasicApp::build_ui(Default::default())?;
    app.load_gif()?;
    app.update_gif()?;
    app.start_timer();
    nwg::dispatch_thread_events();
    Ok(())
}

pub fn setup() {
    std::thread::spawn(move || {
        if let Err(e) = ui() {
            eprintln!("{:?}", e);
        }
    });
}
