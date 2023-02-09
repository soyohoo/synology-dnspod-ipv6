#!/usr/bin/bash    
dnspod_ddnsipv6_id="API_KEY_ID" #【API_id】将引号内容修改为获取的API的ID
dnspod_ddnsipv6_token="API_KEY_TOKEN" #【API_token】将引号内容修改为获取的API的token
dnspod_ddnsipv6_ttl="600" # 【ttl时间】解析记录在 DNS 服务器缓存的生存时间，默认600(s/秒)
dnspod_ddnsipv6_domain='替换自己所购买的域名' #【已注册域名】引号里改成自己注册的域名
dnspod_ddnsipv6_subdomain='替换为想要的名字' #【二级域名】将引号内容修改为自己想要的名字，需要符合域名规范，附常用的规范
local_net="eth0" # 【网络适配器】 默认为eth0，如果你的公网ipv6地址不在eth0上，需要修改为对应的网络适配器
# 常用的规范【二级域名】
# 【www】 常见主机记录，将域名解析为 www.test.com
# 【@】   直接解析主域名 test.com
# 【*】   泛解析，匹配其他所有域名 *.test.com

# 举例
# 在腾讯云注册域名，登陆DNSPOD，在【我的账号】的【账号中心】中，有【密钥管理】
# 点击创建密钥即可创建一个API
# 如果你在腾讯云注册域名叫【test.com】
# 那么【dnspod_ddnsipv6_domain】后面就填【test.com】
# 然后根据常用的规范/自己想要的名字在【dnspod_ddnsipv6_subdomain】填入自己需要的名字
# 现假设为【file】，那么在【dnspod_ddnsipv6_subdomain】填入:"file",你的访问地址为【file.test.com】
if [ "$dnspod_ddnsipv6_record" = "@" ]
then
  dnspod_ddnsipv6_name=$dnspod_ddnsipv6_domain
else
  dnspod_ddnsipv6_name=$dnspod_ddnsipv6_subdomain.$dnspod_ddnsipv6_domain
fi

die () {
    echo "Error: unable to find [public IPv6 address], please use the 'ip addr' command or query the network panel of the system to check the network card, and fill in the name of the network card with the IPv6 address in the 'local_net' position in the command file." >&2
    echo "IP地址提取错误: 在指定的网络适配器上[$local_net]找不到<公网IPv6地址>（不是fe80开头），请使用'ip addr'命令或在系统的网络面板查询有公网IP的网络适配器，然后在脚本的[local_net]中用填写网络适配器的名称。" >&2
    exit
}

ipv6_list=`ip addr show $local_net | grep "inet6.*global" | awk '{print $2}' | awk -F"/" '{print $1}'` || die

for ipv6 in ${ipv6_list[@]}
do
    if [[ "$ipv6" =~ ^fe80.* ]]
    then
        continue
    else
        echo select IP: $ipv6 >&1
        break
    fi
done

if [ "$ipv6" == "" ] || [[ "$ipv6" =~ ^fe80.* ]]
then
    die
fi

dns_server_info=`nslookup -query=AAAA $dnspod_ddnsipv6_name 2>&1`

dns_server_ipv6=`echo "$dns_server_info" | grep 'address ' | awk '{print $NF}'`
if [ "$dns_server_ipv6" = "" ]
then
    dns_server_ipv6=`echo "$dns_server_info" | grep 'Address: ' | awk '{print $NF}'`
fi
    
if [ "$?" -eq "0" ]
then
    echo "DNS server IP: $dns_server_ipv6" >&1

    if [ "$ipv6" = "$dns_server_ipv6" ]
    then
        echo "The address is the same as the DNS server." >&1
    fi
    unset dnspod_ddnsipv6_record_id
else
    dnspod_ddnsipv6_record_id="1"   
fi

send_request() {
    local type="$1"
    local data="login_token=$dnspod_ddnsipv6_id,$dnspod_ddnsipv6_token&domain=$dnspod_ddnsipv6_domain&sub_domain=$dnspod_ddnsipv6_subdomain$2"
    return_info=`curl -X POST "https://dnsapi.cn/$type" -d "$data" 2> /dev/null`
}

query_recordid() {
    send_request "Record.List" ""
}

update_record() {
    send_request "Record.Modify" "&record_type=AAAA&record_line=默认&ttl=$dnspod_ddnsipv6_ttl&value=$ipv6&record_id=$dnspod_ddnsipv6_record_id"
}

add_record() {
    send_request "Record.Create" "&record_type=AAAA&record_line=默认&ttl=$dnspod_ddnsipv6_ttl&value=$ipv6"
}

if [ "$dnspod_ddnsipv6_record_id" = "" ]
then
    echo "seem exists, try update." >&1
    query_recordid
    code=`echo $return_info  | awk -F \"code\":\" '{print $2}' | awk -F \",\"message\" '{print $1}'`
    echo "return code $code" >&1
    if [ "$code" = "1" ]
    then
        dnspod_ddnsipv6_record_id=`echo $return_info | awk -F \"records\":.{\"id\":\" '{print $2}' | awk -F \",\"ttl\" '{print $1}'`
        update_record
        echo "update sucessful" >&1
    else
        echo "error code return, domain not exists, try add." >&1
        add_record
        echo "add sucessful." >&1
    fi
else
    echo "domain not exists, try add."
    add_record
    echo "add sucessful" >&1
fi

