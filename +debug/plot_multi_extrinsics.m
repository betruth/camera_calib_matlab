function plot_multi_extrinsics(Rs, ts, R_1s, t_1s, colors, alphas, opts, a)
    % This will plot multi extrinsics

    % Matlab's 3D plot is not very good; to get it in the orientation I want,
    % I've just switched the x, y, and z components with:
    %   x => y
    %   y => z
    %   z => x

    if ~exist('a', 'var')
        f = figure();
        a = axes(f);
    end

    % Hold
    hold(a, 'on');

    % Get number of cameras and boards
    num_cams = numel(R_1s);
    num_boards = numel(Rs);

    % Plot calibration boards --------------------------------------------%

    % xform is applied to get the calibration boards in the coordinates of
    % the first camera.
    for i = 1:num_boards
        % Get affine xform
        xform = [Rs{i} ts{i}; zeros(1, 3) 1];

        % Plot calibration board
        debug.plot_cb_3D(opts.obj_cb_geom, ...
                         xform, ...
                         colors(i, :), ...
                         alphas(i), ...
                         a);
    end

    % Plot cameras -------------------------------------------------------%

    % If camera size is not set (i.e. nan), then set the camera size to a
    % scalefactor of the calibration board target size.
    if isnan(opts.camera_size)
        if ~isa(opts.obj_cb_geom, 'class.cb_geom.size_intf')
            error('calibration board geometry must inherit from size interface to use default camera size');
        end

        camera_size = min(opts.obj_cb_geom.get_cb_height(), opts.obj_cb_geom.get_cb_width())/4;
    else
        camera_size = opts.camera_size;
    end

    for i = 1:num_cams
        % Get affine xform
        xform = inv([R_1s{i} t_1s{i}; zeros(1, 3) 1]);

        % Plot camera
        debug.plot_cam_3D(camera_size, ...
                          xform, ...
                          'k', ...
                          0.5, ...
                          1, ...
                          'r', ...
                          2, ...
                          10, ...
                          a);
    end

    % Format plot
    set(a, 'Ydir', 'reverse');
    set(a, 'Zdir', 'reverse');
    daspect(a, [1 1 1]);
    grid(a, 'on');
    view(a, 3)
    axis(a, 'tight');

    % Remove hold
    hold(a, 'off');
end
