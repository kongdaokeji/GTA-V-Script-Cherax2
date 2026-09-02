-- Mission Assistant 页面路由

local Router = {
    Name = "Gui.Router"
}

local App

function Router.Init(app)
    App = app
    App.Gui.Router = Router
    return true
end

function Router.GetCurrentPage()
    local state = App.Data.State.Ui
    return App.Data.GetNavigationItem(state.SelectedPage)
end

function Router.Draw(x, y, width, height)
    local page = Router.GetCurrentPage()
    if page.Id == "perico" then
        App.Gui.Pages.Perico.Draw(page, x, y, width, height)
    elseif page.Id == "casino" then
        App.Gui.Pages.Casino.Draw(page, x, y, width, height)
    elseif page.Id == "doomsday" then
        App.Gui.Pages.Doomsday.Draw(page, x, y, width, height)
    elseif page.Id == "apartment" then
        App.Gui.Pages.Apartment.Draw(page, x, y, width, height)
    elseif page.Id == "kortz" then
        App.Gui.Pages.Kortz.Draw(page, x, y, width, height)
    elseif page.Id == "other" then
        App.Gui.Pages.Other.Draw(page, x, y, width, height)
    elseif page.Id == "vehicles" then
        App.Gui.Pages.Vehicles.Draw(page, x, y, width, height)
    elseif page.Id == "quick" then
        App.Gui.Pages.Quick.Draw(page, x, y, width, height)
    elseif page.Id == "solo" then
        App.Gui.Pages.Solo.Draw(page, x, y, width, height)
    elseif page.Id == "asset" then
        App.Gui.Pages.Asset.Draw(page, x, y, width, height)
    elseif page.Id == "theme" then
        App.Gui.Pages.Theme.Draw(page, x, y, width, height)
    else
        App.Data.State.Ui.SelectedPage = "perico"
        App.Gui.Pages.Perico.Draw(App.Data.GetNavigationItem("perico"), x, y, width, height)
    end
end

function Router.Shutdown(app)
    if app.Gui.Router == Router then
        app.Gui.Router = nil
    end
    App = nil
end

return Router
