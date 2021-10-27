# capacitor-video-editor

This Plugin is still under development. Please do not use it, yet.  

A plugin to pick videos from the camera roll and edit them.

## Install

```bash
npm install capacitor-video-editor
npx cap sync
```

## API

<docgen-index>

* [`getVideos(...)`](#getvideos)
* [`checkPermissions()`](#checkpermissions)
* [`requestPermissions(...)`](#requestpermissions)
* [Interfaces](#interfaces)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

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

| Prop          | Type                | Description                                                                                                               | Since |
| ------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------------- | ----- |
| **`path`**    | <code>string</code> | The path will contain a full, platform-specific file URL that can be read later using the Filsystem API.                  | 1.0.0 |
| **`webPath`** | <code>string</code> | webPath returns a path that can be used to set the src attribute of an video element for efficient loading and rendering. | 1.0.0 |
| **`exif`**    | <code>any</code>    | Exif data, if any, retrieved from the video                                                                               | 1.0.0 |
| **`format`**  | <code>string</code> | The format of the video, ex: mp4, MOV, M4V.                                                                               | 1.0.0 |


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
