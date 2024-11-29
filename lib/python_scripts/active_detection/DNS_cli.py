import click
import time
import threading
from scapy.layers.dns import DNS, DNSQR, DNSRR
from scapy.layers.inet import IP, UDP
from scapy.all import sniff, wrpcap, send, get_if_addr,RandShort
from collections import defaultdict
from random import randint

# 用于存储捕获的数据包
captured_packets = []

# DNS统计
dns_statistics = defaultdict(lambda: {"query_name": None, "requests": 0, "responses": 0})

# 用于生成不同的PCAP文件
i = 0

# 用于控制主动探测的时间间隔
probe_interval = 5  # 默认每 5 秒发起一次主动探测

def process_packet(packet):
    """
    处理捕获的DNS数据包，进行实时分析和保存。
    """
    global i
    if packet.haslayer(DNS):
        try:
            dns_layer = packet[DNS]
            ip_layer = packet[IP]
            dns_id = dns_layer.id  # DNS 事务 ID
            query_name = dns_layer.qd.qname.decode() if dns_layer.qd else "UNKNOWN"

            # DNS 查询 (qr=0)
            if dns_layer.qr == 0:
                dns_statistics[dns_id]["query_name"] = query_name
                dns_statistics[dns_id]["requests"] += 1
                print(f"[+] DNS Query: {query_name} from {ip_layer.src} (ID: {dns_id})")

            # DNS 响应 (qr=1)
            elif dns_layer.qr == 1:
                dns_statistics[dns_id]["query_name"] = query_name
                dns_statistics[dns_id]["responses"] += 1
                if dns_layer.an:  # 检查响应是否包含记录
                    print(f"[+] DNS Response for: {query_name} with IP: {dns_layer.an.rdata} (ID: {dns_id})")
                else:
                    print(f"[+] DNS Response for: {query_name} with no answer (ID: {dns_id})")

            # 检测 DNS 欺骗：如果某个请求收到多个响应，则可能存在DNS欺骗
            if dns_statistics[dns_id]["responses"] > 1:
                print(f"[!] Potential DNS Spoofing detected for {query_name} (ID: {dns_id})")
                print(f"    Requests: {dns_statistics[dns_id]['requests']}, Responses: {dns_statistics[dns_id]['responses']}")

            # 保存抓取的数据包
            captured_packets.append(packet)

            # 每抓取一定数量的数据包保存一次
            if len(captured_packets) >= 10:  # 每10个数据包保存一次
                i += 1
                save_packets_to_pcap(i)
        except Exception as e:
            print(f"[!] Error processing packet: {e}")

def save_packets_to_pcap(i):
    """
    将捕获的数据包保存到PCAP文件
    """
    # 设置保存的绝对路径
    save_path = f"D:/code/dns/lib/python_scripts/active_detection/result/captured_dns_packets_{i}.pcap"

    print(f"[*] Saving {len(captured_packets)} packets to pcap file: {save_path}")
    wrpcap(save_path, captured_packets)  # 保存为 PCAP 文件
    captured_packets.clear()  # 清空列表，以便继续捕获新数据包

def send_probe_query(dns_server_ip, probe_domain):
    """
    主动发送DNS查询请求，探测是否有DNS欺骗。
    """
    try:
        # 构造DNS查询数据包
        dns_query = IP(dst=dns_server_ip) / UDP(dport=53, sport=RandShort()) / DNS(rd=1, qd=DNSQR(qname=probe_domain))

        # 发送DNS查询包
        print(f"[*] Sending DNS query for {probe_domain} to {dns_server_ip}")
        send(dns_query)

    except Exception as e:
        print(f"[!] Error sending probe query: {e}")

def start_sniffing(interface):
    """
    开始抓包并进行被动分析
    """
    print(f"[*] Starting DNS sniffing on interface: {interface}")
    sniff(filter="udp port 53", iface=interface, prn=process_packet, store=False)

def start_probing(dns_server_ip, probe_domain, probe_interval):
    """
    启动主动探测，定期发送DNS查询请求
    """
    while True:
        send_probe_query(dns_server_ip, probe_domain)
        time.sleep(probe_interval)

@click.command()
@click.option('--interface', default="WLAN", help="网络接口（例如：Wi-Fi, Ethernet）")
@click.option('--dns-server', default="8.8.8.8", help="目标 DNS 服务器 IP 地址")
@click.option('--probe-domain', default="www.example.com", help="要探测的域名")
@click.option('--probe-interval', default=5, type=int, help="主动探测的间隔时间（秒）")
def main(interface, dns_server, probe_domain, probe_interval):
    """
    启动 DNS 捕获与主动探测
    """
    # 启动两个线程：一个用于抓包，一个用于主动探测
    sniff_thread = threading.Thread(target=start_sniffing, args=(interface,))
    probing_thread = threading.Thread(target=start_probing, args=(dns_server, probe_domain, probe_interval))

    sniff_thread.start()
    probing_thread.start()

    sniff_thread.join()
    probing_thread.join()

if __name__ == '__main__':
    main()
