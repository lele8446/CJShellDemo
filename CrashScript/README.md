# CrashScript

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
