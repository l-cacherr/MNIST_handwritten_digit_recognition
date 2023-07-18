
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <iostream>
#include <cstdlib>
#include <cmath>
#include <cstring>
#include <cstdarg>
#include <vector>
#include <opencv2/opencv.hpp>
#include <Windows.h>

#define RANDBASE1 (long long)0x8000
#define RANDBASE2 (long long)0x40000000
#define RANDBASE3 (long long)0x200000000000

using namespace std;
using namespace cv;

typedef double CalFloat;

CalFloat Sigmoid(CalFloat Val)
{
	if (Val >= 3.00) return 1.00 - 1.00 / (Val * Val * Val);
	if (Val <= -3.00) return -1.00 / (Val * Val * Val);
	return 1.00 / (1.00 + exp(-Val));
}

CalFloat SigmoidGrad(CalFloat Val)
{
	if (Val >= 3.00 || Val <= -3.00) return 3.00 / (Val * Val * Val * Val);
	return Sigmoid(Val) * (1.00 - Sigmoid(Val));
}

double log(double Base, double Antilog)
{
	return log(Antilog) / log(Base);
}

//范围内int随机数
int RandomInt(int minValue, int maxValue)//
{
	if (maxValue - minValue <= 1)
		return minValue;
	return ((rand() + rand() * (RAND_MAX + 1)) % (maxValue - minValue + 1)) + minValue;
}

//范围内long long随机数
long long RandomLongLong(long long minValue, long long maxValue)//
{
	if (maxValue - minValue <= 1)
		return minValue;
	return (((long long)rand() + (long long)rand() * RANDBASE1 + (long long)rand() * RANDBASE2 + (long long)rand() * RANDBASE3) % (maxValue - minValue + 1)) + minValue;
}

//范围内double随机数
double RandomDouble(double minValue, double maxValue)//整数位在1e7范围中，小数精度到7位
{
	const double numscale = 1e7;//先缩放，后还原
	return RandomLongLong((long long)(minValue * numscale), (long long)(maxValue * numscale)) / numscale;
}

//范围内float随机数
float RandomFloat(float minValue, float maxValue)//整数位在1e7范围中，小数精度到7位
{
	const float numscale = 1e3;//先缩放，后还原
	return RandomLongLong((long long)(minValue * numscale), (long long)(maxValue * numscale)) / numscale;
}

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
	NeuroNet(vector<int> Scale, CalFloat InitMode = 1)
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
				if (DebugTag) cout << CalVal[i][j] << " ";
			}
			if (DebugTag) cout << "\n";
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
	void BPTrain(CalFloat** Input, int* Output, int OffsetIdx = 0, int n = 1, CalFloat StepK = 0.0010, bool DebugTag = false, string FileName = "BPDebug.txt")
	{
		vector<int> VecSize(0);
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
	void BPTrain(NeuroNet* DeltaNet, CalFloat** Input, int* Output, int OffsetIdx = 0, int n = 1, CalFloat StepK = 0.0010, bool DebugTag = false, string FileName = "BPDebug.txt")
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
	void WriteToFile(string FileName)
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
	void ReadFromFile(string FileName)
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

unsigned int ImgFileTypeNumber, ImgCnt, ImgWidth, ImgHeight;
unsigned int TagFileTypeNumber, TagCnt;

unsigned int HighToLow(unsigned int Input)//大端转化成小端
{
	unsigned int Byte1, Byte2, Byte3, Byte4;
	Byte1 = Input & ((1 << 8) - 1);//(~(1 << 8));
	Input >>= 8;
	Byte2 = Input & ((1 << 8) - 1);
	Input >>= 8;
	Byte3 = Input & ((1 << 8) - 1);
	Input >>= 8;
	Byte4 = Input & ((1 << 8) - 1);
	Input >>= 8;
	return (Byte1 << 24) | (Byte2 << 16) | (Byte3 << 8) | (Byte4);
}

CalFloat** Img, ** TestImg;
int* Tag, * TestTag;

unsigned int TestImgFileTypeNumber, TestImgCnt, TestImgWidth, TestImgHeight;
unsigned int TestTagFileTypeNumber, TestTagCnt;

void ReadTestImg()
{
	FILE* fpTestImg, * fpTestTag;
	fpTestImg = fopen("D:\\data\\program\\NumberRecognizer\\NumberRecognizer\\NeuroNetwork\\DataBase\\t10k-images.idx3-ubyte", "rb");
	fread(&TestImgFileTypeNumber, sizeof(TestImgFileTypeNumber), 1, fpTestImg);
	fread(&TestImgCnt, sizeof(TestImgCnt), 1, fpTestImg);
	fread(&TestImgWidth, sizeof(TestImgWidth), 1, fpTestImg);
	fread(&TestImgHeight, sizeof(TestImgHeight), 1, fpTestImg);
	TestImgFileTypeNumber = HighToLow(TestImgFileTypeNumber);
	TestImgCnt = HighToLow(TestImgCnt);
	TestImgWidth = HighToLow(TestImgWidth);
	TestImgHeight = HighToLow(TestImgHeight);
	cout << TestImgFileTypeNumber << " " << TestImgCnt << " " << TestImgWidth << " " << TestImgHeight << "\n";

	fpTestTag = fopen("D:\\data\\program\\NumberRecognizer\\NumberRecognizer\\NeuroNetwork\\DataBase\\t10k-labels.idx1-ubyte", "rb");
	fread(&TestTagFileTypeNumber, sizeof(TestTagFileTypeNumber), 1, fpTestTag);
	fread(&TestTagCnt, sizeof(TestTagCnt), 1, fpTestTag);
	TestTagFileTypeNumber = HighToLow(TestTagFileTypeNumber);
	TestTagCnt = HighToLow(TestTagCnt);
	cout << TestTagFileTypeNumber << " " << TestTagCnt << "\n";

	TestImg = (CalFloat**)malloc(TestImgCnt * sizeof(CalFloat*));//free!
	for (int i = 0; i < TestImgCnt; i++)
	{
		TestImg[i] = (CalFloat*)malloc(TestImgWidth * TestImgHeight * sizeof(CalFloat));
	}
	TestTag = (int*)malloc(TestTagCnt * sizeof(int));

	Mat Image(TestImgHeight, TestImgWidth, CV_8UC3);

	for (int Idx = 0; Idx < TestImgCnt; Idx++)
	{
		if ((Idx + 1) % 10000 == 0) cout << "Reading:" << Idx + 1 << "\n";

		// 遍历图像的每个像素，并赋予不同的颜色值
		for (int y = 0; y < Image.rows; y++)
		{
			for (int x = 0; x < Image.cols; x++)
			{
				Vec3b Color;
				int PixelVal = 0;
				fread(&PixelVal, sizeof(char), 1, fpTestImg);
				TestImg[Idx][y * Image.rows + x] = PixelVal / 255.00;
				/*Color[0] = PixelVal; // 蓝色通道
				Color[1] = PixelVal;   // 绿色通道
				Color[2] = PixelVal;   // 红色通道

				// 将颜色值赋给图像的每个像素
				Image.at<Vec3b>(y, x) = Color;*/
			}
		}

		int CurTestTag = 0;
		fread(&CurTestTag, sizeof(char), 1, fpTestTag);
		TestTag[Idx] = CurTestTag;

		//putText(Image, to_string(CurTestTag), Point(0, 7), FONT_HERSHEY_TRIPLEX, 0.3, (255, 255, 255), 1);
		// 创建一个窗口显示图像
		/*namedWindow(to_string(CurTestTag), WINDOW_NORMAL);
		imshow(to_string(CurTestTag), Image);
		waitKey(0);
		destroyWindow(to_string(CurTestTag));*/
	}


	fclose(fpTestImg);
	fclose(fpTestTag);
}

void ReadImg()
{
	FILE* fpImg, * fpTag;
	fpImg = fopen("D:\\data\\program\\NumberRecognizer\\NumberRecognizer\\NeuroNetwork\\DataBase\\train-images.idx3-ubyte", "rb");
	fread(&ImgFileTypeNumber, sizeof(ImgFileTypeNumber), 1, fpImg);
	fread(&ImgCnt, sizeof(ImgCnt), 1, fpImg);
	fread(&ImgWidth, sizeof(ImgWidth), 1, fpImg);
	fread(&ImgHeight, sizeof(ImgHeight), 1, fpImg);
	ImgFileTypeNumber = HighToLow(ImgFileTypeNumber);
	ImgCnt = HighToLow(ImgCnt);
	ImgWidth = HighToLow(ImgWidth);
	ImgHeight = HighToLow(ImgHeight);
	cout << ImgFileTypeNumber << " " << ImgCnt << " " << ImgWidth << " " << ImgHeight << "\n";

	fpTag = fopen("D:\\data\\program\\NumberRecognizer\\NumberRecognizer\\NeuroNetwork\\DataBase\\train-labels.idx1-ubyte", "rb");
	fread(&TagFileTypeNumber, sizeof(TagFileTypeNumber), 1, fpTag);
	fread(&TagCnt, sizeof(TagCnt), 1, fpTag);
	TagFileTypeNumber = HighToLow(TagFileTypeNumber);
	TagCnt = HighToLow(TagCnt);
	cout << TagFileTypeNumber << " " << TagCnt << "\n";

	Img = (CalFloat**)malloc(ImgCnt * sizeof(CalFloat*));//free!
	for (int i = 0; i < ImgCnt; i++)
	{
		Img[i] = (CalFloat*)malloc(ImgWidth * ImgHeight * sizeof(CalFloat));
	}
	Tag = (int*)malloc(TagCnt * sizeof(int));

	Mat Image(ImgHeight, ImgWidth, CV_8UC3);

	for (int Idx = 0; Idx < ImgCnt; Idx++)
	{
		if ((Idx + 1) % 10000 == 0) cout << "Reading:" << Idx + 1 << "\n";

		// 遍历图像的每个像素，并赋予不同的颜色值
		for (int y = 0; y < Image.rows; y++)
		{
			for (int x = 0; x < Image.cols; x++)
			{
				Vec3b Color;
				int PixelVal = 0;
				fread(&PixelVal, sizeof(char), 1, fpImg);
				Img[Idx][y * Image.rows + x] = PixelVal / 255.00;
				/*Color[0] = PixelVal; // 蓝色通道
				Color[1] = PixelVal;   // 绿色通道
				Color[2] = PixelVal;   // 红色通道

				// 将颜色值赋给图像的每个像素
				Image.at<Vec3b>(y, x) = Color;*/
			}
		}

		int CurTag = 0;
		fread(&CurTag, sizeof(char), 1, fpTag);
		Tag[Idx] = CurTag;

		/*//putText(Image, to_string(CurTag), Point(0, 7), FONT_HERSHEY_TRIPLEX, 0.3, (255, 255, 255), 1);
		// 创建一个窗口显示图像
		namedWindow(to_string(CurTag), WINDOW_NORMAL);
		imshow(to_string(CurTag), Image);
		waitKey(0);
		destroyWindow(to_string(CurTag));*/
	}


	fclose(fpImg);
	fclose(fpTag);
}

#include <iostream>
#include <ctime>
#include <string>

string getCurrentDateTime()
{
	// 获取当前时间
	time_t currentTime = time(nullptr);
	tm* localTime = localtime(&currentTime);

	// 拼接年月日时分秒
	int year = localTime->tm_year + 1900;
	int month = localTime->tm_mon + 1;
	int day = localTime->tm_mday;
	int hour = localTime->tm_hour;
	int minute = localTime->tm_min;
	int second = localTime->tm_sec;

	// 构建时间字符串
	string dateTime = to_string(year)
		+ "_" + to_string(month)
		+ "_" + to_string(day)
		+ "_" + to_string(hour)
		+ "_" + to_string(minute)
		+ "_" + to_string(second);

	return dateTime;
}


int main()
{
	srand(time(NULL));
	vector<int> NeuroNetScale = { 784,16,16,10 };//
	//for (int i = 0; i < a.size(); i++) cout << a[i] << " ";
	NeuroNet NumRecogNet(NeuroNetScale, 1);//0
	//NumRecogNet.ReadFromFile(".\\Net_ACR_0.561200_Round_262600_2023_7_17_18_51_59.txt");//!!!
	NumRecogNet.WriteToFile("Test.txt");
	NeuroNet RWTestNumRecogNet(NeuroNetScale, 0);
	RWTestNumRecogNet.ReadFromFile(".\\Test.txt");
	RWTestNumRecogNet.WriteToFile("Test2.txt");
	ReadImg();
	ReadTestImg();
	int ACCount = 0;
	bool AllSame = true;
	int PredictFirstTag = 0;
	for (int i = 0; i < ImgCnt; i++)
	{
		if ((i + 1) % 5000 == 0)
		{
			cout << "Testing Sample:" << (i + 1) << "\n";
			/*for (int j = 0; j < 784; j++)
			{
				//cout << Img[i][j] << " ";
				if (Img[i][j] == 0) cout << "0 ";
				else cout << "1 ";
				if (j % 28 == 27) cout << "\n";
			}*/
		}
		int PredictTag = NumRecogNet.Run(Img[i], ((i + 1) % 5000 == 0 ? false : false));//
		if (i == 0)
		{
			PredictFirstTag = PredictTag;
		}
		if (PredictTag == Tag[i])
		{
			ACCount++;
		}
		if ((i + 1) % 5000 == 0) cout << "Result:" << PredictTag << " " << Tag[i] << "\n";
		if (PredictTag != PredictFirstTag)
		{
			AllSame = false;
		}
	}
	cout << "AC Rate:" << ACCount / (float)ImgCnt * 100 << "%\n";
	cout << "AllSame:" << AllSame << "\n";

	//Test Sigmoid
	/*for (int i = -100; i <= 100; i += 10)
	{
		cout << "Sigmoid(" << i << ")" << " == " << Sigmoid(i) << "    ";
		cout << "Sigmoid'(" << i << ")" << " == " << SigmoidGrad(i) << "\n";
	}*/

	const int TrainScale = 100000;
	//int TrainRound = TrainScale;
	long long TrainRound = 0;
	int GroupIdx = 0, int GroupNum = 50;
	//NumRecogNet.BPTrain(Img[GroupIdx], Tag + GroupIdx, GroupNum);
	//NumRecogNet.WriteToFile("Test3.txt");
	int BPCnt = 0;
	//int BPTest = 0;
	int BestACCount = 0;
	double LearningRate = 0.05;
	int ACBestRound = 0;
	int TestACCount = 0;
	while (true)//for(int Idx = 0;Idx < 5000;Idx++)
	{
		TrainRound++;
		if (TrainRound % 100 == 0) cout << "TrainRound:" << TrainRound << "  ";
		if (GroupIdx + GroupNum >= ImgCnt)
		{
			GroupIdx = 0;
		}

		//LearningRate = (double)(TrainRound - ACBestRound) / (double)30000.00;
		//LearningRate = LearningRate * LearningRate + 0.0001;
		//LearningRate = 0.00002 * LearningRate + 0.0001;
		double ACRate = TestACCount / (double)(TestImgCnt);
		LearningRate = 0.00002 * (double)(TrainRound - ACBestRound) * 1.00 / ((ACRate + 0.2) * (ACRate + 0.2)) + 0.00001;
		if (TrainRound - ACBestRound > 30000) LearningRate = 0.05;
		if (TrainRound - ACBestRound > 50000)
		{
			ACBestRound = TrainRound;
			BestACCount = TestACCount;
		}
		//0.2 -> 0.05
		NumRecogNet.BPTrain(&RWTestNumRecogNet, Img, Tag, GroupIdx, GroupNum, LearningRate, false);// (BPCnt == 9999 ? true : false), "DebugNet_" + getCurrentDateTime() + ".txt");
		BPCnt++;
		//BPTest++;
		if (BPCnt >= 100)
		{
			BPCnt = 0;
			TestACCount = 0;
			for (int i = 0; i < TestImgCnt; i++)
			{
				int PredictTag = NumRecogNet.Run(TestImg[i], ((i + 1) % 5000 == 0 ? false : false));//
				if (PredictTag == TestTag[i])
				{
					TestACCount++;
				}
			}
			if (((TestACCount - BestACCount) / (double)(TestImgCnt)) > 0.001)
			{
				BestACCount = TestACCount;
				NumRecogNet.WriteToFile("Net_ACR_" + to_string(TestACCount / (float)(TestImgCnt)) + "_Round_" + to_string(TrainRound) + "_" + getCurrentDateTime() + ".txt");
				ACBestRound = TrainRound;
			}
			cout << "ACRate=" << TestACCount / (float)(TestImgCnt) << "     BestACRate=" << BestACCount / (float)(TestImgCnt) << "   LearningRate=" << LearningRate << "\n";
		}
		/*if (BPTest >= 100)
		{
			BPTest = 0;
			int TestACCount = 0;
			for (int i = 0; i < TestImgCnt; i++)
			{
				int PredictTag = NumRecogNet.Run(TestImg[i], ((i + 1) % 5000 == 0 ? false : false));//
				if (PredictTag == TestTag[i])
				{
					TestACCount++;
				}
			}
			cout << "ACRate=" << TestACCount / (float)(TestImgCnt) << "\n";
		}*/
		//Sleep(100);
		GroupIdx++;//?
	}

	free(Img);
	free(Tag);
	return 0;
}