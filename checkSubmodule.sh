ROOT_PWD=$( cd "$( dirname $0 )" && cd -P "$( dirname "$SOURCE" )" && pwd )
DOCK_PATH=$ROOT_PWD/src/normal_operation/docking

SUBMOD_ROOT_PATH=$ROOT_PWD/src/public/robotalglbp/core_algorithm
FASTMAP=$SUBMOD_ROOT_PATH/buildMapFast
CLEANAREA=$SUBMOD_ROOT_PATH/clean_area
DOCKING=$SUBMOD_ROOT_PATH/docking
FULLCOVER=$SUBMOD_ROOT_PATH/full_coverage
GYRO=$SUBMOD_ROOT_PATH/gyro
LIDAR=$SUBMOD_ROOT_PATH/lidar
FULLPATH=$SUBMOD_ROOT_PATH/fullpath.tar.gz
submodules=($FASTMAP $CLEANAREA $DOCKING $FULLCOVER $GYRO $LIDAR)
WARNING="Please select the branch and git pull:需更新子模块"
checkCharging=1
isDup=0

FIND_FILE="$ROOT_PWD/src/CMakeLists.txt"
FIND_STR="^\s*set.*normal_operation\/docking\/find_dock"

updateSubmodule(){
    if [[ ! -f $ROOT_PWD/.gitmodules ]];then
        touch $ROOT_PWD/.gitmodules
        line1="[submodule \"src/public/robotalglbp\"]"
        line2="path=src/public/robotalglbp"
        line3='url=git@10.10.3.12:robotalglbp.git'
        echo "$line1">>$ROOT_PWD/.gitmodules
        echo "    $line2">>$ROOT_PWD/.gitmodules
        echo "    $line3">>$ROOT_PWD/.gitmodules
    fi

    if [[ ! -d $SUBMOD_ROOT_PATH ]]; then
        SUB_ROOT_PARENT=$(dirname $SUBMOD_ROOT_PATH)
        rm -rf $SUB_ROOT_PARENT
        mkdir -p $SUBMOD_ROOT_PATH
    fi

    cd $SUBMOD_ROOT_PATH/..
    git submodule init
    git submodule init
    git submodule update
}

pullSubmoduleImpl(){   
    updateSubmodule
    cd $SUBMOD_ROOT_PATH/..
    echo "Pull the submodule from: " $1
    git checkout $1
    git pull
}

pullSubmod() {
    echo -e "\e[33m选择子模块分支: 1.PD_master 2.RZW2X_master 3.PD_develop 4.PD_feature: \e[0m"
    read branch
    if [[ branch -eq 1 ]]; then
        pullSubmoduleImpl "PD_master"
    elif [[ branch -eq 2 ]]; then
        pullSubmoduleImpl "RZW2X_master"
    elif [[ branch -eq 3 ]]; then
        pullSubmoduleImpl "PD_develop"
    elif [[ branch -eq 4 ]]; then
        pullSubmoduleImpl "PD_feature"
    fi
}

checkDuplicatedFiles(){
    for file in `ls -R $SUBMOD_ROOT_PATH`
    do  
        if [[ $file == *.cpp ]]||[[ $file == *.h ]]||[[ $file == *.a ]];then 
            dup_files=($(find $ROOT_PWD/src/public $ROOT_PWD/src/normal_operation -name $file))
            if [[ ${#dup_files[*]} -gt 1 ]];then
                echo -e "\e[1;31m重复文件请删除:${dup_files[@]}\e[0m"
                ((isDup++));
            fi
        fi
    done

    if [[ isDup -gt 1 ]];then
        exit
    fi
}

checkDuplicatedFilesBK(){
    dup_files=$(find $ROOT_PWD/src/public $ROOT_PWD/src/normal_operation -regex ".*\.h\|.*\.cpp\|.*\.a" -type f|\
                awk -F/ 'BEGIN{RS="\n"} {n=$NF} k[n]==1{print p[n]} k[n]{print $0} {p[n]=$0;k[n]++}')

    if [ -n "$dup_files" ];then
        echo -e "\e[31m--- 检测到重复文件或者库: $dup_files 请删除 ---\e[0m"|sed 's/ /\n/g'
        exit
    fi

}

###################################################################################################
#author:wxw date:20231109
#0.更新子模块
#1.检测重复文件
#2.检测子模块文件是否缺失，当缺失时，选择对应的分支编号，可以实现自动拉取更新子模块。
#3.检测回充算法是否使用了子模块 
#4.当回充算法使用了子模块，检测链接子模块的cmakelist编写是否正确。
#5.不使用回充子模块时，设置checkCharging=0
###################################################################################################

pullSubmod
echo -e "\033[32m-- 完成子模块更新!!!!\033[0m"

echo "开始检查子模块是否存在重复文件..."
checkDuplicatedFiles

for i in "${submodules[@]}"; do
    if [[ ! -d $i ]]; then
        echo -e "\e[31m Submodule Missing: $(basename $i) 子模块缺失!!! $WARNING\e[0m"
        exit
    fi
done

if [ ! -f "$FULLPATH" ];then 
    echo -e "\e[31m Submodule Missing: $(basename $FULLPATH) 子模块缺失!!! $WARNING\e[0m"
    exit
fi

if [[ checkCharging -eq 1 ]];then
    if [[ -d "$DOCK_PATH/dock_info" ]]||[[ -d "$DOCK_PATH/exist_map" ]]||[[ -d "$DOCK_PATH/find_dock" ]] \
    ||[[ -d "$DOCK_PATH/guess_dock" ]]||[[ -d "$DOCK_PATH/identify" ]]||[[ -d "$DOCK_PATH/pid_algorithm" ]]; then
        echo -e "\e[31m Old Docking Files Exist: 回充算法正使用老文件!!! 请删除老文件并使用子模块回充算法以及正确修改CMakeList!!!!\e[0m"
        exit
    fi

    if [ -n "$(grep -i $FIND_STR $FIND_FILE)" ];then
        echo -e "\e[31m src/CmakeLists Error:回充源文件没有链接指向子模块!!! \e[0m"
        exit
    fi
fi

# pullSubmod
# echo -e "\033[32m-- 完成子模块更新!!!!\033[0m"

###############
#编译运行
###############

# update git
echo -e "\033[32m-- 更新 robot_app version \033[0m"
git pull

#compile robot.svc
if [ ! -d $ROOT_PWD/build ]; then
  mkdir $ROOT_PWD/build
  cd $ROOT_PWD/build
  echo "mkdir build"
else
  cd $ROOT_PWD/build
  make clean
  rm -rf *
  echo "build exit"
fi

echo "cmake .."
cmake ..

echo "make -j32"
make -j32

#md5sum robot.svc
cd  $ROOT_PWD/out
aarch64-linux-gnu-strip robot.svc
md5sum robot.svc
