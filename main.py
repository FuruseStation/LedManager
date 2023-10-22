#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

from PIL import Image, ImageColor, ImageFont, ImageDraw
from rgbmatrix import RGBMatrix, RGBMatrixOptions
import sys, termios, tty, os, time
import options
import subprocess
from subprocess import PIPE

def fileCheck():
    global imgMin, imgMax, imgPrev, imgNum, imgNext
    #前後番号をチェック
    n = imgNum
    while True:
        n += 1
        if os.path.exists(scDir + '/data/'+str(n)+'.png'):
            imgNext = n
            break
        elif n >= imgMax:
            imgNext = None
            break

    n = imgNum
    while True:
        n -= 1
        if os.path.exists(scDir + '/data/'+str(n)+'.png'):
            imgPrev = n
            break
        elif n <= imgMin:
            imgPrev = None
            break\


matrix = RGBMatrix(options = options.options)

imgNum = 0
ledSize = (128, 32)

fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)

scDir = os.path.dirname(__file__)
imgMin = 0
imgMax = 9999
imgPrev = None
imgNum = 0
imgNext = None
numTmp = ''
offPending = False

#初期画像(0番)がなければ黒画像を生成
if not os.path.exists(scDir + '/data/0.png'):
    Image.new('RGB', ledSize, (0, 0, 0)).save(scDir + '/data/0.png', "PNG")

matrix.SetImage(Image.open(scDir + '/data/0.png').convert('RGB'))
    
fileCheck()

while True:
    #キーボード入力受付
    try:
        tty.setcbreak(sys.stdin.fileno())
        ch = sys.stdin.read(1)
    finally:
        termios.tcsetattr(fd, termios.TCSANOW, old)

    keyIn = '-'+ch.replace('\n', '')+'-'
    if keyIn == '-+-':
        numTmp = ''
    elif keyIn == '-1-':
        numTmp += '1'
    elif keyIn == '-2-':
        numTmp += '2'
    elif keyIn == '-3-':
        numTmp += '3'
    elif keyIn == '-4-':
        numTmp += '4'
    elif keyIn == '-5-':
        numTmp += '5'
    elif keyIn == '-6-':
        numTmp += '6'
    elif keyIn == '-7-':
        numTmp += '7'
    elif keyIn == '-8-':
        numTmp += '8'
    elif keyIn == '-9-':
        numTmp += '9'
    elif keyIn == '-0-':
        numTmp += '0'
    elif keyIn == '-\b-' or keyIn == '-\x7f-':
        if len(numTmp) > 0:
            numTmp = numTmp[:len(numTmp)-1]
        else:
            numTmp = ''
    elif keyIn == '-/-':
        if imgPrev != None:
            numTmp = ''
            imgNum = imgPrev
    elif keyIn == '-*-':
        if imgNext != None:
            numTmp = ''
            imgNum = imgNext
    elif keyIn == '--':
        if len(numTmp) > 0:
            if os.path.exists(scDir + '/data/' + str(int(numTmp)) + '.png'):
                imgNum = int(numTmp)
                numTmp = ''
            else:
                img = Image.open(scDir + '/ui/nf.png').convert('RGB')
                matrix.SetImage(img)
                time.sleep(1)

    if keyIn == '---' and offPending:
        #自動起動スクリプトがあれば自動起動モードなので、シャットダウンを実行
        if os.path.exists('/etc/profile.d/LedManager.sh'):
            subprocess.run('systemctl poweroff -i', shell=True)
        #なければ手動起動モードなので、プロセス終了
        else:
            exit(0)
    elif keyIn == '---' and not offPending:
        offPending = True
    else:
        offPending = False
        
    if len(numTmp) > len(str(imgMax)):
        numTmp = numTmp[:len(str(imgMax))]

    if offPending:
        img = Image.open(scDir + '/ui/off.png').convert('RGB')
        matrix.SetImage(img)
    elif len(numTmp) > 0:
        img = Image.open(scDir + '/ui/in.png').convert('RGB')
        draw = ImageDraw.Draw(img)
        font = ImageFont.load(scDir + '/fonts/10x20gm.pil')
        w, h = draw.textsize(numTmp, font=font)
        draw.text(xy = (66,26-h), text=numTmp, fill=(255, 255, 255), font=font)
        matrix.SetImage(img)
    else:
        matrix.SetImage(Image.open(scDir + '/data/' + str(imgNum) + '.png').convert('RGB'))
        fileCheck()
