# synology-dnspod-ipv6
给群晖原版DDNS添加dnspod的IPV6
文章的出处：https://blog.csdn.net/weixin_43978546/article/details/113222378，版权归作者，我知道转载
7.1 脚本使用方法
根据自身实际情况，修改脚本第2-7行,文件命名为dnspod.sh，然后通过群晖"File Station"上传脚本至/volume2/homes/admin目录下，或者其他目录。
通过ssh工具，ssh到群晖后台系统下，并进入到脚本所在目录，执行如下命令：

sed -i 's/\r//g' dnspod.sh
bash dnspod.sh
1
2
执行结果：

查看脚本有没有执行报错。
如果没有报错，脚本会立即将当前的ipv6地址，同步至腾讯云域名解析界面的“记录值”里面。
如果“记录值”没有修改，或者新增加了一条记录，说明脚本设置错误，返回修改。
————————————————
版权声明：本文为CSDN博主「爬山虎_JL」的原创文章，遵循CC 4.0 BY-SA版权协议，转载请附上原文出处链接及本声明。
原文链接：https://blog.csdn.net/m0_37862262/article/details/128194439
