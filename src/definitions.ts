import type { PermissionState } from '@capacitor/core';


export interface VideoEditorPlugin {
  getVideos(options: VideoOptions): Promise<ReturnVideos>;

  checkPermissions(): Promise<PermissionStatus>;

  requestPermissions(
    permissions?: VideoEditorPluginPermissions,
  ): Promise<PermissionStatus>;
}

export type CameraPermissionState = PermissionState | 'limited';

export type CameraPermissionType = 'camera' | 'videos';

export interface PermissionStatus {
  camera: CameraPermissionState;
  videos: CameraPermissionState;
}

export interface VideoEditorPluginPermissions {
  permissions: CameraPermissionType[];
}

export interface VideoOptions {
  /* 0 equals to unlimited?!*/
  maxVideos?: number;
}

export interface ReturnVideos {
  videos: Video[];
}


export interface Video {

  /**
   * The path will contain a full,
   * platform-specific file URL that can be read later using the Filsystem API.
   *
   * @since 1.0.0
   */
  path: string;
  /**
   * webPath returns a path that can be used to set the src attribute of an video element for efficient
   * loading and rendering.
   *
   * @since 1.0.0
   */
  webPath: string;
  /**
   * Exif data, if any, retrieved from the video
   *
   * @since 1.0.0
   */
  exif?: any;
  /**
   * The webpath to the generated thumbnail
   *
   * @since 1.0.0
   */
  thumbnail: string;
  /**
   * The duration of the video in seconds
   *
   * @since 1.0.0
   */
  duration: string;
}

