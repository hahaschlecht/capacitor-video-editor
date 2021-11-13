import { WebPlugin } from '@capacitor/core';

import type {
  PermissionStatus,
  ReturnVideos,
  Video,
  VideoEditorPlugin,
  VideoEditorPluginPermissions,
} from './definitions';

export class VideoEditorWeb extends WebPlugin implements VideoEditorPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }

  async getVideos(): Promise<ReturnVideos> {
    return Promise.reject(
      new Error('CapacitorVideoEditor does not have web implementation'),
    );
  }

  async checkPermissions(): Promise<PermissionStatus> {
    return Promise.reject(
      new Error('CapacitorVideoEditor does not have web implementation'),
    );
  }

  async requestPermissions(permissions?: VideoEditorPluginPermissions): Promise<PermissionStatus> {
    console.log('request permissions in web', permissions);
    return Promise.reject(
      new Error('CapacitorVideoEditor does not have web implementation'),
    );
  }

  async trim(): Promise<Video> {
    return Promise.reject(
      new Error('CapacitorVideoEditor does not have web implementation'),
    );
  }

  async concatVideos(): Promise<Video> {
    return Promise.reject(
      new Error('CapacitorVideoEditor does not have web implementation'),
    );
  }
}
