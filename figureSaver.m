function appFig=figureSaver
    % App preferences storage
    prefGroup = 'figureSaver';
    prefFiles = 'RecentFilenames';
    prefPath  = 'SaveFolder';
    
    % === Load stored recent filenames ===
    if ispref(prefGroup,prefFiles)
        recentFilenames = getpref(prefGroup,prefFiles);
    else
        recentFilenames = {'myfigure'};
    end
    
    % Normalize to cell array of char
    if isstring(recentFilenames)
        recentFilenames = cellstr(recentFilenames);
    elseif ischar(recentFilenames)
        recentFilenames = {recentFilenames};
    end

    % === Load stored save folder ===
    if ispref(prefGroup,prefPath)
        saveFolder = getpref(prefGroup,prefPath);
    else
        saveFolder = pwd; % default = current folder
    end
    
    % === Create GUI ===
    appFig = uifigure('Name','figureSaver','Position',[200 200 360 160]);

    % Filename controls
    uilabel(appFig,'Text','File name:','Position',[10,130,100,22]);
    filenameDrop = uidropdown(appFig,...
        'Items',recentFilenames,...
        'Editable','on',...
        'Value',recentFilenames{1},...
        'Position',[110,130,230,22]);

    % Resolution controls
    uilabel(appFig,'Text','Resolution (dpi):','Position',[10,100,100,22]);
    resBox = uieditfield(appFig,'numeric',...
        'Position',[110,100,60,22],...
        'Value',600,...
        'HorizontalAlignment','center');   % default 600 dpi centered

    % Checkboxes for file formats
    figCheck = uicheckbox(appFig,'Text','.fig','Position',[180,100,50,22],'Value',true);
    pngCheck = uicheckbox(appFig,'Text','.png','Position',[230,100,50,22],'Value',true);
    epsCheck = uicheckbox(appFig,'Text','.eps','Position',[280,100,50,22],'Value',false);

    % Folder path controls
    uilabel(appFig,'Text','Save folder:','Position',[10,70,100,22]);
    folderBox = uieditfield(appFig,'text',...
        'Position',[110 70 230 22],...
        'Value',saveFolder);

    % Status label (just above button, smaller font)
    statusLabel = uilabel(appFig,...
        'Text','',...
        'Position',[10,45,340,22],...
        'FontColor',[0 0.5 0],...   % green
        'FontSize',10,...
        'HorizontalAlignment','left');

    % Save button (no overwrite)
    uibutton(appFig,'push',...
        'Text','Save Last Clicked Figure',...
        'Position',[150,10,200,30],...
        'ButtonPushedFcn',@(~,~)saveLastClickedFigure(false));

    % Overwrite Save button
    uibutton(appFig,'push',...
        'Text','Overwrite Save',...
        'Position',[10,10,130,30],...
        'ButtonPushedFcn',@(~,~)saveLastClickedFigure(true));

    % === Callback: Save ===
    function saveLastClickedFigure(overwrite)
        fname   = strtrim(filenameDrop.Value);
        res     = resBox.Value;
        outPath = strtrim(folderBox.Value);

        if isempty(fname)
            showStatus('Please enter a file name.','error');
            return;
        end

        if isempty(outPath) || ~isfolder(outPath)
            showStatus('Please enter a valid folder path.','error');
            return;
        end

        % Get the most recently clicked (active) figure
        try
            figHandle = gcf;
        catch
            showStatus('No figure selected. Click a figure window first.','error');
            return;
        end

        % Prevent saving the app's own GUI
        if figHandle == appFig
            showStatus('Please click a plotting figure, not this GUI.','error');
            return;
        end

        % Build full save path base
        fullBase = fullfile(outPath,fname);

        % Collect intended save files
        toSave = {};
        if figCheck.Value, toSave{end+1} = [fullBase '.fig']; end
        if pngCheck.Value, toSave{end+1} = [fullBase '.png']; end
        if epsCheck.Value, toSave{end+1} = [fullBase '.eps']; end

        if isempty(toSave)
            showStatus('No file formats selected. Check at least one.','error');
            return;
        end

        % === Check overwrite condition ===
        if ~overwrite
            existsAlready = any(cellfun(@(f) exist(f,'file'),toSave));
            if existsAlready
                showStatus('File already exists. Use Overwrite Save instead.','error');
                return;
            end
        end

        % Save files
        savedFiles = {};
        if figCheck.Value
            savefig(figHandle, [fullBase '.fig']);
            savedFiles{end+1} = [fullBase '.fig'];
        end

        if pngCheck.Value
            exportgraphics(figHandle,[fullBase '.png'],'Resolution',res);
            savedFiles{end+1} = [fullBase '.png'];
        end

        if epsCheck.Value
            print(figHandle,[fullBase '.eps'],'-depsc',['-r' num2str(res)]);
            savedFiles{end+1} = [fullBase '.eps'];
        end

        % Update recent filenames (unique, most recent first, max 10)
        recentFilenames = [{fname}, setdiff(recentFilenames,fname,'stable')];
        if numel(recentFilenames) > 10
            recentFilenames = recentFilenames(1:10);
        end

        % Save preferences across sessions
        setpref(prefGroup,prefFiles,recentFilenames);
        setpref(prefGroup,prefPath,outPath);

        % Update dropdown items
        filenameDrop.Items = recentFilenames;
        filenameDrop.Value = fname;

        % ✅ Success message
        showStatus(sprintf("Saved:%s", strjoin(savedFiles,newline)),'success');
    end

    % === Helper: show temporary status message ===
    function showStatus(msg,type)
        switch type
            case 'error'
                statusLabel.FontColor = [0.8 0 0]; % red
            otherwise
                statusLabel.FontColor = [0 0.5 0]; % green
        end
        statusLabel.Text = msg;

        % Auto-clear after 5 seconds
        t = timer('StartDelay',5,'TimerFcn',@(~,~) clearStatus());
        start(t);
    end

    function clearStatus()
        if isvalid(statusLabel)
            statusLabel.Text = '';
        end
        stop(timerfindall); delete(timerfindall); % cleanup timers
    end
end
