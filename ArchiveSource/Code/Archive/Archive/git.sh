#!/bin/bash

# 选项字符串中的第一个字符为冒号(:)，表示抑制错误报告
while getopts ":p:a:e:" opt
do
	case $opt in
	# p 参数值为项目文件所在路径	
	p)
		Project_Path=${OPTARG};
	;;
	# action 参数值为git的操作语句	
	a)
		Git_Action=${OPTARG};
	;;
    # 默认出错日志前缀
    e)
        Error_Prefix=$OPTARG;
    ;;
	# 匹配其他选项
	\?)
		echo "${Error_Prefix}无效参数: -${OPTARG}"
	;;
	esac
done

cd $Project_Path

# git status
# 拉取代码
# git pull origin

git $Git_Action

if [ $? != 0 ]; then
	echo "${Error_Prefix}命令出错：git ${Git_Action}"
	exit 1
fi
