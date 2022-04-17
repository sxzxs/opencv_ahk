#include "cv2.ah2"
#DllLoad opencv_ahk.dll
cv := ObjFromPtr(DllCall('opencv_ahk.dll\opencv_init', 'ptr', DllCall(A_AhkPath '\ahkGetApi', 'ptr'), 'cdecl ptr'))
MsgBox("key down in image")

img := cv.imread(A_ScriptDir '\1.png')
copy := img.clone()
cv.imshow('img', img)
cv.waitkey()
cv.cvtColor(img, img_grey := cv.Mat(), cv.constants.COLOR_BGR2GRAY)
cv.imshow('img', img_grey)
cv.waitkey()
cv.Canny(img_grey, canny := cv.Mat(), 80.0, 160.0)
cv.imshow('img', canny)

k := cv.getStructuringElement(cv2.CV_MORPH_RECT, [3, 3], [-1, -1])
cv.dilate(canny, canny, k)
cv.imshow('img', canny)

cv.waitkey()
cv.findContours(canny, contours := cv.Vector_Vector_Point(), cv2.CV_RETR_EXTERNAL, cv2.CV_CHAIN_APPROX_SIMPLE, [])

approx_contours := cv.Vector_Vector_Point()
array_of_contours := contours.toArray()
loop(contours.Size)
{
    approx_contour := cv.Vector_Point()
    cv.approxPolyDP(cv.Vector_Point(array_of_contours[A_Index]), approx_contour, 30, true)
    approx_contours.push(approx_contour)
    cv.drawContours(copy, approx_contours, A_Index - 1, [0, 255, 0], 3, 1, 16)
    cv.imshow('img', copy)
    cv.waitkey()
    array_of_approx_contour := approx_contour.toArray()
    min_index := 1
    loop(array_of_approx_contour.Length)
    {
        next := A_Index == array_of_approx_contour.Length ? 1 : A_Index + 1
        length := getDistance(array_of_approx_contour[A_Index], array_of_approx_contour[next])
        if (A_Index == 1)
            min_length := length
        else if (length < min_length)
        {
            min_index := A_Index
            min_length := length
        }
    }

    next := (min_index == array_of_approx_contour.Length) ? 1 : min_index + 1
    fixed_point_index := Mod(min_index + 2, 5) + 1
    center := [(array_of_approx_contour[min_index][1] + array_of_approx_contour[next][1]) / 2, (array_of_approx_contour[min_index][2] + array_of_approx_contour[next][2]) / 2]
    cv.line(copy, center, array_of_approx_contour[fixed_point_index], [0, 255, 0])
    angel := get_point_angle(center, array_of_approx_contour[fixed_point_index])
    cv.putText(copy, String(Integer(angel)), center, cv2.CV_FONT_HERSHEY_SIMPLEX, 0.45, [0, 0, 255], 2)
    cv.imshow('img', copy)
    cv.waitkey()
}

cv.imshow('img', copy)

;opencv  求两点间距
getDistance(pointO, pointA)
{
    distance := (pointO[1] - pointA[1])**2 + (pointO[2] - pointA[2])**2
    distance := Sqrt(distance)
    return distance
}

/************************************************************************
*函数名：        get_point_angle
*
*函数作用：      已知2个坐标点，求从 0------->x 逆时针需旋转多少角度到该位置
*
*                   |
*                   |
*                   |
*                   |
*------------------------------------> x
*                   | 0
*                   |
*                   |
*                   |
*                   v
*                   y
*
*函数参数：
*CvPoint2D32f pointO  - 起点
*CvPoint2D32f pointA  - 终点
*
*函数返回值：
*double         向量OA，从 0------->x 逆时针需旋转多少角度到该位置
**************************************************************************/
get_point_angle(pointO, pointA)
{
    point := [(pointA[1] - pointO[1]), (pointA[2] - pointO[2])]

    if ((0 == point[1]) && (0 == point[2]))
    {
        return 0
    }

    if (0 == point[1])
    {
        angle := 90
        return angle
    }

    if (0 == point[2])
    {
        angle := 0
        return angle
    }

    temp := Abs(float(point[2]) / float(point[1]))
    temp := ATan(temp)
    temp := temp * 180 / cv2.CV_PI

    if ((0 < point[1]) && (0 < point[2]))
    {
        angle := 360 - temp
        return angle
    }

    if ((0 > point[1]) && (0 < point[2]))
    {
        angle := 360 - (180 - temp)
        return angle
    }

    if ((0 < point[1]) && (0 > point[2]))
    {
        angle := temp
        return angle
    }

    if ((0 > point[1]) && (0 > point[2]))
    {
        angle := 180 - temp
        return angle
    }
    return -1
}
