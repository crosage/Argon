import os
import argparse
from scapy.layers.dns import DNS, DNSQR
from scapy.layers.inet import IP
from scapy.all import sniff, wrpcap
from collections import defaultdict

# 用于存储捕获的数据包
captured_packets = []

# DNS统计
dns_statistics = defaultdict(lambda: {"query_name": None, "requests": 0, "responses": 0})

# 用于生成不同的PCAP文件
i = 0

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

            # 检测 DNS 欺骗：如果某个请求收到多个响应,则可能存在DNS欺骗
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
    print(f"[*] Saving {len(captured_packets)} packets to pcap file.")
    # 将捕获的数据包保存到指定路径的 PCAP 文件
    if args.output_folder:
        pcap_file = os.path.join(args.output_folder, f"captured_dns_packets_{i}.pcap")
    else:
        pcap_file = f"captured_dns_packets_{i}.pcap"
    wrpcap(pcap_file, captured_packets)  # 保存为 PCAP 文件
    captured_packets.clear()  # 清空列表，以便继续捕获新数据包

def start_sniffing(interface):
    """
    开始抓包并进行被动分析
    """
    print(f"[*] Starting DNS sniffing on interface: {interface}")
    sniff(filter="udp port 53", iface=interface, prn=process_packet, store=False)

def parse_args():
    """
    解析命令行参数
    """
    parser = argparse.ArgumentParser(description="DNS Sniffer and Analyzer")
    parser.add_argument("interface", help="Network interface to sniff on")
    parser.add_argument("-o", "--output-folder", help="Folder to save PCAP files", default=None)
    return parser.parse_args()

if __name__ == "__main__":
    # 解析命令行参数
    args = parse_args()

    # 启动抓包
    start_sniffing(args.interface)
