# Dream Rigger (드림 리거)

<a href="https://www.buymeacoffee.com/CretaPark" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" width="120" height="26"></a>

이 플러그인은 Godot용 시트 애니메이션 스타일에 친화적인 스프라이트 리깅
및 컴포지션 생성 도구입니다.

설치하는 방법은 이 저장소의 `addons` 폴더를 프로젝트 폴더에 복사 하기만 하면 됩니다.

> [!Important]
> 최소 Godot 엔진 지원 버전은 `4.5.1` 입니다.

## ⚠️ 부인 ⚠️

현재 알파 단계입니다.

이 애드온은 아직 개발 중이며, 처음 구현하고 사용해 보는 중이기 때문입니다.

저도 제가 만들 게임에 사용하기 위해 만들고 있습니다만,
가급적 프로덕션에서 바로 사용하시는 것을 추천하지 않습니다.

다만, 순수하게 흥미가 생기신다면 한 번 살펴봐주세요.

기여는 언제든지 환영입니다! (아래 기여 문단 참고)

## 용어

이 플러그인에서 사용되는 용어가 있습니다.

대부분은 내장 노드 유형과 구별하기 위해 `DreamRigger` 접두사가 붙습니다.

<table>
    <tr>
        <th>용어</th>
        <th>설명</th>
    </tr>
    <tr>
        <td>파트</td>
        <td>
            이 애드온에서 제공하는, 시각적으로 표현되는 특수한 유형의 스프라이트 노드로, 리깅에서 일종의 본(Bone)과 유사한 역할을 수행합니다.
        </td>
    </tr>
    <tr>
        <td>포즈</td>
        <td>
            리소스 유형의 데이터 모음으로, 어떤 스프라이트들이 포즈에 포함되어 있는지 담겨있습니다.<br/>
            일종의 스프라이트 라이브러리와 같은 역할을 합니다.
        </td>
    </tr>
    <tr>
        <td>스프라이트</td>
        <td>
            부품을 시각적으로 표현하는 데 필요한 리소스 데이터입니다.<br/>
            단위당 픽셀 수(PPU), 오프셋(피벗 용도),
            다른 파트가 부착되어야 할 위치를 나타내는 조인트 데이터가 포함됩니다.
        </td>
    </tr>
    <tr>
        <td>조인트</td>
        <td>
            스프라이트 내에서 다른 부품들이 부착되어야 할 위치를 나타내는 리소스 데이터입니다.
        </td>
    </tr>
</table>

## 기본적인 워크플로우

워크플로우는 크게 4단계로 나뉘어져 있습니다.
1. 최상위 part 준비하기
2. 그래픽 리소스 설정 및 준비하기
3. Part 계층구조 구성 후 그래픽 리소스 조정하기
4. 컴포지션 하기
  - 스프라이트 컴포지션하기
  - `AnimationPlayer`와 함께 애니메이션 컴포지션하기

## 1. 최상위 part 준비하기

> [!Note]
> 아직 참고할 수 있는 에디터 내 화면을 담은 사진이 없습니다.

- DreamRigger를 설치한 후, 애드온에서 활성화를 해줍니다.
- 현재 씬에서 원하는 좌표계에 해당하는 `DreamRiggerPart2D`/`DreamRiggerPart3D` 노드를 추가합니다.  
  이것이 흔히 말하는 루트 본의 역할을 할 것입니다.  
  노드를 만들었다면 인스펙터에서 `Is Root Part`를 체크해주세요.

## 2. 그래픽 리소스 설정 및 준비하기

> [!Note]
> 아직 참고할 수 있는 에디터 내 화면을 담은 사진이 없습니다.

DreamRigger를 활성화 했다면 기본적으로 좌측 하단 패널에 'DreamRigger Control Panel'이 추가됩니다.

저희는 여기에서 스프라이트를 설정하고 파트나 조인트, 등을 조절하게 될 것입니다.

> [!Note]
> 이후로는 간단하게 이를 컨트롤 패널이라 부르겠습니다.

- 루트 파트 노드를 다시 선택하면 컨트롤 패널의 `Hierarchy`에 루트 파트가 나타납니다.
- 이제 컨트롤 패널 우측의 `PoseBrowser`에서 새 `DreamRiggerPose` 리소스를 만들고,
  그 아래 빈 공간에 임포트 한 그래픽 리소스들 중에서 몸체, 즉, 루트 본이 될 부위에 해당하는 것들만 한꺼번에 선택해서 드래그 합니다.  
  이렇게 하면 드래그 한 그래픽 리소스들은 `DreamRiggerSprite` 리소스로 만들어집니다.
- `PoseBrowser` 아래의 인스펙터의 `Sprites`를 선택하고, 포즈에 추가 된 스프라이트들을 하나씩 선택하면서
  이름, 오프셋, Pixels per unit을 설정해줍니다.  
  오프셋은 Sprite2D/Sprite3D의 `offset`과 동일하고, 원점은 기본적으로 중심으로 설정되어 있습니다.
- 이 작업을 모든 스프라이트들에 진행합니다.

> [!Tip]
> 인스펙터 중 `Scratch pad`라는 것도 있는데, 여기에서 파트, 스프라이트, 조인트들의 설정을 빠르게 구성할 수 있게 돕는 인터페이스를 제공합니다.

## 3. Part 계층 구조 구성 후 그래픽 리소스 조정하기

> [!Note]
> 아직 참고할 수 있는 에디터 내 화면을 담은 사진이 없습니다.

이전 단계에서 하나의 파트에 대한 스프라이트들을 모두 컴포지션했다면,
다음은 여기에서 뻗어나가게 될 하위 파트들에 대해 컴포지션하는 작업을 진행해야 합니다.

- Hierarchy에서 하위 파트를 추가하고 싶은 파트를 우클릭 한 후, 자식 파트 만들기를 수행합니다.
- 해당 파트를 선택한 후, 1에서 진행했던 작업을 수행하되, 첫번째 스프라이트만 우선 진행합니다.
- 다시 상위 파트를 선택한 후, 포즈에서 모든 스프라이트를 선택한 다음, 인스펙터의 조인트 탭으로 이동합니다.
- 조인트 목록 아래 빈 공간을 우클릭을 하면 나타나는 메뉴에서, 자식 파트를 선택하여 추가합니다.
- 이제 스프라이트를 하나씩 넘겨가며 조인트 위치를 조정하여 각 스프라이트에 대해
  하위 파트가 올바른 위치에 배치되도록 컴포지션을 진행하면 됩니다.
- 이 작업을 모든 부위가 설정이 될 때까지 반복하세요.

## 3. 컴포지션하기

> [!Note]
> 아직 참고할 수 있는 에디터 내 화면을 담은 사진이 없습니다.

모든 파트 계층을 구성하고 조정을 끝마쳤다면 이제 자유로운 표현과 묘사의 시간입니다!

이제 정적인 구성을 다룰 때와 애니메이션과 같이 동적인 구성을 다룰 때에 대해 컴포지션 하는 방법을 안내하겠습니다.

### 스프라이트 컴포지션하기

하이어라이키에서 자세를 변경하고 싶은 파트를 선택하고, `PoseBrowser`에서 원하는 스프라이트를 선택한 뒤,
인스펙터의 `Parts`에서 미세 위치 조정을 하면서 컴포지션을 하는 것이 기본입니다.

### `AnimationPlayer`와 함께 애니메이션 컴포지션하기

스프라이트를 컴포지션하는 것과 유사합니다.

- `AnimationPlayer` 노드를 만듭니다.
- 컨트롤 패널의 상단에서 `Record to track`을 활성화 한 다음, `AnimationPlayer` 노드를 선택합니다.
- 애니메이션 키프레임을 추가하고 싶은 각 파트를 선택해가면서 스프라이트를 컴포지션하는 과정을 따릅니다.  
  이 때, 애니메이션 트랙 에디터에서 키프레임은 자동으로 추가되는 것을 볼 수 있습니다.

> [!Warning]
> 이렇게 만들어진 트랙은 `RESET` 트랙을 자동으로 추가하지 않습니다!

> [!Tip]
> 애니메이션 움직임을 좀 더 세밀하고 부드럽게 묘사하고 싶다면 어니언 스킨 기능을 활용해보세요!

### 작품 구성 워크플로의 모습

https://github.com/user-attachments/assets/585d9d61-584e-4c94-aa0c-b95c331aa71b

\* 참고로 이 영상은 DreamRigger의 약간 오래된 버전에서 제작된 것으로,
   현재 DreamRiggerPart 노드는 Sprite2D/3D 유형으로 변경되었습니다.

### `Scratch pad`가 어떻게 쓰이는 지의 모습

https://github.com/user-attachments/assets/69cb26a1-74c9-4a7c-a1e6-a31144a64556

\* 참고로 이 영상은 DreamRigger의 약간 오래된 버전에서 제작된 것으로,
   현재 모습과 다르게 보일 수 있습니다.

## 기여하기

이 프로젝트는 아직 알파 단계입니다만, 사용하시게 된다면 저장소의 이슈 탭을 통해 문제를 보고하거나
아이디어를 제안해주시는 것만으로도 큰 도움이 됩니다.

DreamRigger는 게임 내에서 적은 리소스로 다양하고 디테일한 묘사를 위해 만들어졌으며, 창작을 돕기 위한 도구입니다.

여러분들의 솔직한 의견과 문제 보고 만으로도 실제 사용자 입장에서 도움이 될 수 있는 모습으로 발전하는 데 도움이 됩니다.

만약 이것을 넘어서 직접 코드 베이스에 기여를 원하시는 분들을 위해 아래 가이드라인을 마련했습니다.

- 들여쓰기는 공백을 사용합니다.
- 주석에 들어가는 내용은 영어를 사용합니다.
- 에디터는 `DreamRiggerEditor`, 런타임은 `DreamRigger`를 `class_name`으로 정의해야 합니다.
```gdscript
## This is my class
## 
## It's some example for guideline, this class helps to understand standards.
@tool
class_name DreamRiggerEditorMyControl extends BoxContainer
```
- 스크립트에는 `region`, `endregion`을 사용하여 각 용도를 구분할 수 있도록 합니다.
- 정의 순서는 아래와 같습니다.
  - 클래스 정의
  - 인라인 타입 정의 (`enum`, `class` 등)
  - 상수 (`const`)
  - 멤버 (`var`)
  - 시그널 메서드 (베이스 노드 타입에서 제공하는 `internal` 특성의 메서드나 시그널 콜백을 받는 메서드)
  - API 메서드 (내외부에서 기능을 사용하도록 제공하며 `_`가 앞에 붙지 않는 메서드)
  - 동작 메서드 (내부에서 복잡한 로직들을 캡슐화 하는, '_'가 앞에 붙는 메서드)
- 변수 선언과 함께 타입을 정의할 때, 맥락에 따라 타입 명칭을 읽기 쉽게 동일한 들여쓰기 수준을 잡아주어야 합니다.
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
- 파라미터가 너무 길어지는 경우, 아래로 계속 읽어갈 수 있도록 `,`을 기준으로 개행해야 합니다.
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

여러분들의 기여에 감사드립니다!
