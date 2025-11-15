import requests
import json
import time
import os
from typing import List, Dict, Optional

# =================== MicrosoftTranslator 类 (保持不变) ===================

class MicrosoftTranslator:
    def __init__(self):
        self.base_url = "https://edge.microsoft.com"
        self.translate_endpoint = "/translate/translatetext"
        self.session = requests.Session()
        
        # 设置请求头，模拟浏览器请求
        self.headers = {
            'Host': 'edge.microsoft.com',
            'content-type': 'application/json',
            'sec-ch-ua-platform': '"Android"',
            'user-agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Mobile Safari/537.36 EdgA/139.0.0.0',
            'sec-ch-ua': '"Not;A=Brand";v="99", "Microsoft Edge";v="139", "Chromium";v="139"',
            'sec-ch-ua-mobile': '?1',
            'accept': '*/*',
            'sec-mesh-client-edge-version': '139.0.3405.125',
            'sec-mesh-client-edge-channel': 'stable',
            'sec-mesh-client-os': 'Android',
            'sec-mesh-client-os-version': '12',
            'sec-mesh-client-arch': 'aarch64',
            'sec-mesh-client-webview': '0',
            'origin': 'https://github.com',
            'sec-fetch-site': 'cross-site',
            'sec-fetch-mode': 'cors',
            'sec-fetch-dest': 'empty',
            'referer': 'https://github.com/richie0866/orca',
            'accept-encoding': 'gzip, deflate, br, zstd',
            'accept-language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
            'priority': 'u=1, i'
        }
    
    def translate(self, texts: List[str], from_lang: str = "en", to_lang: str = "zh-CHS") -> Optional[List[Dict]]:
        """翻译文本列表"""
        if not texts:
            return None
        
        url = f"{self.base_url}{self.translate_endpoint}"
        params = {
            'from': from_lang,
            'to': to_lang,
            'isEnterpriseClient': 'false'
        }
        
        try:
            response = self.session.post(
                url,
                params=params,
                headers=self.headers,
                json=texts,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                print(f"翻译失败，状态码: {response.status_code}")
                print(f"响应内容: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"请求异常: {e}")
            return None
    
    def translate_single(self, text: str, from_lang: str = "en", to_lang: str = "zh-CHS") -> Optional[str]:
        """翻译单个文本"""
        result = self.translate([text], from_lang, to_lang)
        if result and len(result) > 0:
            translations = result[0].get('translations', [])
            if translations:
                return translations[0].get('text')
        return None
    
    def translate_batch(self, texts: List[str], from_lang: str = "en", to_lang: str = "zh-CHS", 
                       delay: float = 0.5) -> List[Optional[str]]:
        """批量翻译，支持分批处理避免请求过快"""
        results = []
        for i, text in enumerate(texts):
            print(f"翻译进度: {i+1}/{len(texts)} - {text[:50]}...")
            translated = self.translate_single(text, from_lang, to_lang)
            results.append(translated)
            
            if i < len(texts) - 1:
                time.sleep(delay)
        
        return results

# =================== 新增功能函数 ===================

def translate_from_file(translator: MicrosoftTranslator, input_path: str, output_path: str, 
                        from_lang: str = "en", to_lang: str = "zh-CHS", delay: float = 0.5):
    """
    从文件读取文本，翻译后保存到新文件
    
    Args:
        translator: MicrosoftTranslator 实例
        input_path: 输入文件路径
        output_path: 输出文件路径
        from_lang: 源语言
        to_lang: 目标语言
        delay: 请求间隔
    """
    print(f"正在从文件 '{input_path}' 读取内容...")
    try:
        with open(input_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # 过滤掉空行
        texts_to_translate = [line.strip() for line in lines if line.strip()]
        
        if not texts_to_translate:
            print("文件为空或只包含空行，无需翻译。")
            return

        print(f"共读取 {len(texts_to_translate)} 行有效文本，开始翻译...")
        
        # 调用批量翻译
        results = translator.translate_batch(texts_to_translate, from_lang, to_lang, delay)
        
        print(f"\n翻译完成，正在将结果保存到 '{output_path}'...")
        with open(output_path, 'w', encoding='utf-8') as f:
            for original, translated in zip(texts_to_translate, results):
                # 写入格式：原文 --- 译文
                f.write(f"{original} --- {translated}\n")
        
        print("文件保存成功！")

    except FileNotFoundError:
        print(f"错误：找不到文件 '{input_path}'。请检查路径是否正确。")
    except Exception as e:
        print(f"处理文件时发生错误: {e}")


def interactive_mode(translator: MicrosoftTranslator):
    """增强的交互式翻译模式"""
    print("\n=== 交互式翻译模式 ===")
    print("输入 'quit' 或 'q' 退出程序")
    print("输入 'file' 或 'f' 进入文件翻译模式")
    print("输入 'batch' 或 'b' 进入批量文本模式")
    
    while True:
        text = input("\n请输入要翻译的文本: ").strip()
        
        if text.lower() in ['quit', 'q']:
            print("退出程序。")
            break
        elif text.lower() in ['file', 'f']:
            input_file = input("请输入源文件路径: ").strip()
            output_file = input("请输入要保存的文件名 (例如: output.txt): ").strip()
            from_lang = input("源语言 (默认 en): ").strip() or "en"
            to_lang = input("目标语言 (默认 zh-CHS): ").strip() or "zh-CHS"
            
            translate_from_file(translator, input_file, output_file, from_lang, to_lang)
            continue
        elif text.lower() in ['batch', 'b']:
            print("\n批量文本模式 - 输入多行文本，输入空行结束:")
            batch_texts = []
            while True:
                line = input().strip()
                if not line:
                    break
                batch_texts.append(line)
            
            if batch_texts:
                from_lang = input("源语言 (默认 en): ").strip() or "en"
                to_lang = input("目标语言 (默认 zh-CHS): ").strip() or "zh-CHS"
                results = translator.translate_batch(batch_texts, from_lang, to_lang)
                print("\n--- 翻译结果 ---")
                for original, translated in zip(batch_texts, results):
                    print(f"原文: {original}")
                    print(f"译文: {translated}\n")
            continue
        
        if text:
            from_lang = input("源语言 (默认 en): ").strip() or "en"
            to_lang = input("目标语言 (默认 zh-CHS): ").strip() or "zh-CHS"
            result = translator.translate_single(text, from_lang, to_lang)
            if result:
                print(f"译文: {result}")
            else:
                print("翻译失败，请重试。")

# =================== 主程序入口 ===================

def main():
    """主函数 - 选择运行模式"""
    translator = Micro
