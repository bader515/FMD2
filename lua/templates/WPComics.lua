----------------------------------------------------------------------------------------------------
-- Module Initialization
----------------------------------------------------------------------------------------------------

local _M = {}

----------------------------------------------------------------------------------------------------
-- Local Constants
----------------------------------------------------------------------------------------------------

DirectoryPagination = '/tim-truyen?status=&sort=15&page=%s'

----------------------------------------------------------------------------------------------------
-- Event Functions
----------------------------------------------------------------------------------------------------

-- Get links and names from the manga list of the current website.
function _M.GetNameAndLink()
	local next_url, x = nil
	local u = MODULE.RootURL .. DirectoryPagination:format(1)

	if not HTTP.GET(u) then return net_problem end

	x = CreateTXQuery(HTTP.Document)
	while true do
		x.XPathHREFAll('//div[@class="item"]//h3/a', LINKS, NAMES)
		next_url = x.XPathString('//ul[@class="pagination"]/li[last()]/a/@href')
		if next_url == '' then break end
		UPDATELIST.UpdateStatusText('Loading page ' .. (next_url:match('page=(%d+)') or ''))
		if HTTP.GET(next_url) then
			x.ParseHTML(HTTP.Document)
		else
			break
		end
	end

	return no_error
end

-- Get info and chapter list for current manga.
function _M.GetInfo()
	local x = nil
	local u = MaybeFillHost(MODULE.RootURL, URL)

	if not HTTP.GET(u) then return net_problem end

	x = CreateTXQuery(HTTP.Document)
	MANGAINFO.Title     = x.XPathString('//h1[@class="title-detail"]')
	MANGAINFO.CoverLink = x.XPathString('//div[contains(@class, "col-image")]/img/@src')
	MANGAINFO.Authors   = x.XPathString('//li[contains(@class, "author")]/p[2]/normalize-space(.)')
	MANGAINFO.Genres    = x.XPathStringAll('//li[contains(@class, "kind")]/p[2]/a')
	MANGAINFO.Status    = MangaInfoStatusIfPos(x.XPathString('//li[contains(@class, "status")]/p[2]'), 'Ongoing|Đang tiến hành', 'Completed|Hoàn thành')
	MANGAINFO.Summary   = x.XPathString('//div[@class="detail-content"]/*[not(@class="list-title")]')

	x.XPathHREFAll('//div[@class="list-chapter"]//ul/li/div[contains(@class, "chapter")]/a', MANGAINFO.ChapterLinks, MANGAINFO.ChapterNames)
	MANGAINFO.ChapterLinks.Reverse(); MANGAINFO.ChapterNames.Reverse()

	HTTP.Reset()
	HTTP.Headers.Values['Referer'] = MODULE.RootURL

	return no_error
end

-- Get the page count for the current chapter.
function _M.GetPageNumber()
	local u = MaybeFillHost(MODULE.RootURL, URL)

	if not HTTP.GET(u) then return net_problem end

	CreateTXQuery(HTTP.Document).XPathStringAll('//div[@class="page-chapter"]/img/@data-src', TASK.PageLinks)

	return no_error
end

-- Prepare the URL, http header and/or http cookies before downloading an image.
function _M.BeforeDownloadImage()
	HTTP.Headers.Values['Referer'] = MODULE.RootURL

	return true
end

----------------------------------------------------------------------------------------------------
-- Module After-Initialization
----------------------------------------------------------------------------------------------------

return _M
