import type { PermissionState } from '@capacitor/core';


export interface VideoEditorPlugin {
  getVideos(options: VideoOptions): Promise<ReturnVideos>;

  checkPermissions(): Promise<PermissionStatus>;

  requestPermissions(
    permissions?: VideoEditorPluginPermissions,
  ): Promise<PermissionStatus>;

  trim(options: TrimOptions): Promise<Video>;

  concatVideos(paths: ConcatItems): Promise<Video>;
}

export type CameraPermissionState = PermissionState | 'limited';

export type CameraPermissionType = 'camera' | 'videos';

export interface TrimOptions {
  /* start and end in format HH:MM:SS eg.: 00:00:02 for 2seconds */
  start: string;
  end: string;
  path: string;
  extension: string;
}

export interface ConcatItems {
  videos: ConcatItem[];
  audio?: string;
}

export interface ConcatItem {
  /*start and duration in seconds*/
  /*duration actually is end -> will refactor later*/
  path: string;
  start: string;
  duration: string;
}

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
   * format of the video
   *
   * @since 1.0.0
   */
  extension: string;
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
  /**
   * The size of the video in bytes
   *
   * @since 1.0.0
   */
  size: string;
}

