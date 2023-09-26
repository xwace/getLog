import paramiko
import datetime
import time
import os
import configparser
import sys
import datefinder

# 机器ip
ipAddr = "10.10.35.73"
# 保存log的路径
DIR = ''
config_parser = configparser.ConfigParser()

class Connection:
    def __int__(self):
         pass

    def connect(self, ip, port, user, pwd):
        self.ip = ip
        self.port = port
        self.user = user
        self.pwd = pwd
        self.sshClient = paramiko.SSHClient()
        self.sshClient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        if pwd != '':
            try:
                self.sshClient.connect(ip, port, user, pwd)
            except:
                print('连接失败，请检查ip是否正确')
                return 0
        else:
            try:
                self.sshClient.connect(ip, port, user, pwd, look_for_keys=False, timeout=5.0)
            except paramiko.ssh_exception.AuthenticationException:
                self.sshClient.get_transport().auth_none(user)
        self.sftp = paramiko.SFTPClient.from_transport(self.sshClient.get_transport())
        return 1


    def try_connect(self, ip, port, user, pwd):
        if self.connect(ip, port, user, pwd):
            return 1
        i = 0
        while 1:
            # 为了让ctrl+c快速响应
            time.sleep(1)
            i += 1
            if i == 10:
                i = 0
                print('正在尝试重连...')
                if self.connect(ip, port, user, pwd):
                    return 1


    def push(self, local_file, remote_file):
        try:
            self.sftp.put(local_file, remote_file)
        except:
            print('push 错误')

    def _timer(start_time, timelimit=2000):
        elapsed_time = time.time() - start_time
        print(time.time())
        if elapsed_time > timelimit:
            raise Connection

    def pull(self, remote_file, local_file):
        try:
            start_time = time.time()
            self.sftp.get(remote_file, local_file, self.percent)#, self._timer(start_time))
            return 1
        except:
            print('pull 错误')
            return 0

    def exe(self, cmd):
        a = self.sshClient.exec_command(cmd, timeout=60000)
        f_in, f_out, f_err = a
        return f_out.read()

    def exists(self, path):
        path_d = '//'.join(path.split('//')[:-1])
        path_b = path.split('//')[-1]
        print('---------')
        print(path_d)
        print(path_b)
        ls = self.exe('ls %s' % path_d).decode().split('\n')
        print(ls)
        if path_b in ls:
            return True
        else:
            return False

    def reconect(self):
        print('reconneting')
        try:
            self.close()
        except:
            pass
        finally:
            self.connect(self.ip, self.port, self.user, self.pwd)

    def close(self):
        self.sshClient.close()
        self.sftp.close()


ssh = Connection()
md5Exist = [""]
length = 0
lenExist = 0
preFileName = ''

class GetLog:
    def __int__(self, s):
        pass

    def zipAndpull(self):
        try:
            res = ssh.exe("rm /home/robot/business/log.zip")
            res = ssh.exe("rm /home/robot/business/zi*")
            res = ssh.exe("rm -rf /home/robot/business/log/AIlog/AI*")
        except:
            return 0
        rstr = res.decode()
        sp = rstr.split()
        print(sp)
        print("正在压缩，请稍后。。。")
        try:
            res = ssh.exe("zip -rP 888888  /home/robot/business/log.zip /home/robot/business/log/")
        except:
            print("压缩失败！")
            return 0
        try:
            res = ssh.exe("zip -rP 888888  /home/robot/business/log.zip /tmp")
        except:
            print("压缩失败！")
            return 0

        print("压缩完成。开始下载。。。")
        if ssh.pull("/home/robot/business/log.zip", DIR + "log.zip") == 0:
            return 0
        print("下载完成！")

    def check_log_file(self):
        try:
            res = ssh.exe("md5sum /home/robot/business/log/log*")
        except:
            return 0
        rstr = res.decode()
        sp = rstr.split()
        global length
        length = len(sp)
        length = int(length / 2)
        global lenExist
        lenExist = len(md5Exist)
        for i in range(length):
            count = i * 2
            if sp[count] not in md5Exist:
                md5Exist.append(sp[count])
                dt_ms = datetime.datetime.now().strftime('%m%d.%H%M%S.%f_')
                log_file_name = sp[count + 1].split('/')[len(sp[count + 1].split('/')) - 1]

                # 仅抓取robot和slam，并过滤掉第一个
                if 'log_slam' in log_file_name or 'log_robot' in log_file_name:
                    if log_file_name == 'log_robot' or log_file_name == 'log_slam' \
                            or log_file_name == 'log_robot_fullpath.88':
                        continue
                    filename = dt_ms + log_file_name
                    if 'log_slam' in log_file_name:
                        rdir = DIR + 'slam//' + filename.replace('log_', '')
                    if 'log_robot' in log_file_name:
                        rdir = DIR + 'robot//' + filename.replace('log_', '')
                    print(sp[count] + rdir)
                    if ssh.pull(sp[count + 1], rdir) == 0:
                        return 0
                    print(log_file_name)
                    self.renameFile(rdir, dt_ms)
        return 1

    def renameFile(self, oldName, dt_ms):
        global preFileName
        with open(oldName, "rb") as f:
            line_f = f.readlines()
            # print(line_f)

            for line in line_f:
                s = str(line, 'utf-8')
                if '<' in s:
                    date_time_list = s.split('<')[1].split(' ')
                    print(date_time_list)
                    date_time = date_time_list[4].replace('-', '') + '.' + date_time_list[5].replace(':', '')[:8] + '_'
                    print(date_time)
                    fileName = oldName.replace(dt_ms, date_time)
                    print(fileName)
                    preFileName = fileName
                    f.close()
                    try:
                        os.rename(oldName, fileName)
                    except:
                        os.remove(oldName)
                    return 1
        preFileName += 'l'
        print('errrrrrr')
        return 0

    def getIp(self):
        config_parser.read(".//config.cfg", encoding='utf-8')  # 读取config.cfg配置文件
        global ipAddr
        global DIR
        print(config_parser.sections())
        ipAddr = config_parser['default']['ip']
        print(ipAddr)
        print(DIR)
        if ipAddr == '':
            return 0
        DIR = './/' + ipAddr + '//'
        return 1

    def creatFile(self):
        isExists = os.path.exists(DIR + 'robot')
        if not isExists:
            os.makedirs(DIR + 'robot')
            print(DIR + 'robot' + ' 创建成功')
        else:
            print(DIR + 'robot' + ' 目录已存在')

    def tarFile(self):
        try:
            res = ssh.exe("tar -czvf - file | openssl des3 -salt -k passw0rd -out /path/to/file.tar.gz")
        except:
            return 0
        rstr = res.decode()

getlog = GetLog()

def pri_file():
    port = 22
    username = "root"
    password = "123"
    i = 0

    global ipAddr
    global DIR
    ipAddr = sys.argv[0].split('\\')[-1].replace('.exe', '')
    ipAddr = ipAddr.replace('.py', '')
    ipAddr = ipAddr.replace('.\\', '')
    # ipAddr = '10.10.35.100'
    DIR = './/' + ipAddr + '//'

    getlog.creatFile()
    print('正在连接机器。。。')
    ssh.try_connect(ipAddr, port, username, password)
    print('机器连接成功。')

    i = 9
    while 1:
        # 为了让ctrl+c快速响应
        print(i)
        i = 1 + i
        if i == 10:
            i = 0
            # if getlog.check_log_file() == 0:
            if getlog.zipAndpull() == 0:
                ssh.try_connect(ipAddr, port, username, password)
            else:
                exit(0)
        time.sleep(1)

def getTime():
    str = './/10.10.35.1//robot//0731.161517.411657_robot.16'
    dt = '0731.161517.411657_'
    getlog.renameFile(str, dt)
    # print(t)

def main():
    pri_file()
    # getTime()
    # print(sys.argv[0].split('\\')[-1])
    os.system('pause')

if __name__ == '__main__':
    main()