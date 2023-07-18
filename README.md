# MNIST_handwritten_digit_recognition MNIST数据集手写数字识别

## 简介

作者初学神经网络，用C++写了一个训练和识别的程序。
作者是很懒的初学者，技术很菜，写法很冗杂、很不标准，本代码仅供参考娱乐，勿喷谢谢。

## 环境和库

开发软件：Visual Studio 2022

cuda12.1, gnuplot, boost, qt6.5.1, opencv

请查看相关官网和博客教程等进行安装。

由于上传限制，无法将完整的解决方案上传，不过应该可以单独打开每个项目（有的因为文件大小限制删去了.vs文件夹）。如果遇到文件报错情况，请自行尝试修复，或者新建项目复制源码。

## 文件结构

NeuroNetwork是训练用的。

MirrorNeuroNetwork和MirrorMirrorNeuroNetwork也是训练用的，作者为了在电脑上多开所以弄了个镜像。
这几个的代码稍有区别。

MirrorMirrorMirMirRelease、MirrorMirrorMirRelease、MirrorMirrorRelease、MirrorRelease、x64\Release、NeuroNetwork
中均有运行训练的记录文件。为了便于调试，文件是txt格式的，文件名称中ACR意思是准确率，Round是训练轮数，最后一长串是日期时间。
MirrorMirrorMirMirRelease、MirrorMirrorMirRelease、MirrorMirrorRelease、MirrorRelease这四个是只有exe文件和一堆txt文件，用来运行程序的文件夹。
x64\Release、NeuroNetwork也被用来运行过程序，但是这是项目原有的文件夹。

FIleProcessor用来处理文件信息制成图表。

Interface是手写数字识别的窗口UI交互，可以手动改源码来更换模型。


## 使用注意事项

关于文件中的路径，我这里有的写的是本地的绝对路径"D:\data\program\NumberRecognizer\NumberRecognizer"，
运行程序的时候请根据实际环境更改路径——直接在源码上搜索替换吧……

Interface程序运行中，回车是“识别”的快捷键，delete键是“清空”的快捷键。

## 一些说明

由于上传限制，无法上传完整数据集，请搜索MNIST数据集并下载。包括四个文件:"t10k-images.idx3-ubyte""t10k-labels.idx1-ubyte""train-images.idx3-ubyte""train-labels.idx1-ubyte".

使用了ChatGPT进行辅助编程。

Sigmoid函数进行了多项式的近似，因为无脑exp会直接爆成nan，具体见代码。

实际效果比较有限，因为本项目写训练的时候没有卷积、没有Adam,直接把数据扔进去梯度下降。

使用Interface的时候，由于训练数据集的局限，如果要比较准确地识别的话，1需要写的比较斜，0要写的比较大，7需要在竖着的笔画中间加一个短横杠（MNIST数据集中的写法）
，而且尽量在中间区域写。如果靠边写，结果会变得很不稳定。

作者很菜，如果发现错误请及时指出，不胜感激！
