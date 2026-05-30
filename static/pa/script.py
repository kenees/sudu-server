from playwright.sync_api import sync_playwright
import time
import json

def run_hint(page):
    """
    调用81次hint，补全所有数字。
    每次hint后短暂等待，确保UI更新。
    """
    for i in range(81):
        try:
            page.evaluate("DKS.puzzle.hint();")
            # 给页面一点渲染时间，避免过快导致状态不一致
            page.wait_for_timeout(50)
        except Exception as e:
            print(f"执行第{i+1}次hint时出错: {e}")
            break

def get_answer(page, puzzle_id):
    """
    等待所有单元格填满后，提取答案数组。
    返回长度为81的整数列表，失败返回None。
    """
    try:
        # 等待直到页面上出现81个 .cell-value 元素，超时 100 秒
        page.wait_for_function(
            '() => document.querySelectorAll(".cell-value").length === 81',
            timeout=100000
        )
        # 用evaluate提取所有单元格文本并转数字
        answer = page.evaluate('''() => {
            const cells = document.querySelectorAll(".cell-value");
            const arr = [];
            for (let cell of cells) {
                let txt = cell.innerText.trim();
                let num = parseInt(txt, 10);
                if (!isNaN(num)) arr.push(num);
                else arr.push(0);   // 异常值填0，但理论上都是数字
            }
            return arr;
        }''')
        if len(answer) == 81:
            print(f"ID {puzzle_id} 答案: {answer}")
            return answer
        else:
            print(f"ID {puzzle_id} 提取到的答案长度不是81: {len(answer)}")
            return None
    except Exception as e:
        print(f"ID {puzzle_id} 获取答案出错: {e}")
        return None

def open_sudu_by_id(puzzle_id, page):
    """
    打开指定 puzzle 页面，补全答案并提取。
    """
    url = f"https://www.dailykillersudoku.com/puzzle/{puzzle_id}"
    try:
        # 增加超时时间到 100 秒，等待 DOM 加载完成
        page.goto(url, wait_until='domcontentloaded', timeout=100000)
        print(f"ID {puzzle_id} 页面标题:", page.title())
    except Exception as e:
        print(f"ID {puzzle_id} 页面加载失败: {e}")
        return None

    # 等待游戏核心对象加载（超时 100 秒）
    try:
        # 等待 DKS.puzzle 出现且具备 hint 方法
        page.wait_for_function(
            '() => typeof DKS !== "undefined" && DKS.puzzle',
            timeout=100000
        )
        # 额外等待单元格容器出现
        # page.wait_for_selector('.cell-value', timeout=100000)
        print(f"ID {puzzle_id} 游戏加载完成")
    except Exception as e:
        print(f"ID {puzzle_id} 游戏组件加载超时: {e}")
        return None

    # 执行 hint
    # run_hint(page)
    
    # 提取答案
    # answer = get_answer(page, puzzle_id)
    # return answer

    # 直接从DKS接口获取数据
    answer = page.evaluate('''() => {
                           let array = []
            DKS.puzzle.solution._values.forEach(v => array = array.concat(v))
                           
                           return array
        }''')
    # TODO 二维数组，需要打平
    print(f"answer: {answer}")

    # 获取cages
    cages = page.evaluate('''() => {
            let array = []
            let cagesList = DKS.puzzle.board._cages;
            
            for(let i = 0; i < cagesList.length; i ++) {
                let item = cagesList[i]
                let obj = {
                    id: i+1,
                    sum: item.sum,
                    cells: item.cells.map(v => ({col: v.column, row: v.row})),
                    inner: item.combinations.combinations.map(v => v.values)
                }
                array.push(obj)
            }
            return array                          
    }''')

    print("cages: {}", cages)

    return {"cages": cages, "answer": answer}

def get_sudu_info(difficulty=1):
    """
    从之前保存的 puzzle 列表中读取 ID，逐个打开并获取答案，
    将结果保存到答案文件。全程顺序执行。
    """
    input_filename = f"killer_sudoku_difficulty_{difficulty}.txt"
    output_filename = f"killer_sudoku_answers_{difficulty}.txt"
    
    try:
        with open(input_filename, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print(f"文件 {input_filename} 不存在，请先爬取数据。")
        return
    
    # 清空或创建输出文件（以写模式打开后立即关闭）
    with open(output_filename, "w", encoding="utf-8") as f:
        pass

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-features=IsolateOrigins,site-per-process',
            ]
        )
        context = browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )
        page = context.new_page()
        
        # 收集结果
        with open(output_filename, "a", encoding="utf-8") as f_out:        
            for line in lines:
                line = line.strip()
                if not line:
                    continue
                parts = line.split("/")
                if len(parts) != 4:
                    print(f"格式错误，跳过该行: {line}")
                    continue
                puzzle_id, diff, time_sec, page_num = parts
                print(f"正在处理 ID: {puzzle_id}, 难度: {diff}, 时间(秒): {time_sec}, 页码: {page_num}")
                
                if int(puzzle_id) and int(diff) > -1 and int(time_sec) > 0:
                    data = open_sudu_by_id(puzzle_id, page)
                    if data and data.get("answer") and data.get("cages"):
                        if len(data['answer']) == 81:
                            cages_str = json.dumps(data["cages"], separators=(',', ':'))
                            result_line = f'{puzzle_id}:{diff}:{time_sec}:{data["answer"]}:{cages_str}\n'
                            f_out.write(result_line)
                            # f_out.flush()  # 立即刷新到磁盘
                        else:
                            f_out.write(f"{puzzle_id}:FAILED\n")
                    else:
                        print(f"谜题{puzzle_id}数据获取失败: answer: {data.answer}, cages: {data.cages}")
                        f_out.write(f"{puzzle_id}:FAILED\n")
                else:
                    f_out.write(f"{puzzle_id}:MESSAGE LOSE\n")
                
                # 避免请求过快
                time.sleep(1)
        
        browser.close()
    
    print(f"信息已更新： {output_filename}")

def get_sudu_ids(difficulty=1, start_page=1):
    # 用于存储所有页面的数据
    all_pages_data = []

    with sync_playwright() as p:
        # 1: 打开网页（初始页，先打开第一页以获取最大页码）
        url = ("https://www.dailykillersudoku.com/search?d={}&s=0&t=2&p={}").format(difficulty, start_page)
        browser = p.chromium.launch(
            headless=False, 
            args=[
                '--disable-blink-features=AutomationControlled',
                '--disable-features=IsolateOrigins,site-per-process',
            ])
        context = browser.new_context(
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
        )
        page = context.new_page()
        page.goto(url, wait_until='domcontentloaded', timeout=15000)
        print("页面标题:", page.title())

        page.wait_for_selector('.puzzle-number', timeout=5000)
        print("找到了 .puzzle-number 元素")

        # 获取最大页码
        max_page_number = -1
        try:
            js_code = """
                () => {
                     let childrens = document.getElementsByClassName("pages")[0].children
                     let len = childrens.length
                     let max = parseInt(childrens[len-1].innerHTML, 10)
                     if (!isNaN(max)) {
                        return max
                     }
                     return -1
                }
            """
            max_page_number = page.evaluate(js_code)
            print("执行结果", max_page_number)
        except Exception as e:
            print("evaluate 出错:", e)

        # 从 start_page 到 max_page_number 循环处理
        for page_num in range(start_page, max_page_number + 1):
            # 如果不是起始页，需要导航到新 URL
            if page_num != start_page:
                new_url = ("https://www.dailykillersudoku.com/search?d={}&s=0&t=2&p={}").format(difficulty, page_num)
                try:
                    page.goto(new_url, wait_until='domcontentloaded', timeout=15000)
                    print(f"页面 {page_num} 标题:", page.title())
                    page.wait_for_selector('.puzzle-number', timeout=5000)
                    print(f"找到了第 {page_num} 页的 .puzzle-number 元素")
                except Exception as e:
                    print(f"跳转到第 {page_num} 页失败: {e}")
                    continue

            # 提取 puzzle_ids
            try:
                js_code = """
                    () => {
                            let elements = document.getElementsByClassName("puzzle-number");
                            let arr = [];
                            let timings = document.getElementsByClassName("puzzle-timing-value");
                            let timing = [];

                            for (let i = 0; i < elements.length; i++) {
                                // 获取id
                                let txt = elements[i].innerText;
                                let num = parseInt(txt, 10);
                                if (!isNaN(num)) arr.push(num);

                                // 获取时间
                                let time = timings[i].innerText.trim().toLowerCase();
                                let seconds = 0;
                                // 修正：单位部分改为捕获组 (hour|hr|...)
                                let matches = time.matchAll(/(\d+(?:\.\d+)?)\s*(hour|hr|h|minute|min|m|second|sec|s)/gi);
                                for (let match of matches) {
                                    let val = parseFloat(match[1]);
                                    let unit = match[2].toLowerCase();
                                    
                                    if (unit.startsWith('h')) seconds += val * 3600;
                                    else if (unit.startsWith('m')) seconds += val * 60;
                                    else if (unit.startsWith('s')) seconds += val;
                                }
                                // 纯数字（无单位）按分钟处理
                                if (matches.length === 0 && /^\d+$/.test(txt)) {
                                    seconds = parseInt(txt, 10) * 60;
                                }
                                if (!isNaN(seconds)) timing.push(seconds);
                            }
                            return [arr, timing];
                    }
                """
                result = page.evaluate(js_code)
                puzzle_infos = result
                print(f"第 {page_num} 页 IDs 执行结果", result)
            except Exception as e:
                print(f"第 {page_num} 页 evaluate 出错:", e)
            
            for j in range(0, len(puzzle_infos[0])):
                s = "{}/{}/{}/{}\n".format(
                    puzzle_infos[0][j], 
                    difficulty,  
                    puzzle_infos[1][j], 
                    page_num
                )
                all_pages_data.append(s)
            
        browser.close()

    # 所有页面处理完毕后，将数据保存为 JSON 文件
    output_filename = f"killer_sudoku_difficulty_{difficulty}.txt"
    with open(output_filename, "a", encoding="utf-8") as f:
        # f.writelines(["{}/{}/{}/{}\n".format("puzzle_id", "difficulty",  "puzzle_times", "page_num")])
        f.writelines(all_pages_data)  # 直接写入所有行
    print(f"数据已保存到 {output_filename}")


if __name__ == "__main__":
    # 获取所有id
    # get_sudu_ids(1, 1) 
    # 获取所有题目数据
    get_sudu_info(1)