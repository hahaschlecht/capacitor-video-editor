package com.capacitorvideoeditor.plugin;

import android.Manifest;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ContentResolver;
import android.content.Intent;

import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;
import android.os.Build;
import android.provider.MediaStore;
import android.util.Base64;
import android.util.Log;

import androidx.activity.result.ActivityResult;
import androidx.core.content.FileProvider;

import com.arthenica.ffmpegkit.ExecuteCallback;
import com.arthenica.ffmpegkit.FFmpegKit;
import com.arthenica.ffmpegkit.FFprobeKit;
import com.arthenica.ffmpegkit.LogCallback;
import com.arthenica.ffmpegkit.MediaInformation;
import com.arthenica.ffmpegkit.MediaInformationSession;
import com.arthenica.ffmpegkit.ReturnCode;
import com.arthenica.ffmpegkit.Session;
import com.arthenica.ffmpegkit.SessionState;
import com.arthenica.ffmpegkit.Statistics;
import com.arthenica.ffmpegkit.StatisticsCallback;
import com.getcapacitor.FileUtils;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Logger;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.text.SimpleDateFormat;
import java.util.Date;

@CapacitorPlugin(name = "VideoEditor", permissions = {
        @Permission(strings = {Manifest.permission.CAMERA}, alias = VideoEditorPlugin.CAMERA),
        @Permission(
                strings = {Manifest.permission.READ_EXTERNAL_STORAGE, Manifest.permission.WRITE_EXTERNAL_STORAGE},
                alias = VideoEditorPlugin.PHOTOS
        )
})
public class VideoEditorPlugin extends Plugin {

    // Permission alias constants
    static final String CAMERA = "camera";
    static final String PHOTOS = "photos";

    // Message constants
    private static final String PERMISSION_DENIED_ERROR_PHOTOS = "User denied access to photos";
    private static final String NO_PHOTO_ACTIVITY_ERROR = "Unable to resolve photo activity";


    private VideoEditor implementation = new VideoEditor();
    private VideoEditorSettings settings = new VideoEditorSettings();

    @PluginMethod
    public void requestPermissions(PluginCall call) {
        call.unimplemented("Not implemented on Android.");
    }

    @PluginMethod
    public void getVideos(PluginCall call) {
        settings = getSettings(call);
        openPhotos(call);
    }

    @PluginMethod
    public void concatVideos(PluginCall call) {
        String audio = call.getString("audio");
        JSArray videos = call.getArray("videos");
        Integer amountThumbnails = call.getInt("amountThumbnails");

        ConcatItem[] concatItems = new ConcatItem[videos.length()];

        for (int i = 0; i < videos.length(); i++) {
            ConcatItem item = new ConcatItem();
            try {
                item.path = videos.getJSONObject(i).getString("path");
                item.start = videos.getJSONObject(i).getString("start");
                item.duration = videos.getJSONObject(i).getString("duration");
                concatItems[i] = item;
            }
            catch (Exception e) {
                call.reject("Bad request");
                return;
            }
        }

        FfmpegCommands commands = new FfmpegCommands();

        String filterCommand = commands.getFilterCommand(concatItems, audio);
        String inputCommand = "";

        for (int i = 0; i< concatItems.length; i++) {
            inputCommand = inputCommand + commands.getInputCommand(concatItems[i].path);
        }

        if (audio != null) {
            inputCommand = inputCommand + commands.getInputCommand(audio);
        }

        String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());

        try {
            File file = CameraUtils.createVideoFile(getActivity(), ".mp4", timeStamp);
            Log.i("Concat", file.toString());
            String outPath = file.getAbsolutePath();
            Log.i("Concat", outPath);

            Uri ursula = Uri.fromFile(file);
            Log.i("ursula", ursula.toString());

            String command = inputCommand + filterCommand + outPath + " -y";

            Log.i("FFMPEG", command);

            FFmpegKit.executeAsync(command, session -> {
                SessionState state = session.getState();
                ReturnCode returnCode = session.getReturnCode();

                if (state == SessionState.COMPLETED) {
                    Log.i("FFMPEG", "completed?");
                    if (returnCode.getValue() == ReturnCode.SUCCESS) {
                        Log.i("FFMPEG", "success?");
                        try {
                        /*Uri thumbFile = CameraUtils.createVideoFileUri(getActivity(), getAppId(), ".mp4", timeStamp);*/
                        processPickedVideo(ursula, call, true, ursula);
                        }
                        catch (Exception e) {
                            call.reject("Bad request");
                        }
                    }
                    else {
                        call.reject("Error concatenating videos");
                    }
                }
            }, log -> {

                // CALLED WHEN SESSION PRINTS LOGS
                Log.i("ffmpeg logs", log.toString());


            }, statistics -> {
                // CALLED WHEN SESSION GENERATES STATISTICS

            });

        }
        catch (Exception e) {
            call.reject("Bad request of all");
            Log.e("Concat", e.toString());
        }
    }

    private VideoEditorSettings getSettings(PluginCall call) {
        VideoEditorSettings settings = new VideoEditorSettings();

        settings.setSaveToGallery(call.getBoolean("saveToGallery", VideoEditorSettings.DEFAULT_SAVE_IMAGE_TO_GALLERY));
        settings.setAllowEditing(call.getBoolean("allowEditing", false));
        settings.setQuality(call.getInt("quality", VideoEditorSettings.DEFAULT_QUALITY));
        settings.setWidth(call.getInt("width", 0));
        settings.setHeight(call.getInt("height", 0));
        settings.setShouldResize(settings.getWidth() > 0 || settings.getHeight() > 0);
        settings.setShouldCorrectOrientation(call.getBoolean("correctOrientation", VideoEditorSettings.DEFAULT_CORRECT_ORIENTATION));
        return settings;
    }

    private void openPhotos(final PluginCall call) {
        if (checkPhotosPermissions(call)) {
            Intent intent = new Intent(Intent.ACTION_PICK);
            intent.setType("video/*");

            try {
                startActivityForResult(call, intent,  "processPickedVideo");
            } catch (ActivityNotFoundException ex) {
                call.reject(NO_PHOTO_ACTIVITY_ERROR);
            }
        }
    }

    private boolean checkPhotosPermissions(PluginCall call) {
        if (getPermissionState(PHOTOS) != PermissionState.GRANTED) {
            requestPermissionForAlias(PHOTOS, call, "cameraPermissionsCallback");
            return false;
        }


        return true;
    }

    /**
     * Completes the plugin call after a camera permission request
     *
     * @param call the plugin call
     */
    @PermissionCallback
    private void cameraPermissionsCallback(PluginCall call) {
        Log.w("callback", "checking permision");

       if ( getPermissionState(PHOTOS) != PermissionState.GRANTED) {
            Logger.debug(getLogTag(), "User denied photos permission: " + getPermissionState(PHOTOS).toString());
            call.reject(PERMISSION_DENIED_ERROR_PHOTOS);
            return;
        }

        Log.w("callback", "permissions should be granted");
        openPhotos(call);
        }

    @ActivityCallback
    public void processPickedVideo(PluginCall call, ActivityResult result) {
        Log.i("debug_video1", result.toString());
        if (result.getResultCode() == Activity.RESULT_CANCELED) {
            call.reject("Canceled");
            return;
        }
        if (result.getResultCode() == Activity.RESULT_OK) {


        settings = getSettings(call);

        Intent data = result.getData();
        Log.i("debug_video2 data", data.toString());
        if (data == null) {
            call.reject("No video picked");
            return;
        }

        Uri u = data.getData();

        processPickedVideo(u, call, false, null);
        }
        else {
            call.reject("error picking video");
        }
    }

    private void processPickedVideo(Uri videoUri, PluginCall call, boolean trimmed, Uri ursula) {
        Log.i("FFMPEG", "processing?");
        JSObject video = new JSObject();
        Log.i("FFMPEGURI", videoUri.toString());
        String webPath = FileUtils.getPortablePath(getContext(), bridge.getLocalUrl(), videoUri);
        Log.i("FFMPEG", "processing? 2");
        String path = FileUtils.getFileUrlForUri(getContext(), videoUri);
        Log.i("FFMPEG", "processing? 3");
        MediaInformationSession session = FFprobeKit.getMediaInformation(path);
        Log.i("FFMPEG", "processing? 4");
        MediaInformation info = session.getMediaInformation();
        Log.i("FFMPEG", "processing? 5");

        Log.i("FFMPEG", "got info?");

        if (ursula != null) {
            video.put("path", ursula);
        } else {
        video.put("path", path);
        }
        video.put("webPath", webPath);
        video.put("extension", "mp4");
        video.put("duration", info.getDuration());
        video.put("size", info.getSize());

        Log.i("FFMPEG", "get thumbnails!");

        getThumbnails(path, info.getDuration(), 9.0, call, video, trimmed);
    }


    private void getThumbnails(String path, String duration, double amount, PluginCall call, JSObject video, boolean trimmed) {
        try {
            Log.i("FFMPEG", "try thumbnails 1");
            double durationDouble = Double.parseDouble(duration);
            double interval = (durationDouble - 0.002) / amount;

            Log.i("FFMPEG", "try thumbnails 2");

            String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss").format(new Date());

            File file = CameraUtils.createVideoFile(getActivity(), "%d.jpg", timeStamp);
            String outPath = file.getAbsolutePath();

            Log.i("FFMPEG", "try thumbnails 3");

            String exec = "-y -i " + path + " -vf fps=1/" + String.valueOf(interval) + " " + outPath;

            FFmpegKit.executeAsync(exec, session -> {
                SessionState state = session.getState();
                ReturnCode returnCode = session.getReturnCode();
                Log.i("FFMPEG", "try thumbnails 4");
                if (state == SessionState.COMPLETED) {
                    if (returnCode.getValue() == ReturnCode.SUCCESS) {
                        Log.i("FFMPEG", "try thumbnails 5");
                    // CALLED WHEN SESSION IS EXECUTED
                    try {
                        JSArray thumbs = new JSArray();

                        for(int i=1;i<amount;i++) {
                            String suffix = String.valueOf(i) + ".jpg";
                            Uri thumbFile = CameraUtils.createVideoFileUri(getActivity(), getAppId(), suffix, timeStamp);
                            String thumbPathString = FileUtils.getPortablePath(getContext(), bridge.getLocalUrl(), thumbFile);
                            thumbs.put(thumbPathString);
                        }

                        JSObject ret = new JSObject();
                        JSArray videos = new JSArray();
                        video.put("thumbnails", thumbs);
                        videos.put(video);
                        ret.put("videos", videos);
                        Log.i("FFMPEG", "try thumbnails 6");
                        if (trimmed) {
                            resolveCall(call, video);
                        } else {
                            resolveCall(call, ret);
                        }

                    } catch (Exception e) {
                        call.reject("Unhandled Error");
                    }


                } else {
                    call.reject("Error generating thumbnails");
                }
                }

            }, log -> {
                // CALLED WHEN SESSION PRINTS LOGS
                Log.i("ffmpeg logs", log.toString());

            }, statistics -> {
                // CALLED WHEN SESSION GENERATES STATISTICS
                Log.i("ffmpeg statistics", statistics.toString());
            });
        }
        catch (Exception e) {
            Log.i("ffmpeg session", e.toString());
            Log.i("ffmpeg session", "execute exception super bad");
        }
    }

    private void resolveCall(PluginCall call, JSObject ret) {
        call.resolve(ret);
    }

    public static String getRealVideoPathFromURI(ContentResolver contentResolver, Uri contentURI) {
        Cursor cursor = contentResolver.query(contentURI, null, null, null, null);
        if (cursor == null)
            return contentURI.getPath();
        else {
            cursor.moveToFirst();
            int idx = cursor.getColumnIndex(MediaStore.Video.VideoColumns.DATA);
            try {
                return cursor.getString(idx);
            } catch (Exception exception) {
                return null;
            }
        }
    }
}


