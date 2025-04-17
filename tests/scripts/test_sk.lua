local dlg 
local cmdDlg
local max_child = 8  
local radius = 5
local row_space = 10
local colum_space = 10
local max_depth = 4
local bone_sprite = nil
local bone_layer = nil
local sk_layer_name = "BoneTree"
-- 存储骨骼数据的树形结构
local skeleton_tree = {name="root",x=64,y=64,NodeButtonLeft, NodeButtonRight,children={},index = 1,parent=nil,depth=1,image=nil,offset_x=0,offset_y=0}
local bone_label_ids = {} 
local node_list = {}  -- 存储所有节点的名称
local node_map = {}   -- 用于映射名称到节点对象
local canvas_size = { width = 20, height = 20 }
local icon_path = "d:/bone.png"
local custom_icon = Image{ fromFile = icon_path}
local dragging_index = nil
local target_point =  nil
local node_radius = 10  -- 每个节点的半径
local selected_node = skeleton_tree  -- 记录当前点击的骨骼节点

---select size at first

local sizes = {
  { label = "128x128", width = 128, height = 128 },
  { label = "192x192", width = 192, height = 192 },
  { label = "256x256", width = 256, height = 256 },
  { label = "512x512", width = 512, height = 512 },
  { label = "1024x1024", width = 1024, height = 1024 },
}
local selected_size = sizes[1]

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

local function create_skeleton_sprite()
	if bone_sprite == nil then	
	-- *create Sprite for skeleton**
		bone_sprite = Sprite(selected_size.width, selected_size.height,ColorMode.RGBA)  -- 创建 400x400 大小的新 Sprite  selected_size
		bone_sprite.transparentColor = Color(0,0,0,0)
		bone_sprite.filename = "skeleton_sprite"
	end
	if bone_layer == nil then
		  bone_layer =  bone_sprite.layers[1] 
		 -- local cel = bone_sprite:newCel(bone_layer,1)
		  bone_layer.name = sk_layer_name
		 -- bone_layer.stackIndex = 100
		--spr:newCel(bone_layer,1)
	end
end
local function moveSkLayer2Top()
	if bone_sprite == nil then
	   app.alert("Not found skeleton sprite")
	   return
	end
	if bone_layer then 
		local newSkLayer = bone_sprite:newLayer()
		--newSkLayer.name = sk_layer_name
		for _,cel in ipairs(bone_layer.cels) do
			local newImage = cel.image:clone()
			bone_sprite:newCel(newSkLayer,cel.frameNumber,newImage,cel.position)
			
		end
		bone_sprite:deleteLayer(bone_layer)
		bone_layer = newSkLayer
		bone_layer.name = sk_layer_name
	end
		
end
local function findBondLayer()
	for _,layer in ipairs(bone_sprite.layers) do
	   if layer.name == sk_layer_name then
	      bone_layer = layer
		  break
	   end
	end
end

local function freshSprite() 
	--local image = cel.image
	--local layer = spr.layers[1]
	--if not bone_layer:cel(1) then
	   
	local image = bone_layer:cel(1).image
	image:clear()
	-- **调用递归函数绘制骨骼树**
	drawBoneTree(spr,skeleton_tree)  -- 以 root 节点为根绘制

	-- **显示新创建的 Sprite**
	app.selectprite = spr
	app.refresh()
end
-- 获取骨骼层级字符串（用于 label 显示）
local function getSkeletonHierarchy()
    return table.concat(generateIndentedList(skeleton_tree, ""), "\n")
end

local function add_skin_layer(skinLayer_name)
	local src_cel = nil
	local src_spr = app.sprite
	local src_layer = nil
	for _,layer in ipairs(src_spr.layers) do
		if layer.isImage and layer.name ~= sk_layer_name and layer.name ~= skinLayer_name then
		   src_cel = layer:cel(1)
		   if src_cel then
		      src_layer = layer
			  break
			end
		end
	end
	
	if not src_cel then
	   app.alert("not select a layer")
	   return
	end
	local selection = app.sprite.selection
	if  selection.isEmpty then 
	   app.alert("not selection a region")
	   return
	end
	local skin_layer = bone_sprite.layers[skinLayer_name]
	if skin_layer == nil then
	   skin_layer = bone_sprite:newLayer()
	   skin_layer.name = skinLayer_name
	   --skin_layer.stackIndex = 1
	end
	local skin_cel = skin_layer:cel(1)
	if not skin_cel then
		skin_cel= bone_sprite:newCel(skin_layer,1)
	end

	local bounds = selection.bounds
	local w,h = bounds.width, bounds.height
	
	--print("w:"..w.."h:"..h.."x:"..bounds.x.."y:"..bounds.y)
	local src_img = src_cel.image
	local croppedImg = Image(w,h,src_spr.colorMode)
	for y = bounds.y, bounds.y+bounds.height - 1 do 
	    for x = bounds.x, bounds.x + bounds.width - 1 do
		  if selection:contains(x,y) then
				local color = src_img:getPixel(x,y)
				croppedImg:putPixel(x-bounds.x,y-bounds.y,color)
				--croppedImg:putPixel(x,y,color)
			end
		end
	end
	--croppedImg:drawImage(src_img,Point(-bounds.x,-bounds.y))
	--skin_cel.image:drawImage(croppedImg,0,0)
	skin_cel.image:drawImage(croppedImg,selected_node.x ,selected_node.y)
	selected_node.image = croppedImg
	--selected_node.point = Poinet()
	--moveSkLayer2Top()
	app.refresh()
end

	







-- 递归函数：在骨骼树中添加节点
function add_skeleton_node(parent, name)
    local x = parent.x + row_space   -- * parent.depth
	local y = parent.y + colum_space * parent.index
	local depth = parent.depth + 1
    local node = { name = name, x=x,y=y,NodeButtonLeft, NodeButtonRight,children = {},index=1 ,parent=parent, depth=depth,image=nil,offset_x = 0,offset_y =0}
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

local function drawLine(layer,cel,p1x,p1y, p2x,p2y, color)
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



local function drawCircle(lay,cel,px,py, size,color)
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
        ink = "copy_color",
    }
end

function drawSelectLayerImage()
    local layerName = selected_node.name
	local skin_layer = bone_sprite.layers[layerName]
	if skin_layer == nil then
	  return
	end
	local skin_cel = skin_layer:cel(1)
	if not skin_cel then
		return
	end
	skin_cel.image:clear()
	skin_cel.image:drawImage(selected_node.image,selected_node.x + dlg.data.offset_x,selected_node.y+dlg.data.offset_y )
	app.refresh()
end 

-- 递归绘制骨骼树到 Sprite
function drawBoneTree(spr, node)
  local color = Color { r = 255, g = 255, b = 255, a = 255 }
  
  if bone_layer == nil then
     return
	 
  end
  local cel = bone_layer.cels[1]
  --local pos_y = node.y + colum_space * index 
  --local pos_x = node.x + row_space * node.depth
  --drawCircle(layer,cel,node.x + 10 * node.depth ,node.y + 10* node.index,5,color)
  drawCircle(bone_layer,cel,node.x ,node.y,radius,color)
  if node.parent ~= nil then
  -- 绘制连线（如果有父节点）
	drawLine(bone_layer,cel,node.x,node.y, node.parent.x, node.parent.y, Color(255, 0, 0))  -- 红色连线
  end
  
  --draw skin
  local skin = bone_sprite.layers[node.name] 
  if skin and node.image ~= nil then
	local skin_cel = skin:cel(1)
	skin_cel.image:clear()
	skin_cel.image:drawImage(node.image,node.x,node.y )

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
     drawBoneTree(spr, child)
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

local function move_child(node,offset_x,offset_y)
    for _,child in ipairs(node.children) do 
	   child.x = math.max(0, math.min(app.activeSprite.width - 1, child.x + offset_x))
	   child.y = math.max(0, math.min(app.activeSprite.height - 1, child.y + offset_y))
	   move_child(child,offset_x,offset_y)
	end
end
local function move_point(ev)
	
    if target_point == nil then
	   target_point = get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y, 3)
    end
	if target_point ~= nil then
	   local ori_x = target_point.x
	   local ori_y = target_point.y
	   target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
	   target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
	   dlg:modify { id = "point",text= target_point.name}
	   
	   local offset_x = target_point.x - ori_x 
	   local offset_y = target_point.y - ori_y 
	   move_child(target_point,offset_x,offset_y)
       freshSprite()
    end	
	
	-- if target_point ~= nil then
		-- target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
		-- target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
		-- dlg:modify { id = "point",text= target_point.name}
		-- freshSprite()
	-- else
            -- target_point = get_bone_at_pos(skeleton_tree,ev.point.x, ev.point.y, 3)
            -- if target_point ~= nil then
			   -- target_point.x = math.max(0, math.min(app.activeSprite.width - 1, ev.point.x))
			   -- target_point.y = math.max(0, math.min(app.activeSprite.height - 1, ev.point.y))
			   -- dlg:modify { id = "point",text= target_point.name}
               -- freshSprite()
            -- end
	-- end
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
        if app.activeSprite.selection.isEmpty == false then
            app.command.Cancel()
            app.activeSprite.selection:deselect()
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





function createDiaglog()
	if dlg then
		dlg:close()
	end

	-- 初始化对话框
	dlg = Dialog("Skeleton")
	dlg:label { id = "sprite_size", label = "Size: ", text = selected_size.label }
	--collect_nodes(skeleton_tree) -- 收集所有节点信息
	dlg:label { id = "point", label = "Selected: ", text = "None" }
	dlg:entry{id="bone_name", label="BoneName"}

	dlg:button{id="add_bone", text=" + ", onclick=addBoneNode}
	dlg:button{id="delete_done", text=" - ", onclick=rmBoneChildNode}
	
	dlg_canvas = dlg:canvas{
		id = "skeleton_canvas",
		width = 200,
		height = 200,
		onpaint = function(ev)
			node_positions = {}  -- 清空旧的节点位置
			draw_skeleton(ev, skeleton_tree, 1, 1, 0)
			--ev.context:drawThemeRect("horizontal_symmetry", 200, 100, 100, 100)
		end,
		
		onmousedown = function(ev)
			local click_x, click_y = ev.x, ev.y
			-- 遍历所有节点位置，检测点击
				for _, entry in ipairs(node_positions) do
					if click_x >= entry.x and click_x <= (entry.x + entry.width) and
						click_y >= entry.y and click_y <= (entry.y + entry.height) then
						--showCommandDialog(entry.node)
						selected_node = entry.node
						dlg:modify { id = "offset_x", value = selected_node.offset_x }
						dlg:modify { id = "offset_y", value = selected_node.offset_y }
						
						dlg:repaint()

						return
					end
				end
				selected_node = nil
		end
	}
	dlg:button{id="edit", text="Move", onclick=function() edit_start() end}
	dlg:button{id="bind", text="Bind", onclick=function() 
	                             add_skin_layer(selected_node.name) 
								 --moveSkLayer2Top()
								 end }
	dlg:newrow()

	dlg:slider { id = "offset_x",
            label = "offset_x",
            min = -selected_size.width/2,
            max = selected_size.width/2,
            value = 0,
			onchange=function()  selected_node.offset_x=dlg.data.offset_x drawSelectLayerImage() end 
			}
    dlg:slider { id = "offset_y",
            label = "offset_y",
            min = -selected_size.height/2,
            max = selected_size.height/2,
            value = 0 ,
			onchange= function() selected_node.offset_y=dlg.data.offset_y drawSelectLayerImage() end 
			}
	dlg:slider { id = "rotator",
            label = "rotator",
            min = 0,
            max = 360,
            value = 0 }
	dlg:newrow()
	dlg:button{id="CreateKey", text="CreateKey", onclick=function() dlg:close() end}
	dlg:button{id="Save", text="Save", onclick=function() dlg:close() end}
	dlg:button{id="close", text="Close", onclick=function() dlg:close() end}

	dlg:show{wait = false}
end



local select_size_dlg = Dialog { title = "select resolution" }

-- 添加下拉选项
local select_size_labels = {}
for i, item in ipairs(sizes) do
  table.insert(select_size_labels, item.label)
end

select_size_dlg:combobox{
  id = "size_choice",
  options = select_size_labels,
  option = select_size_labels[1]  -- 默认选择第一个
}

select_size_dlg:button { id = "ok", text = "OK" }
select_size_dlg:button { id = "cancel", text = "Cancel" }

-- 显示对话框并处理结果
select_size_dlg:show()

local select_size_data = select_size_dlg.data
if not select_size_data.ok then
  return -- 用户取消
end

-- 查找用户选择的大小
for _, item in ipairs(sizes) do
  if item.label == select_size_data.size_choice then
    selected_size = item
    break
  end
end


create_skeleton_sprite()

createDiaglog()
