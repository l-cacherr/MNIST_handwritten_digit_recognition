#include <iostream>
#include <string>
#include <vector>
#include <regex>
#include "dirent.h"
#include <utility>
#include "gnuplot-iostream.h"

using namespace gnuplotio;

bool compareFirstElement(const std::pair<long long, double>& pair1, const std::pair<long long, double>& pair2) {
    return pair1.first < pair2.first;
}

int main() {
    std::string directory = ".\\Files"; // 指定目录路径
    std::vector<std::string> txtFiles; // 用于存储txt文件名的向量

    DIR* dir;
    struct dirent* entry;

    if ((dir = opendir(directory.c_str())) != nullptr) {
        while ((entry = readdir(dir)) != nullptr) {
            std::string filename = entry->d_name;
            if (filename.length() >= 4 && filename.substr(filename.length() - 4) == ".txt") {
                txtFiles.push_back(filename);
            }
        }
        closedir(dir);
    }
    else {
        std::cout << "无法打开目录" << std::endl;
        return 1;
    }

    std::vector<std::string> arr = txtFiles;

    // 打印输出txt文件名
    /*for (const auto& file : txtFiles) {
        std::cout << file << std::endl;
    }*/

    std::vector<std::string> strArray = txtFiles;

    std::vector<std::string> filteredArray;
    std::vector<std::pair<long long, double>> extractedData;

    std::regex pattern("^Net_ACR_([0-9]+\\.[0-9]+)_Round_([0-9]+)_.*$");

    for (const std::string& str : strArray) {
        if (std::regex_match(str, pattern)) {
            filteredArray.push_back(str);

            std::smatch match;
            if (std::regex_search(str, match, pattern) && match.size() > 2) {
                double floatValue = std::stod(match[1].str());
                long long intValue = std::stoll(match[2].str());
                extractedData.push_back(std::make_pair(intValue, floatValue));
            }
        }
    }

    /*std::cout << "Filtered Array:" << std::endl;
    for (const std::string& str : filteredArray) {
        std::cout << str << std::endl;
    }

    std::cout << "Extracted Data:" << std::endl;
    for (const auto& data : extractedData) {
        std::cout << "Pair: (" << data.first << ", " << data.second << ")" << std::endl;
    }*/

    std::sort(extractedData.begin(), extractedData.end(), compareFirstElement);

    /*std::cout << "Extracted Data:" << std::endl;
    for (const auto& data : extractedData) {
        std::cout << "Pair: (" << data.first << ", " << data.second << ")" << std::endl;
    }*/

    std::vector<std::pair<double, double>> data(extractedData.size());

    for (int i = 0; i < data.size(); i++)
    {
        data[i].first = extractedData[i].first;
        data[i].second = extractedData[i].second;
        //std::cout << "Pair: (" << data[i].first << ", " << data[i].second << ")" << std::endl;
    }



    // 创建一个gnuplot对象
    Gnuplot gp;

    // 设置输出文件的格式
    gp << "set terminal png\n";

    // 设置输出文件的名称和大小
    gp << "set output 'line_plot.png'\n";
    gp << "set size ratio " << (std::to_string(data[data.size()].first / data[data.size()].second)) << "\n";
    //gp << "set size ratio -1\n";

    // 设置横坐标和纵坐标的范围
    gp << "set xrange [" << data.front().first << ":" << data.back().first << "]\n";
    gp << "set yrange [" << data.front().second << ":" << data.back().second << "]\n";
    
    // 绘制折线图
    gp << "plot '-' with linespoints title 'Data'\n";
    gp.send1d(data);
    return 0;
}
