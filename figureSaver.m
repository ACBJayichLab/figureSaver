function figureSaver
    % App preferences storage
    prefGroup = 'figureSaver';
    prefName  = 'RecentFilenames';
    
    % Load stored recent filenames
    if ispref(prefGroup,prefName)
        recentFilenames = getpref(prefGroup,prefName);
    else
        recentFilenames = {'myfigure'};
    end
    
    % Normalize to cell array of char
    if isstring(recentFilenames)
        recentFilenames = cellstr(recentFilenames);
    elseif ischar(recentFilenames)
        recentFilenames = {recentFilenames};
    end

    % === Create GUI ===
    appFig = uifigure('Name','figureSaver','Position',[100 100 400 200]);

    % Filename controls
    uilabel(appFig,'Text','File name:','Position',[20 140 100 22]);
    filenameDrop = uidropdown(appFig,...
        'Items',recentFilenames,...
        'Editable','on',...
        'Value',recentFilenames{1},...
        'Position',[120 140 200 22]);

    % Resolution controls
    uilabel(appFig,'Text','Resolution (dpi):','Position',[20 100 100 22]);
    resBox = uieditfield(appFig,'numeric',...
        'Position',[120 100 100 22],...
        'Value',600);   % default 600 dpi

    % Save button
    uibutton(appFig,'push',...
        'Text','Save Last Clicked Figure',...
        'Position',[120 50 200 30],...
        'ButtonPushedFcn',@saveLastClickedFigure);

    % === Callback: Save ===
    function saveLastClickedFigure(~,~)
        fname = strtrim(filenameDrop.Value);
        res   = resBox.Value;

        if isempty(fname)
            uialert(appFig,'Please enter a file name.','Error','Icon','error');
            return;
        end

        % Get the most recently clicked (active) figure
        try
            figHandle = gcf;
        catch
            uialert(appFig,'No figure selected. Click a figure window first.',...
                'Error','Icon','error');
            return;
        end

        % Prevent saving the app's own GUI
        if figHandle == appFig
            uialert(appFig,'Please click a plotting figure, not this GUI.',...
                'Error','Icon','error');
            return;
        end

        % Save as .fig
        savefig(figHandle, [fname '.fig']);

        % Save as .png (entire figure)
        exportgraphics(figHandle,[fname '.png'],'Resolution',res);

        % Update recent filenames (unique, most recent first, max 10)
        recentFilenames = [{fname}, setdiff(recentFilenames,fname,'stable')];
        if numel(recentFilenames) > 10
            recentFilenames = recentFilenames(1:10);
        end

        % Save preferences across sessions
        setpref(prefGroup,prefName,recentFilenames);

        % Update dropdown items
        filenameDrop.Items = recentFilenames;
        filenameDrop.Value = fname;

        % ✅ Success alert with blue info icon
        uialert(appFig, ...
            sprintf('Figure saved as:\n%s.fig\n%s.png',fname,fname), ...
            'Success','Icon','info');
    end
end
