
function CELLSELECT_ON_INIT(addon, frame)
	addon:RegisterMsg('CELL_CASTING_START', 'ON_CELL_CASTING_START');
	addon:RegisterMsg('CELL_REMAIN_COUNT', 'ON_CELL_REMAIN_COUNT');
end

