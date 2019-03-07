function calib = stereo_calib_fp(f_single_calib_fp, obj_single_calib, obj_cb_geom, img_cbs, p_fp_p_dss, calib_config, intrin)

    util.verbose_disp('------------', 1, calib_config);
    util.verbose_disp('Performing stereo calibration with four point method...', 1, calib_config);

    % Create stereo object; copy stuff stuff single object
    obj_stereo_calib = class.calib.stereo(obj_single_calib.get_obj_A(), ...
                                          obj_single_calib.get_obj_R(), ...
                                          obj_single_calib.get_obj_cb_w2p(), ...
                                          obj_single_calib.get_obj_distortion(), ...
                                          calib_config);
    
    % Perform calibration ------------------------------------------------%

    % Get the calibration board points in world coordinates
    p_cb_ws = obj_cb_geom.get_p_cb_ws();

    % Get number of boards
    num_boards = numel(img_cbs.L);

    % Get optimization type
    if exist('intrin', 'var')
        optimization_type = 'extrinsic'; % Only optimize extrinsics
    else
        optimization_type = 'full';      % Optimize intrinsics and extrinsics
    end

    % Calibrate left camera
    util.verbose_disp('---------', 1, calib_config);
    util.verbose_disp('Calibrating left camera...', 1, calib_config);

    if exist('intrin', 'var')
        calib_L = f_single_calib_fp(obj_single_calib, ...
                                    obj_cb_geom, ...
                                    img_cbs.L, ...
                                    p_fp_p_dss.L, ...
                                    calib_config, ...
                                    intrin.L);
    else
        calib_L = f_single_calib_fp(obj_single_calib, ...
                                    obj_cb_geom, ...
                                    img_cbs.L, ...
                                    p_fp_p_dss.L, ...
                                    calib_config);
    end

    % Remove config since its redundant
    calib_L = rmfield(calib_L, 'config');

    % Calibrate right camera
    util.verbose_disp('---------', 1, calib_config);
    util.verbose_disp('Calibrating right camera...', 1, calib_config);

    if exist('intrin', 'var')
        calib_R = f_single_calib_fp(obj_single_calib, ...
                                    obj_cb_geom, ...
                                    img_cbs.R, ...
                                    p_fp_p_dss.R, ...
                                    calib_config, ...
                                    intrin.R);
    else
        calib_R = f_single_calib_fp(obj_single_calib, ...
                                    obj_cb_geom, ...
                                    img_cbs.R, ...
                                    p_fp_p_dss.R, ...
                                    calib_config);
    end

    % Remove config since its redundant
    calib_R = rmfield(calib_R, 'config');

    % Repackage initial guesses and other parameters ---------------------%

    % Get intrinsics
    A.L = calib_L.intrin.A;
    A.R = calib_R.intrin.A;
    d.L = calib_L.intrin.d;
    d.R = calib_R.intrin.d;

    % Get extrinsics
    Rs.L = {calib_L.extrin.R};
    Rs.R = {calib_R.extrin.R};
    ts.L = {calib_L.extrin.t};
    ts.R = {calib_R.extrin.t};
    p_cb_p_dss.L = {calib_L.extrin.p_cb_p_ds};
    p_cb_p_dss.R = {calib_R.extrin.p_cb_p_ds};
    cov_cb_p_dss.L = {calib_L.extrin.cov_cb_p_ds};
    cov_cb_p_dss.R = {calib_R.extrin.cov_cb_p_ds};
    idx_valids.L = {calib_L.extrin.idx_valid};
    idx_valids.R = {calib_R.extrin.idx_valid};

    % Get initial guesses for transform between left and right cameras ---%

    % Get least squares linear initial guess for R_s
    r = [];
    R = [];
    for i = 1:num_boards
        r = vertcat(r, Rs.R{i}(:)); %#ok<AGROW>
        R = vertcat(R, [Rs.L{i}(1, 1)*eye(3) Rs.L{i}(2, 1)*eye(3) Rs.L{i}(3, 1)*eye(3);
                        Rs.L{i}(1, 2)*eye(3) Rs.L{i}(2, 2)*eye(3) Rs.L{i}(3, 2)*eye(3);
                        Rs.L{i}(1, 3)*eye(3) Rs.L{i}(2, 3)*eye(3) Rs.L{i}(3, 3)*eye(3)]); %#ok<AGROW>
    end

    % Get least squares approximation
    R_s = reshape(alg.safe_lscov(R, r), 3, 3);
    R_s = alg.approx_R(R_s); % Get best rotational approximation

    % Get least squares linear guess for t_s
    t = [];
    T = [];
    for i = 1:num_boards
        t = vertcat(t, ts.R{i}-Rs.R{i}*Rs.L{i}'*ts.L{i}); %#ok<AGROW>
        T = vertcat(T, eye(3)); %#ok<AGROW>
    end

    % Get least squares approximation
    t_s = alg.safe_lscov(T, t);

    % Perform nonlinear refinement of all parameters ---------------------%

    util.verbose_disp('---------', 1, calib_config);
    util.verbose_disp(['Refining stereo parameters with ' optimization_type ' optimization...'], 1, calib_config);
  
    if calib_config.apply_covariance_optimization
        [A, d, Rs, ts] = obj_stereo_calib.refine(A, ...
                                                 d, ...
                                                 Rs, ...
                                                 ts, ...
                                                 R_s, ...
                                                 t_s, ...
                                                 p_cb_ws, ...
                                                 p_cb_p_dss, ...
                                                 idx_valids, ...
                                                 optimization_type, ...
                                                 cov_cb_p_dss);
    else
        [A, d, Rs, ts] = obj_stereo_calib.refine(A, ...
                                                 d, ...
                                                 Rs, ...
                                                 ts, ...
                                                 R_s, ...
                                                 t_s, ...
                                                 p_cb_ws, ...
                                                 p_cb_p_dss, ...
                                                 idx_valids, ...
                                                 optimization_type);
    end

    % Repackage outputs --------------------------------------------------%
    % Config
    calib.config = calib_config;
    % Store individual calibrations directly
    calib.L = calib_L;
    calib.R = calib_R;
    % Overwrite intrinsics and extrinsics with stereo optimized values
    calib.L.intrin.A = A.L;
    calib.L.intrin.d = d.L;
    calib.R.intrin.A = A.R;
    calib.R.intrin.d = d.R;
    for i = 1:num_boards
        calib.L.extrin(i).R = Rs.L{i};
        calib.L.extrin(i).t = ts.L{i};
        calib.L.extrin(i).p_cb_p_d_ms = obj_stereo_calib.p_cb_w2p_cb_p_d(p_cb_ws, Rs.L{i}, ts.L{i}, A.L, d.L);
        calib.R.extrin(i).R = Rs.R{i};
        calib.R.extrin(i).t = ts.R{i};
        calib.R.extrin(i).p_cb_p_d_ms = obj_stereo_calib.p_cb_w2p_cb_p_d(p_cb_ws, Rs.R{i}, ts.R{i}, A.R, d.R);
    end
    % Store relative extrinsics
    calib.R_s = R_s;
    calib.t_s = t_s;
end