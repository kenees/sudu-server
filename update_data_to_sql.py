#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
导入超大 JSON 数组到 MySQL 表（流式解析 + 批量插入）
适用场景：JSON 文件为 [{col1:val1, col2:val2}, ...] 格式
"""

import ijson
import pymysql
import json
import os
from datetime import datetime, timedelta
from typing import Dict, Any, List, Tuple

# ==================== 配置区域（请按需修改） ====================
DB_CONFIG = {
    'host': '120.53.246.10',
    'user': 'sudoku',          # 数据库用户名
    'password': 'ksJZy7sJ48nwHkzr',  # 数据库密码
    'database': 'sudoku',      # 数据库名
    'charset': 'utf8mb4'
}

JSON_FILE = 'my_puzzles_3.json'     # JSON 文件路径
TABLE_NAME = 'puzzles'         # 目标表名

# 批量插入的批次大小（根据内存和网络调整，建议 500~2000）
BATCH_SIZE = 1000
BASE_TIME = datetime(2026, 3, 1, 10, 0, 0)  # 起始时间

# 可选：字段映射（如果 JSON 键名与数据库列名不一致，在此映射）
# 格式：{ 'json_key': 'db_column' }
FIELD_MAPPING = {
    # 示例：'cages': 'cages_json',
    # 如果一致则不需要映射，脚本会直接使用 JSON 的键作为列名
}

# 需要忽略的 JSON 字段（不插入数据库）
IGNORE_FIELDS = set()

# ===============================================================
def build_cages_json(cages, sums):
    """
    根据 cages（坐标列表）和 sums（和列表）生成目标格式的 cages_json。
    返回 JSON 字符串。
    """
    cages_json = []
    for idx, (cage_coords, sum_val) in enumerate(zip(cages, sums), start=1):
        # 将坐标对转换为 {"row": r, "col": c}
        cells = [{"row": coord[0], "col": coord[1]} for coord in cage_coords]
        # inner 暂时设为空列表（如果需要自动计算组合，可在此扩展）
        inner = []
        cage_obj = {
            "id": idx,
            "sum": sum_val,
            "cells": cells,
            "inner": inner
        }
        cages_json.append(cage_obj)
    # 返回 JSON 字符串（紧凑格式）
    return json.dumps(cages_json, separators=(',', ':'))

def build_answer_json(solution):
    """
    将 9x9 二维数组 solution 展平为一维数组，并转为 JSON 字符串。
    """
    flat = [num for row in solution for num in row]
    return json.dumps(flat, separators=(',', ':'))

def insert_puzzles():
    if not os.path.exists(JSON_FILE):
        print(f"错误：文件 {JSON_FILE} 不存在")
        return

    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()

    insert_sql = f"""
        INSERT INTO {TABLE_NAME}
        (difficulty, average_solving_time, cages_json, answer_json, created_at)
        VALUES (%s, %s, %s, %s, %s)
    """

    batch = []
    total = 0
    record_count = 0  # 用于计算 created_at 偏移天数

    try:
        with open(JSON_FILE, 'rb') as f:
            # 流式解析根数组的每个元素（ijson 的 'item'）
            parser = ijson.items(f, 'item')
            for obj in parser:
                # 提取字段
                difficulty = obj.get('difficulty')
                est_time = obj.get('est_time', 0.0)
                avg_time = int(est_time * 60)  # 转为整数秒
                cages = obj.get('cages')
                sums = obj.get('sums')
                solution = obj.get('solution')

                # 数据校验
                if not all([difficulty is not None, cages, sums, solution]):
                    print(f"跳过无效记录：缺少必要字段，位置 {record_count+1}")
                    continue

                # 构造 JSON 字段
                cages_json_str = build_cages_json(cages, sums)
                answer_json_str = build_answer_json(solution)

                # 计算 created_at（基准时间 + 记录索引天数）
                created_at = BASE_TIME + timedelta(days=record_count)

                time_str = created_at.strftime("%Y%m%d")

                print(f"{time_str}01, {created_at}")
                batch.append(( difficulty, avg_time, cages_json_str, answer_json_str, created_at))
                record_count += 1

                # 批量插入
                if len(batch) >= BATCH_SIZE:
                    cursor.executemany(insert_sql, batch)
                    conn.commit()
                    total += len(batch)
                    print(f"已插入 {total} 条记录")
                    batch = []

        # 处理最后一批
        if batch:
            cursor.executemany(insert_sql, batch)
            conn.commit()
            total += len(batch)
            print(f"已插入 {total} 条记录")

        print(f"全部完成！共插入 {total} 条记录到表 {TABLE_NAME}")

    except Exception as e:
        conn.rollback()
        print(f"发生错误，已回滚当前批次：{e}")
        raise
    finally:
        cursor.close()
        conn.close()
        pass

if __name__ == '__main__':
    insert_puzzles()
