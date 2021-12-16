package com.capacitorvideoeditor.plugin;

public class FfmpegCommands {
    /* for mobile 1125 x 2436 might actually be better */
    private final String width = "1080";
    private final String height = "1920";

    private String getVideoFilter(int index) {
        return "[" + index + ":v]scale=w=" + width + ":h=" + height + ":force_original_aspect_ratio=decrease,pad=" + width + ":" + height + ":(ow-iw)/2:(oh-ih)/2,fps=24,setpts=PTS-STARTPTS[resize" + index + "];";
    }

    private String getAudioFilter(int index) {
        return "[" + index + ":a]aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo,volume=0.2,asetpts=PTS-STARTPTS[audio" + index + "];";
    }

    private String getTrimVideo(int index, String start, String end) {
        return "[resize" + index + "]trim=start=" + start + ":end=" + end + ",setpts=PTS-STARTPTS[ag" + index + "];";
    }

    private String getTrimAudio(int index, String start, String end) {
        return "[audio" + index+ "]atrim=start=" + start + ":end=" + end+ ",asetpts=PTS-STARTPTS[au" + index + "];";
    }

    private String getVideo(int index) {
        return "[ag" + index + "]";
    }

    private String getAudio(int index) {
        return "[au" + index + "]";
    }

    private String getConcat(int amount) {
        return "concat=n=" + amount + ":v=1:a=1[v][a]";
    }

    private String getAudiMixer(int index) {
        return ";[a][" + index + "]amix[a] ";
    }

    private String getH264(){
        return " -c:v libx264 -preset ultrafast -crf 20 -c:a aac -b:a 160k -movflags +faststart ";
    }


    public String getFilterCommand(ConcatItem[] videos, String audio) {
        String commandString = " -filter_complex \"";

        for (int i= 0; i< videos.length; i++) {
            commandString = commandString + getVideoFilter(i);
        }

        for (int i= 0; i< videos.length; i++) {
            commandString = commandString + getAudioFilter(i);
        }

        for (int i= 0; i< videos.length; i++) {
            commandString = commandString + getTrimVideo(i, videos[i].start, videos[i].duration);
        }

        for (int i= 0; i< videos.length; i++) {
            commandString = commandString + getTrimAudio(i, videos[i].start, videos[i].duration);
        }

        for (int i= 0; i< videos.length; i++) {
            commandString = commandString + getVideo(i) + getAudio(i);
        }

        commandString = commandString + getConcat(videos.length);


        if (audio != null) {
            commandString = commandString + getAudiMixer(videos.length);
        }

        commandString = commandString + "\" -map [v] -map [a] ";

        if (audio != null) {
            commandString = commandString + "-map "+ videos.length + ":a ";
        }

        commandString = commandString + getH264();

        return commandString;
    }

    public String getInputCommand(String path) {
        return "-i " +path + " ";
    }
}
