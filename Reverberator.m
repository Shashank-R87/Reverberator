classdef Reverberator < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure         matlab.ui.Figure
        filename         matlab.ui.control.EditField
        export           matlab.ui.control.Button
        stop_reverb      matlab.ui.control.Button
        play_reverb      matlab.ui.control.Button
        AddReverbButton  matlab.ui.control.StateButton
        graphing         matlab.ui.control.StateButton
        delete_audio     matlab.ui.control.Button
        stop_2           matlab.ui.control.Button
        record_pause     matlab.ui.control.StateButton
        RecordingLabel   matlab.ui.control.Label
        play             matlab.ui.control.Button
        stop             matlab.ui.control.Button
        Audio_Graph      matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        recorder_obj
        recorded_audio = []
        recorded_player
        paused = 0
        p
        reverb_obj = reverberator("SampleRate",44100)
        reverb_audio
        reverb_audio_player
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Value changed function: record_pause
        function record_pauseValueChanged(app, event)
            value = app.record_pause.Value;
            if(value==1)
                app.record_pause.Icon = "pause.png";
                app.RecordingLabel.Visible = "on";
                app.RecordingLabel.Text = "Recording ...";
                if (app.paused == 0)
                    app.recorder_obj = audiorecorder(44100, 16, 2, 1);
                    record(app.recorder_obj);
                else
                    resume(app.recorder_obj);
                end
            else
                app.record_pause.Icon = "record.png";
                app.RecordingLabel.Visible = "on";
                app.RecordingLabel.Text = "Recording Paused";
                app.paused = 1;
                pause(app.recorder_obj);
            end
        end

        % Button pushed function: stop
        function stopButtonPushed(app, event)
            app.record_pause.Icon = "record.png";
            app.record_pause.Value = 0;
            app.RecordingLabel.Text = "Recording ...";
            app.RecordingLabel.Visible = "off";
            try
                stop(app.recorder_obj);
                app.recorded_audio = getaudiodata(app.recorder_obj);
                app.paused = 0;
                if (~isempty(app.recorded_audio))
                    app.play.Visible = "on";
                    app.stop_2.Visible = "on";
                    app.delete_audio.Visible = "on";
                    app.graphing.Visible = "on";
                    app.AddReverbButton.Visible = "on";
                else
                    app.play.Visible = "off";
                    app.stop_2.Visible = "off";
                    app.delete_audio.Visible = "off";
                    app.graphing.Visible = "off";
                    app.Audio_Graph.Visible = "off";
                    app.AddReverbButton.Visible = "off";
                end
            catch
                uialert(app.UIFigure, "Record to stop", "Recording Error")
            end
        end

        % Button pushed function: play
        function playButtonPushed(app, event)
            app.recorded_player = getplayer(app.recorder_obj);
            play(app.recorded_player);
        end

        % Button pushed function: stop_2
        function stop_2ButtonPushed(app, event)
            try 
                if (isplaying(app.recorded_player))
                    stop(app.recorded_player);
                end
            catch
                uialert(app.UIFigure, "No audio file is playing right now", "Audio Player Error")
            end
        end

        % Button pushed function: delete_audio
        function delete_audioButtonPushed(app, event)
            app.recorded_audio = [];
            app.recorded_player = 0;
            app.delete_audio.Visible = "off";
            app.play.Visible = "off";
            app.stop_2.Visible = "off";
            app.Audio_Graph.Visible = "off";
            app.graphing.Value = 0;
            app.graphing.Visible ="off";
            app.p.Visible = "off";
        end

        % Value changed function: graphing
        function graphingValueChanged(app, event)
            value = app.graphing.Value;
            if(value==1)
                app.p = plot(app.Audio_Graph, app.recorded_audio(:,1), Color="#D95319");
                app.Audio_Graph.Visible = "on";
            else
                app.Audio_Graph.Visible = "off";
                app.p.Visible = "off";
            end
        end

        % Value changed function: AddReverbButton
        function AddReverbButtonValueChanged(app, event)
            value = app.AddReverbButton.Value;
            if (value==1)
                app.reverb_audio = app.reverb_obj(app.recorded_audio);
                app.play_reverb.Visible = "on";
                app.stop_reverb.Visible = "on";
                app.filename.Visible = "on";
            else
                app.reverb_audio = 0;
                app.play_reverb.Visible = "off";
                app.stop_reverb.Visible = "off";
                app.filename.Visible = "off";
            end
        end

        % Button pushed function: play_reverb
        function play_reverbButtonPushed(app, event)
            app.reverb_audio_player = audioplayer(app.reverb_audio, 44100);
            app.reverb_audio_player.play();
        end

        % Button pushed function: stop_reverb
        function stop_reverbButtonPushed(app, event)
            try 
                if (isplaying(app.reverb_audio_player))
                    stop(app.reverb_audio_player);
                end
            catch
                uialert(app.UIFigure, "No audio file is playing right now", "Audio Player Error")
            end
        end

        % Button pushed function: export
        function exportButtonPushed(app, event)
            audiowrite(strcat(app.filename.Value, ".mp3"), app.reverb_audio, 44100);
            uialert(app.UIFigure, "Audio exported successfully", "Audio Export", "Icon","success")
            app.reverb_audio = 0;
            app.play_reverb.Visible = "off";
            app.stop_reverb.Visible = "off";
            app.filename.Visible = "off";
            app.export.Visible = "off";
        end

        % Value changing function: filename
        function filenameValueChanging(app, event)
            changingValue = event.Value;
            if (~isempty(changingValue))
                app.export.Visible = "on";
            else
                app.export.Visible = "off";
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 371 287];
            app.UIFigure.Name = 'MATLAB App';

            % Create Audio_Graph
            app.Audio_Graph = uiaxes(app.UIFigure);
            title(app.Audio_Graph, 'Audio Recording')
            xlabel(app.Audio_Graph, 'sample')
            ylabel(app.Audio_Graph, 'amplitude')
            zlabel(app.Audio_Graph, 'Z')
            app.Audio_Graph.Toolbar.Visible = 'off';
            app.Audio_Graph.Visible = 'off';
            app.Audio_Graph.Position = [23 26 324 115];

            % Create stop
            app.stop = uibutton(app.UIFigure, 'push');
            app.stop.ButtonPushedFcn = createCallbackFcn(app, @stopButtonPushed, true);
            app.stop.Icon = fullfile(pathToMLAPP, 'stop.png');
            app.stop.Tooltip = {'Stop Recording'};
            app.stop.Position = [63 240 31 28];
            app.stop.Text = '';

            % Create play
            app.play = uibutton(app.UIFigure, 'push');
            app.play.ButtonPushedFcn = createCallbackFcn(app, @playButtonPushed, true);
            app.play.Icon = fullfile(pathToMLAPP, 'play.png');
            app.play.Visible = 'off';
            app.play.Tooltip = {'Play Recording'};
            app.play.Position = [23 170 31 28];
            app.play.Text = '';

            % Create RecordingLabel
            app.RecordingLabel = uilabel(app.UIFigure);
            app.RecordingLabel.Visible = 'off';
            app.RecordingLabel.Position = [23 206 147 25];
            app.RecordingLabel.Text = 'Recording ...';

            % Create record_pause
            app.record_pause = uibutton(app.UIFigure, 'state');
            app.record_pause.ValueChangedFcn = createCallbackFcn(app, @record_pauseValueChanged, true);
            app.record_pause.Icon = fullfile(pathToMLAPP, 'record.png');
            app.record_pause.Text = '';
            app.record_pause.Position = [23 240 31 28];

            % Create stop_2
            app.stop_2 = uibutton(app.UIFigure, 'push');
            app.stop_2.ButtonPushedFcn = createCallbackFcn(app, @stop_2ButtonPushed, true);
            app.stop_2.Icon = fullfile(pathToMLAPP, 'stop.png');
            app.stop_2.Visible = 'off';
            app.stop_2.Tooltip = {'Stop Recording'};
            app.stop_2.Position = [63 170 31 28];
            app.stop_2.Text = '';

            % Create delete_audio
            app.delete_audio = uibutton(app.UIFigure, 'push');
            app.delete_audio.ButtonPushedFcn = createCallbackFcn(app, @delete_audioButtonPushed, true);
            app.delete_audio.Icon = fullfile(pathToMLAPP, 'delete.png');
            app.delete_audio.Visible = 'off';
            app.delete_audio.Tooltip = {'Delete Recording'};
            app.delete_audio.Position = [104 240 31 28];
            app.delete_audio.Text = '';

            % Create graphing
            app.graphing = uibutton(app.UIFigure, 'state');
            app.graphing.ValueChangedFcn = createCallbackFcn(app, @graphingValueChanged, true);
            app.graphing.Visible = 'off';
            app.graphing.Icon = fullfile(pathToMLAPP, 'graph.png');
            app.graphing.Text = '';
            app.graphing.Position = [105 171 30 27];

            % Create AddReverbButton
            app.AddReverbButton = uibutton(app.UIFigure, 'state');
            app.AddReverbButton.ValueChangedFcn = createCallbackFcn(app, @AddReverbButtonValueChanged, true);
            app.AddReverbButton.Visible = 'off';
            app.AddReverbButton.Text = 'Add Reverb';
            app.AddReverbButton.Position = [225 242 122 23];

            % Create play_reverb
            app.play_reverb = uibutton(app.UIFigure, 'push');
            app.play_reverb.ButtonPushedFcn = createCallbackFcn(app, @play_reverbButtonPushed, true);
            app.play_reverb.Icon = fullfile(pathToMLAPP, 'play.png');
            app.play_reverb.Visible = 'off';
            app.play_reverb.Tooltip = {'Play Recording'};
            app.play_reverb.Position = [227 206 31 28];
            app.play_reverb.Text = '';

            % Create stop_reverb
            app.stop_reverb = uibutton(app.UIFigure, 'push');
            app.stop_reverb.ButtonPushedFcn = createCallbackFcn(app, @stop_reverbButtonPushed, true);
            app.stop_reverb.Icon = fullfile(pathToMLAPP, 'stop.png');
            app.stop_reverb.Visible = 'off';
            app.stop_reverb.Tooltip = {'Stop Recording'};
            app.stop_reverb.Position = [271 206 31 28];
            app.stop_reverb.Text = '';

            % Create export
            app.export = uibutton(app.UIFigure, 'push');
            app.export.ButtonPushedFcn = createCallbackFcn(app, @exportButtonPushed, true);
            app.export.Icon = fullfile(pathToMLAPP, 'export.png');
            app.export.Visible = 'off';
            app.export.Tooltip = {'Stop Recording'};
            app.export.Position = [317 206 31 28];
            app.export.Text = '';

            % Create filename
            app.filename = uieditfield(app.UIFigure, 'text');
            app.filename.ValueChangingFcn = createCallbackFcn(app, @filenameValueChanging, true);
            app.filename.Visible = 'off';
            app.filename.Position = [227 170 120 28];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Reverberator

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
