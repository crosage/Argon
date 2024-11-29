import requests
from bs4 import BeautifulSoup
from scapy.all import *
from collections import defaultdict
from scapy.layers.dns import DNS
import os.path
import pickle
import sys


def ai_zhan_reverse_dns(ip):
    """
    :param ip: IP地址
    """
    ai_zhan_url = 'https://dns.aizhan.com/'
    header = {
        'host': 'dns.aizhan.com',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-encoding': 'gzip, deflate, br, zstd',
        'accept-language': 'zh-CN,zh;q=0.9,ja;q=0.8',
        'cookie': 'PHPSESSID=5381vfe4c2eg5jklm54s24rgi7; _csrf=3ece87ae7a1b625307e15a4b40f16302c6a08471c996cd12725fef7005b71e18a%3A2%3A%7Bi%3A0%3Bs%3A5%3A%22_csrf%22%3Bi%3A1%3Bs%3A32%3A%22JDOLfdDc39qJPAZWUMCfjAs_N9tiDOwi%22%3B%7D; b-user-id=522754d1-6cbd-30e7-ce70-846c53f8f609; _c_WBKFRo=n0HcFkMYqqlOeZe2pxS6n2LCkwtDuCHBwRSNpQiN; _nb_ioWEgULi=; Hm_lvt_b37205f3f69d03924c5447d020c09192=1732324456; HMACCOUNT=40E3626E8061118B; userId=1521144; userName=qiyue_y%40163.com; userGroup=1; userSecure=HGhSQPdPpM3duZBLWOZvdb%2FyKfKinntIB1%2BTKVmEM4kIeVBxsXBDLuo10sRAUmHasK10W5oZahBkgri46852TiBs5I7gH7mpQPIJBhlGicj6PLQ6QcLUzIlxoXdcT16b6K9oSCXUC%2BQ%3D; allSites=hsck123.com%2C0; Hm_lpvt_b37205f3f69d03924c5447d020c09192=1732324825'
    }
    url = ai_zhan_url + ip + '/'
    response = requests.get(url=url, headers=header)

    if response.status_code == 200:
        text = response.text
        # address = re.findall(r'<strong>(.*?)</strong>', text)
        number = re.findall(r'<span class="red">(\d*?)</span>', text)
        domains = re.findall(r'rel="nofollow" target="_blank">([^-]+?)</a>', text)
        page_number = -(-int(number[0]) // 20)
        for i in range(2, page_number + 1):
            url = ai_zhan_url + ip + '/' + str(i) + '/'
            response = requests.get(url=url, headers=header)
            text = response.text
            domains += re.findall(r'rel="nofollow" target="_blank">(.*?)</a>', text)
        # print(address[0])
        # print(domains)
        # print(len(domains))
        # print(number)
        return domains
    else:
        return []


def ip138_reverse_dns(ip):
    """
    :param ip: IP地址
    """
    url = 'https://site.ip138.com/' + ip + '/'
    header = {
        'host': 'site.ip138.com',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-encoding': 'gzip, deflate, br, zstd',
        'accept-language': 'zh-CN,zh;q=0.9,ja;q=0.8',
        'cookie': 'b-user-id=9d5807d2-7d58-ff25-fcfe-2eb9a4fab976; Hm_lvt_aac43b0aec3a1123494f170e0aec4778=1732328578; HMACCOUNT=40E3626E8061118B; Hm_lpvt_aac43b0aec3a1123494f170e0aec4778=1732329893'
    }
    response = requests.get(url, headers=header)
    # <a href="/www.best48.com/" target="_blank">www.best48.com</a>
    if response.status_code == 200:
        text = response.text
        # address = re.findall(r'<h3>(.*?)</h3>', text)
        # print(address[0])
        soup = BeautifulSoup(text, 'html.parser')
        div = soup.find('div', class_='result result2')
        domains = []
        if div:
            domains = re.findall(r'"/(.*\D+?)/" target="_blank">\1</a>', str(div))
        # print(len(domains))
        return domains
    else:
        return []


def reverse_dns(ip: str):
    """
    :param ip: IP地址
    """
    if not ipv4_pattern.match(ip) and not ipv6_pattern.match(ip):
        raise ValueError('Invalid IP address')
    if ipv6_pattern.match(ip):
        raise ValueError('IPv6 address is not supported')
    domains1 = ai_zhan_reverse_dns(ip)
    domains2 = ip138_reverse_dns(ip)
    domains = domains1 + domains2
    return list(set(domains))


def process_pcap(file_name):
    # 读取 pcap 文件
    packets = rdpcap(file_name)
    # 存储查询和响应的字典
    queries = defaultdict(list)
    responses = defaultdict(list)

    for packet in packets:
        if packet.haslayer(DNS):
            # 获取 DNS 层
            dns_layer = packet[DNS]

            # 处理 DNS 查询
            if dns_layer.qr == 0:  # qr=0 表示这是一个查询
                query_name = dns_layer.qd.qname.decode('utf-8').rstrip('.')
                query_id = dns_layer.id
                if queries.get(query_id) is None:
                    queries[query_id].append(query_name)

            # 处理 DNS 响应
            elif dns_layer.qr == 1:  # qr=1 表示这是一个响应
                responses_name = dns_layer.qd.qname.decode('utf-8').rstrip('.')
                for i in range(dns_layer.ancount):
                    rrname = dns_layer.an[i].rrname.decode('utf-8').rstrip('.')
                    rdata = dns_layer.an[i].rdata
                    rid = dns_layer.id
                    if isinstance(rdata, bytes):
                        rdata = rdata.decode('utf-8').rstrip('.')
                    responses[(responses_name, rid)].append((rrname, rdata))
    # 匹配查询和响应
    matched_records = {}
    for query_id, query_list in queries.items():
        query_name = query_list[0]
        if responses.get((query_name, query_id)):
            response_list = responses[(query_name, query_id)]
            for response in response_list:
                if matched_records.get(response[1]) != response[0]:
                    matched_records[response[1]] = response[0]

    return matched_records


# 测试函数，查看提取的域名和 IP 地址是否正确
# def test():
#     for i in range(1, 12):
#         file_name = f'captured_dns_packets_{i}.pcap'
#         matched_records = process_pcap(file_name)
#         for ip, domain in matched_records.items():
#             if domain_ip_table.get(domain) is None:
#                 domain_ip_table[domain] = list((ip,))
#             else:
#                 domain_ip_table[domain].append(ip)
#         show_domain_ip_table()
#         with open("data.pkl", "wb") as f:
#             pickle.dump(domain_ip_table, f)

ipv4_pattern = re.compile(r'^(\d{1,3}\.){3}\d{1,3}$')
ipv6_pattern = re.compile(
    r'^(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,7}:$|^(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|^(?:[0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|^(?:[0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|^(?:[0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}$|^(?:[0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}$|^[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{1,4}){1,6}$|^::([0-9a-fA-F]{1,4}:){1,7}$')


class CrossValidation:
    """
    交叉验证模块
    将Pcap文件中的域名和IP地址进行提取并验证，初始化会有一个pkl文件，其中保存了已经验证通过的域名和IP地址
    如果没有pkl文件，可以使用Init.py中的代码生成一个空的pkl文件
    验证通过的域名和IP地址保存在security.pkl中
    未通过验证的域名和IP地址保存在skeptical.pkl中
    CNAME记录保存在cname.pkl中
    """

    def __init__(self, secure_pkl=None):
        if secure_pkl is not None:
            with open(secure_pkl, "rb") as f:
                self.secure_domain_ip_table = pickle.load(f)
        else:
            self.secure_domain_ip_table = dict()
        self.skeptical_domain_ip_table = dict()
        self.cname_table = dict()

    def first_validate(self, domain, ip):
        if ip in self.secure_domain_ip_table.get(domain, []):
            return True
        return False

    def second_validate(self, domain, ip):
        domains = reverse_dns(ip)
        if domain in domains:
            return True
        return False

    def validate(self, domain, ip):
        if self.first_validate(domain, ip):
            return True
        if self.second_validate(domain, ip):
            return True
        return False

    def update(self, file_names):
        """
        从多个pcap文件中更新域名和IP地址
        :param file_names:
        :return:
        """
        for file_name in file_names:
            matched_records = process_pcap(file_name)
            for ip, domain in matched_records.items():
                if ipv4_pattern.match(ip):
                    if self.validate(domain, ip):
                        tem = self.secure_domain_ip_table.get(domain, [])
                        tem.append(ip)
                        self.secure_domain_ip_table[domain] = list(set(tem))
                    else:
                        tem = self.skeptical_domain_ip_table.get(domain, [])
                        tem.append(ip)
                        self.skeptical_domain_ip_table[domain] = list(set(tem))
                elif ipv6_pattern.match(ip):
                    tem = self.skeptical_domain_ip_table.get(domain, [])
                    tem.append(ip)
                    self.skeptical_domain_ip_table[domain] = list(set(tem))
                else:
                    tem = self.skeptical_domain_ip_table.get(domain, [])
                    tem.append(ip)
                    self.cname_table[domain] = list(set(tem))

        with open("security.pkl", "wb") as f:
            pickle.dump(self.secure_domain_ip_table, f)
        with open("skeptical.pkl", "wb") as f:
            pickle.dump(self.skeptical_domain_ip_table, f)
        with open("cname.pkl", "wb") as f:
            pickle.dump(self.cname_table, f)

    def get_skeptical_domain_ip_table(self):
        for domain, ips in self.skeptical_domain_ip_table.items():
            print(f"SkepticalDomain: {domain} with IPs: {ips}")
        return self.skeptical_domain_ip_table

    def get_cname_table(self):
        for domain, trueDomains in self.cname_table.items():
            print(f"CName: {domain} with trueDomains: {trueDomains}")
        return self.cname_table

    def get_domain_ip_table(self):
        print("********33333333")
        for domain, ips in self.secure_domain_ip_table.items():
            print(f"Domain: {domain} with IPs: {ips}")
        return self.secure_domain_ip_table


if __name__=="__main__":
    if os.path.isdir(sys.argv[1]):
        if os.path.exists("security.pkl"):
            cross_validation = CrossValidation("security.pkl")
        else:
            cross_validation = CrossValidation()
        # 所给文件地址必须为pcap文件夹否则会引起报错
        cross_validation.update([f"{sys.argv[1]}/{file_name}" for file_name in os.listdir(sys.argv[1])])
        cross_validation.get_domain_ip_table()
        cross_validation.get_cname_table()
        cross_validation.get_skeptical_domain_ip_table()
    else:
        print("Please input a pcap folder")