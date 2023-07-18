#include "Interface.h"

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


int main(int argc, char* argv[]) {

    srand(time(NULL));
	std::vector<int> NeuroNetScale = { 784,16,16,10 };
	NeuroNet NumRecogNet(NeuroNetScale, 1);
    NumRecogNet.ReadFromFile(std::string(".\\Net_ACR_0.935200_Round_1052100_2023_7_18_8_14_11.txt"));

    QApplication app(argc, argv);

    MainWindow mainWindow(&NumRecogNet);
    mainWindow.show();

    return app.exec();
}
