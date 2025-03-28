local dlg 

-- 🔹 存储节点绘制位置（用于点击检测）
local node_positions = {}
local customButton = {
    bounds = Rectangle(5, 5, 20, 20),
    state = {
        normal = {part = "button_normal", color = "button_normal_text"},
        hot = {part = "button_hot", color = "button_hot_text"},
        selected = {part = "button_selected", color = "button_selected_text"},
        focused = {part = "button_focused", color = "button_normal_text"}
    },
    text = "Custom Button",
    onclick = function() print("Clicked <Custom Button>") end
}
local NodeButtonLeft = {
    bounds = Rectangle(5, 50, 40, 20),
    state = {
        normal = {
            part = "drop_down_button_left_normal",
            color = "button_normal_text"
        },
        hot = {part = "drop_down_button_left_hot", color = "button_hot_text"},
        selected = {
            part = "drop_down_button_left_selected",
            color = "button_selected_text"
        },
        focused = {
            part = "drop_down_button_left_focused",
            color = "button_normal_text"
        }
    },
    text = "Search",
    onclick = function() print("Clicked <Search Button Left>") end
}

local NodeButtonRight = {
    bounds = Rectangle(65, 50, 20, 20),
    state = {
        normal = {
            part = "drop_down_button_right_normal",
            color = "button_normal_text"
        },
        hot = {part = "drop_down_button_right_hot", color = "button_hot_text"},
        selected = {
            part = "drop_down_button_right_selected",
            color = "button_selected_text"
        },
        focused = {
            part = "drop_down_button_right_focused",
            color = "button_normal_text"
        }
    },
    icon = "tool_zoom",
    onclick = function() print("Clicked <Search Button Right>") end
}

-- 存储骨骼数据的树形结构
local skeleton_tree = {name="root",NodeButtonLeft, NodeButtonRight,children={}}

local bone_label_ids = {} 
local node_list = {}  -- 存储所有节点的名称
local node_map = {}   -- 用于映射名称到节点对象
local canvas_size = { width = 20, height = 20 }
local icon_path = "d:/bone.png"
local custom_icon = Image{ fromFile = icon_path}


-- 获取骨骼层级字符串（用于 label 显示）
local function getSkeletonHierarchy()
    return table.concat(generateIndentedList(skeleton_tree, ""), "\n")
end



-- 递归打印树结构
function print_skeleton_tree(node, depth)
    depth = depth or 0
    local indent = string.rep("+", depth) -- 用空格缩进表示层级关系
    --print(indent .. node.name) -- 打印当前节点名称
	local label_id = "bone_label_" .. depth
	local node_id = "node_name_" .. depth
	local label_name = node.name
	dlg:canvas{ 
		id = "canvas_"..depth,
		 width = 300,
		height = 200,
		onpaint = function(ev)
        node_positions = {}  -- 清空旧的节点位置
        draw_skeleton(ev, skeleton_tree, 10, 10, 0)
    end,
    onmousedown = on_canvas_click
		} 

end
-- 递归函数：在骨骼树中添加节点
function add_skeleton_node(parent, name)
    local node = { name = name, NodeButtonLeft, NodeButtonRight,children = {} }
    table.insert(parent.children, node)
    return node -- 返回新创建的节点，方便继续添加子节点
end
function collect_nodes(node)
    table.insert(node_list, node.name)  -- 存入下拉列表
    node_map[node.name] = node           -- 存入映射表

    for _, child in ipairs(node.children) do
        collect_nodes(child) -- 递归添加子节点
    end
end
-- 添加骨骼节点
local function addBoneNode()
    local sprite = app.activeSprite
    if not sprite then
        app.alert("请先打开一个文件")
        return
    end

    local boneName = dlg.data.bone_name
    local selected_name = dlg.data.selected_node
    local selected_node = node_map[selected_name] -- 返回选中的节点对象
    if boneName == "" then
        app.alert("请输入骨骼名称")
        return
    end

    local newBone = {name = boneName, children = {}}

    -- 设定父骨骼
    add_skeleton_node(selected_node,boneName)
	
    node_list =  {}
	node_map = {}
	--collect_nodes(skeleton_tree)
    createDiagog()
end

function on_canvas_click(ev)
    local click_x, click_y = ev.x, ev.y

    -- 遍历所有节点位置，检测点击
    for _, entry in ipairs(node_positions) do
        if click_x >= entry.x and click_x <= (entry.x + entry.width) and
           click_y >= entry.y and click_y <= (entry.y + entry.height) then
            print("Clicked on node:", entry.node.name)
            break
        end
    end
end
function createDiagog()
	if dlg then
		dlg:close()
	end
	-- 初始化对话框
	dlg = Dialog("构建骨骼")
	collect_nodes(skeleton_tree) -- 收集所有节点信息
	dlg:entry{id="bone_name", label="骨骼名称"}
	dlg:combobox{
    id = "selected_node",
    label = "选择节点:",
    options = node_list
	}
	dlg:button{id="add_bone", text="添加骨骼", onclick=addBoneNode}
	dlg:button{id="close", text="关闭", onclick=function() dlg:close() end}
	dlg:canvas{
		id = "skeleton_canvas",
		width = 300,
		height = 200,
		onpaint = function(ev)
			node_positions = {}  -- 清空旧的节点位置
			draw_skeleton(ev, skeleton_tree, 10, 10, 0)
		end,
		onmousedown = on_canvas_click
	}
	dlg:show()
end



-- 🔹 递归绘制骨骼树
function draw_skeleton(ev, node, x, y, depth)
    local icon_size = 16  -- icon 尺寸
    local spacing = 5     -- 节点间距
    local indent = depth * 20  -- 缩进

    -- 记录节点位置（用于点击检测）
    table.insert(node_positions, {
        node = node,
        x = x + indent,
        y = y,
        width = icon_size + spacing + 100, -- icon + 文字宽度
        height = icon_size
    })


    -- 画文本
    ev.context:fillText(node.name,x + indent + spacing, y)
	local textSize= ev.context:measureText(node.name)
	ev.context:drawImage(custom_icon,x + indent + textSize.width + spacing,y-4)

    -- 递归画子节点
    local new_y = y + icon_size + spacing
    for _, child in ipairs(node.children) do
        new_y = draw_skeleton(ev, child, x, new_y, depth + 1)
    end

    return new_y
end


createDiagog()