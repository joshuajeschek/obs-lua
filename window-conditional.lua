obs = obslua
source_name = ""
window_class = ""
last_execution = 0
UPDATE_INTERVAL = 3

function script_tick(_)
  local current_time = os.time()
  if current_time - last_execution > UPDATE_INTERVAL then
    print('hi')
    last_execution = current_time
    local active_window = os.capture('hyprctl -j activewindow | jq -r ".class"')
    print(active_window)
    print(window_class)
    if active_window == window_class then
      source_enable(true)
    else
      source_enable(false)
    end
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

function script_properties()
  local props = obs.obs_properties_create()
  local p = obs.obs_properties_add_list(props, "source", "Source",
                                        obs.OBS_COMBO_TYPE_EDITABLE,
                                        obs.OBS_COMBO_FORMAT_STRING)
  obs.obs_properties_add_text(props, "class", "Window Class",
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
  local wc = obs.obs_data_get_string(settings, "class")
  if source_name ~= sn then source_name = sn end
  if window_class ~= wc then window_class = wc end
end

function script_defaults(settings) end

function script_save(settings) end

function script_load(settings) script_update(settings) end
