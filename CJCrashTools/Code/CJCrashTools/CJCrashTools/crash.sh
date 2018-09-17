#!/bin/bash

#--------------------------------------------
# 参数说明：
#     -p <File_Path>              .dSYM 文件所在路径        
#     -a <Action_Type>			  操作类型：
#										 1、GET_UUID（获取 UUID ，参数: <-p> <-a>）
#										 2、CRASH_ANALYZE（分析错误地址，参数: <-p> <-a> <-t> <-c>）
#  										 3、EXPORT_LOG（导出日志，参数: <-p> <-a> <-l>）
#     -t <CPU_TYPE>			      CPU 类型
#     -c <CRASH_ADDRESS>	      错误信息内存地址
#	  -e <Error_Prefix>           默认出错日志前缀
#--------------------------------------------

# .dSYM 文件所在路径
File_Path=""
# 操作类型：1、GET_UUID（获取 UUID ，参数: <-p> <-a>）；2、CRASH_ANALYZE（分析错误地址，参数: <-p> <-a> <-t> <-d> <-c>）
Action_Type=""
# CPU 类型：arm64，armv7
CPU_TYPE=""
# 默认偏移地址：32位 0x4000（16384）；64位 0x100000000（4294967296）
SLIDE_ADDRESS=""
# 错误信息内存地址
CRASH_ADDRESS=""
# dSYM文件名
dSYM_NAME=""
# 需要导出的日志
LOG_FILE=""

while getopts ":p:a:t:d:c:l:e:" opt
do
	case $opt in
	# 项目路径
	p)
		File_Path=${OPTARG};
	;;
	# 操作类型：
    # 1、GET_UUID（获取 UUID ，参数: <-p> <-a>）
    # 2、CRASH_ANALYZE（分析错误地址，参数: <-p> <-a> <-t> <-d> <-c>）
	a)
        Action_Type=${OPTARG};
	;;
	# CPU 类型
	t)
		CPU_TYPE=${OPTARG};
	;;
	# 默认偏移地址
	d)
		SLIDE_ADDRESS=${OPTARG};
	;;
	# 错误信息内存地址
	c)
		CRASH_ADDRESS=$OPTARG;
	;;
	# log日志
	l)
		LOG_FILE=$OPTARG;
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

DWARF_Path="${File_Path}/Contents/Resources/DWARF"
cd $DWARF_Path


getdSYMUUID(){
	for i in `ls`;
	do 
		# echo "******************** 获取UUID ********************"
		# echo ''
		dSYM_NAME=${i}
		# 获取UUID
		UUID=`dwarfdump --uuid ${dSYM_NAME}`
		echo "${UUID}"
		# echo ''
	done
}

getCrashInfo(){
	echo "******************** 获取出错代码 ********************"
	# 64位默认偏移地址
	if [[ ${CPU_TYPE} == "arm64" ]]
	then
		SLIDE_ADDRESS='4294967296'
	# 32位默认偏移地址
	elif [[ ${CPU_TYPE} == "armv7" ]]
	then
		SLIDE_ADDRESS='16384'
	else
		echo "${Error_Prefix}************************ 获取出错！！ ************************"
		echo ''
		exit 1;
	fi

	for i in `ls`;
	do
		echo  -e "******************** 下面是xcrun atos查找 ********************"
		dSYM_NAME=${i}
		# 搜索地址＝偏移地址32位：转换为16进制后加0x4000; 64位：加0x100000000
		searchAddress="0x"$(echo "ibase=10;obase=16;${CRASH_ADDRESS}+${SLIDE_ADDRESS}"|bc);
		crash_Info=`xcrun atos -arch ${CPU_TYPE} -o ${dSYM_NAME} ${searchAddress}`
		echo "${crash_Info}"
	done

		echo ''
		echo ''
		echo ''
		echo  -e "******************** 下面是dwarfdump查找 ********************"
		cd $File_Path
		dSYM_File=`basename ${File_Path}`
		cd ..
		echo "${dSYM_File}"
		crash_Info=`dwarfdump --lookup ${searchAddress} ${dSYM_File}`
		echo "${crash_Info}"
}

exportLogFile(){
	cd $File_Path
	cd ..
	Current_Path=`pwd`
	Now=$(date +"%Y_%m_%d_%H:%M:%S")
	Log_path="${Current_Path}/LogFile_${Now}"
	echo "${LOG_FILE}" >> ${Log_path}
	open ${Log_path}
}

# 获取 UUID
if [[ ${Action_Type} == "GET_UUID" ]]
then
	getdSYMUUID

# 获取出错信息
elif [[ ${Action_Type} == "CRASH_ANALYZE" ]]
then
    getCrashInfo

# 导出日志
elif [[ ${Action_Type} == "EXPORT_LOG" ]]
then
    exportLogFile

    
# 不能识别的操作类型
else
    echo "${Error_Prefix}不能识别的操作类型: ${Action_Type}"
fi




