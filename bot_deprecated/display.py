from tkinter import *
from threading import Thread, Lock
import sys
from math import sin

exit_required = False
img = None

def main():
    colors = ["#000000", "#0000aa", "#aa0000", "#00aa00"]
    f = int(sys.stdin.readline())
    w = int(sys.stdin.readline())
    h = int(sys.stdin.readline())
    lock = Lock()
    matrix = [ [ 0 for i in range(w) ] for j in range(h) ]

    # UPDATE MATRIX FROM INPUT
    def parse_input():
        global exit_required
        while True:
            try:
                line = sys.stdin.readline()
                lock.acquire()
                try:
                    for j in range(h):
                        for i in range(w):
                            matrix[j][i] = int(line[i])
                        if j < h-1:
                            line = sys.stdin.readline()
                except:
                    exit_required = True
                    break
                finally:
                    lock.release()
            except:
                exit_required = True

    t1 = Thread(target=parse_input)
    t1.start()

    # DRAW MATRIX
    master = Tk()
    canvas = Canvas(master, width=f*w+10, height=f*h+10, bg="#ffffff")
    canvas.pack()

    def refresh():
        global img, exit_required
        lock.acquire()
        try:
            canvas.delete("all")
            img = PhotoImage(width=w, height=h)
            for j in range(h):
                for i in range(w):
                    img.put(colors[matrix[j][i]],(i,j))
            img = img.zoom(f,f)
            canvas.create_image((f*w//2+5, f*h//2+5), image=img, state="normal")
            if exit_required:
                master.destroy()
            else:
                master.after(50, refresh)
        except:
            if exit_required:
                master.destroy()
        finally:
            lock.release()

    refresh()
    mainloop()

main()
