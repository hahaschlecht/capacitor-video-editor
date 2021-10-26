# capacitor-video-editor

A small plugin to pick videos from the camera roll and edit them.

## Install

```bash
npm install capacitor-video-editor
npx cap sync
```

## API

<docgen-index>

* [`echo(...)`](#echo)
* [`getVideos(...)`](#getvideos)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions(...)`](#requestpermissions)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### echo(...)

```typescript
echo(options: { value: string; }) => any
```

| Param         | Type                            |
| ------------- | ------------------------------- |
| **`options`** | <code>{ value: string; }</code> |

**Returns:** <code>any</code>

--------------------


### getVideos(...)

```typescript
getVideos(options: VideoOptions) => any
```

| Param         | Type                                                  |
| ------------- | ----------------------------------------------------- |
| **`options`** | <code><a href="#videooptions">VideoOptions</a></code> |

**Returns:** <code>any</code>

--------------------


### checkPermissions()

```typescript
checkPermissions() => any
```

**Returns:** <code>any</code>

--------------------


### requestPermissions(...)

```typescript
requestPermissions(permissions?: VideoEditorPluginPermissions | undefined) => any
```

| Param             | Type                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------- |
| **`permissions`** | <code><a href="#videoeditorpluginpermissions">VideoEditorPluginPermissions</a></code> |

**Returns:** <code>any</code>

--------------------


### Interfaces


#### VideoOptions

| Prop            | Type                |
| --------------- | ------------------- |
| **`maxVideos`** | <code>number</code> |


#### Video

| Prop               | Type                | Description                                                                                                                                           | Since |
| ------------------ | ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`base64String`** | <code>string</code> | The base64 encoded string representation of the image, if using CameraResultType.Base64.                                                              | 1.0.0 |
| **`dataUrl`**      | <code>string</code> | The url starting with 'data:image/jpeg;base64,' and the base64 encoded string representation of the image, if using CameraResultType.DataUrl.         | 1.0.0 |
| **`path`**         | <code>string</code> | If using CameraResultType.Uri, the path will contain a full, platform-specific file URL that can be read later using the Filsystem API.               | 1.0.0 |
| **`webPath`**      | <code>string</code> | webPath returns a path that can be used to set the src attribute of an image for efficient loading and rendering.                                     | 1.0.0 |
| **`exif`**         | <code>any</code>    | Exif data, if any, retrieved from the image                                                                                                           | 1.0.0 |
| **`format`**       | <code>string</code> | The format of the image, ex: jpeg, png, gif. iOS and Android only support jpeg. Web supports jpeg and png. gif is only supported if using file input. | 1.0.0 |


#### PermissionStatus

| Prop         | Type                                                                                   |
| ------------ | -------------------------------------------------------------------------------------- |
| **`camera`** | <code>"prompt" \| "prompt-with-rationale" \| "granted" \| "denied" \| "limited"</code> |
| **`videos`** | <code>"prompt" \| "prompt-with-rationale" \| "granted" \| "denied" \| "limited"</code> |


#### VideoEditorPluginPermissions

| Prop              | Type            |
| ----------------- | --------------- |
| **`permissions`** | <code>{}</code> |

</docgen-api>
