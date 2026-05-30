import base64

solution_base64 = "你的Base64字符串..."  # 替换为实际值
# 解码为字节串
raw_bytes = base64.b64decode(solution_base64)
# 每个字节就是1~9的数字，转为列表
answer = list(raw_bytes)   # [5, 3, 4, 6, 7, 8, 9, 1, 2, ...]

print(answer[:9])   # 第一行
print(len(answer))  # 应该是 81

if __name__ == "__main__":
    pass