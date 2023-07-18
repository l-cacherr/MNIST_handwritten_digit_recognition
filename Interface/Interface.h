#pragma once

#include <QtWidgets/QApplication>
#include <QtWidgets/QApplication>
#include <QtWidgets/QWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QLabel>
#include <QMouseEvent>
#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <QPainter>
#include <QObject>
#include <iostream>
#include <cstring>
#include <cstdlib>
#include <vector>
#include <QSlider>
#include <QColorDialog>
#include <opencv2/opencv.hpp>

#define RANDBASE1 (long long)0x8000
#define RANDBASE2 (long long)0x40000000
#define RANDBASE3 (long long)0x200000000000

typedef double CalFloat;

CalFloat Sigmoid(CalFloat Val);

CalFloat SigmoidGrad(CalFloat Val);

double log(double Base, double Antilog);

//范围内int随机数
int RandomInt(int minValue, int maxValue);

//范围内long long随机数
long long RandomLongLong(long long minValue, long long maxValue);

//范围内double随机数
double RandomDouble(double minValue, double maxValue);

//范围内float随机数
float RandomFloat(float minValue, float maxValue);

struct NeuroNet
{
	int Deep, * Size;
	CalFloat*** w, ** b;
	CalFloat** CalVal;
	NeuroNet()
	{
		Deep = 0;
		Size = NULL;
		w = NULL;
		b = NULL;
	}
	//InitMode == 0 => all 0 init; InitMode == 1 => Random Init
	NeuroNet(std::vector<int> Scale, CalFloat InitMode = 1)
	{
		Size = (int*)malloc(Scale.size() * sizeof(int));
		for (int i = 0; i < Scale.size(); i++)
			Size[i] = Scale[i];
		Deep = Scale.size() - 1;
		b = (CalFloat**)malloc(Deep * sizeof(CalFloat*));
		for (int i = 0; i < Deep; i++)
		{
			b[i] = (CalFloat*)malloc(Scale[i + 1] * sizeof(CalFloat));
			//memset(b[i], 0, sizeof(Scale[i + 1] * sizeof(CalFloat)));
			for (int j = 0; j < Size[i + 1]; j++)
			{
				b[i][j] = RandomFloat(-1, 1) * InitMode;
			}
		}
		w = (CalFloat***)malloc(Deep * sizeof(CalFloat**));//
		for (int i = 0; i < Deep; i++)
		{
			w[i] = (CalFloat**)malloc(Scale[i] * sizeof(CalFloat*));
			for (int j = 0; j < Scale[i]; j++)
			{
				w[i][j] = (CalFloat*)malloc(Scale[i + 1] * sizeof(CalFloat));
				for (int k = 0; k < Size[i + 1]; k++)
				{
					w[i][j][k] = RandomFloat(-1, 1) * InitMode;
				}
				//memset(w[i][j], 0, sizeof(Scale[i + 1] * sizeof(CalFloat)));
			}
		}
		CalVal = (CalFloat**)malloc(Deep * sizeof(CalFloat*));
		for (int i = 0; i < Deep; i++)
		{
			CalVal[i] = (CalFloat*)malloc(Size[i + 1] * sizeof(CalFloat));
			for (int j = 0; j < Size[i + 1]; j++)
			{
				CalVal[i][j] = 0;
			}
		}
	}
	~NeuroNet()
	{
		free(w);
		free(b);
		free(Size);
		free(CalVal);
	}
	int Run(CalFloat* Input, bool DebugTag = false)
	{
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i + 1]; j++)
			{
				CalFloat TmpVal = 0;
				for (int k = 0; k < Size[i]; k++)
				{
					if (i == 0)
					{
						TmpVal += Input[k] * w[i][k][j];
					}
					else
					{
						TmpVal += CalVal[i - 1][k] * w[i][k][j];
					}
				}
				TmpVal += b[i][j];
				CalVal[i][j] = Sigmoid(TmpVal);
				//if (DebugTag) cout << CalVal[i][j] << " ";
			}
			//if (DebugTag) cout << "\n";
		}
		CalFloat MaxVal = 0, MaxLabel = 0;//-1e9?
		for (int i = 0; i < Size[Deep]; i++)
		{
			if (MaxVal < CalVal[Deep - 1][i])
			{
				MaxLabel = i;
				MaxVal = CalVal[Deep - 1][i];
			}
		}
		return MaxLabel;
	}
	void BPTrain(CalFloat** Input, int* Output, int OffsetIdx = 0, int n = 1, CalFloat StepK = 0.0010, bool DebugTag = false, std::string FileName = "BPDebug.txt")
	{
		std::vector<int> VecSize(0);
		for (int i = 0; i < Deep + 1; i++)
		{
			VecSize.push_back(Size[i]);
		}
		NeuroNet DeltaNet(VecSize, 0);
		for (int ImgIdx = 0; ImgIdx < n; ImgIdx++)
		{
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					CalVal[i][j] = 0;
				}
			}
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					CalFloat TmpVal = 0;
					for (int k = 0; k < Size[i]; k++)
					{
						if (i == 0)
						{
							TmpVal += Input[ImgIdx + OffsetIdx][k] * w[i][k][j];
						}
						else
						{
							TmpVal += CalVal[i - 1][k] * w[i][k][j];
						}
					}
					TmpVal += b[i][j];
					CalVal[i][j] = Sigmoid(TmpVal);
				}
			}
			CalFloat MaxVal = 0, MaxLabel = 0;//-1e9?
			for (int i = 0; i < Size[Deep]; i++)
			{
				if (MaxVal < CalVal[Deep - 1][i])
				{
					MaxLabel = i;
					MaxVal = CalVal[Deep - 1][i];
				}
			}
			for (int i = Deep - 1; i >= 0; i--)
			{
				if (i == Deep - 1)
				{
					for (int j = 0; j < Size[Deep]; j++)
					{
						DeltaNet.CalVal[Deep - 1][j] = (j == Output[ImgIdx + OffsetIdx] ? 1.00 : 0.00);//
					}
				}
				else
				{
					for (int k = 0; k < Size[i + 1]; k++)
					{
						CalFloat CalGrad = 0;
						for (int j = 0; j < Size[i + 1 + 1]; j++)
						{
							CalGrad += 2.00 * (CalVal[i + 1][j] - DeltaNet.CalVal[i + 1][j]) * CalVal[i + 1][j] * w[i + 1][k][j];
						}
						DeltaNet.CalVal[i][k] = CalVal[i][k] - StepK * CalGrad;//+= =
					}
				}//
				for (int j = 0; j < Size[i + 1]; j++)
				{
					DeltaNet.b[i][j] += -2.00 * (CalVal[i][j] - DeltaNet.CalVal[i][j]) * CalVal[i][j] * StepK;
				}
				for (int k = 0; k < Size[i]; k++)
				{
					for (int j = 0; j < Size[i + 1]; j++)
					{
						if (i - 1 < 0) DeltaNet.w[i][k][j] += -2.00 * (CalVal[i][j] - DeltaNet.CalVal[i][j]) * CalVal[i][j] * Input[ImgIdx + OffsetIdx][k] * StepK;
						else DeltaNet.w[i][k][j] += -2.00 * (CalVal[i][j] - DeltaNet.CalVal[i][j]) * CalVal[i][j] * CalVal[i - 1][k] * StepK;
					}
				}
			}
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i + 1]; j++)
			{
				b[i][j] += DeltaNet.b[i][j] / (CalFloat)n;
			}
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i]; j++)
			{
				for (int k = 0; k < Size[i + 1]; k++)
				{
					w[i][j][k] += DeltaNet.w[i][j][k] / (CalFloat)n;
				}
			}
		}
		if (DebugTag)
		{
			DeltaNet.WriteToFile(FileName);
			FILE* fp;
			fp = fopen(FileName.c_str(), "a");
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					fprintf(fp, "%llf ", CalVal[i][j]);
				}
				fprintf(fp, "\n");
			}
			fclose(fp);
		}
		//free(&DeltaNet);
		//free(&VecSize);
	}
	void BPTrain(NeuroNet* DeltaNet, CalFloat** Input, int* Output, int OffsetIdx = 0, int n = 1, CalFloat StepK = 0.0010, bool DebugTag = false, std::string FileName = "BPDebug.txt")
	{
		for (int i = 0; i < DeltaNet->Deep; i++)
		{
			for (int j = 0; j < DeltaNet->Size[i + 1]; j++)
			{
				DeltaNet->b[i][j] = 0;
				DeltaNet->CalVal[i][j] = 0;
			}
		}
		for (int i = 0; i < DeltaNet->Deep; i++)
		{
			for (int j = 0; j < DeltaNet->Size[i]; j++)
			{
				for (int k = 0; k < DeltaNet->Size[i + 1]; k++)
				{
					DeltaNet->w[i][j][k] = 0;
				}
			}
		}

		for (int ImgIdx = 0; ImgIdx < n; ImgIdx++)
		{
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					CalVal[i][j] = 0;
				}
			}
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					CalFloat TmpVal = 0;
					for (int k = 0; k < Size[i]; k++)
					{
						if (i == 0)
						{
							TmpVal += Input[ImgIdx + OffsetIdx][k] * w[i][k][j];
						}
						else
						{
							TmpVal += CalVal[i - 1][k] * w[i][k][j];
						}
					}
					TmpVal += b[i][j];
					CalVal[i][j] = Sigmoid(TmpVal);
				}
			}
			CalFloat MaxVal = 0, MaxLabel = 0;//-1e9?
			for (int i = 0; i < Size[Deep]; i++)
			{
				if (MaxVal < CalVal[Deep - 1][i])
				{
					MaxLabel = i;
					MaxVal = CalVal[Deep - 1][i];
				}
			}
			for (int i = Deep - 1; i >= 0; i--)
			{
				if (i == Deep - 1)
				{
					for (int j = 0; j < Size[Deep]; j++)
					{
						DeltaNet->CalVal[Deep - 1][j] = (j == Output[ImgIdx + OffsetIdx] ? 1.00 : 0.00);//
					}
				}
				else
				{
					for (int k = 0; k < Size[i + 1]; k++)
					{
						CalFloat CalGrad = 0;
						for (int j = 0; j < Size[i + 1 + 1]; j++)
						{
							CalGrad += 2.00 * (CalVal[i + 1][j] - DeltaNet->CalVal[i + 1][j]) * CalVal[i + 1][j] * (1.00 - CalVal[i + 1][j]) * w[i + 1][k][j];
						}
						DeltaNet->CalVal[i][k] = CalVal[i][k] - StepK * CalGrad;//+= =
					}
				}//
				for (int j = 0; j < Size[i + 1]; j++)
				{
					DeltaNet->b[i][j] += -2.00 * (CalVal[i][j] - DeltaNet->CalVal[i][j]) * CalVal[i][j] * (1.00 - CalVal[i][j]) * StepK;
				}
				for (int k = 0; k < Size[i]; k++)
				{
					for (int j = 0; j < Size[i + 1]; j++)
					{
						if (i - 1 < 0) DeltaNet->w[i][k][j] += -2.00 * (CalVal[i][j] - DeltaNet->CalVal[i][j]) * CalVal[i][j] * (1.00 - CalVal[i][j]) * Input[ImgIdx + OffsetIdx][k] * StepK;
						else DeltaNet->w[i][k][j] += -2.00 * (CalVal[i][j] - DeltaNet->CalVal[i][j]) * CalVal[i][j] * (1.00 - CalVal[i][j]) * CalVal[i - 1][k] * StepK;
					}
				}
			}
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i + 1]; j++)
			{
				b[i][j] += DeltaNet->b[i][j] / (CalFloat)n;
			}
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i]; j++)
			{
				for (int k = 0; k < Size[i + 1]; k++)
				{
					w[i][j][k] += DeltaNet->w[i][j][k] / (CalFloat)n;
				}
			}
		}
		if (DebugTag)
		{
			DeltaNet->WriteToFile(FileName);
			FILE* fp;
			fp = fopen(FileName.c_str(), "a");
			for (int i = 0; i < Deep; i++)
			{
				for (int j = 0; j < Size[i + 1]; j++)
				{
					fprintf(fp, "%llf ", CalVal[i][j]);
				}
				fprintf(fp, "\n");
			}
			fclose(fp);
		}
		//free(&DeltaNet);
		//free(&VecSize);
	}
	void WriteToFile(std::string FileName)
	{
		FILE* fp;
		fp = fopen(FileName.c_str(), "w");
		fprintf(fp, "%d\n", Deep);
		for (int i = 0; i < Deep + 1; i++)
		{
			fprintf(fp, "%d ", Size[i]);
		}
		fprintf(fp, "\n");
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i + 1]; j++)
			{
				fprintf(fp, "%lf ", b[i][j]);
			}
			fprintf(fp, "\n");
		}
		fprintf(fp, "\n");
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i]; j++)
			{
				for (int k = 0; k < Size[i + 1]; k++)
				{
					fprintf(fp, "%lf ", w[i][j][k]);
				}
				fprintf(fp, "\n");
			}
			fprintf(fp, "\n");
		}
		fclose(fp);
	}
	void ReadFromFile(std::string FileName)
	{
		FILE* fp;
		fp = fopen(FileName.c_str(), "r");
		if (fp == NULL) {
			printf("FileOpenError\n");
			return;
		}
		//cout << "Reading from file:" << FileName << "\n";
		fscanf(fp, "%d", &Deep);
		for (int i = 0; i < Deep + 1; i++)
		{
			fscanf(fp, "%d", &Size[i]);
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i + 1]; j++)
			{
				fscanf(fp, "%lf", &b[i][j]);//"%llf _"
				//cout << b[i][j] << " ";
			}
			//cout << "\n";
		}
		for (int i = 0; i < Deep; i++)
		{
			for (int j = 0; j < Size[i]; j++)
			{
				for (int k = 0; k < Size[i + 1]; k++)
				{
					fscanf(fp, "%lf", &w[i][j][k]);//
				}
			}
		}
		fclose(fp);
	}
};

class DrawingArea : public QWidget {
    Q_OBJECT
public:
    DrawingArea(QWidget* parent = nullptr) : QWidget(parent), mousePressed(false) {
        setFixedSize(280, 280); // 设置绘图区域的大小为280x280像素
        setAutoFillBackground(true); // 允许自动填充背景
        setPalette(QPalette(Qt::black)); // 设置背景颜色为纯黑色
        image.fill(Qt::black);

		// 设置默认画笔宽度和颜色
		penWidth = 1;
    }

public:
    void paintEvent(QPaintEvent* event) override {
        QPainter painter(this);
        painter.setPen(Qt::black);
        painter.fillRect(rect(), Qt::white); // 绘制白色背景
        painter.drawImage(QRect(0, 0, 280, 280), image); // 将保存的绘图内容绘制到窗口上
    }

    void mousePressEvent(QMouseEvent* event) override {

        if (event->button() == Qt::LeftButton) {
            lastPoint = event->pos();
            mousePressed = true;

            // 将鼠标事件坐标进行缩放调整
            int x = event->pos().x() * 28 / width();
            int y = event->pos().y() * 28 / height();

            // 将像素点设置为白色
            image.setPixelColor(x, y, QColor(Qt::white));

            update(); // 更新绘图区域
        }
    }

    void mouseMoveEvent(QMouseEvent* event) override {

        if ((event->buttons() & Qt::LeftButton) && mousePressed) {
            QPoint currentPoint = event->pos();

            // 将鼠标事件坐标进行缩放调整
            int x1 = lastPoint.x() * 28 / width();
            int y1 = lastPoint.y() * 28 / height();
            int x2 = currentPoint.x() * 28 / width();
            int y2 = currentPoint.y() * 28 / height();

			// 在两个坐标之间绘制带有宽度的白色线段
			QPainter painter(&image);
			painter.setRenderHint(QPainter::Antialiasing, true);
			painter.setPen(QPen(Qt::white, penWidth, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
			painter.drawLine(x1, y1, x2, y2);

			lastPoint = currentPoint;

			update(); // 更新绘图区域
        }
    }

    void mouseReleaseEvent(QMouseEvent* event) override {

        if (event->button() == Qt::LeftButton && mousePressed) {
            mousePressed = false;
            emit drawingCompleted(image); // 发送绘图完成信号，并传递绘图内容
        }
    }

public:
    void drawLineTo(const QPoint& endPoint) {
        QPainter painter(&image);
        painter.setRenderHint(QPainter::Antialiasing, true);
        painter.setPen(Qt::black);
        painter.drawLine(lastPoint, endPoint); // 绘制线条
        lastPoint = endPoint;
        update();
    }

public slots:
    void clearImage() {
        image.fill(Qt::black); // 将绘图内容填充为黑色
        update(); // 更新绘图区域

    }

signals:
    void drawingCompleted(const QImage& image);

public:
    QImage image{ 28, 28, QImage::Format_RGB32 }; // 用于保存绘图内容的QImage对象
    bool mousePressed;
    QPoint lastPoint;
	int penWidth;
};

class MainWindow : public QWidget {
    Q_OBJECT
public:
	MainWindow(NeuroNet* InitPtr, QWidget* parent = nullptr) : QWidget(parent) {
		NumRecogNet = InitPtr;

		QVBoxLayout* layout = new QVBoxLayout(this);

		drawingArea = new DrawingArea(this);
		connect(drawingArea, &DrawingArea::drawingCompleted, this, &MainWindow::onDrawingCompleted);

		QPushButton* recognizeButton = new QPushButton("Recognize", this);
		connect(recognizeButton, &QPushButton::clicked, this, &MainWindow::onRecognizeClicked);

		QPushButton* clearButton = new QPushButton("Clear", this);
		connect(clearButton, &QPushButton::clicked, drawingArea, &DrawingArea::clearImage);
		connect(clearButton, &QPushButton::clicked, this, &MainWindow::onClearRecognitionResult);

		resultLabel = new QLabel("Result: -", this);

		// 创建画笔宽度和颜色选项
		QLabel* penWidthLabel = new QLabel("Pen Width:", this);
		QSlider* penWidthSlider = new QSlider(Qt::Horizontal, this);
		penWidthSlider->setRange(1, 3); // 设置画笔宽度的范围
		penWidthSlider->setValue(drawingArea->penWidth);
		connect(penWidthSlider, &QSlider::valueChanged, drawingArea, [&](int value) {
			drawingArea->penWidth = value;
			});

		layout->addWidget(drawingArea);
		layout->addWidget(clearButton);
		layout->addWidget(recognizeButton);
		layout->addWidget(resultLabel);
		layout->addWidget(penWidthLabel);
		layout->addWidget(penWidthSlider);

		setLayout(layout);
		setWindowTitle("Number Recognize");
	}

public slots:

	void keyPressEvent(QKeyEvent* event) override {
		if (event->key() == Qt::Key_Enter || event->key() == Qt::Key_Return) {
			onRecognizeClicked();
		}
		else if (event->key() == Qt::Key_Delete || event->key() == Qt::Key_Backspace) {
			onClearRecognitionResult();
			drawingArea->clearImage();
		}
	}

    void onDrawingCompleted(const QImage& image) {
        cvImage = cv::Mat(image.height(), image.width(), CV_8UC4, const_cast<uchar*>(image.constBits()), image.bytesPerLine());	
	}

	void onRecognizeClicked() {
		// 将cvImage拆分为一行，并将像素的灰度值写入Input数组
		double Input[28 * 28];
		for (int row = 0; row < cvImage.rows; row++) {
			for (int col = 0; col < cvImage.cols; col++) {
				cv::Vec4b pixel = cvImage.at<cv::Vec4b>(row, col);
				double gray = (pixel[0] + pixel[1] + pixel[2]) / 3.0; // 计算灰度值
				Input[row * cvImage.cols + col] = gray / 255.00;
				//Input[col * cvImage.rows + row] = gray / 255.00;
			}
		}

        RecogResult = NumRecogNet->Run(Input,0); // 替换为实际的识别结果
        resultLabel->setText(QString("Result: %1").arg(RecogResult));
    }

    void onClearRecognitionResult() {
        // 清除识别结果
        resultLabel->setText("Result: -");
    }


public:
	cv::Mat cvImage;
    QLabel* resultLabel;
    int RecogResult;
    NeuroNet* NumRecogNet;
	DrawingArea* drawingArea;
};