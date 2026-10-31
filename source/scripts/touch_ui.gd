extends RefCounted
# Original game deliberately disables mouse emulation for independent touch fingers.
# Handle GUI touch explicitly so menus and the action button keep that guarantee.
static func handle(root:Control,event:InputEvent)->bool:
 if not root.is_visible_in_tree():return false
 if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return false
 var children=root.get_children();children.reverse()
 for child in children:
  if child is Control and handle(child,event):return true
 if root is Button and not root.disabled and event is InputEventScreenTouch and event.pressed and root.get_global_rect().has_point(event.position):
  root.grab_focus();root.pressed.emit();return true
 if root is HSlider:
  if event is InputEventScreenTouch:
   if event.pressed and root.get_global_rect().grow(12).has_point(event.position):root.set_meta("touch_id",event.index)
   elif not event.pressed and root.get_meta("touch_id",-1)==event.index:root.remove_meta("touch_id");return true
  if root.get_meta("touch_id",-1)==event.index:
   var t=clampf((event.position.x-root.global_position.x)/root.size.x,0,1);root.value=lerpf(root.min_value,root.max_value,t);return true
 return false
