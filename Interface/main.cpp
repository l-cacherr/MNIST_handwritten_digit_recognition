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

//��Χ��int�����
int RandomInt(int minValue, int maxValue)//
{
	if (maxValue - minValue <= 1)
		return minValue;
	return ((rand() + rand() * (RAND_MAX + 1)) % (maxValue - minValue + 1)) + minValue;
}

//��Χ��long long�����
long long RandomLongLong(long long minValue, long long maxValue)//
{
	if (maxValue - minValue <= 1)
		return minValue;
	return (((long long)rand() + (long long)rand() * RANDBASE1 + (long long)rand() * RANDBASE2 + (long long)rand() * RANDBASE3) % (maxValue - minValue + 1)) + minValue;
}

//��Χ��double�����
double RandomDouble(double minValue, double maxValue)//����λ��1e7��Χ�У�С�����ȵ�7λ
{
	const double numscale = 1e7;//�����ţ���ԭ
	return RandomLongLong((long long)(minValue * numscale), (long long)(maxValue * numscale)) / numscale;
}

//��Χ��float�����
float RandomFloat(float minValue, float maxValue)//����λ��1e7��Χ�У�С�����ȵ�7λ
{
	const float numscale = 1e3;//�����ţ���ԭ
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
