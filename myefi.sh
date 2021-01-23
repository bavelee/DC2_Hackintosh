#!/bin/sh
cwd=$(dirname $0)
config=$cwd/OC/config.plist
config4k=$cwd/OC/config_4k.plist
backup_path=~/UUID-Backup
getCode(){
	if test ! -f $backup_path/$1;then
		echo null
		return
	fi
	echo `cat $backup_path/$1`
}

mlb=`getCode MLB`
rom=`getCode ROM`
ssn=`getCode SystemSerialNumber`
uuid=`getCode SystemUUID`

usage(){
echo "
  $0 <make|reset_uuid|clear_uuid|push|rmf(remove_macos_files)> [extra arguments...]
"
}
change_config(){
if test -z $1;then
	echo "less than 1 arguments"
	exit 1
fi
/usr/bin/sed -i "" "s/$1/$2/g" $config
}
xhange_config(){
change_config "$2" "$1"
}
setCode(){
	p=`grep -n "<key>$1</key>" $config|head -n 1|cut -d ':' -f1`
	let p=p+1
	sed -i "" "${p}s#<.*>#$2#" $config
}

reset_uuid(){
setCode MLB "<string>${mlb}</string>"
setCode ROM "<data>${rom}</data>"
setCode SystemSerialNumber "<string>${ssn}</string>"
setCode SystemUUID "<string>${uuid}</string>"
echo "UUID 已恢复"
}
clear_uuid(){
remove_macos_files
setCode MLB "<string>000000000000000000000</string>"
setCode ROM "<data>00000000</data>"
setCode SystemSerialNumber "<string>000000000000</string>"
setCode SystemUUID "<string>00000000-0000-0000-0000-000000000000</string>"
echo "UUID 已清除"
}
enable_4k(){
	echo "为 4K 屏幕设置参数"
	setCode dpcd-max-link-rate "<data>FAAAAA==</data>"
	setCode UIScale "<data>Ag==</data>"
}
disable_4k(){
	echo "为 1080P 屏幕设置参数"
	setCode dpcd-max-link-rate "<data>CgAAAA==</data>"
	setCode UIScale "<data>AQ==</data>"
}
usemy(){
	echo "恢复我的配置文件"
	cp -f $config4k $config
	rm -f $config4k
	enable_4k
	reset_uuid
}
autoconfig(){
	clear_uuid
	cp -f $config $config4k
	echo "已生成 4K屏 配置文件\t: $config4k"
	disable_4k
	echo "已生成 1080P屏 配置文件\t: $config"
}
make(){
if test -z "$1";then
	echo "less than 1 arguments"
	exit 1
fi
autoconfig
cd ..
zip -qr "$1" EFI/BOOT EFI/OC EFI/附加工具 EFI/README.md
cd - >/dev/null
usemy
}
push(){
if test -z "$1";then
	echo "less than 1 arguments"
	exit 1
fi
autoconfig
git add .
git commit -m "$1"
git push -u origin OpenCore
usemy
}
remove_macos_files(){
	find "$cwd/.." -name "._*" -exec rm -rf {} \;
}


if test -z $1;then
	usage
elif [[ "$1"x == "clear_uuid"x ]];then
		clear_uuid
elif [[ "$1"x == "reset_uuid"x ]];then
		reset_uuid
elif [[ "$1"x == "make"x ]];then
		make "$2"
elif [[ "$1"x == "push"x ]];then
		push "$2"
elif [[ "$1"x == "rmf"x ]];then
		remove_macos_files
fi





