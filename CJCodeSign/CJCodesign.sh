#!/bin/bash

#######################
# 脚本使用说明：
# 1. 新建文件夹new，将需要重签名的.ipa放到new文件夹下；
# 2. 将该重签名脚本放到new文件夹下；
# 3. 同时安装可签名证书，并将该证书对应的Provision Profile文件重命名为embedded.mobileprovision，也一并放到new文件夹下；
# 4. cd到new路径，执行指令：security cms -D -i embedded.mobileprovision
# 找到 <key>Entitlements</key>，然后把<key>Entitlements</key>下面`<dict>...</dict>的内容拷贝到新建的entitlements.plist文件中，
# （可以通过Xcode生成plist文件，选Property List类型），最后将entitlements.plist文件也放到new文件夹下；
# 5. 如果要注入动态库，将生成的动态库放入到new文件夹；
#
# 6. 执行签名脚本： ./CJCodesign.sh -p xxx.ipa -s SignFramework.framework -i "证书名称"
# 
#######################
# 参数说明：
#     -p <重签名ipa路径>            
#     -s <注入动态库的名称，带.framework>
#     -i <签名证书名称>
#	  -e <Error_Prefix>           默认出错日志前缀

while getopts ":p:s:i:e:" opt
do
	case $opt in
	# 导入包路径
	p)
		App_Path=${OPTARG};
	;;
	# 注入动态库SignFramework的路径
	s)
		Framework_Path=${OPTARG};
	;;
	# 签名证书名称
    i)
        EXPANDED_CODE_SIGN_IDENTITY=${OPTARG};
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

App_Name=${App_Path##*/}
# 获取当前脚本所在的路径
Work_Path=$(cd $(dirname $0); pwd)
Sign_Framework_Path="${Work_Path}/${Framework_Path}";
# 注入动态库名称
Sign_Framework_Name="${Framework_Path%.*}";

# 建立临时文件夹
Temp_Path="${Work_Path}/Temp"
rm -rf "${Temp_Path}"
mkdir -p "${Temp_Path}"


cp -rf "${App_Path}" "${Temp_Path}/${App_Name}"

cd ${Temp_Path}

# 0. 解压IPA到Temp下
unzip -oqq "$Temp_Path/$App_Name" -d "$Temp_Path"
# 拿到解压的临时的APP的路径
Temp_App_Path=$(set -- "$Temp_Path/Payload/"*.app;echo "$1")
echo "Temp_App_Path路径是:$Temp_App_Path"

# 1. 删除extension和WatchAPP.个人证书没法签名Extention
rm -rf "$Temp_App_Path/PlugIns"
rm -rf "$Temp_App_Path/Watch"

# 2. 替换embedded.mobileprovision文件
cp -rf "${Work_Path}/embedded.mobileprovision" "$Temp_App_Path"

# 3. 对MachO文件，上可执行权限
# 拿到MachO文件的路径
App_Binary=`plutil -convert xml1 -o - $Temp_App_Path/Info.plist|grep -A1 Exec|tail -n1|cut -f2 -d\>|cut -f1 -d\<`
# 上可执行权限
chmod +x "$Temp_App_Path/$App_Binary"

# 4. 判断是否添加动态库
if [ -n "$Framework_Path" ]; then 
    # 不存在Frameworks，创建Frameworks文件夹
	if [ ! -d "${Temp_App_Path}/Frameworks" ];then
		mkdir -p "${Temp_App_Path}/Frameworks"
	fi
	Frameworks="${Temp_App_Path}/Frameworks"
	# 复制动态库到Frameworks文件夹
	cp -rf "${Sign_Framework_Path}" "${Frameworks}"
	# 需要注入的动态库的路径
	INJECT_FRAMEWORK_RELATIVE_PATH="Frameworks/${Sign_Framework_Name}.framework/${Sign_Framework_Name}"
	## 通过工具实现注入
	# yololib MachO名称
	yololib "$Temp_App_Path/$App_Binary" "$INJECT_FRAMEWORK_RELATIVE_PATH"

	echo "yololib注入成功"
fi	

echo "${Error_Prefix}************* 签名证书: $EXPANDED_CODE_SIGN_IDENTITY **************"


# 5. 重签名第三方 FrameWorks
TARGET_APP_FRAMEWORKS_PATH="$Temp_App_Path/Frameworks"
if [ -d "$TARGET_APP_FRAMEWORKS_PATH" ];
then
for FRAMEWORK in "$TARGET_APP_FRAMEWORKS_PATH/"*
do

codesign -fs "$EXPANDED_CODE_SIGN_IDENTITY" --no-strict --deep "$FRAMEWORK"
done
fi

# 6. 对APP签名
codesign -f -s "$EXPANDED_CODE_SIGN_IDENTITY" --no-strict --deep --entitlements=${Work_Path}/entitlements.plist "Payload/${App_Binary}.app"

# 7. 生成新的ipa文件
zip -ry ${Work_Path}/new_${App_Name} Payload

# 8. 清理临时数据
rm -rf "${Temp_Path}"

echo "${Error_Prefix}************* 重签完成✅ **************"
