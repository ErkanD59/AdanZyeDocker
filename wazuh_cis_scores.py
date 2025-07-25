#!/usr/bin/env python3
"""
Wazuh Agent CIS Scores Viewer
Bu script Wazuh üzerindeki agentların CIS skorlarını tablo şeklinde gösterir.
"""

import requests
import json
import pandas as pd
from tabulate import tabulate
import argparse
import sys
from datetime import datetime
import os

class WazuhCISViewer:
    def __init__(self, manager_url="https://localhost", username=None, password=None, 
                 api_token=None, verify_ssl=True):
        """
        Wazuh CIS Viewer sınıfı
        
        Args:
            manager_url (str): Wazuh Manager URL'i
            username (str): Wazuh kullanıcı adı
            password (str): Wazuh şifresi
            api_token (str): API token (alternatif kimlik doğrulama)
            verify_ssl (bool): SSL sertifikasını doğrula
        """
        self.manager_url = manager_url.rstrip('/')
        self.username = username
        self.password = password
        self.api_token = api_token
        self.verify_ssl = verify_ssl
        self.session = requests.Session()
        
        # SSL doğrulama ayarı
        if not verify_ssl:
            import urllib3
            urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
            self.session.verify = False
    
    def authenticate(self):
        """Wazuh API'ye kimlik doğrulama yapar"""
        try:
            if self.api_token:
                # Token ile kimlik doğrulama
                headers = {'Authorization': f'Bearer {self.api_token}'}
                response = self.session.get(f"{self.manager_url}/api/", headers=headers)
            else:
                # Kullanıcı adı/şifre ile kimlik doğrulama
                auth_data = {
                    'user': self.username,
                    'password': self.password
                }
                response = self.session.post(f"{self.manager_url}/api/auth", json=auth_data)
                
                if response.status_code == 200:
                    token = response.json()['data']['token']
                    self.session.headers.update({'Authorization': f'Bearer {token}'})
                else:
                    raise Exception(f"Kimlik doğrulama başarısız: {response.status_code}")
            
            return response.status_code == 200
            
        except Exception as e:
            print(f"Kimlik doğrulama hatası: {e}")
            return False
    
    def get_agents(self):
        """Tüm agentları getirir"""
        try:
            response = self.session.get(f"{self.manager_url}/api/agents")
            if response.status_code == 200:
                return response.json()['data']['affected_items']
            else:
                print(f"Agent listesi alınamadı: {response.status_code}")
                return []
        except Exception as e:
            print(f"Agent listesi alma hatası: {e}")
            return []
    
    def get_cis_scores(self, agent_id):
        """Belirli bir agent için CIS skorlarını getirir"""
        try:
            # CIS compliance endpoint'i
            response = self.session.get(f"{self.manager_url}/api/agents/{agent_id}/compliance/cis")
            
            if response.status_code == 200:
                data = response.json()['data']['affected_items']
                return self.parse_cis_data(data)
            else:
                return None
                
        except Exception as e:
            print(f"Agent {agent_id} için CIS verisi alınamadı: {e}")
            return None
    
    def parse_cis_data(self, cis_data):
        """CIS verilerini parse eder"""
        scores = {
            'total_checks': 0,
            'passed': 0,
            'failed': 0,
            'error': 0,
            'unknown': 0,
            'compliance_score': 0,
            'last_scan': None
        }
        
        if not cis_data:
            return scores
        
        for item in cis_data:
            if 'compliance' in item:
                compliance = item['compliance']
                scores['total_checks'] += compliance.get('total_checks', 0)
                scores['passed'] += compliance.get('passed', 0)
                scores['failed'] += compliance.get('failed', 0)
                scores['error'] += compliance.get('error', 0)
                scores['unknown'] += compliance.get('unknown', 0)
                
                # Compliance score hesaplama
                if scores['total_checks'] > 0:
                    scores['compliance_score'] = (scores['passed'] / scores['total_checks']) * 100
                
                # Son tarama tarihi
                if 'last_scan' in compliance:
                    scores['last_scan'] = compliance['last_scan']
        
        return scores
    
    def get_all_cis_scores(self):
        """Tüm agentlar için CIS skorlarını getirir"""
        print("Agentlar alınıyor...")
        agents = self.get_agents()
        
        if not agents:
            print("Hiç agent bulunamadı.")
            return []
        
        print(f"{len(agents)} agent bulundu. CIS skorları alınıyor...")
        
        results = []
        for i, agent in enumerate(agents, 1):
            agent_id = agent['id']
            agent_name = agent.get('name', f'Agent-{agent_id}')
            agent_status = agent.get('status', 'unknown')
            
            print(f"İşleniyor: {i}/{len(agents)} - {agent_name}")
            
            cis_scores = self.get_cis_scores(agent_id)
            
            if cis_scores:
                result = {
                    'Agent ID': agent_id,
                    'Agent Name': agent_name,
                    'Status': agent_status,
                    'Total Checks': cis_scores['total_checks'],
                    'Passed': cis_scores['passed'],
                    'Failed': cis_scores['failed'],
                    'Error': cis_scores['error'],
                    'Unknown': cis_scores['unknown'],
                    'Compliance Score (%)': round(cis_scores['compliance_score'], 2),
                    'Last Scan': cis_scores['last_scan'] or 'N/A'
                }
                results.append(result)
            else:
                # CIS verisi olmayan agentlar için
                result = {
                    'Agent ID': agent_id,
                    'Agent Name': agent_name,
                    'Status': agent_status,
                    'Total Checks': 0,
                    'Passed': 0,
                    'Failed': 0,
                    'Error': 0,
                    'Unknown': 0,
                    'Compliance Score (%)': 0,
                    'Last Scan': 'N/A'
                }
                results.append(result)
        
        return results
    
    def display_table(self, data, output_format='table'):
        """Verileri tablo formatında gösterir"""
        if not data:
            print("Gösterilecek veri bulunamadı.")
            return
        
        df = pd.DataFrame(data)
        
        if output_format == 'csv':
            filename = f"wazuh_cis_scores_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
            df.to_csv(filename, index=False)
            print(f"Veriler {filename} dosyasına kaydedildi.")
        elif output_format == 'json':
            filename = f"wazuh_cis_scores_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            print(f"Veriler {filename} dosyasına kaydedildi.")
        else:
            # Tablo formatında göster
            print("\n" + "="*100)
            print("WAZUH AGENT CIS SKORLARI")
            print("="*100)
            print(tabulate(df, headers='keys', tablefmt='grid', showindex=False))
            
            # Özet istatistikler
            print("\n" + "="*50)
            print("ÖZET İSTATİSTİKLER")
            print("="*50)
            
            total_agents = len(data)
            agents_with_cis = len([d for d in data if d['Total Checks'] > 0])
            avg_compliance = df['Compliance Score (%)'].mean()
            
            print(f"Toplam Agent Sayısı: {total_agents}")
            print(f"CIS Verisi Olan Agent Sayısı: {agents_with_cis}")
            print(f"Ortalama Uyumluluk Skoru: {avg_compliance:.2f}%")
            
            if agents_with_cis > 0:
                high_compliance = len(df[df['Compliance Score (%)'] >= 80])
                medium_compliance = len(df[(df['Compliance Score (%)'] >= 60) & (df['Compliance Score (%)'] < 80)])
                low_compliance = len(df[df['Compliance Score (%)'] < 60])
                
                print(f"Yüksek Uyumluluk (≥80%): {high_compliance} agent")
                print(f"Orta Uyumluluk (60-79%): {medium_compliance} agent")
                print(f"Düşük Uyumluluk (<60%): {low_compliance} agent")

def main():
    parser = argparse.ArgumentParser(description='Wazuh Agent CIS Skorları Görüntüleyici')
    parser.add_argument('--url', default='https://localhost', help='Wazuh Manager URL')
    parser.add_argument('--username', help='Wazuh kullanıcı adı')
    parser.add_argument('--password', help='Wazuh şifresi')
    parser.add_argument('--token', help='API Token')
    parser.add_argument('--no-ssl-verify', action='store_true', help='SSL sertifikasını doğrulama')
    parser.add_argument('--output', choices=['table', 'csv', 'json'], default='table', 
                       help='Çıktı formatı')
    
    args = parser.parse_args()
    
    # Kimlik doğrulama bilgilerini kontrol et
    if not args.token and (not args.username or not args.password):
        print("Hata: Ya API token ya da kullanıcı adı/şifre belirtmelisiniz.")
        print("Örnek kullanım:")
        print("  python wazuh_cis_scores.py --username admin --password password")
        print("  python wazuh_cis_scores.py --token YOUR_API_TOKEN")
        sys.exit(1)
    
    # Wazuh CIS Viewer'ı başlat
    viewer = WazuhCISViewer(
        manager_url=args.url,
        username=args.username,
        password=args.password,
        api_token=args.token,
        verify_ssl=not args.no_ssl_verify
    )
    
    # Kimlik doğrulama
    print("Wazuh API'ye bağlanılıyor...")
    if not viewer.authenticate():
        print("Kimlik doğrulama başarısız!")
        sys.exit(1)
    
    print("Kimlik doğrulama başarılı!")
    
    # CIS skorlarını al
    data = viewer.get_all_cis_scores()
    
    # Sonuçları göster
    viewer.display_table(data, args.output)

if __name__ == "__main__":
    main()