#!/bin/bash

# Wazuh Agent CIS Scores Viewer - Bash Script
# Bu script Wazuh Manager'dan direkt CIS skorlarını çeker

set -e

# Renk kodları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Varsayılan ayarlar
WAZUH_URL="https://localhost"
WAZUH_USER=""
WAZUH_PASS=""
API_TOKEN=""
OUTPUT_FORMAT="table"
OUTPUT_FILE=""

# Yardım fonksiyonu
show_help() {
    echo -e "${BLUE}Wazuh Agent CIS Skorları Görüntüleyici${NC}"
    echo ""
    echo "Kullanım: $0 [OPTIONS]"
    echo ""
    echo "Seçenekler:"
    echo "  -u, --url URL           Wazuh Manager URL (varsayılan: https://localhost)"
    echo "  -U, --username USER     Wazuh kullanıcı adı"
    echo "  -p, --password PASS     Wazuh şifresi"
    echo "  -t, --token TOKEN       API Token (kullanıcı adı/şifre yerine)"
    echo "  -o, --output FORMAT     Çıktı formatı: table, csv, json (varsayılan: table)"
    echo "  -f, --file FILE         Çıktı dosyası"
    echo "  -k, --insecure          SSL sertifikasını doğrulama"
    echo "  -h, --help              Bu yardım mesajını göster"
    echo ""
    echo "Örnekler:"
    echo "  $0 -U admin -p password"
    echo "  $0 -t YOUR_API_TOKEN -o csv -f results.csv"
    echo "  $0 -U admin -p password -u https://wazuh.example.com"
}

# Argümanları parse et
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            WAZUH_URL="$2"
            shift 2
            ;;
        -U|--username)
            WAZUH_USER="$2"
            shift 2
            ;;
        -p|--password)
            WAZUH_PASS="$2"
            shift 2
            ;;
        -t|--token)
            API_TOKEN="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -f|--file)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -k|--insecure)
            CURL_INSECURE="-k"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Bilinmeyen seçenek: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Kimlik doğrulama kontrolü
if [[ -z "$API_TOKEN" && (-z "$WAZUH_USER" || -z "$WAZUH_PASS") ]]; then
    echo -e "${RED}Hata: Ya API token ya da kullanıcı adı/şifre belirtmelisiniz.${NC}"
    show_help
    exit 1
fi

# Çıktı dosyası belirtilmemişse otomatik oluştur
if [[ -z "$OUTPUT_FILE" ]]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    case $OUTPUT_FORMAT in
        csv)
            OUTPUT_FILE="wazuh_cis_scores_${TIMESTAMP}.csv"
            ;;
        json)
            OUTPUT_FILE="wazuh_cis_scores_${TIMESTAMP}.json"
            ;;
        *)
            OUTPUT_FILE=""
            ;;
    esac
fi

# Token alma fonksiyonu
get_token() {
    if [[ -n "$API_TOKEN" ]]; then
        echo "$API_TOKEN"
    else
        local response=$(curl -s $CURL_INSECURE -X POST \
            -H "Content-Type: application/json" \
            -d "{\"user\":\"$WAZUH_USER\",\"password\":\"$WAZUH_PASS\"}" \
            "$WAZUH_URL/api/auth")
        
        echo "$response" | jq -r '.data.token' 2>/dev/null || {
            echo -e "${RED}Token alma hatası:${NC}"
            echo "$response"
            exit 1
        }
    fi
}

# API çağrısı yapma fonksiyonu
api_call() {
    local endpoint="$1"
    local token="$2"
    
    curl -s $CURL_INSECURE -X GET \
        -H "Authorization: Bearer $token" \
        "$WAZUH_URL/api/$endpoint"
}

# Ana fonksiyon
main() {
    echo -e "${BLUE}Wazuh API'ye bağlanılıyor...${NC}"
    
    # Token al
    TOKEN=$(get_token)
    if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
        echo -e "${RED}Kimlik doğrulama başarısız!${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Kimlik doğrulama başarılı!${NC}"
    
    # Agentları al
    echo -e "${BLUE}Agentlar alınıyor...${NC}"
    AGENTS_RESPONSE=$(api_call "agents" "$TOKEN")
    
    # jq kontrolü
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}jq komutu bulunamadı. Lütfen jq'yu yükleyin.${NC}"
        echo "Ubuntu/Debian: sudo apt-get install jq"
        echo "CentOS/RHEL: sudo yum install jq"
        exit 1
    fi
    
    AGENT_COUNT=$(echo "$AGENTS_RESPONSE" | jq '.data.total_affected_items // 0')
    echo -e "${GREEN}$AGENT_COUNT agent bulundu.${NC}"
    
    if [[ $AGENT_COUNT -eq 0 ]]; then
        echo -e "${YELLOW}Hiç agent bulunamadı.${NC}"
        exit 0
    fi
    
    # Sonuçları topla
    RESULTS="[]"
    CURRENT=0
    
    echo "$AGENTS_RESPONSE" | jq -c '.data.affected_items[]' | while read -r agent; do
        CURRENT=$((CURRENT + 1))
        AGENT_ID=$(echo "$agent" | jq -r '.id')
        AGENT_NAME=$(echo "$agent" | jq -r '.name // "Agent-'$AGENT_ID'"')
        AGENT_STATUS=$(echo "$agent" | jq -r '.status // "unknown"')
        
        echo -e "${BLUE}İşleniyor: $CURRENT/$AGENT_COUNT - $AGENT_NAME${NC}"
        
        # CIS verilerini al
        CIS_RESPONSE=$(api_call "agents/$AGENT_ID/compliance/cis" "$TOKEN")
        
        # CIS verilerini parse et
        TOTAL_CHECKS=0
        PASSED=0
        FAILED=0
        ERROR=0
        UNKNOWN=0
        COMPLIANCE_SCORE=0
        LAST_SCAN="N/A"
        
        if [[ $(echo "$CIS_RESPONSE" | jq '.data.total_affected_items // 0') -gt 0 ]]; then
            echo "$CIS_RESPONSE" | jq -c '.data.affected_items[]' | while read -r cis_item; do
                if [[ $(echo "$cis_item" | jq 'has("compliance")') == "true" ]]; then
                    COMPLIANCE=$(echo "$cis_item" | jq '.compliance')
                    TOTAL_CHECKS=$((TOTAL_CHECKS + $(echo "$COMPLIANCE" | jq '.total_checks // 0')))
                    PASSED=$((PASSED + $(echo "$COMPLIANCE" | jq '.passed // 0')))
                    FAILED=$((FAILED + $(echo "$COMPLIANCE" | jq '.failed // 0')))
                    ERROR=$((ERROR + $(echo "$COMPLIANCE" | jq '.error // 0')))
                    UNKNOWN=$((UNKNOWN + $(echo "$COMPLIANCE" | jq '.unknown // 0')))
                    
                    if [[ $TOTAL_CHECKS -gt 0 ]]; then
                        COMPLIANCE_SCORE=$(echo "scale=2; $PASSED * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "0")
                    fi
                    
                    SCAN_DATE=$(echo "$COMPLIANCE" | jq -r '.last_scan // empty')
                    if [[ -n "$SCAN_DATE" && "$SCAN_DATE" != "null" ]]; then
                        LAST_SCAN="$SCAN_DATE"
                    fi
                fi
            done
        fi
        
        # Sonucu JSON'a ekle
        RESULT=$(jq -n \
            --arg id "$AGENT_ID" \
            --arg name "$AGENT_NAME" \
            --arg status "$AGENT_STATUS" \
            --arg total "$TOTAL_CHECKS" \
            --arg passed "$PASSED" \
            --arg failed "$FAILED" \
            --arg error "$ERROR" \
            --arg unknown "$UNKNOWN" \
            --arg score "$COMPLIANCE_SCORE" \
            --arg scan "$LAST_SCAN" \
            '{
                "Agent ID": $id,
                "Agent Name": $name,
                "Status": $status,
                "Total Checks": ($total | tonumber),
                "Passed": ($passed | tonumber),
                "Failed": ($failed | tonumber),
                "Error": ($error | tonumber),
                "Unknown": ($unknown | tonumber),
                "Compliance Score (%)": ($score | tonumber),
                "Last Scan": $scan
            }')
        
        RESULTS=$(echo "$RESULTS" | jq --argjson result "$RESULT" '. += [$result]')
    done
    
    # Sonuçları göster
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$RESULTS" > "$OUTPUT_FILE"
            echo -e "${GREEN}Sonuçlar $OUTPUT_FILE dosyasına kaydedildi.${NC}"
        else
            echo "$RESULTS"
        fi
    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        if [[ -n "$OUTPUT_FILE" ]]; then
            echo "$RESULTS" | jq -r '.[] | [.[]] | @csv' > "$OUTPUT_FILE"
            echo -e "${GREEN}Sonuçlar $OUTPUT_FILE dosyasına kaydedildi.${NC}"
        else
            echo "$RESULTS" | jq -r '.[] | [.[]] | @csv'
        fi
    else
        # Tablo formatında göster
        echo ""
        echo "=================================================================================================="
        echo "WAZUH AGENT CIS SKORLARI"
        echo "=================================================================================================="
        echo "$RESULTS" | jq -r '.[] | "| \(.["Agent ID"]) | \(.["Agent Name"]) | \(.["Status"]) | \(.["Total Checks"]) | \(.["Passed"]) | \(.["Failed"]) | \(.["Compliance Score (%)"]) | \(.["Last Scan"]) |"' | \
        sed '1i | Agent ID | Agent Name | Status | Total Checks | Passed | Failed | Compliance Score (%) | Last Scan |' | \
        sed '2i |----------|------------|--------|--------------|--------|--------|---------------------|-----------|'
    fi
}

# Scripti çalıştır
main