local dlg 
local cmdDlg
local max_child = 8  
local radius = 5
local row_space = 20
local colum_space = 20
local max_depth = 4
local bone_sprite = nil
local bone_layer = nil
local bone_cel = nil
-- 存储骨骼数据的树形结构
local skeleton_tree = {name="root",x=100,y=100,NodeButtonLeft, NodeButtonRight,children={},index = 1,parent=nil,depth=1}
local bone_label_ids = {} 
local node_list = {}  -- 存储所有节点的名称
local node_map = {}   -- 用于映射名称到节点对象
local canvas_size = { width = 20, height = 20 }
local icon_path = "d:/bone.png"
local custom_icon = Image{ fromFile = icon_path}
local dragging_index = nil
local target_point =  nil
local node_radius = 10  -- 每个节点的半径
local selected_node = nil  -- 记录当前点击的骨骼节点
-- 🔹 存储节点绘制位置（用于点击检测）
local node_positions = {}


local function create_bone_sprite()
    if bone_sprite == nil then
		-- **创建新的 Sprite**
		bone_sprite = Sprite(400, 400,ColorMode.RGBA)  -- 创建 400x400 大小的新 Sprite
		bone_sprite.transparentColor = Color(0,0,0,0)
		bone_sprite.filename = "bone_sprite"
		bone_layer = bone_sprite.layers[1]
		bone_layer.name = "BoneTree"
		bone_cel = bone_sprite:newCel(bone_layer,1)
	end
end


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

local function freshSprite() 
	--local image = cel.image
	--local layer = spr.layers["BoneTree"]
	app.layer = bone_layer
	local image = bone_cel.image
	image:clear()
	-- **调用递归函数绘制骨骼树**
	drawBoneTree(skeleton_tree)  -- 以 root 节点为根绘制

	-- **显示新创建的 Sprite**
	--app.selectprite = spr
	--app.refresh()
end
-- 获取骨骼层级字符串（用于 label 显示）
local function getSkeletonHierarchy()
    return table.concat(generateIndentedList(skeleton_tree, ""), "\n")
end




-- 递归函数：在骨骼树中添加节点
function add_skeleton_node(parent, name)
    local x = parent.x + row_space   -- * parent.depth
	local y = parent.y + colum_space * parent.index
	local depth = parent.depth + 1
    local node = { name = name, x=x,y=y,NodeButtonLeft, NodeButtonRight,children = {},index=1 ,parent=parent, depth=depth}
    table.insert(parent.children, node)
	parent.index = parent.index+1
	
    return node -- 返回新创建的节点，方便继续添加子节点
end

-- 添加骨骼节点
local function addBoneNode()
    local boneName = dlg.data.bone_name
	if boneName == "" then
		app.alert("Please input bone node name")
		return
	end
	if selected_node == nil then 
		app.alert("Please select a bone node")
		return
	end
	if selected_node.index >= max_child then
		app.alert("Limited to "..max_child.." siblings node")
		return
	end
	if selected_node.depth > max_depth then
		app.alert("Limited to "..max_depth.." depth")
		return
	end
	local newnode = add_skeleton_node(selected_node,boneName)
	--print("depth:"..newnode.depth.." index:"..newnode.index)
	-- 设定父骨骼
    node_list =  {}
	node_map = {}
	dlg:modify{id = "skeleton_canvas"}
	dlg:repaint()
	freshSprite()
end


-- 添加骨骼子节点
local function addBoneChildNode(node,boneName)
	if boneName == "" then
        app.alert("请输入骨骼名称")
        return
    end


    -- 设定父骨骼
    add_skeleton_node(node,boneName)
	
    node_list =  {}
	node_map = {}
	dlg:modify{id = "skeleton_canvas"}
	dlg:repaint()
end

local function drawLine(layer,sel,p1x,p1y, p2x,p2y, color)
    local line_color = Color { r = 255, g = 255, b = 255, a = 255 }

    local brush = Brush(1)
    app.useTool {
        tool = "line",
        color = line_color,
        points = { Point(p1x,p1y), Point(p2x,p2y) },
        brush = brush,
        layer = layer,
        cel = cel
    }
end



local function drawCircle(lay,sel,px,py, size,color)
    local brush = Brush {
        type = BrushType.CIRCLE,
        size = size,
    }
	local point1 = Point(px, py)
	local x2 = px + 1
	local point2 = Point(x2,py)
    app.useTool {
        tool = "pencil",
        color = color,
        points = {point1,point2},
        brush = brush,
        layer = layer,
        cel = cel,
		frame = bone_sprite.frames[1],
        ink = "copy_color",
    }
end



-- 递归绘制骨骼树到 Sprite
function drawBoneTree(node)
  local color = Color { r = 255, g = 255, b = 255, a = 255 }
  --local bonelayer = spr.layers["BoneTree"]
  --local sel = bonelayer.cels[1]
  --local pos_y = node.y + colum_space * index 
  --local pos_x = node.x + row_space * node.depth
  --drawCircle(layer,cel,node.x + 10 * node.depth ,node.y + 10* node.index,5,color)
  drawCircle(bone_layer,bone_cel,node.x ,node.y,radius,color)
  if node.parent ~= nil then
  -- 绘制连线（如果有父节点）
	drawLine(bone_layer,bone_cel,node.x,node.y, node.parent.x, node.parent.y, Color(255, 0, 0))  
  end
  
  --else
    --drawCircle(layer,cel,node.x,node.y,1,color)
    --drawLine(spr,parent_x, parent_y, root.x, root.y, Color(255, 0, 0))  -- 红色连线

  -- 画骨骼节点
  -- Fill a smaller circle in white
	--ctx.color = Color {r = 255, g = 255, b = 255, a = 255}

	--ctx:beginPath()
	--ctx:roundedRect(Rectangle(20, 20, 60, 60), 30)
	--ctx:fill()
  

  -- 递归绘制子节点
  for i, child in ipairs(node.children) do
     drawBoneTree(child)
  end
end


-- 删除骨骼子节点
local function rmBoneChildNode()
	if selected_node == nil then
	  app.alert("Select a bone node")
	  return
	end 
	if selected_node.parent == nil then	
	  app.alert("Could not delete root bone")
		return
	end
	
	local clickButton = nil
    -- 设定父骨骼
	local comfirmDlg = Dialog("Delete'"..selected_node.name.."'?")
	comfirmDlg:button{"Button_Yes",text="Yes", onclick = function() 
		clickButton = "Button_Yes" 
		local parenNode = selected_node.parent
			for i,node in ipairs(parenNode.children) do
				if node == selected_node then
				table.remove(parenNode.children,i)
				parenNode.index = parenNode.index - 1
				freshSprite()
				break
			end
		end
		selected_node = nil
		node_list =  {}
		node_map = {}
		dlg:modify{id = "skeleton_canvas"}
		dlg:repaint()
		comfirmDlg:close() 
		end
		}
	comfirmDlg:button{"Button_No",text="No", onclick = function() clickButton="Button_No" comfirmDlg:close() end}
	comfirmDlg:show()
	
	
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


-- 显示骨骼命令对话框
function showCommandDialog(node)
    if cmdDlg then
		cmdDlg:close{}
	end
    cmdDlg = Dialog("Modify: " .. node.name)
	cmdDlg:canvas{id="cmdDlg_canva",width=80,height=1}
	--cmdDlg:entry{id="childBone", label="骨骼名称"}
    cmdDlg:button{ id="cmd1", text="Add", onclick=function() 
											local addChildDlg = Dialog{title="add bone to " .. node.name,parent=cmdDlg}
											
											local chilebone_name = ""
											addChildDlg:entry{id="childBone", label="骨骼名称"}
											addChildDlg:button{ id="ok", text="ok", onclick=function() 
														chilebone_name = addChildDlg.data.childBone
														addChildDlg:close() end }
											addChildDlg:show{}
											
											addBoneChildNode(node,chilebone_name)
					
											end
				}
	
	cmdDlg:newrow()
    cmdDlg:button{ id="cmd2", text="Rotate", onclick=function() print(node.name .. " Rotate") end }
	cmdDlg:newrow()
    cmdDlg:button{ id="cmd3", text="Scale", onclick=function() print(node.name .. " Scale") end }
	cmdDlg:newrow()
    cmdDlg:button{ id="cmd4", text="Delete", onclick=function() 
											if selected_node.parent == nil then	
												print("Could not delete root bone")
												return
											end
											
											rmBoneChildNode(); cmdDlg:close() end }
	cmdDlg:newrow()
    cmdDlg:button{ id="close", text="Close", onclick=function() cmdDlg:close() end }
    cmdDlg:show{wait = false}
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
	if node == selected_node then 
		local origialColor = ev.context.color
		ev.context.color = Color(50,200,50)
		ev.context:strokeRect(x+indent+spacing-2,y-4,textSize.width+4,textSize.height+4)
		ev.context.color = origialColor
	end
    -- 递归画子节点

    local new_y = y + icon_size + spacing
    for _, child in ipairs(node.children) do
        new_y = draw_skeleton(ev, child, x, new_y, depth + 1)
    end

    return new_y
end


local function edit_stop()
    app.editor:cancel()
end

function get_bone_at_pos(bone,px, py, size)
	--for i, bone in ipairs(skeleton_tree) do
	local dx = px - bone.x
	local dy = py - bone.y
	if (dx ^ 2 + dy ^ 2) <= size ^ 2 then
      return bone
	else 
	   -- 递归绘制子节点
		local bone_child = nil
		for i, child in ipairs(bone.children) do
			bone_child = get_bone_at_pos(child,px, py, size)
			if bone_child ~= nil then 
			   return bone_child
			end
		end
    end
	return nil
end



-- 判断是否在某个节点上
local function get_bone(mx, my, size)
  for i, bone in ipairs(skeleton_tree) do
	print("node:"..bone.x..":"..bone.y)
    local dx = mx - bone.x
    local dy = my - bone.y
    if (dx ^ 2 + dy ^ 2) <= size ^ 2 then
      return bone
    end
  end
  return nil
end
local function move_point(ev)
	
    if target_point ~= nil then
		target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
		target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
		dlg:modify { id = "point",text= target_point.name}
		freshSprite()
	else
            target_point = get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y, 3)
            if target_point ~= nil then
			   target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
			   target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
			   dlg:modify { id = "point",text= target_point.name}
               freshSprite()
            end
	end
end


local function get_node_at_pos(mouse_pos)
  local index = nil
  local dist_nearest = 10000
  for i, point_order in ipairs(handle_pose.draw_points_order) do
       local p = handle_pose.points[point_order]
       distance_between_points = distance(mouse_position, p.position)
       if distance_between_points <= max_distance ^ 2 and distance_between_points < dist_nearest then
            dist_nearest = distance_between_points
            index = i
            if dist_nearest == 0 then
			  return index
            end
		end
	end 
end

---edit pose
local function edit_skeletion_pose(ev)
	target_point = nil
	target_point =  get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y ,0.99)
	local redraw = false
	--local nearest_point = get_closest_point_index_and_within_distance(new_point, 0.99)
    while node_index ~= nil  do
          new_point.x = new_point.x + 1
          redraw = true
          target_point = get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y ,0.99)
    end

    if redraw then
          target_point.x = ev.point.x
	      target_point.y = ev.point.y
		  freshSprite()
		  app.refresh()
    end
       
end


local function delayed_restart()
        target_point = nil
        --if app.activeSprite.selection.isEmpty == false then
         --   app.command.Cancel()
         --   app.activeSprite.selection:deselect()
        --end
		
		if bone_sprite.selection.isEmpty == false then
		   app.command.Cancel()
		   bone_sprite.selection:deselect()
		end
		
        local timer
        timer = Timer {
            interval = 0.01,
            ontick = function()
                app.editor:askPoint {
                    title = "Edit pose",
                    onclick = function(ev)
                        edit_skeletion_pose(ev)
                        delayed_restart()
						dlg:modify { id = "point", text = "None" }
                       -- handle_pose.dialog_edit:modify { id = "point", text = "None" }
                    end,
                    onchange = function(ev)
                        move_point(ev)
                    end,
                    oncancel = function(ev)
                        edit_stop()
                    end,
                }
                timer:stop()
            end }
        timer:start()
    end



local function edit_start()
    if app.editor ~= nil then
        app.editor:askPoint {
            title = "Edit pose",
            onclick = function(ev)
                delayed_restart()
            end,
            onchange = function(ev) move_point(ev) end,
            oncancel = function(ev)
                edit_stop()
            end,
        }
    end
end 

local function bind_start(skinLayer_name)
	local skin_layer = bone_sprite.layers[skinLayer_name]
	if skin_layer == nil then
	   skin_layer = bone_sprite:newLayer()
	   skin_layer.name = skinLayer_name
	end
end 




function createDiaglog()
	if dlg then
		dlg:close()
	end
	-- 初始化对话框
	dlg = Dialog("构建骨骼")
	--collect_nodes(skeleton_tree) -- 收集所有节点信息
	dlg:label { id = "point", label = "Selected: ", text = "None" }
	dlg_canvas = dlg:canvas{
		id = "skeleton_canvas",
		width = 300,
		height = 200,
		onpaint = function(ev)
			node_positions = {}  -- 清空旧的节点位置
			draw_skeleton(ev, skeleton_tree, 10, 10, 0)
		end,
		
		onmousedown = function(ev)
			local click_x, click_y = ev.x, ev.y
			-- 遍历所有节点位置，检测点击
				for _, entry in ipairs(node_positions) do
					if click_x >= entry.x and click_x <= (entry.x + entry.width) and
						click_y >= entry.y and click_y <= (entry.y + entry.height) then
						--showCommandDialog(entry.node)
						selected_node = entry.node
						dlg:repaint()

						return
					end
				end
				selected_node = nil
		end
	}
	dlg:entry{id="bone_name", label="骨骼名称"}

	dlg:button{id="add_bone", text=" + ", onclick=addBoneNode}
	dlg:button{id="delete_done", text=" - ", onclick=rmBoneChildNode}
	dlg:button{id="bind", text="create", onclick=function() edit_start() end}
	dlg:button{id="bind", text="bind", onclick=function() 
										if selected_node ~= nil then
										  bind_start(selected_node.name)
										end
									   end}
	dlg:button{id="close", text="关闭", onclick=function() dlg:close() end}
	dlg:show{wait = false}
end


create_bone_sprite()
createDiaglog()
