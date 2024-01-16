obs = obslua
source_name = ""
default_icon = ""
last_execution = 0
UPDATE_INTERVAL = 3

function script_tick(_)
  local current_time = os.time()
  if current_time - last_execution > UPDATE_INTERVAL then
    last_execution = current_time
    local window_class = os.capture('hyprctl -j activewindow | jq -r ".class"')
    local icon = os.capture('/home/josh/.local/bin/get-icon '..window_class)
    if icon == nil or icon == '' then
      icon = default_icon
    end
    set_icon(icon)
  end
end

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end

function source_enable(enable)
  local scenes = obs.obs_frontend_get_scenes()
  if scenes ~= nil then
    for _, scenesource in ipairs(scenes) do
      local scenename = obs.obs_source_get_name(scenesource)
      local scene = obs.obs_scene_from_source(scenesource)
      local sceneitems = obs.obs_scene_enum_items(scene)
      local maxindex = 0
      local index = 1
      for i, sceneitem in ipairs(sceneitems) do
        local source = obs.obs_sceneitem_get_source(sceneitem)
        local sourcename = obs.obs_source_get_name(source)
        if sourcename == source_name then
          obs.obs_sceneitem_set_visible(sceneitem, enable)
        end
      end
      obs.sceneitem_list_release(sceneitems)
    end
    obs.source_list_release(scenes)
    -- obs.obs_frontend_source_list_free(scenes)
  end
end

function set_icon(icon)
  local source = obs.obs_get_source_by_name(source_name)
  if source ~= nil then
    local settings = obs.obs_source_get_settings(source)
    obs.obs_data_set_string(settings, "file", icon)
    obs.obs_source_update(source, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(source)
  end
end

function script_properties()
  local props = obs.obs_properties_create()
  local p = obs.obs_properties_add_list(props, "source", "Source",
                                        obs.OBS_COMBO_TYPE_EDITABLE,
                                        obs.OBS_COMBO_FORMAT_STRING)
  obs.obs_properties_add_text(props, "default", "Default Icon",
                                        obs.OBS_TEXT_DEFAULT)
  local sources = obs.obs_enum_sources()
  if sources ~= nil then
    for _, source in ipairs(sources) do
      local name = obs.obs_source_get_name(source)
      obs.obs_property_list_add_string(p, name, name)
    end
    obs.source_list_release(sources)
  end
  return props
end

function script_description()
  return
      "Enables / Disables a certain source, when active window is a certain window"
end

function script_update(settings)
  local sn = obs.obs_data_get_string(settings, "source")
  local di = obs.obs_data_get_string(settings, "default")
  if source_name ~= sn then source_name = sn end
  if default_icon ~= di then default_icon = di end
end

function script_defaults(settings) end

function script_save(settings) end

function script_load(settings) script_update(settings) end
