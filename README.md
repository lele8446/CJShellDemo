## CJShellDemo 说明

* ArchiveSource 一键打包程序资源
* CJCrashTools 崩溃Crash查找工具
* CrashScript 线上crash查找脚本
* ReleaseDir Xcode打包脚本

***
### ArchiveSource
##### ArchiveSource一键打包步骤：

1. 进入Source文件夹，启动 Archive 应用程序
2. 选择 .xcodeproj 或 .xcworkspace 文件
3. 修改打包版本号
> 启动Xcode，手动选择签名证书（如果默认签名失败的话）

4. 点击打包


##### ArchiveSource一键打包资源简介：
* Code文件夹下是打包应用程序源代码
* Source文件夹下是打包资源

> Source文件夹：
>> 1. Archive.app（打包应用程序）
>> 2. ExportOptions.plist（导出IPA包配置文件）

##### 打包生成的IPA包路径说明：
../项目所在路径/Archiving/（以AppId命名的文件夹）/（App名+版本号命名的文件夹）/（以打包时间命名的文件夹）

示例：
`../Archiving/(AppI)/(App名)_3_1_29/2018_04_10_11:18:51`

***
### CrashScript

    #--------------------------------------------------------------------------------
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
    
***
### ReleaseDir


	#--------------------------------------------------------------------------------
	# 脚本说明：
	# 1、实现功能：
	#     1）、指定打包项目的Build号，Version版本号（Version号可选择自增或自定义）
	#     2）、导出xcarchive文件
	#     3）、打包生成ipa文件
	# 2、使用方式：
	#     1）、将ReleaseDir文件夹，放到跟所要打包的项目的根目录（TestDemo）同级别的目录下
	#     2）、cd至ReleaseDir，运行脚本./Release.sh TestDemo，并选择输入相关参数，开始打包
	#     3）、完成打包后，生成的目标文件在如下目录：
	#          /ReleaseDir/ArchivePath/TestDemo/1.0.0/2017_03_03_10:37:34
	#         (/ReleaseDir/ArchivePath/打包项目名称/打包版本号/打包时间)
	#--------------------------------------------------------------------------------
	#
	#--------------------------------------------------------------------------------
	# 打包project
	#        ./Release.sh  <Project directory name> [-s <Name>] [-e] [-d] [-a] [-b <Build number>]
	# 打包workspace
	#        ./Release.sh  <Project directory name> [-w] [-s <Name>] [-e] [-d] [-b <Build number>] [-v <Version number>]
	# 参数说明：
	#     <Project directory name>   第一个参数：所要打包的项目的根目录文件夹名称         
	#     -w 		         workspace打包，不传默认为project打包
	#     -s <Name>			 对应workspace下需要编译的scheme（不传默认取xcodeproj根目录文件名）
	#     -e 	        	 打包前是否先编译工程（不传默认不编译）
	#     -d 		         工程的configuration为 Debug 模式，不传默认为Release
	#     -a 	                 打包，Version版本号自动＋1（针对多次打测试包时的版本号修改）
	#     -b <Build Num>             Build版本号，指定项目Build号
	#     -v <Version Num>           Version版本号，指定项目Version号
	#  注意，参数-a 与 -v 互斥，只能选择传其中一种参数！！
	#--------------------------------------------------------------------------------
	#
	#--------------------------------------------------------------------------------
	# ReleaseDir文件目录说明：
	#
	# |___TestDemo                                所要打包的项目的根目录
	# |___ReleaseDir                              打包相关资源的根目录
	#    |___Release.sh                           Release.sh打包脚本
	#    |___ExportOptions.plist                  -exportOptionsPlist 配置文件
	#    |___ArchivePath                          打包文件输出路径
	#       |___TestDemo                          打包项目名称
	#          |___1.0.0                          打包版本号
	#             |___2017_03_02_16/23/28         打包时间（格式：年_月_日_时/分/秒）
	#                |___TestDemo_1.0.0.xcarchive 导出的.xcarchive文件
	#                |___TestDemo.ipa             导出的.ipa文件
	#                |___LogPath                  打包日志
	#
	#--------------------------------------------------------------------------------

