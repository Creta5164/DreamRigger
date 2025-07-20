# Dream Rigger

This plugin is a sprite rigging and composition creation tool
that is friendly to the sheet animation style, for Godot.

Installation is simply pasting the addons folder from this repository
into your project folder.

## Disclaimer

It's currently in alpha as I'm still developing, implementing, and using it for the first time.

I don't recommend using it in production, but if you're purely interested in content creation,
you might want to take a look.

## Terminology

There's terminology used in this plugin.

Most are prefixed with DreamRigger to distinguish them from the built-in node types.

<table>
    <tr>
        <th>Term</th>
        <th>Description</th>
    </tr>
    <tr>
        <td>Part</td>
        <td>
            A special type of Sprite node for that plugin that is visually represented,
            and serves as a sort of Bone-like role in the rigging.
        </td>
    </tr>
    <tr>
        <td>Pose</td>
        <td>
            A collection of data of the Resource type that holds what poses are in the part,
            which holds the sprite data.
        </td>
    </tr>
    <tr>
        <td>Sprite</td>
        <td>
            The Resources data needed to actually visually represent the part.<br/>
            It has data of Pixels Per Unit, Offset (for pivot purposes),
            Joints to indicate where other parts should be attached.
        </td>
    </tr>
    <tr>
        <td>Joint</td>
        <td>
            Resource data that indicates where other parts should be attached to in the sprite.
        </td>
    </tr>
</table>

## Basic workflow

The basic workflow is to create a Part node (make sure to set the Root in the Inspector),
create a Pose resource by opening the control panel you will see in the bottom left panel,
and then insert the imported sprite textures into the Pose Browser to compose them.

For now, since I don't have the time to write a tutorial,
I'm attaching a quick video below for now...

### How composition workflow looks like

https://github.com/user-attachments/assets/585d9d61-584e-4c94-aa0c-b95c331aa71b

\* Note that this video is from a slightly older version of DreamRigger,
   as the DreamRiggerPart node is now a Sprite2D/3D type.

## How scratch pad being used for

https://github.com/user-attachments/assets/69cb26a1-74c9-4a7c-a1e6-a31144a64556
