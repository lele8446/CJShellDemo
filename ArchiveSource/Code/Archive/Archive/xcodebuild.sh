#!/bin/bash

# 参数说明：
#     -p <Project_Path>           项目文件（.xcworkspace 或者 .xcodeproj） 所在路径        
#     -a <Action_Type>			  操作类型：
#										 1、BUNDLE_IDENTIFIER（获取AppId，参数: <-p> <-a> <-e>）
#										 2、BUNDLE_SHORT_VRESION（获取App版本号，参数: <-p> <-a> <-n> <-e>）
#										 3、XCODE_BUILD（Xcode Build，参数: <-p> <-a> <-n> <-e>）
# 										 4、PBXPROJ_CONFING（修改project.pbxproj文件配置，参数: <-p> <-a> <-n> <-s> <-f> <-r> <-d> <-e>）
#										 5、XCODE_ARCHIVE（打包archive，参数: <-p> <-a> <-n> <-c> <-s> <-f> <-o> <-v> <-e>）
#     -n <APP_ID>			      AppID名称
#     -s <Sign_Identity>		  企业证书
#     -f <Profile_Name>	          描述文件
#     -r <Profile_Specifier>	  PROVISIONING_PROFILE_SPECIFIER（证书名）
#     -d <Development_Team>	      PRODUCT_NAME（开发者团队id）
#     -c <Custom_Sign>	          Custom_Sign（自定义签名证书）
#     -o <ExportOptionsPlistPath> ExportOptionsPlist文件地址
#	  -v <APP_Version>            app版本号（示例：3_1_1）
#	  -e <Error_Prefix>           默认出错日志前缀

APP_ID=""
APP_Version=""
Sign_Identity=""
Profile_Name=""
Profile_Specifier=""
Development_Team=""
Custom_Sign="NO"
ExportOptionsPlistPath=""
while getopts ":p:a:n:s:f:r:d:c:o:v:e:" opt
do
	case $opt in
	# 项目路径
	p)
		Project_Path=${OPTARG};
	;;
	# 操作类型：
    # 1、BUNDLE_IDENTIFIER（获取AppId，参数: <-p> <-a> <-e>）
    # 2、BUNDLE_SHORT_VRESION（获取App版本号，参数: <-p> <-a> <-n> <-e>）
    # 3、XCODE_BUILD（Xcode Build，参数: <-p> <-a> <-n> <-e>）
    # 4、PBXPROJ_CONFING（修改project.pbxproj文件配置，参数: <-p> <-a> <-n> <-s> <-f> <-r> <-d> <-e>）
    # 5、XCODE_ARCHIVE（打包archive，参数: <-p> <-a> <-n> <-c> <-s> <-f> <-r> <-o> <-v> <-e>）
	a)
        Action_Type=${OPTARG};
	;;
	# AppID名称
	n)
		APP_ID=${OPTARG};
		echo "APP ID：$APP_ID"
	;;
	# 企业证书
	s)
		Sign_Identity=${OPTARG};
		echo "签名证书：$Sign_Identity"
	;;
	# 描述文件
	f)
		Profile_Name=$OPTARG;
	;;
	# PROVISIONING_PROFILE_SPECIFIER（证书名）
	r)
		Profile_Specifier=$OPTARG;
		echo "描述文件：$Profile_Specifier"
	;;
	# PRODUCT_NAME（开发者团队id）
	d)
		Development_Team=$OPTARG;
	;;
	# Custom_Sign（自定义签名证书）
	c)
		Custom_Sign=$OPTARG;
	;;
	# ExportOptionsPlistPath ExportOptionsPlist文件地址
	o)
		ExportOptionsPlistPath=$OPTARG;
	;;
	# app版本号（示例：3_1_1）
	v)
		APP_Version=$OPTARG;
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

App_Name=`find . -name *.xcodeproj | awk -F "[/.]" '{print $(NF-1)}'`
Scheme_Name="${App_Name}"

Is_Ework="NO"
if [[ ${Scheme_Name} == "Ework" ]]; then
	Is_Ework="YES"
fi

Workspace_Path="${Project_Path}/${App_Name}.xcworkspace"
Xcodeproj_Path="${Project_Path}/${App_Name}.xcodeproj"
# project.pbxproj文件路径
Pbxproj_Path="${Xcodeproj_Path}/project.pbxproj"


# info.plist文件路径
InfoPlist_Path="${Project_Path}/${App_Name}/Info.plist"
if [ ! -e "${InfoPlist_Path}" ];then
	InfoPlist_Path="${Project_Path}/${App_Name}/${App_Name}-Info.plist"
fi

# !!!!! 注意 !!!!!
# Ework特殊处理，写死 "BitAutoCRM"
if [[ ${Is_Ework} == "YES" ]]; then
	InfoPlist_Path="${Project_Path}/BitAutoCRM/Info.plist"
fi

# 加载配置文件ReleaseConfig.plist
Config_Files_Path="${Project_Path}/BitAutoCRM/Config/ReleaseConfig.plist"


# 配置类型
Configuration="Release"
# 归档路径
Output_Path="${Project_Path}/Archiving/${APP_ID}"

# 判断是否为 xcworkspace
Is_Workspace="NO"
for i in `ls`;
do 
	#获取文件后缀名
	extension=${i##*.}
	if [[ ${extension} == "xcworkspace" ]]; then
		Is_Workspace="YES"
		break
	fi
done

# 获取项目的bundle ID
getAppBundleIdentifier(){
	configuration=$(grep -i "PRODUCT_BUNDLE_IDENTIFIER =" ${Pbxproj_Path})
	Array=($(echo $configuration))
	Bundle_Identifier=${Array[5]}
	if [ ! -n $Bundle_Identifier ]
    then
		Bundle_Identifier=${Array[3]}
	fi

	if [ ! -n $Bundle_Identifier ]
    then
		echo "${Error_Prefix}AppId获取出错"
	else
        echo "AppId：${Bundle_Identifier}"
	fi
}

# 获取项目的版本号
getAppVersion(){
	# # 版本号取info.plist信息
	App_Version=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${InfoPlist_Path})


	if [[ ${Is_Ework} == "YES" ]]; then
		if [[ ${APP_ID} == "" ]]
	    then
			echo "${Error_Prefix}错误提示：缺少参数 -n（AppID）"
			exit 1
		fi

		# # Ework 特殊处理，直接读取ReleaseConfig.plist的信息
		# # 获取配置信息
	    # App_Dic=$(/usr/libexec/PlistBuddy -c "Print ${APP_ID}" "${Config_Files_Path}")
	    # # app名
	    # DisplayName=$(/usr/libexec/PlistBuddy -c "Print :${APP_ID}:DisplayName" "${Config_Files_Path}")
	    The_Major_Version_Number=$(/usr/libexec/PlistBuddy -c "Print :${APP_ID}:The_Major_Version_Number" "${Config_Files_Path}")
	    The_Minor_Version_Number=$(/usr/libexec/PlistBuddy -c "Print :${APP_ID}:The_Minor_Version_Number" "${Config_Files_Path}")
	    The_Code_Version_Number=$(/usr/libexec/PlistBuddy -c "Print :${APP_ID}:The_Code_Version_Number" "${Config_Files_Path}")
		App_Version="${The_Major_Version_Number}.${The_Minor_Version_Number}.${The_Code_Version_Number}"
	fi

	
	if [ ! -n $App_Version ]
    then
		echo "${Error_Prefix}App版本号获取出错"
	else
        echo "App版本号：${App_Version}"
	fi
}

# 执行 Xcode Build
startXcodeBuild(){

	if [[ ${APP_ID} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -n（AppID）"
		exit 1
	fi

	mkdir -p "${Output_Path}"
	# 编译日志路径
	Build_Log_path="${Output_Path}/Build_Log_path"

	if [[ ${Is_Workspace} == "YES" ]];then
		#编译workspace
		xcodebuild -workspace "${Workspace_Path}" -scheme "${Scheme_Name}" -configuration "${Configuration}" >> ${Build_Log_path}
	else
		#编译project
		xcodebuild -configuration "${Configuration}" >> ${Build_Log_path}
	fi

	if [ $? = 0 ]; then
		echo "************* xcodebuild 编译 完成 **************"
		echo ''
		rm -rf "${Build_Log_path}"
	else
		echo "${Error_Prefix}************* xcodebuild 编译 失败 **************"
		echo ''
		echo "出错日志路径：${Build_Log_path}"
		open ${Build_Log_path}
		rm -rf "${Build_Log_path}"
	fi
	
}


# 修改project.pbxproj配置
changeConfiguration(){

	key=$1
	value=$2

	# echo "************************ ${key} 修改前 ************************"
    # configuration=$(grep -i -n "$key =" ${Pbxproj_Path})
	# echo "$configuration"
	# Array=($(echo $configuration))
	# Array_length=$(echo ${#Array[@]})
	
	# for (( i = 0; i < ${Array_length}; i++ )); do
	# 		index_num=${Array[$i]}
	# 		echo "index_${i} : $index_num"
	# 	done

	sed -i "" "s/$key =.*$/$key = $value/g" $Pbxproj_Path

	if [ $? = 0 ]; then
		# echo "************************ ${key} 修改后 ************************"
		# configuration=$(grep -i -n "$key =" $Pbxproj_Path)
		# echo "$configuration"
		echo ''
	else
		echo "${Error_Prefix}************************ ${key} 修改出错！！ ************************"
		echo ''
		exit 1;
	fi
}

# 修改 project.pbxproj 文件配置
changePbxprojConfig(){
	# echo "===================== 修改 project.pbxproj 文件配置 ====================="

	if [[ ${Sign_Identity} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -s（企业证书名称）"
		exit 1
	fi

	if [[ ${Profile_Name} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -f（描述文件名称）"
		exit 1
	fi

	if [[ ${Profile_Specifier} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -r（PROVISIONING_PROFILE_SPECIFIER（证书名））"
		exit 1
	fi

	if [[ ${Development_Team} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -d（PRODUCT_NAME（开发者团队id））"
		exit 1
	fi
	

	#修改 PRODUCT_BUNDLE_IDENTIFIER
	changeConfiguration "PRODUCT_BUNDLE_IDENTIFIER" "${APP_ID};"

	#修改 PROVISIONING_PROFILE
	changeConfiguration "PROVISIONING_PROFILE" "\"${Profile_Name}\";"

	#修改 PROVISIONING_PROFILE_SPECIFIER
	changeConfiguration "PROVISIONING_PROFILE_SPECIFIER" "${Profile_Specifier};"

	#修改 PRODUCT_NAME
	changeConfiguration "PRODUCT_NAME" "${Scheme_Name};"

	#修改 "CODE_SIGN_IDENTITY[sdk=iphoneos*]"
	changeConfiguration "\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\"" '"iPhone Distribution";'

	#修改 CODE_SIGN_STYLE
	changeConfiguration "CODE_SIGN_STYLE" "Manual;"

	#修改 ProvisioningStyle
	changeConfiguration "ProvisioningStyle" "Manual;"
	
	#修改 DEVELOPMENT_TEAM
	changeConfiguration "DEVELOPMENT_TEAM" "${Development_Team};"

	#修改 DevelopmentTeam
	changeConfiguration "DevelopmentTeam" "${Development_Team};"


	echo "===================== project.pbxproj 文件配置修改完成 ====================="
}


# 修改app版本号
changeAppVersion(){

	echo ''
	echo "===================== 修改 App版本号 ====================="

	# 把APP_Version字符串根据_分割为数组
	Array=($(echo $APP_Version | tr '_' ' ' | tr -s ' '))
	# 数组长度
	Array_length=$(echo ${#Array[@]})

	if [[ ${Array_length} -ge 3 ]] 
	then
		Main_Num=${Array[0]}
		Min_Num=${Array[1]}
		Code_Num=${Array[2]}
	elif [[ ${Array_length} -ge 2 ]]; 
	then
		Main_Num=${Array[0]}
		Min_Num=${Array[1]}
		Code_Num="0"
	elif [[ ${Array_length} -ge 1 ]]; 
	then
		Main_Num=${Array[0]}
		Min_Num="0"
		Code_Num="0"
	else
	    Main_Num="1"
		Min_Num="0"
		Code_Num="0"
	fi

	Version_String="${Main_Num}.${Min_Num}.${Code_Num}"
	# 获取到版本号之后，修改版本号，这边直接设置version
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${Version_String}"  ${InfoPlist_Path}
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${Version_String}" ${InfoPlist_Path}

		
	if [[ ${Is_Ework} == "YES" ]]; then
		/usr/libexec/PlistBuddy -c "Set :${APP_ID}:The_Major_Version_Number ${Main_Num}" "${Config_Files_Path}"
		/usr/libexec/PlistBuddy -c "Set :${APP_ID}:The_Minor_Version_Number ${Min_Num}" "${Config_Files_Path}"
		/usr/libexec/PlistBuddy -c "Set :${APP_ID}:The_Code_Version_Number ${Code_Num}" "${Config_Files_Path}"
	fi

	if [ $? = 0 ]; then
		echo "************************ App版本号修改为：${Version_String} ************************"
		echo ''
	else
		echo "${Error_Prefix}************************ App版本号 修改出错！！ ************************"
		echo ''
		exit 1;
	fi

	# 开始自定义打包
	xcodebuildArchiveCustom
}

# 自定义打包
xcodebuildArchiveCustom(){

	echo "===================== 开始导出 .xcarchive 文件 ====================="
	# 判断编译的项目类型是workspace还是project
	if [[ ${Is_Workspace} == "YES" ]]; then
		# 编译前清理工程
		xcodebuild clean -configuration "${Configuration}" -alltargets >> ${Log_path}

		# xcodebuild archive -workspace "${Workspace_Path}" -scheme "${Scheme_Name}" -configuration "${Configuration}" -archivePath "${Xcarchive_path}" >> ${Log_path}
		if [[ ${Custom_Sign} == "YES" ]]; then
			xcodebuild archive -workspace "${Workspace_Path}" \
						   -scheme "${Scheme_Name}" \
						   -archivePath "${Xcarchive_path}" \
						   -configuration "${Configuration}" \
						   PROVISIONING_PROFILE="${Profile_Name}" \
						   CODE_SIGN_IDENTITY="${Sign_Identity}" \
						   >> ${Log_path}
	    else
			xcodebuild archive -workspace "${Workspace_Path}" \
						   -scheme "${Scheme_Name}" \
						   -archivePath "${Xcarchive_path}" \
						   -configuration "${Configuration}" \
						   >> ${Log_path}
		fi
		

	else
		# 编译前清理工程
		xcodebuild clean -configuration "${Configuration}" -alltargets >> ${Log_path}

		if [[ ${Custom_Sign} == "YES" ]]; then
			xcodebuild archive -project "${Xcodeproj_Path}" \
			                   -scheme "${Scheme_Name}" \
			                   -archivePath "${Xcarchive_path}" \
	   		                   -configuration "${Configuration}" \
			                   PROVISIONING_PROFILE="${Profile_Name}" \
			                   CODE_SIGN_IDENTITY="${Sign_Identity}"\
			                   >> ${Log_path}
        else
        	xcodebuild archive -project "${Xcodeproj_Path}" \
		                   -scheme "${Scheme_Name}" \
		                   -archivePath "${Xcarchive_path}" \
   		                   -configuration "${Configuration}" \
		                   >> ${Log_path}
        fi

	fi

	# if [ $? = 0 ]; then
	# 	echo "===================== 导出 .xcarchive 文件 完成 ====================="
	# 	echo ''
	# else
	# 	echo "${Error_Prefix}导出 .xcarchive 文件 失败"
	# 	open ${Log_path}
	#   echo "出错日志路径：${Log_path}"
	# 	echo ''
	# 	exit 1;
	# fi

	# 导出ipa文件
	exportIPA
}

# 执行打包
startXcodeArchive(){

	if [[ ${APP_ID} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -n（AppID）"
		exit 1
	fi

	if [[ ${APP_Version} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -v（AppVersion指定版本号）"
		exit 1
	fi

	if [[ ${ExportOptionsPlistPath} == "" ]]
    then
		echo "${Error_Prefix}错误提示：缺少参数 -o（ExportOptionsPlist文件地址）"
		exit 1
	fi

	#不同版本包对应的文件夹
	IPAName="${Scheme_Name}_${APP_Version}"
	# 如果是线上包
	if [[ ${APP_ID} == "com.bitauto.ework" ]]; then
		IPAName="${Scheme_Name}_release_${APP_Version}"
	fi

	Now=$(date +"%Y_%m_%d_%H:%M:%S")
	IPA_Archiving_Path="${Output_Path}/${IPAName}/${Now}"
	mkdir -p "${IPA_Archiving_Path}"
	Log_path="${IPA_Archiving_Path}/LogPath"
	#指定xcarchive文件输出路径
	Xcarchive_path="${IPA_Archiving_Path}/${IPAName}.xcarchive"

	# 修改app版本号
	changeAppVersion

}


# 导出ipa文件
exportIPA(){

	echo "===================== 导出 .xcarchive 文件 成功 ====================="
	echo ''

	# 获取shell脚本所在路径
	# Shell_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

    if [ ! -f ${ExportOptionsPlistPath} ];then
        echo -e "${Error_Prefix}请检查ExportOptions.plist文件权限！\n1、cd到文件所在路径：${ExportOptionsPlistPath}；\n2、执行：chmod 777 ExportOptions.plist"
    fi

    if [[ ${ExportOptionsPlistPath} == "" ]]; then
        echo "${Error_Prefix}文件丢失，请重新选择 ExportOptions.plist 文件配置"
    fi

	provisioningProfiles=$(/usr/libexec/PlistBuddy -c "Print provisioningProfiles" "${ExportOptionsPlistPath}")
	AppProvisioningProfiles=""
	AppProvisioningProfiles=$(/usr/libexec/PlistBuddy -c "Print :provisioningProfiles:${APP_ID}" "${ExportOptionsPlistPath}")
	if [[ ${AppProvisioningProfiles} == "${Profile_Specifier}" ]]; then
		echo ''
	else
	    echo "===================== 添加 ExportOptions.plist 文件配置provisioningProfiles: ${APP_ID}:${Profile_Specifier} ====================="
		/usr/libexec/PlistBuddy -c  "Add :provisioningProfiles:${APP_ID} string ${Profile_Specifier}" ${ExportOptionsPlistPath}

		if [ $? = 0 ]; then
			echo ''
		else
			echo "===================== 修改 ExportOptions.plist 文件配置provisioningProfiles: ${APP_ID}:${Profile_Specifier} ====================="
			/usr/libexec/PlistBuddy -c  "Set :provisioningProfiles:${APP_ID} ${Profile_Specifier}" ${ExportOptionsPlistPath}

			if [ $? = 0 ]; then
				echo ''
			else
				echo "${Error_Prefix}请检查 ExportOptions.plist 文件配置"
				open ${ExportOptionsPlistPath}
				echo ''
				exit 1;
			fi
		fi
	fi

	
	echo "===================== 开始导出 .ipa 文件 ====================="

	#导出ipa包
	xcodebuild -exportArchive -archivePath "${Xcarchive_path}" -exportPath "${IPA_Archiving_Path}" -exportOptionsPlist "${ExportOptionsPlistPath}" >> ${Log_path}

	# 重命名.ipa文件
	if [ $? = 0 ]; then
		cd ${IPA_Archiving_Path}
		ipa_File=""
		ipa_Name="${IPAName}.ipa"
		for i in `ls`;
		do 
			#获取文件后缀名
			extension=${i##*.}
			if [[ ${extension} == "ipa" ]]; then
				ipa_File=${i}
			fi
		done
		if [ ${ipa_File} != "" ]; then
			mv ${ipa_File} ${ipa_Name}
		fi
	else
		echo "${Error_Prefix}重命名ipa包 失败"
		echo ''
		echo "出错日志路径：${Log_path}"
		open ${Log_path}
		exit 1;
	fi

	if [ $? = 0 ]; then
		echo "*********** 导出ipa包 success *************"
		echo ''
	else
		echo "${Error_Prefix}导出ipa包 失败"
		echo ''
		echo "出错日志路径：${Log_path}"
		open ${Log_path}
		exit 1;
	fi

	# 如果是线上包
	if [[ ${APP_ID} == "com.bitone.allApp" ]]; then
		echo "*********** 删除archive *************"
		rm -rf "${Xcarchive_path}"
		if [ $? = 0 ]; then
			echo "*********** 删除archive 文件 success *************"
			echo ''
		else
			echo "*********** 删除archive 文件 failed *************"
			echo ''
			exit 1;
		fi
	fi

	echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "ipa 包路径：${IPA_Archiving_Path}"
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++"
	open ${IPA_Archiving_Path}
	
}



# 获取项目的bundle ID
if [[ ${Action_Type} == "BUNDLE_IDENTIFIER" ]]
then
	getAppBundleIdentifier

# 获取app版本号
elif [[ ${Action_Type} == "BUNDLE_SHORT_VRESION" ]]
then
    getAppVersion

# Xcode Build
elif [[ ${Action_Type} == "XCODE_BUILD" ]]
then
	startXcodeBuild

# 修改project.pbxproj文件配置
elif [[ ${Action_Type} == "PBXPROJ_CONFING" ]]
then
	changePbxprojConfig

# 打包
elif [[ ${Action_Type} == "XCODE_ARCHIVE" ]]
then
    startXcodeArchive

    
# 不能识别的操作类型
else
    echo "${Error_Prefix}不能识别的操作类型: ${Action_Type}"
fi







