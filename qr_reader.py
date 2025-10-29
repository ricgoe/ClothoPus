import cv2 as cv
import numpy as np
import time
from bs4 import BeautifulSoup
import requests
from pyzbar.pyzbar import decode
import pickle
from pathlib import Path


class QRReader:
    def __init__(self, filename: Path):
        self.filename = filename
        self._cam = None
        self._qr_read: bool = False
        self._img: np.ndarray = None
        self._prusa_ID: None | str = None
        self._prusa_url: None | str = None
        self._current_filaments = {i: "" for i in range(1, 6)}
        self._MAX_CAPTURE_TIME = 10 #[s]
    
    
    @property
    def current_filaments(self):
        return self._current_filaments
    
    
    def set_new_filament(self, filament: str, idx: int):
        if not (1 <= idx <= 5):
            raise ValueError(f"Filament index must be between 1 and 5 (got {idx})")

        self._current_filaments[idx] = filament
            
            
    def init_cam(self) -> None:
        try:
            self._cam = cv.VideoCapture(0)
            if not self._cam.isOpened():
                raise RuntimeError("Camera not accessible")
            
            self._cam.set(cv.CAP_PROP_AUTOFOCUS, 1)
            self._cam.set(cv.CAP_PROP_FRAME_WIDTH, 1000)
            self._cam.set(cv.CAP_PROP_FRAME_HEIGHT, 1000)
            self._cam.set(cv.CAP_PROP_FPS, 30)
            
            print('Camera initialized successfully.')
            return True        
        
        except Exception as e:
            print(f"Camera initialization failed: {e}")
            self._cam = None
            return False
            
            
    def save_filaments(self, filename: Path) -> None:
        with open(filename, "wb") as f:
            pickle.dump(self._current_filaments, f)


    def load_filaments(self, filename: Path) -> None:
        try:
            with open(filename, "rb") as f:
                self._current_filaments = pickle.load(f)
        except FileNotFoundError:
            print(f"No filaments found in {filename.resolve()}")

    
    def capture_img_stream(self) -> None:
        timer = time.time()
        while not self._qr_read and (time.time()-timer < self._MAX_CAPTURE_TIME):
            _, cur_frame = self._cam.read()
            cur_frame_gray = cv.cvtColor(cur_frame, cv.COLOR_BGR2GRAY)
            self._prusa_url = self.read_qr(cur_frame_gray) or self.read_qr(cur_frame_gray, invert=True) # check in inverted if not found in normal pic
            if self._prusa_url:
                self.qr_read = True
                self._prusa_ID = self._prusa_url.split('/')[-1] #returns just ID of prusa roll from QR
                return
        raise TimeoutError(f"QR reading timed out after {self._MAX_CAPTURE_TIME} seconds.")
           
            
    def get_filament_name(self, roll_id: str) -> str: # input of spool ID possible if no QR provided for some reason
        url = f"https://prusament.com/spool/?spoolId={roll_id}" # prusa support for now. # TODO Look out for other vendors if they provide ID system
        response = requests.get(url)
        self.soup = BeautifulSoup(response.text, "html.parser")
        return self.soup.select_one("h1.headline").text
    
    
    def read_qr(self, img: np.ndarray, invert: bool = False) -> str | None:
        data = None
        if invert:
            img = cv.bitwise_not(img)
        for barcode in decode(img):
            data: str = barcode.data.decode('utf-8')
        return data
    
    
    def filament_picker(self):
        scanned_spool = self.get_filament_name(self._prusa_ID)
        while True:
            try:
                cur_filament_spot = int(input(f"In which spot will the spool ({scanned_spool}) be placed in (1-5)?"))
                self.set_new_filament(scanned_spool, cur_filament_spot)
                break
            except (AssertionError, KeyError, IndexError, ValueError) as e:
                print(f"Invalid input: {e}. Please try again.")
        
    
    def start(self) -> None:
        if not self.init_cam():
            print('Check cam and try again!')
        self.load_filaments(self.filename)
        try:
            self.capture_img_stream()
        except TimeoutError as e:
            print(e)
            self.stop()
            return
        self.filament_picker()
        self.stop()
        
    
    def stop(self):
        if self._cam and self._cam.isOpened():
            self._cam.release()
        self.save_filaments(self.filename)
   
         

if __name__ == "__main__":
    qrr = QRReader(Path("filamentstore.pkl"))
    qrr.start()
    
    
