#重签名脚步说明



1. 新建文件夹new，将需要重签名的.ipa放到new文件夹下；

2. 将该重签名脚本放到new文件夹下；

3. 同时安装可签名证书，并将该证书对应的Provision Profile文件重命名为embedded.mobileprovision，也一并放到new文件夹下；

4. cd到new路径，执行指令：`security cms -D -i embedded.mobileprovision`

   找到 <key>Entitlements</key>，然后把<key>Entitlements</key>下面`<dict>...</dict>的内容拷贝到新建的entitlements.plist文件中，（可以通过Xcode生成plist文件，选Property List类型），最后将entitlements.plist文件也放到new文件夹下；

5. 如果要注入动态库，将生成的动态库放入到new文件夹；

6. 执行签名脚本：

   ```
   ./CJCodesign.sh -p xxx.ipa -s SignFramework.framework -i "证书名称"
   ```

7. 参数说明：

   ```
   -p <重签名ipa路径>            
   
   -s <注入动态库的名称，带.framework>
   
   -i <签名证书名称>
   ```



更多见：https://mp.weixin.qq.com/s/zCaHftxdoM-R9L_0oO2ahw

**3. ipa包重签名** 部分

