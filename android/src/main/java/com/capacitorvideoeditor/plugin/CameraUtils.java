package com.capacitorvideoeditor.plugin;

import android.app.Activity;
import android.net.Uri;
import android.os.Environment;

import androidx.core.content.FileProvider;

import com.getcapacitor.FileUtils;
import com.getcapacitor.Logger;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;

public class CameraUtils {
    public static Uri createVideoFileUri(Activity activity, String appId, String suffix, String timeStamp) throws IOException {
        File photoFile = CameraUtils.createVideoFile(activity, suffix, timeStamp);
        return FileProvider.getUriForFile(activity, appId + ".fileprovider", photoFile);
    }

    public static File createVideoFile(Activity activity, String suffix, String timeStamp ) throws IOException {
        // Create an image file name

        String imageFileName = "file_" + timeStamp + "_" + suffix;
        /*File storageDir = activity.getExternalFilesDir(Environment.DIRECTORY_PICTURES);*/
        File storageDir = activity.getExternalFilesDir(Environment.DIRECTORY_MOVIES);

        File image = new File(storageDir, imageFileName);

        return image;
    }

    protected static String getLogTag() {
        return Logger.tags("CameraUtils");
    }
}
