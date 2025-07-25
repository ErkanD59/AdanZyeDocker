# Wazuh Agent CIS Skorları Görüntüleyici

Bu proje, Wazuh üzerindeki agentların CIS (Center for Internet Security) uyumluluk skorlarını tablo şeklinde görüntülemek için geliştirilmiş araçları içerir.

## 📋 İçindekiler

- [Özellikler](#özellikler)
- [Gereksinimler](#gereksinimler)
- [Kurulum](#kurulum)
- [Kullanım](#kullanım)
- [Araçlar](#araçlar)
- [API Endpoint'leri](#api-endpointleri)
- [Sorun Giderme](#sorun-giderme)
- [Katkıda Bulunma](#katkıda-bulunma)

## ✨ Özellikler

- 🔍 **Tüm Agentların CIS Skorları**: Wazuh'taki tüm agentların CIS uyumluluk skorlarını toplar
- 📊 **Görsel Dashboard**: Modern ve kullanıcı dostu web arayüzü
- 📈 **İstatistikler**: Özet istatistikler ve uyumluluk dağılımı
- 📄 **Çoklu Format Desteği**: Tablo, CSV, JSON formatlarında çıktı
- 🔐 **Güvenli Kimlik Doğrulama**: API token veya kullanıcı adı/şifre ile kimlik doğrulama
- 🚀 **Hızlı ve Verimli**: Paralel işleme ve optimize edilmiş API çağrıları

## 🔧 Gereksinimler

### Python Script için:
- Python 3.7+
- requests
- pandas
- tabulate
- urllib3

### Bash Script için:
- bash
- curl
- jq
- bc (opsiyonel)

### Web Dashboard için:
- Modern web tarayıcısı (Chrome, Firefox, Safari, Edge)
- JavaScript etkin

## 📦 Kurulum

### 1. Python Bağımlılıklarını Yükleme

```bash
pip install -r requirements.txt
```

### 2. Bash Script için Gerekli Araçları Yükleme

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install jq curl bc
```

**CentOS/RHEL:**
```bash
sudo yum install jq curl bc
```

**macOS:**
```bash
brew install jq curl bc
```

### 3. Scriptleri Çalıştırılabilir Yapma

```bash
chmod +x wazuh_cis_scores.py
chmod +x wazuh_cis_scores.sh
```

## 🚀 Kullanım

### Python Script Kullanımı

```bash
# Temel kullanım
python wazuh_cis_scores.py --username admin --password your_password

# API token ile
python wazuh_cis_scores.py --token YOUR_API_TOKEN

# Farklı URL ile
python wazuh_cis_scores.py --url https://wazuh.example.com --username admin --password password

# CSV formatında çıktı
python wazuh_cis_scores.py --username admin --password password --output csv

# JSON formatında çıktı
python wazuh_cis_scores.py --username admin --password password --output json

# SSL doğrulamasını devre dışı bırak
python wazuh_cis_scores.py --username admin --password password --no-ssl-verify
```

### Bash Script Kullanımı

```bash
# Temel kullanım
./wazuh_cis_scores.sh -U admin -p your_password

# API token ile
./wazuh_cis_scores.sh -t YOUR_API_TOKEN

# Farklı URL ile
./wazuh_cis_scores.sh -u https://wazuh.example.com -U admin -p password

# CSV formatında çıktı
./wazuh_cis_scores.sh -U admin -p password -o csv

# JSON formatında çıktı ve dosyaya kaydet
./wazuh_cis_scores.sh -U admin -p password -o json -f results.json

# SSL doğrulamasını devre dışı bırak
./wazuh_cis_scores.sh -U admin -p password -k
```

### Web Dashboard Kullanımı

1. `wazuh_cis_dashboard.html` dosyasını web tarayıcınızda açın
2. Wazuh Manager URL'ini girin
3. Kullanıcı adı/şifre veya API token girin
4. "Verileri Yükle" butonuna tıklayın
5. Sonuçları görüntüleyin ve gerekirse dışa aktarın

## 🛠️ Araçlar

### 1. Python Script (`wazuh_cis_scores.py`)

**Özellikler:**
- Nesne yönelimli tasarım
- Hata yönetimi
- İlerleme göstergesi
- Çoklu çıktı formatı
- SSL sertifika yönetimi

**Parametreler:**
- `--url`: Wazuh Manager URL'i
- `--username`: Kullanıcı adı
- `--password`: Şifre
- `--token`: API token
- `--output`: Çıktı formatı (table/csv/json)
- `--no-ssl-verify`: SSL doğrulamasını devre dışı bırak

### 2. Bash Script (`wazuh_cis_scores.sh`)

**Özellikler:**
- Renkli çıktı
- Detaylı hata mesajları
- Otomatik dosya adlandırma
- Paralel işleme desteği

**Parametreler:**
- `-u, --url`: Wazuh Manager URL'i
- `-U, --username`: Kullanıcı adı
- `-p, --password`: Şifre
- `-t, --token`: API token
- `-o, --output`: Çıktı formatı
- `-f, --file`: Çıktı dosyası
- `-k, --insecure`: SSL doğrulamasını devre dışı bırak

### 3. Web Dashboard (`wazuh_cis_dashboard.html`)

**Özellikler:**
- Modern ve responsive tasarım
- Gerçek zamanlı veri yükleme
- İnteraktif istatistikler
- Çoklu export seçenekleri
- Yazdırma desteği

## 🔌 API Endpoint'leri

Bu araçlar aşağıdaki Wazuh API endpoint'lerini kullanır:

### Kimlik Doğrulama
```
POST /api/auth
```

### Agent Listesi
```
GET /api/agents
```

### CIS Uyumluluk Verileri
```
GET /api/agents/{agent_id}/compliance/cis
```

## 📊 Çıktı Formatları

### Tablo Formatı
```
==================================================================================================
WAZUH AGENT CIS SKORLARI
==================================================================================================
| Agent ID | Agent Name | Status | Total Checks | Passed | Failed | Compliance Score (%) | Last Scan |
|----------|------------|--------|--------------|--------|--------|---------------------|-----------|
| 1        | server-01  | active | 150          | 120    | 25     | 80.0                | 2024-01-15 |
| 2        | server-02  | active | 150          | 135    | 10     | 90.0                | 2024-01-15 |
```

### CSV Formatı
```csv
Agent ID,Agent Name,Status,Total Checks,Passed,Failed,Error,Unknown,Compliance Score (%),Last Scan
1,server-01,active,150,120,25,3,2,80.0,2024-01-15
2,server-02,active,150,135,10,2,3,90.0,2024-01-15
```

### JSON Formatı
```json
[
  {
    "Agent ID": 1,
    "Agent Name": "server-01",
    "Status": "active",
    "Total Checks": 150,
    "Passed": 120,
    "Failed": 25,
    "Error": 3,
    "Unknown": 2,
    "Compliance Score (%)": 80.0,
    "Last Scan": "2024-01-15"
  }
]
```

## 🔍 Sorun Giderme

### Yaygın Hatalar

#### 1. Kimlik Doğrulama Hatası
```
Hata: Kimlik doğrulama başarısız!
```
**Çözüm:**
- Kullanıcı adı ve şifrenin doğru olduğundan emin olun
- API token'ın geçerli olduğunu kontrol edin
- Wazuh Manager'ın erişilebilir olduğunu doğrulayın

#### 2. SSL Sertifika Hatası
```
SSL: certificate verify failed
```
**Çözüm:**
- `--no-ssl-verify` parametresini kullanın
- SSL sertifikasını doğru şekilde yapılandırın

#### 3. Agent Bulunamadı
```
Hiç agent bulunamadı.
```
**Çözüm:**
- Wazuh'ta agent'ların kayıtlı olduğunu kontrol edin
- Agent'ların aktif durumda olduğunu doğrulayın

#### 4. CIS Verisi Yok
```
CIS verisi olmayan agentlar
```
**Çözüm:**
- Agent'larda CIS compliance modülünün etkin olduğunu kontrol edin
- CIS taramalarının çalıştırıldığından emin olun

### Debug Modu

Python script için debug bilgilerini görmek:
```bash
python -u wazuh_cis_scores.py --username admin --password password 2>&1 | tee debug.log
```

Bash script için debug modu:
```bash
bash -x wazuh_cis_scores.sh -U admin -p password
```

## 🔒 Güvenlik

### API Token Kullanımı
- API token'ları güvenli bir şekilde saklayın
- Token'ları düzenli olarak yenileyin
- Minimum gerekli izinlere sahip token'lar kullanın

### SSL/TLS
- Üretim ortamında SSL sertifikalarını doğru şekilde yapılandırın
- Self-signed sertifikaları sadece test ortamında kullanın

### Ağ Güvenliği
- Wazuh API'sine sadece güvenli ağlardan erişim sağlayın
- Firewall kurallarını uygun şekilde yapılandırın

## 📈 Performans

### Optimizasyon İpuçları

1. **Paralel İşleme**: Çok sayıda agent varsa paralel API çağrıları kullanın
2. **Önbellekleme**: Sık kullanılan verileri önbelleğe alın
3. **Filtreleme**: Sadece gerekli agent'ları sorgulayın
4. **Batch İşleme**: Büyük veri setleri için batch işleme kullanın

### Performans Metrikleri

- **100 Agent**: ~30-60 saniye
- **500 Agent**: ~2-5 dakika
- **1000+ Agent**: ~5-15 dakika

## 🤝 Katkıda Bulunma

1. Bu repository'yi fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

### Geliştirme Ortamı

```bash
# Repository'yi klonlayın
git clone https://github.com/your-username/wazuh-cis-scores.git
cd wazuh-cis-scores

# Virtual environment oluşturun
python -m venv venv
source venv/bin/activate  # Linux/macOS
# venv\Scripts\activate  # Windows

# Bağımlılıkları yükleyin
pip install -r requirements.txt

# Test edin
python wazuh_cis_scores.py --help
```

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için `LICENSE` dosyasına bakın.

## 📞 Destek

- **Issues**: GitHub Issues sayfasını kullanın
- **Discussions**: GitHub Discussions sayfasını kullanın
- **Email**: [your-email@example.com]

## 🙏 Teşekkürler

- Wazuh ekibine harika bir SIEM platformu sağladıkları için
- Center for Internet Security'e CIS benchmark'ları için
- Açık kaynak topluluğuna katkıları için

---

**Not**: Bu araçlar Wazuh'un resmi ürünleri değildir ve Wazuh tarafından desteklenmemektedir. Sadece topluluk tarafından geliştirilmiş yardımcı araçlardır.