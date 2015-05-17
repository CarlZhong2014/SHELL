#!/bin/bash
#
# 介绍
#	这个脚本用于下载RedHat所有产品的所有手册
#
# 版本 3.1
#
# 制作人和时间
#    CarlZhong    2015.5.17
#
######################################################

WEBHOME="https://access.redhat.com/documentation"
Lang="en-US"
#文件类型
TYPE=""
#存放目录
DLD=""
#临时目录
TMPDIR="/tmp/DLTMP/"
#RedHat的产品列表
PDLS="$TMPDIR/productlist"
#某产品所有手册的URL
FLLS="$TMPDIR/filelist"
#某产品的版本列表
PFV="$TMPDIR/version"
LOG="$TMPDIR/logfie"       
PRODUCT=""
VERSION=""

#菜单
echo -n "
    What kind of file type do you want.
    1) pdf
    2) epub
    please enter your choice [1-2]: 
"
read choice
case "$choice" in
  1) TYPE=pdf;;
  2) TYPE=epub;;
  *) echo "Bad choice!!! Program done!!"
     exit 10;;
esac

#设置存放目录
read -p "Where you want to saving download file. : " DLD
if [ -z "$DLD" ]
then
    echo "This item is not been empty!!! Program done!"
    exit 1;
fi

#检查存放目录是否存在
if [ ! -d $DLD ]
then 
    mkdir $DLD
fi
#检查临时目录是否存在
if [ ! -d $TMPDIR ]
then
    mkdir $TMPDIR
fi

#存放目录不存在则退出
if [ ! -d $DLD ]
then
    echo "Couldn't Crate $DLD"
    exit 1
fi

#临时目录不存在则退出
if [ ! -d $TMPDIR ]
then
    echo "Couldn't Create $TMPDIR"
    exit 1
fi

#下载主页
echo "Download $WEBHOME/$Lang/index.html"
wget $WEBHOME/$Lang/index.html -O $TMPDIR/index.html >/dev/null 2>&1
if [ $? -ne 0 ]
then
    echo "Couldn't download $WEBHOME/$Lang/index.html"
    exit 2
fi

#获取RedHat产品列表
sed -n "/  *<li>..*$Lang/ p" $TMPDIR/index.html | sed "s/^  *<..*\/$Lang\/\([^\"][^\"]*\)\/..*>$/\1/g" > $PDLS


for PRODUCT in $(cat $PDLS)
do
    #创建产品目录
    mkdir $DLD/$PRODUCT
    
    #获取该产品的所有手册URL并存入$FLLS 文件中
    wget $WEBHOME/$Lang/$PRODUCT/index.html -O $TMPDIR/index.html > /dev/null 2>&1
    cat $TMPDIR/index.html | grep "/${PRODUCT}..*/$TYPE/" | sed "s/..*\/${PRODUCT}\/\(..*\)\">.*$/\1/g" > $FLLS

    #获取该产品的版本列表
    cat $FLLS | cut -d"/" -f1 | sort -u > $PFV

    #根据版本下载该产品的手册
    for VERSION in $(cat ${PFV})
    do
    	#创建版本目录
	    mkdir $DLD/$PRODUCT/$VERSION

	    #获取该产品当前版本的相关手册列表
	    cat $FLLS | grep "^$VERSION/..*$" > $TMPDIR/verlist

        for PDDL in $(cat $TMPDIR/verlist)
	    do

	    	#处理URL，下载文档
	        file=$(echo $PDDL|sed "s/^$VERSION\/.*\/\(..*\.${TYPE}\)/\1/g")
	        DLLINK=$WEBHOME/$Lang/$PRODUCT/$PDDL
	        DST=$DLD/$PRODUCT/$VERSION/$file
            if [ ! -f $DST ]
	        then
	            echo "Get $DLLINK saving in $DST" >>$LOG
	            wget -c $DLLINK -O $DST >/dev/null  2>&1
	        fi
	        Recho=$?
	        echo "$Recho" >>$LOG
	    done
    done
done

#清理临时文件
rm -fr $TMPDIR
