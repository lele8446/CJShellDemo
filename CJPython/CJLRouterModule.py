#!/usr/bin/python
# coding=utf-8

##################################
# CJLRouterModule.py 路由业务组件模板快速创建脚本
#
# 使用方式：./CJLRouterModule.py ModuleName（ModuleName为新建组件名称）
#
##################################

import sys
import os
import os.path
import re
import io
import fileinput
import urllib
import zipfile
import shutil

# github 模板
# templateUrl = "https://github.com/lele8446/CJTemplate.git"
# templateUrl = "https://github.com/lele8446/CJTemplate/archive/refs/heads/main.zip"

# coding 模板
# templateUrl = "https://e.coding.net/lele8446/cjtemplate/CJTemplate.git"
templateUrl = "https://lele8446.coding.net/p/cjtemplate/d/CJTemplate/git/archive/master/?download=true"

if len(sys.argv) >= 2:
    newName = sys.argv[1]
else:
    print("！！！参数缺失！请输入新的业务组件名称！！！")
    sys.exit(1)

# newName = sys.argv[1]
oldName = "CJTemplate"
# 获取当前脚步所在路径
scriptPath = os.getcwd()
# 判断是否已经存在旧的同名业务组件
oldFilePath = os.path.join(scriptPath,newName)
if os.path.isdir(oldFilePath):
	shutil.rmtree(oldFilePath)


def schedule(blocknum,blocksize,totalsize):
    """
    blocknum:当前已经下载的块
    blocksize:每次传输的块大小
    totalsize:网页文件总大小
    """
    per=100.0*(blocknum*blocksize)/totalsize
    if per>100:
        per=100
    print("download : %.2f%%" %(per))
    if per >= 100.0:
    	print '+++++++++ Download Successful +++++++++'


def downloadTemplate():
	"""
	下载业务组件模板
	"""

	templateTempDir = "TemplateTemp"
	# 新建TemplateTemp文件夹
	os.mkdir(templateTempDir)
	# 修改工作路径为TemplateTemp
	templateTempPath = os.path.join(scriptPath,templateTempDir)
	os.chdir(templateTempPath)

	# 下载模板文件为CJTemplate.zip
	# print "\n"
	print "Start Downloading"
	print "+++++++++ Downloading CJTemplate +++++++++"
	urllib.urlretrieve(templateUrl,"CJTemplate.zip",schedule)

	# 解压到TemplateTemp路径下的Temp文件夹
	with zipfile.ZipFile('CJTemplate.zip', "r") as zzz:
		zzz.extractall('Temp')

	# 修改工作路径为 TemplateTemp/Temp
	tempPath = os.path.join(templateTempPath,'Temp')
	os.chdir(tempPath)
	currentTempPath = os.getcwd()

	fileList = os.listdir(currentTempPath)
	for fileName in fileList:
		curFilePath = os.path.join(currentTempPath,fileName)
		resultTempPath = os.path.join(currentTempPath,oldName)
		if os.path.isdir(curFilePath):
			os.rename(curFilePath, resultTempPath)
		  	shutil.move(resultTempPath,scriptPath)
		  	break

	# 修改工作路径为脚本所在路径： scriptPath
	os.chdir(scriptPath)
	# 删除TemplateTemp文件夹
	shutil.rmtree(templateTempDir)


def alterText(filePath,oldStr,newStr):
	"""
	替换文件中的字符串
	:param file:文件名
	:param oldStr:旧字符串
	:param newStr:新字符串
	"""
	# 需要修改的文件类型
	needAlterFiles = (".h",".m",".podspec",".json",".storyboard",".plist","Podfile",".pch",".markdown",".lock",)
	# 需要修改的文件名称
	needAlterNames = ("Podfile")
	# print("当前文件路径" + filePath)

	file = os.path.basename(filePath)
	fileSuffix = os.path.splitext(file)[-1]
	fileName = os.path.splitext(file)[0]
	# print("当前文件名" + fileName)
	if (fileSuffix in needAlterFiles) or (fileName in needAlterNames):
		for line in fileinput.input(filePath, backup='',inplace=True):
			print(line.rstrip().replace(oldStr,newStr))
			# line = line.replace(oldStr,newStr)
			# print line
	fileinput.close()

  
def renameFile(dicPath, fileNewName, fileOldName):
	"""
	递归修改文件以及自文件名称
	"""
	fileList = os.listdir(dicPath)
	for fileName in fileList:

		# CJDemo 文件夹不修改
		if "CJDemo" in fileName:
			continue

		curFilePath = os.path.join(dicPath,fileName)
		if os.path.isdir(curFilePath):
		  	renameFile(curFilePath, fileNewName, fileOldName)
		  	curFileNewPath = os.path.join(dicPath, fileName.replace(oldName,newName))
			os.rename(curFilePath, curFileNewPath)
		elif os.path.isfile(curFilePath):
			curFileNewPath = os.path.join(dicPath, fileName.replace(oldName,newName))
			os.rename(curFilePath, curFileNewPath)
			# 修改文件内容
			alterText(curFileNewPath, oldName, newName)


# 下载模板
downloadTemplate()

# 开始重命名
# print "\n"
print "Start Rename"
renameFile(scriptPath, newName, oldName)
print "+++++++++ Rename Successful +++++++++"
