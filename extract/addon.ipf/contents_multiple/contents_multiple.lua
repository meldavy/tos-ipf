function CONTENTS_MULTIPLE_ON_INIT(addon, frame)
	addon:RegisterMsg('CONTENTS_MULTIPLE_OPEN', 'ON_CONTENTS_MULTIPLE_OPEN');
	addon:RegisterMsg('CONTENTS_MULTIPLE_OPEN_CONTENTS', 'ON_CONTENTS_MULTIPLE_OPEN_CONTENTS');	
	addon:RegisterMsg('CONTENTS_MULTIPLE_CLOSE', 'ON_CONTENTS_MULTIPLE_CLOSE');
end

function ON_CONTENTS_MULTIPLE_OPEN(frame, msg, argStr, argNum)
	local contents_multiple = ui.GetFrame('contents_multiple')
	contents_multiple:ShowWindow(1)
	contents_multiple:SetUserValue('ITEM_STR_ARG', argStr)
	if argNum ~= nil then
		contents_multiple:SetUserValue("MSG_BOX_CHECK_FLAG", argNum);
	end
end

function ON_CONTENTS_MULTIPLE_OPEN_CONTENTS(frame, msg, argStr, argNum)
	local contents_multiple = ui.GetFrame('contents_multiple');
	if contents_multiple ~= nil then
		contents_multiple:ShowWindow(1);
		if argStr ~= nil then
			local str_list = StringSplit(argStr, '/');
			if str_list ~= nil and #str_list > 0 then
				for i = 1, #str_list do
					if i == 1 then contents_multiple:SetUserValue("ITEM_STR_ARG", str_list[i]);
					elseif i == 2 then contents_multiple:SetUserValue("CONTENTS_NAME", str_list[i]); end
				end
			end
		end

		if argNum ~= nil then
			contents_multiple:SetUserValue("MSG_BOX_CHECK_FLAG", argNum);
		end
	end
end

function OPEN_CONTENTS_MULTIPLE(frame)
	ui.OpenFrame('inventory')
	CONTENTS_MULTIPLE_INIT(frame)
	INVENTORY_SET_CUSTOM_RBTNDOWN('CONTENTS_MULTIPLE_INVENTORY_RBTN_CLICK')
end

function CLOSE_CONTENTS_MULTIPLE(frame)
	ui.CloseFrame('inventory')
	INVENTORY_SET_CUSTOM_RBTNDOWN('None')
end

local function SET_TARGET_SLOT(frame, targetItem)
	local req_str_arg = frame:GetUserValue('ITEM_STR_ARG');
	local slot = GET_CHILD_RECURSIVELY(frame, 'slot');
	local slot_bg_image = GET_CHILD_RECURSIVELY(frame, 'slot_bg_image');
	local text_putonitem = GET_CHILD_RECURSIVELY(frame, 'text_putonitem');
	local text_itemname = GET_CHILD_RECURSIVELY(frame, 'text_itemname');
	if targetItem ~= nil then
		local targetItemObj = GetIES(targetItem:GetObject());
		local str_arg = TryGetProp(targetItemObj, 'StringArg', 'None')
		if req_str_arg ~= str_arg then
			ui.SysMsg(ClMsg('IMPOSSIBLE_ITEM'));
			return;
		end
		
		SET_SLOT_ITEM(slot, targetItem);
		text_itemname:SetText(targetItemObj.Name);
		slot_bg_image:ShowWindow(0);
		text_putonitem:ShowWindow(0);
	else
		slot:ClearIcon();
		text_itemname:SetText('');
		slot_bg_image:ShowWindow(1);
		text_putonitem:ShowWindow(1);
	end
end

local function GET_TARGET_SLOT_ITEM(frame)
	local slot = GET_CHILD_RECURSIVELY(frame, 'slot');
	local icon = slot:GetIcon();
	if icon == nil then
		return nil;
	end

	local targetItem = session.GetInvItemByGuid(icon:GetInfo():GetIESID());
	if targetItem == nil then
		return nil;
	end
	return targetItem;
end

local function CHECK_PARTY_LOCATE()
	local party_list = session.party.GetPartyMemberList(PARTY_NORMAL);
	local count = party_list:Count();
	local myAID = session.loginInfo.GetAID();
	local myMapID = session.GetMapID();
	local myChannel = session.loginInfo.GetChannel();

	for i = 0, count - 1 do
		local partyMemberInfo = party_list:Element(i);
		if partyMemberInfo:GetAID() ~= myAID then
			local mapID = partyMemberInfo:GetMapID();
			local channel = partyMemberInfo:GetChannel();
			if mapID <= 0 then -- ???????????? ???????????? ??????
				return false;
			elseif mapID ~= myMapID or channel ~= myChannel then -- ?????? ?????? ???????????? ??????
				return false;
			end
		end
	end
	return true;
end

function CONTENTS_MULTIPLE_INIT(frame)
	if ui.CheckHoldedUI() == true then
		return;
	end
	frame = frame:GetTopParentFrame();
	SET_TARGET_SLOT(frame, nil)
end

function CONTENTS_MULTIPLE_INVENTORY_RBTN_CLICK(itemObj, invSlot, invItemGuid)
	local frame = ui.GetFrame('contents_multiple');
	if invSlot:IsSelected() == 1 then
		CONTENTS_MULTIPLE_INIT(frame);
	else
		CONTENTS_MULTIPLE_REGISTER_ITEM(frame, invItemGuid);
	end
end

function CONTENTS_MULTIPLE_DROP_ITEM(parent, slot)
	if ui.CheckHoldedUI() == true then return; end
	local liftIcon = ui.GetLiftIcon();
	local fromFrame = liftIcon:GetTopParentFrame();
	local toFrame = parent:GetTopParentFrame();
	if fromFrame:GetName() == 'inventory' then
		local iconInfo = liftIcon:GetInfo();
		CONTENTS_MULTIPLE_REGISTER_ITEM(toFrame, iconInfo:GetIESID());
	end
end

function CONTENTS_MULTIPLE_REGISTER_ITEM(frame, invItemID)
	if ui.CheckHoldedUI() == true then return; end
	local targetItem = session.GetInvItemByGuid(invItemID);
	SET_TARGET_SLOT(frame, targetItem);
end

function CONTENTS_MULTIPLE_EXECUTE(parent, ctrl)
	local frame = parent:GetTopParentFrame();
	local slot = GET_CHILD_RECURSIVELY(frame, 'slot');
	local icon = slot:GetIcon();
	if icon == nil or icon:GetInfo() == nil then
		ui.SysMsg(ClMsg('NotExistTargetItem'));
		return;
	end

	local multiple_item = GET_TARGET_SLOT_ITEM(frame);
	if multiple_item.isLockState == true then
		ui.SysMsg(ClMsg('MaterialItemIsLock'));
		return;
	end

	local targetItemID = icon:GetInfo():GetIESID();
	local yesscp = string.format('_CONTENTS_MULTIPLE_EXECUTE("%s")', targetItemID);;

	local msgBoxCheckFlag = frame:GetUserValue("MSG_BOX_CHECK_FLAG");
	local clMsg = 'ReallyUseContentsMultiple';
	if CHECK_PARTY_LOCATE() == false and tonumber(msgBoxCheckFlag) ~= 1 then
		clMsg = 'SomePartyMembersAreNotExists';
	end

	local multiple_item_obj = GetIES(multiple_item:GetObject());
	local msgBox = ui.MsgBox(ScpArgMsg(clMsg, 'Name', TryGetProp(multiple_item_obj, 'Name', 'None')), yesscp, '');
	SET_MODAL_MSGBOX(msgBox);
end

function _CONTENTS_MULTIPLE_EXECUTE(targetItemID)
	local frame = ui.GetFrame('contents_multiple')
	if frame:IsVisible() == 0 then
		return;
	end

	local targetInvItem = session.GetInvItemByGuid(targetItemID)
	if targetInvItem == nil then
		ui.SysMsg(ClMsg('NotExistTargetItem'))
		CONTENTS_MULTIPLE_INIT(frame)
		return;
	end

	if targetInvItem.isLockState == true then
		ui.SysMsg(ClMsg('MaterialItemIsLock'))
		CONTENTS_MULTIPLE_INIT(frame)
		return;
	end

	local argStr = targetItemID;
	local content_name = frame:GetUserValue("CONTENTS_NAME");
	if content_name ~= nil and content_name ~= "None" then
		pc.ReqExecuteTx_Item("USE_CONTENTS_MULTIPLE_CONTENTS", argStr);		
	else
		pc.ReqExecuteTx_Item("USE_CONTENTS_MULTIPLE", argStr);
	end
end

function ON_CONTENTS_MULTIPLE_CLOSE(frame, msg, argStr, argNum)
	local contents_multiple = ui.GetFrame('contents_multiple');
	contents_multiple:ShowWindow(0);
end