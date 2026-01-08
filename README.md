# Dream Rigger

<a href="https://www.buymeacoffee.com/CretaPark" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" width="120" height="26"></a>

[한국어 매뉴얼 보기 (View Korean Manual)](./README.ko.md)

This addon is a sprite rigging and composition creation tool that is friendly to the sheet animation style for Godot.

To install, simply copy the `addons` folder from this repository to your project folder.

> [!Important]
> The minimum supported Godot Engine version is `4.5.1`.

## ⚠️ Disclaimer ⚠️

Currently in alpha stage.

This addon is still under development, as I'm implementing and using it for the first time.

I'm also building this for use in the games I will create, but I don't recommend using it directly in production just yet.

However, if you're purely interested, please feel free to take a look.

Contributions are always welcome! (See the Contributing section below)

## Terminology

There are terms used in this addon.

Most have a `DreamRigger` prefix to distinguish them from built-in node types.

<table>
    <tr>
        <th>Term</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Part</td>
        <td>
            A special type of sprite node provided by this addon that is visually represented and performs a role similar to a Bone in rigging.
        </td>
    </tr>
    <tr>
        <td>Pose</td>
        <td>
            A collection of Resource-type data that contains which sprites are included in the pose.<br/>
            It acts as a kind of sprite library.
        </td>
    </tr>
    <tr>
        <td>Sprite</td>
        <td>
            Resource data needed to visually represent a part.<br/>
            It includes Pixels Per Unit (PPU), Offset (for pivot purposes),
            and joint data indicating where other parts should be attached.
        </td>
    </tr>
    <tr>
        <td>Joint</td>
        <td>
            Resource data that indicates where other parts should be attached within the sprite.
        </td>
    </tr>
</table>

## Basic Workflow

The workflow is broadly divided into 4 steps:
1. Prepare the top-level part
2. Set up and prepare graphic resources
3. Configure the Part hierarchy and adjust graphic resources
4. Composition
   - Sprite composition
   - Animation composition with `AnimationPlayer`

## 1. Prepare the Top-Level Part

> [!Note]
> There are currently no screenshots available showing the editor interface for reference.

- After installing DreamRigger, enable it in the addons.
- Add a `DreamRiggerPart2D`/`DreamRiggerPart3D` node corresponding to the desired coordinate system in the current scene.
  This will serve as the root bone.
  Once the node is created, check `Is Root Part` in the Inspector.

## 2. Set Up and Prepare Graphic Resources

> [!Note]
> There are currently no screenshots available showing the editor interface for reference.

When you enable DreamRigger, the 'DreamRigger Control Panel' is added to the bottom-left panel by default.

This is where we will configure sprites and adjust parts, joints, etc.

> [!Note]
> From now on, we'll simply refer to this as the Control Panel.

- Select the root part node again, and the root part will appear in the `Hierarchy` section of the Control Panel.
- Now, in the `PoseBrowser` on the right side of the Control Panel, create a new `DreamRiggerPose` resource.
  In the empty space below it, select only the imported graphic resources corresponding to the body (i.e., the parts that will become the root bone) and drag them all at once.
  This will convert the dragged graphic resources into `DreamRiggerSprite` resources.
- Select `Sprites` in the Inspector below the `PoseBrowser`, then select each sprite added to the pose one by one and configure the Name, Offset, and Pixels per unit.
  The Offset is the same as the `offset` in Sprite2D/Sprite3D, with the origin set at the center by default.
- Perform this task for all sprites.

> [!Tip]
> There's also something called `Scratch pad` in the Inspector, which provides an interface to help quickly configure settings for parts, sprites, and joints.

## 3. Configure the Part Hierarchy and Adjust Graphic Resources

> [!Note]
> There are currently no screenshots available showing the editor interface for reference.

If you have composed all sprites for a single part in the previous step, next you need to compose the sub-parts that will branch out from here.

- Right-click the part where you want to add a child part in the Hierarchy, then perform Create Child Part.
- Select that part, then perform the tasks from step 1, but only for the first sprite initially.
- Select the parent part again, then select all sprites in the pose and navigate to the Joints tab in the Inspector.
- Right-click in the empty space below the Joint list. From the menu that appears, select the child part to add it.
- Now, iterate through each sprite, adjusting the joint position to ensure the child part is correctly positioned for each sprite as you compose.
- Repeat this process until all parts are configured.

## 4. Composition

> [!Note]
> There are currently no screenshots available showing the editor interface for reference.

Once you've configured and adjusted all part hierarchies, it's time for free expression and depiction!

Now, I'll guide you on how to compose for both static configurations and dynamic configurations like animations.

### Sprite Composition

The basic approach is to select the part you want to change the pose for in the Hierarchy, select the desired sprite in the `PoseBrowser`, and fine-tune the position in the `Parts` section of the Inspector while composing.

### Animation Composition with `AnimationPlayer`

Similar to sprite composition.

- Create an `AnimationPlayer` node.
- Enable `Record to track` at the top of the Control Panel, then select the `AnimationPlayer` node.
- Follow the sprite composition process while selecting each part where you want to add animation keyframes.
  At this point, you'll see that keyframes are automatically added in the Animation Track Editor.

> [!Warning]
> Tracks created this way do not automatically add a `RESET` track!

> [!Tip]
> If you want to depict animation movements more precisely and smoothly, try using the onion skin feature!

### How Composition Workflow Looks Like

https://github.com/user-attachments/assets/585d9d61-584e-4c94-aa0c-b95c331aa71b

\* Note that this video is from a slightly older version of DreamRigger,
   as the DreamRiggerPart node has now been changed to Sprite2D/3D type.

### How Scratch Pad Is Used

https://github.com/user-attachments/assets/69cb26a1-74c9-4a7c-a1e6-a31144a64556

\* Note that this video is from a slightly older version of DreamRigger,
   so it may look different from the current version.

## Contributing

This project is still in alpha stage, but if you do use it, simply reporting issues or suggesting ideas through the repository's Issues tab is a great help.

DreamRigger was created to enable diverse and detailed depictions with minimal resources in games, and is a tool to help with creation.

Your honest feedback and issue reports alone can help it evolve into something useful from an actual user's perspective.

For those who want to go beyond this and contribute directly to the codebase, I've prepared the following guidelines:

- Use spaces for indentation.
- Use English for comments.
- For editors, define `DreamRiggerEditor`, and for runtime, define `DreamRigger` as the `class_name`.
```gdscript
## This is my class
##
## It's some example for guideline, this class helps to understand standards.
@tool
class_name DreamRiggerEditorMyControl extends BoxContainer
```
- Use `region` and `endregion` in scripts to distinguish each purpose.
- The definition order is as follows:
  - Class definition
  - Inline type definitions (`enum`, `class`, etc.)
  - Constants (`const`)
  - Members (`var`)
  - Signal methods (methods with the `internal` property provided by the base node type, or methods that receive signal callbacks)
  - API methods (methods provided for use internally and externally that do not have `_` prefix)
  - Action methods (methods that encapsulate complex logic internally, with `_` prefix)
- When defining types along with variable declarations, you should maintain the same indentation level to make type names readable according to context.
```gdscript
#region Members

@onready var _record_to_track_button: CheckButton = %RecordToTrackButton

@onready var _pose_previewer:   DreamRiggerEditorPosePreviewer   = %PosePreviewContainer
@onready var _part_hierarchy:   DreamRiggerEditorPartTree        = %PartHierarchy

@onready var _pose_sprite_list: DreamRiggerEditorPoseSpritesList = %PoseSpriteList

@onready var _part_inspector:   DreamRiggerEditorPartInspector   = %Parts
@onready var _sprite_inspector: DreamRiggerEditorSpriteInspector = %Sprites
@onready var _joint_inspector:  DreamRiggerEditorJointInspector  = %Joints

#endregion
```
- When parameters become too long, break lines at `,` to allow for continued reading downward.
```gdscript
# Do
func some_method_that_has_lots_of_params(
    long_param_name:      LongParamType,
    too_long_param_stuff: SuperLongParamValue) -> void:

    pass

# Don't
func some_method_that_has_lots_of_params(long_param_name: LongParamType, too_long_param_stuff: SuperLongParamValue) -> void:

    pass
```

Thank you for your contributions!
