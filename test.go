package main

import (
	"github.com/nsqio/go-nsq"
	"flag"
	"fmt"
	"os/exec"
	"log"
	"os"
)

var nsqProducer *nsq.Producer

func init() {
	var err error

	log.SetOutput(os.Stdout)
	log.SetFlags(log.Lshortfile | log.LstdFlags)

	wcfg := nsq.NewConfig()

	nsqProducer, err = nsq.NewProducer("127.0.0.1:4150", wcfg)
	if err != nil {
		log.Fatalf("failed creating nsq producer: %s \n", err.Error())
	}
	nsqProducer.SetLogger(log.New(os.Stderr, "", log.Flags()), nsq.LogLevelError)
}


// 扫描管理卡IP获取主机硬件配置信息

func main() {

	// 命名行参数解析 -ip 获取浪潮机器的idracIP
	var idracip string
	flag.StringVar(&idracip,"ip","127.0.0.1","idracip")
	flag.Parse()


	// 执行浪潮机器工具获取基本配置信息 -all -cpu -mem - hdd -net
	// （cpu、内存、硬盘、网络）
	cmd := exec.Command("./instool.sh", idracip, "admin ","admin", "-conf", "-all")
	bytes, err := cmd.Output()
	if err != nil {
		fmt.Println("cmd.Output: ", err)
		return
	}
	// 1. 打印在屏幕上
	fmt.Println(string(bytes))

	// 2. 以topic形式发布到nsq，等待消费
	err = sendInfoToNSQ(bytes)
	if err != nil {
		log.Printf("error: %s\n", err.Error())
	}

	// 查看服务器fru
	cmd = exec.Command("./instool.sh", idracip, "admin", "admin", "-fru","list")
        bytes, err = cmd.Output()
        if err != nil {
                fmt.Println("cmd.Output: ", err)
                return
        }
       
        fmt.Println(string(bytes))
        
        err = sendFruToNSQ(bytes)
        if err != nil {
                log.Printf("error: %s\n", err.Error())
        }       

        // 查看服务器mac、ip
        cmd = exec.Command("./instool.sh", idracip, "admin", "admin", "-lan","-ip","-info")
        bytes, err = cmd.Output()
        if err != nil {
                fmt.Println("cmd.Output: ", err)
                return
        }

        fmt.Println(string(bytes))

        err = sendIpToNSQ(bytes)
        if err != nil {
                log.Printf("error: %s\n", err.Error())
        }


	//关闭
	nsqProducer.Stop()
	
}


// 生产基本配置信息到nsq
func sendInfoToNSQ(message []byte) (err error) {
	err = nsqProducer.Ping()
	if err != nil {
		return
	}
	err = nsqProducer.Publish("info", message)
	return
}

// 生产fru信息到nsq
func sendFruToNSQ(message []byte) (err error) {
        err = nsqProducer.Ping()
        if err != nil {
                return
        }
        err = nsqProducer.Publish("fru", message)
        return
}
// 生产ip信息岛nsq
func sendIpToNSQ(message []byte) (err error) {
        err = nsqProducer.Ping()
        if err != nil {
                return
        }
        err = nsqProducer.Publish("ip", message)
        return
}

