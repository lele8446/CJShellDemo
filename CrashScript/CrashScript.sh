#!/bin/bash

#--------------------------------------------
# 脚本说明：
#
# 1、实现功能：
#     1）、查看 .xcarchive 文件的UUID
#     2）、查看10进制的出错地址对应的代码
#
# 2、使用方式：
#     1）、将CrashScript.sh脚本和 .xcarchive 文件放到同一级文件夹下
#     2）、运行脚本：
#            ./CrashScript.sh [-u] [-t <Device type>] -a <Code address> 
#         参数说明：
#                 -u 				         是否查看UUID
#                 -t <Device type>			 发生crash的设备类型，有两种值：32和64，默认64
#                 -a <Code address>	         10进制的出错地址
#--------------------------------------------------------------------------------

# 脚本文件所在根目录
Release_path=$(pwd)
xcarchive_path=""
cd ${Release_path}
Valid_dic=false
for i in `ls`;
do 
	#获取文件后缀名
	extension=${i##*.}
	if [[ ${extension} == "xcarchive" ]]; then
		Valid_dic=true
		xcarchive_path="${Release_path}/${i}"
	fi
done

if [[ ${Valid_dic} == false ]]; then
	echo -e "\033[31mCrashScript.sh脚本所在路径不存在.xcarchive文件，请检查！！\033[0m"
	exit 2
fi

Check_UUID="NO"
Device_type="64"
Have_code_address="NO"
Code_address=""

# 参数处理
param_pattern=":ut:a:"
OPTIND=1
while getopts $param_pattern optname
  do
    case "$optname" in
	  "u")        
		Check_UUID="YES"	
        ;;
      "t")
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  -e "\033[31m选项参数错误 $tmp_optname\033[0m"
			exit 2
		fi
		OPTIND=$tmp_optind
		Device_type=$tmp_optarg
		if [[ ${Device_type} != "32" && ${Device_type} != "64" ]]; then
			echo  -e "\033[31m选项$tmp_optname 参数错误 $Device_type\033[0m"
			exit 2
		fi
        ;;
      "a")        
		tmp_optind=$OPTIND
		tmp_optname=$optname
		tmp_optarg=$OPTARG
		Have_code_address="YES"

		OPTIND=$OPTIND-1
		if getopts $param_pattern optname ;then
			echo  -e "\033[31m选项参数错误 $tmp_optname\033[0m"
			exit 2
		fi
		OPTIND=$tmp_optind
		Code_address=$tmp_optarg
        ;;
      "?")
        echo -e "\033[31m选项错误: $OPTARG\033[0m"
		exit 2
        ;;
      ":")
        echo -e "\033[31m选项 $OPTARG 必须带参数\033[0m"
		exit 2
        ;;
      *)
        echo -e "\033[31m参数错误\033[0m"
		exit 2
        ;;
    esac
  done

dSYMs_path="${xcarchive_path}/dSYMs"
dSYM_file=""
cd ${dSYMs_path}

# if [ ! -d "${dSYMs_path}" ];then
if [ $? != 0 ]; then
	echo -e "\033[31m*************  dSYMs路径不存在  **************\033[0m"
	echo -e "\033[31mdSYMs_path = ${dSYMs_path}\033[0m"
	exit 2
fi

for file in `ls`;
do 
	#获取文件后缀名
	extension=${file##*.}
	if [[ ${extension} == "dSYM" ]]; then
		dSYM_file=${file}
	fi
done

if [[ ${Check_UUID} == "YES" ]]; then
	echo -e "\033[32m*************** 获取  UUID ***************\033[0m"
	echo -e "\033[36mdSYM文件 : ${dSYM_file}\033[0m";
	echo ''
	# 获取UUID
	dwarfdump --uuid ${dSYM_file}
	echo ''

	if [ $? != 0 ]; then
	echo -e "\033[31m*************  获取UUID出错  **************\033[0m"
	exit 2
fi
fi

if [[ ${Have_code_address} == "NO" ]]; then
	echo -e "\033[31m请输入出错的10进制代码地址！！\033[0m"
	exit 2
fi

DWARF_path="${dSYMs_path}/${dSYM_file}/Contents/Resources/DWARF"
echo -e "\033[32m*************** 获取  DWARF ***************\033[0m"
# echo -e "\033[36mDWARF_path : ${DWARF_path}\033[0m";

cd ${DWARF_path}
for file in `ls`;
do
	echo -e "\033[36mDWARF文件 : ${file}\033[0m"

	echo ''
	echo -e "\033[32m*************** 获取出错代码 ***************\033[0m"

	if [[ ${Device_type} == "32" ]]; then
		# 搜索地址＝偏移地址转换为16进制后加0x4000;
		searchAddress="0x"$(echo "ibase=10;obase=16;${Code_address}+16384"|bc);
		xcrun atos -arch armv7 -o ${file} ${searchAddress}
	elif [[ ${Device_type} == "64" ]]; then
		#搜索地址＝偏移地址转换为16进制后，64位系统加100000000
		searchAddress="0x"$(echo "ibase=10;obase=16;${Code_address}+4294967296"|bc);
		xcrun atos -arch arm64 -o ${file} ${searchAddress}
	fi
	
done