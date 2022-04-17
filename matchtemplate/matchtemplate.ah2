#DllLoad opencv_ahk.dll
#include <wincapture> 
#include <cv2>
#include <log>
SetWorkingDir A_ScriptDir

;初始化opencv模块
cv := ObjFromPtr(DllCall('opencv_ahk.dll\opencv_init', 'ptr', DllCall(A_AhkPath '\ahkGetApi', 'ptr'), 'cdecl ptr'))
dxcp := wincapture.DXGI() ;DXGI初始化

;查找目标
rtn := find_image_from_screen(A_ScriptDir '\template.png', 0, 0, A_ScreenWidth, A_ScreenHeight)

;展示结果
cv.rectangle(rtn["src"], [rtn["x"], rtn["y"], rtn["template"]["w"], rtn["template"]["h"]], [0, 255, 0], 2, 8, 0)
cv.imshow('src', rtn["src"])
MsgBox(rtn["x"] "  " rtn["y"] " sim:" rtn["sim"])
/**
* 屏幕指定区域找图
* @param template_path 目标图像路径
* @param thresh 图像灰度二值化 0-255
* @param x ROI x
* @param y ROI y
* @param w ROI w
* @param h ROI h
* @param screen_agin 重新截图
* true 重新截图， false 使用上次图像
* @return  {map}
* Map("src", l_screen_shot_roi,"x", x, "y", y, "sim", sim, "template", Map("w", template.cols ,"h", template.rows))
*/
find_image_from_screen(template_path, x, y, w, h, thresh := 100, screen_again := true)
{
	;截屏
	static l_screen_shot := cv.Mat()
	l_new_image := false
	if(screen_again)
		screen_shot()
	l_screen_shot.copyTo(l_screen_shot_roi := cv.Mat())
	l_screen_shot_roi := l_screen_shot_roi([x, y, w, h])
	;读取模板
	template := cv.imread(template_path)
	;转换为灰度
	cv.cvtColor(l_screen_shot_roi, gray_src := cv.Mat(), cv2.CV_COLOR_BGR2GRAY)
	cv.cvtColor(template, gray_template := cv.Mat(), cv2.CV_COLOR_BGR2GRAY)
	;二值化
	cv.threshold(gray_src, gray_src, thresh, 255, cv2.CV_THRESH_BINARY)
	cv.threshold(gray_template, gray_template, thresh, 255, cv2.CV_THRESH_BINARY)

	method := cv2.CV_TM_CCORR_NORMED
	;method := cv2.CV_TM_SQDIFF_NORMED
	;method := cv2.CV_TM_CCOEFF_NORMED
	;mask参数目前opencv好像没有实现
	cv.matchTemplate(gray_src, gray_template, res := cv.Mat(), method)
	cv.minMaxLoc(res, &minVal, &maxVal, &minLoc, &maxLoc)

	if(method == cv2.CV_TM_SQDIFF || method == cv2.CV_TM_SQDIFF_NORMED)
		matchLoc := minLoc, sim := minVal
	else
		matchLoc := maxLoc, sim := maxVal

	x := matchLoc[1]
	y := matchLoc[2]
	rtn := Map("src", l_screen_shot_roi,"x", x, "y", y, "sim", sim, "template", Map("w", template.cols ,"h", template.rows))
	log.info(rtn)
	return rtn

	screen_shot()
	{
		cb := CallbackCreate(revice)
		dxcp.capture(cb)
		while(l_new_image == false){
		}
		l_new_image := false
	}
	;DXGI截图回调函数
	revice(pdata, pitch, sw, sh, tick) 
	{
		if tick && pdata 
		{
			bb := BitmapBuffer(pdata, pitch, sw, sh)
			bb := bb.cvtBytes(3)
			wid := bb.width ,hei := bb.height, pBits:= bb.Ptr, Channels := 3 ;通道
			mat := cv.Mat(hei, wid, cv.constants.CV_8UC3, pBits, (wid * Channels + 3) & -4)
		}
		mat.copyTo(l_screen_shot)
		l_new_image := true
	}
}
