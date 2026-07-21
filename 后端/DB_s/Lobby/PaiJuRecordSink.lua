package.path = require("./lua/DB_s/Head").path

local tBase = require("base") -- 基础功能接口
local redis = require("redis") -- Redis数据库接口
local api = require("publicApi") -- 共用功能接口
local tname = require("typename") -- 类弄定义接口
local tErr = require("ErrorSink") -- 捕捉错误
local ProtoMgr = require("ProtoManager") -- 协议管理对象 
local cjson = require("cjson") -- 数据交换格式

PaiJuRecordSink = {
    
    _LuaFun = {
       InsertTable_ = table.insert,
    },
}

local function RecordDB_executeSQL(sql)
    local cursor = assert(dbSink.RecordDB_connect:execute(sql))
    if type(cursor) =="number" then
        return cursor
    end
    local rows ={}
	repeat
		row = cursor:fetch({}, "a")
		while row do
			rows[#rows+1]=row
			row = cursor:fetch(row, "a")
		end
		cursor:close()
		cursor = dbSink.RecordDB_connect:nextres()
	until(cursor == 0)		
    return rows
end


function PaiJuRecordSink.PaiJuStatistic(sReturnKey, sData, nLen)

	local ReadData = base.GetRP().new(sData, nLen)
	local nSystemID = ReadData:GetModuleID()
	local nNewsID = ReadData:GetMsgID()
	local sJsonStr = ReadData:GetString()

	--tBase.Log("PaiJuStatistic   %s",sJsonStr or "nil")

	local tRoundStatistic = cjson.decode(sJsonStr)

	local rows =RecordDB_executeSQL(string.format("INSERT INTO PaiJu(RoomType) VALUES(%d);",tRoundStatistic.nRoomType))
	local rows =RecordDB_executeSQL("SELECT LAST_INSERT_ID() AS ID;")
	tBase.Log("SELECT LAST_INSERT_ID() AS ID ==>%s",cjson.encode(rows))

	if #rows ==0 then
		return
	end

	local roundID =rows[1].ID
	for _,item in ipairs(tRoundStatistic.tInfos) do
		local sql =string.format("INSERT INTO PaiJuStatistic VALUES(%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d);",
			roundID, 
			item.nUserID,
			item.nDrawCnt,
			item.nOutCnt,
			item.nActionCnt,
			item.nTingTime,
			item.nTingDex,
			item.nActionCntAfterT,
			item.nDrawCntAfterT,
			item.nOutCntAfterT,
			item.nIsHu,
			item.nIsRobot)
			RecordDB_executeSQL(sql)
	end

end

-- 获取牌局记录列表
function PaiJuRecordSink.GetPaiJuList(sReturnKey, sData, nLen)

    local ReadData = base.GetRP().new(sData, nLen)
	local nSystemID = ReadData:GetModuleID()
	local nNewsID = ReadData:GetMsgID()
    
    local Read = ProtoMgr.PubProto_pb.RUQ_PaiJuRecord()
    Read:ParseFromString(ReadData:GetString())
    local nClientID = Read.nClientID
    local nUserID = Read.nUserID
    local nPages =  Read.nPages

	local sSql = "Call PaiJuRecord_GetList("..nUserID..","..nPages..")"
	
	local nPaiJuID = 0
	local nRoomType = 0
	local nMaxCount = 0 
	local nCollect = 0  
	local sTempData = ""
    local nIndex = 0
    local tData = {}
    local nTotal = 0 -- 总条数

	tBase.Log( " nClientID:"..nClientID.." nUserID: "..nUserID.." 请求nPages:"..nPages.." 获取玩家的历史列表的sql: %s ", sSql)
	local cursor = assert(dbSink.RecordDB_connect:execute(sSql))
	repeat
		local row = cursor:fetch({}, "a")
		while row do
			function GetRes(row)
                local tmp = {}
				tmp.nPaiJuID = row.PaiJuRecordId
				tmp.sSession = row.Session
				tmp.nProfit =  tonumber(row.Profit)
				tmp.sRecordTime = row.RecordTime
                tmp.nMaxCount = tonumber(row.MaxCount)
                nTotal = tmp.nMaxCount
                PaiJuRecordSink._LuaFun.InsertTable_(tData,tmp)
                tBase.Log(" nIndex:"..(nIndex+1).." cjson tData:%s",cjson.encode(tmp) )
			end
			-- 捕获异常,输出错误日志
            xpcall(GetRes,tErr.tpLog, row)
			nIndex = nIndex + 1
			row = cursor:fetch(row, "a")
		end
		cursor:close()
		cursor = dbSink.RecordDB_connect:nextres()
	until(cursor == 0)

    local s = tBase.GetSP().new(nSystemID, nNewsID)
    local tSend = ProtoMgr.PubProto_pb.RUP_PaiJuRecord()
    tSend.nClientID = nClientID
    tSend.nUserID = nUserID
    tSend.nTotal = nTotal
    tSend.nPages = nPages
    tSend.nCount = #tData
    
    for i = 1, #tData do
        local tItem = tSend.tPaijuStruct:add()
        tItem.nPaiJuID = tData[i].nPaiJuID
        tItem.sSession = tData[i].sSession
        tItem.nProfit = math.modf(tData[i].nProfit)
        tItem.sRecordTime = tData[i].sRecordTime
    end

    s:AddString(tSend:SerializeToString())
	tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
	tBase.Log("  ------------------ 一页牌局记录包大小：  "..s:GetSize())
	tBase.Log("读取数据库完毕 玩家的请求第%d页历史列表 共(%d)条数据",nPages, #tData)

end

-- 获取牌局记录
function PaiJuRecordSink.GetRecord(sReturnKey, sData, nLen)
    local ReadData = base.GetRP().new(sData, nLen)
	local nSystemID = ReadData:GetModuleID()
	local nNewsID = ReadData:GetMsgID()
	local sPaiJuId = ReadData:GetString()
	local sClientID = ReadData:GetString()
	local sSql = "Call PaiJuRecord_Read("..sPaiJuId..")"	
	local sUsrInfo = ""
	local sRoomInfo = ""
	local nRoomType = -1
	local sTableInfo = ""
	local sFullHand = ""
	local sShowHand = ""
	local sTablePai = ""
    local sHuWhat = ""
	local sMaPai = ""
	local sDetailedScore = ""
	local sTempData = ""
	local nResult = 0
	local nIndex = 0 
	local sExData = ""   
	tBase.Log("获取玩家的历史牌局的sql:%s ", sSql)
	local cursor = assert(dbSink.RecordDB_connect:execute(sSql))
	repeat
		local row = cursor:fetch({}, "a")
		while row do
			function GetRes(row)
				sUsrInfo = row.UsrInfo
				-- sUsrInfo = PaiJuRecordSink.StringSpilt(sUsrInfo)  -- 对特殊昵称字符处理
				sRoomInfo = row.RoomInfo
				sTableInfo = row.TableInfo	
				nRoomType = tonumber(row.RoomType)
				sFullHand = row.FullHand
				sShowHand = row.ShowHand
				sTablePai = row.TablePai
				sHuWhat = row.HuWhat
				sMaPai = row.MaPai
				sDetailedScore = row.DetailedScore
				sExData = row.ExData or "null"
				tBase.Log("sExData:"..sExData)
				--if(sDetailedScore=='')then sDetailedScore='null_string' end
				-- if nRoomType == -1 then -- 原来数据没有处理
				-- 	tBase.Log(" 旧牌局记录数据 需要处理一下 ")
				-- 	nRoomType = PaiJuRecordSink.DiposesTableInfo(sTableInfo)
				-- 	nResult = 1   -- 更新数据
				-- end

				local tJson ={}
				tJson[1]= sUsrInfo
				tJson[2]= sRoomInfo
				tJson[3]= sTableInfo
				tJson[4]= sFullHand
				tJson[5]= sShowHand
				tJson[6]= sTablePai
				tJson[7]= sHuWhat
				tJson[8]= sMaPai
				tJson[9]= sDetailedScore
				tJson[10]= nRoomType
				tJson[11]= sExData
				sTempData =cjson.encode(tJson)
				--cjson.encode()
				--sTempData = sUsrInfo.."}"..sRoomInfo.."}"..sTableInfo.."}"..sFullHand.."}"..sShowHand.."}"..sTablePai.."}"..sHuWhat.."}"..sMaPai.."}"..sDetailedScore.."}"..nRoomType.."}"..sExData.."}"
				--tBase.Log("读取数据库，仔细的历史牌局信息  --->玩家信息：%s,房间信息：%s,牌桌信息：%s ,初始手牌：%s ,结束手牌：%s ,仔细信息：%s ,胡的番型：%s ,马牌信息：%s ,分数明细：%s ",房间类型： %d
				--sUsrInfo, sRoomInfo,sTableInfo,sFullHand,sShowHand,sTablePai,sHuWhat,sMaPai,sDetailedScore)
			end
			-- 捕获异常,输出错误日志
            xpcall(GetRes,tErr.tpLog, row)
			--tBase.Log("组合成%s",sData)
			nIndex = nIndex + 1
			row = cursor:fetch(row, "a")
		end
		cursor:close()
		cursor = dbSink.RecordDB_connect:nextres()
	until(cursor == 0)
	--tBase.Log("%s组合成%s",sClientID,sTempData)
	-- local s = tBase.GetSP().new(tPubProto.MAIN.DB, tPubProto.SUB_DB.SUB_REP_READ_RECORD)
	-- s:AddString(sClientID)
	-- local arr = tApi.CutString(sTempData, 1000)
 --    s:AddInt32(#arr)
 --    for i = 1, #arr do
 --        s:AddString(arr[i])
 --    end	
	-- tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())
	tBase.Log("读取数据库完毕，玩家的历史牌局")
	tBase.Log("  ------------------  一条牌局记录大小：  "..s:GetSize())	
	-- if nResult == 1 then 
	-- 	tBase.Log(" 更新 旧数据中 的房间类型      ")	 
	-- 	PaiJuRecordSink.PaiJuRecord_Update_RoomType(sPaiJuId,nRoomType)
	-- end 
end

-- 更新 旧数据的房间类型 
function PaiJuRecordSink.PaiJuRecord_Update_RoomType(sPaiJuId,tData)
	tBase.Log(" 更新     牌局记录房间类型   sPaiJuId:  %d   %d   ",sPaiJuId,nRoomType )
	local sSql = "Call PaiJuRecord_Update_RoomType("..sPaiJuId..","..tData.nRoomType..","..tData.sTableInfo..")"
	local nRuslt = 1
	local nIndex = 0
	local cursor = assert(dbSink.RecordDB_connect:execute(sSql))
	repeat
		local row = cursor:fetch({}, "a")
		while row do
			function GetRes(row)
				nRuslt = row.Ruslt
			end
			-- 捕获异常,输出错误日志
            xpcall(GetRes,tErr.tpLog, row)
			nIndex = nIndex + 1
			row = cursor:fetch(row, "a")
		end
		cursor:close()
		cursor = dbSink.RecordDB_connect:nextres()
	until(cursor == 0)
	if nRuslt == 0 then 	
		tBase.Log(" 更新   牌局记录房间类型    完成   "	)
	else
		tBase.Log(" 更新   牌局记录房间类型    失败 Error_Info==2103  "	)
	end 
	return
end

-- 对昵称的特殊字符串  解码处理： 
function PaiJuRecordSink.StringSpilt(sString)
	tBase.Log(" 牌局记录 -----sString:   "..sString)
	local tUserInfo = tApi.Split(sString,":")
	local sData = ""
	local tData = ""

	for i=1,#tUserInfo do
		local tUser = tApi.Split(tUserInfo[i],"#")
		for y=1,#tUser do
			if y == 3 then 	
	   			tUser[y]  = tBase64.decode(tUser[y])    -- 对昵称 解码
	   		end 
			tData = tData..tUser[y].."#"
		end
		sData = tData .. ":"
	end
	tBase.Log(" 牌局记录 -----sData:   "..sData)	
	return sData
end

function PaiJuRecordSink.HandleCollect(sReturnKey, sData, nLen)

    local ReadData = base.GetRP().new(sData, nLen)
	local nSystemID = ReadData:GetModuleID()
	local nNewsID = ReadData:GetMsgID()
    local nUsrId = ReadData:GetInt32()
    local nPaiJuId = ReadData:GetInt32()
    local nCollectFlag = ReadData:GetInt32()
	local sClientID = ReadData:GetString()
	local nReturn = -1
    local nIndex = 0
	local sSql = "Call PaiJuRecord_Collect("..nUsrId..","..nPaiJuId..","..nCollectFlag..")"


	local cursor = assert(dbSink.RecordDB_connect:execute(sSql))
	repeat
		local row = cursor:fetch({}, "a")
		while row do

			function GetRes(row)
				nReturn = row.nReturn
			end

			-- 捕获异常,输出错误日志
            xpcall(GetRes,tErr.tpLog, row)

			nIndex = nIndex + 1
			row = cursor:fetch(row, "a")
		end
		cursor:close()
		cursor = dbSink.RecordDB_connect:nextres()
	until(cursor == 0)

	-- local s = tBase.GetSP().new(tPubProto.MAIN.DB, tPubProto.SUB_DB.SUB_REP_COLLECT)

	-- s:AddInt32(nPaiJuId)
	-- s:AddInt32(nReturn)
	-- s:AddString(sClientID)

	-- tBase.PostToClient(sReturnKey, s:GetData(), s:GetSize())



	tBase.Log("存储数据库，牌局的收藏信息  --->玩家ID：%d,牌局ID：%d ,收藏Flag：%d",
	nUsrId, nPaiJuId,nCollectFlag)

    
	tBase.Log("处理完毕")
end

-- 处理旧数据
function PaiJuRecordSink.DiposesTableInfo(sTableInfo)
	tBase.Log(" 牌局记录 -----sTableInfo:   "..sTableInfo)	
	local tTableInfo = tApi.Split(sTableInfo,"#")
	local nRoomType = 0
	for i=1,#tTableInfo do
		if i == 3 then 
			if tTableInfo[i] ~= 0 then 
				nRoomType = 1
			end 
		end 
	end
 --    tBase.Log(" 牌局记录     旧数据操作 拼接新数据    ")
 --    local sData = ""
 --    for y=1,#tTableInfo do
 --    	if y == 1 then 
 --    		sData = sData..nRoomType.."#"
 --    	end 
 --    	sData = sData..tTableInfo[y].."#"
 --    end
	-- tBase.Log(" 牌局记录 -----sData:   "..sData)	
	return nRoomType
end

-- 获取房间类型
function PaiJuRecordSink.GetPosData(nPos,sTableInfo)
	tBase.Log(" 牌局记录    获取牌桌数据   nPos:    %d ",nPos)
	-- tBase.Log(" 牌局记录 -----GetRoomType   sTableInfo:   "..sTableInfo)
	local nRoomType =  0
	local tTableInfo = tApi.Split(sTableInfo,"#")
	for i=1,#tTableInfo do
		if i == nPos then 
			nRoomType =  tTableInfo[i]
			tBase.Log(" 牌局记录 -----------:   "..tTableInfo[i])	
			return nRoomType
		end 
	end
	return -1 
end


function PaiJuRecordSink.GetGameType(sTableInfo)

    local nPageEnd = string.find(sTableInfo, "#", 1)
	local nPageStart = string.find(sTableInfo, "#", nPageEnd + 1)
	local nPageEnd = string.find(sTableInfo, "#", nPageStart + 1)
	return tonumber(string.sub(sTableInfo, nPageStart+1, nPageEnd-1))
	
end



function PaiJuRecordSink.GetGameNumber(sUsrInfo,sUsrId)

    local ntemp = 0
    local nPageStart = string.find(sUsrInfo, sUsrId, 1 )
	local nPageEnd = string.find(sUsrInfo, ":", nPageStart)
	
	
	--tBase.Log("nPageEnd111："..nPageEnd)

	if nPageEnd == nil then nPageEnd = string.len(sUsrInfo) 
	else
		nPageEnd = nPageEnd - 1
	end
	local sUsrData = string.sub(sUsrInfo, nPageStart, nPageEnd)
	local sUsrSit  = ""

	
	--tBase.Log("sUsrData :%s,nPageEnd222：%d",sUsrData,nPageEnd)

	--tBase.Log("GetGameNumber截取的字符串是：%s",sUsrData)

	nPageStart = string.find(sUsrData, "#", 1 )	
	--tBase.Log("GetGameNumber截取的字符串111是：%s",string.sub(sUsrData, 1, nPageStart))
   ntemp = string.find(sUsrData, "#", nPageStart + 1 )
	--tBase.Log("GetGameNumber截取的字符串222是：%s",string.sub(sUsrData,nPageStart, ntemp))
	sUsrSit = string.sub(sUsrData,nPageStart + 1 , ntemp - 1 )
	nPageStart = string.find(sUsrData, "#", ntemp + 1 )	
	--tBase.Log("GetGameNumber截取的字符串333是：%s",string.sub(sUsrData, ntemp, nPageStart))
    ntemp = string.find(sUsrData, "#", nPageStart + 1 )
    nPageStart = ntemp
	--tBase.Log("GetGameNumber截取的字符串444是：%s",string.sub(sUsrData,nPageStart , ntemp))
	nPageEnd = string.find(sUsrData, "#", ntemp + 1 )
	
	--tBase.Log("GetGameNumber截取的字符串555是：%s",string.sub(sUsrData, nPageStart+1, nPageEnd))

	return sUsrSit.."#"..string.sub(sUsrData, nPageStart+1, nPageEnd - 1), sUsrSit
end

function PaiJuRecordSink.GetLocalShowHand(sSit, sShowHand)

	sShowHand = ":"..sShowHand..":"
	sSit = sSit.."#"

	tBase.Log("GetLocalShowHand：%s",sShowHand)

	local sRes = string.sub(sShowHand, string.find(sShowHand, ":"..sSit.."[^:]+:"))
	return string.gsub(sRes, ":", "")
end

return PaiJuRecordSink

