%% Clear
clear, clc;

%% Set images
cb_img_paths.L = {'images/left01.jpg'};
cb_img_paths.R = {'images/right01.jpg'};

% Validate all calibration board images
cb_imgs.L = class.img.validate_similar_imgs(cb_img_paths.L);
cb_imgs.R = class.img.validate_similar_imgs(cb_img_paths.R);
                     
%% Load calibration config file
cal_config = util.load_cal_config('configs/stereo.conf');

%% Get four points in pixel coordinates per calibration board image
four_points_ps.L = {};
four_points_ps.R = {};
switch cal_config.calibration
    case 'four_point_auto'
        error('Automatic four point detection has not been implemented yet');
    case 'four_point_manual'
        % Four points are selected manually; Do refinement of four points 
        % here since automatic detection may not be on corners.
        [~, four_points_w] = alg.cb_points(cal_config);

        four_points_ps.L{1} = [244 94;
                               249 254;
                               479 86;
                               476 264];                            
        four_points_ps.R{1} = [128 110;
                               137 266;
                               346 94;
                               347 278];
                           
        % Refine
        for i = 1:length(cb_imgs.L)
            four_points_ps.L{i} = alg.refine_points(four_points_ps.L{i}, ...
                                                    cb_imgs.L(i), ...
                                                    alg.homography(four_points_w,four_points_ps.L{i},cal_config), ...
                                                    cal_config);  
            four_points_ps.R{i} = alg.refine_points(four_points_ps.R{i}, ...
                                                    cb_imgs.R(i), ...
                                                    alg.homography(four_points_w,four_points_ps.R{i},cal_config), ...
                                                    cal_config);   
        end   
end

%% Perform stereo calibration
[A,distortion,rotations,translations,R_s,t_s,board_points_ps,homographies_refine] = alg.stereo_calibrate(cb_imgs, ...
                                                                                                         four_points_ps, ...
                                                                                                         cal_config);

%% Save calibration
calibration_path = 'calibrations/stereo2.txt';
util.write_stereo_calib(cb_imgs, ...
                        board_points_ps, ...
                        four_points_ps, ...
                        A, ...
                        distortion, ...
                        rotations, ...
                        translations, ...
                        R_s, ...
                        t_s, ...
                        homographies_refine, ...
                        cal_config, ...
                        calibration_path);
                    
%% Read calibration
[cb_imgs,board_points_ps,four_points_ps,A,distortion,rotations,translations,R_s,t_s,homographies_refine,cal_config] = util.read_stereo_calib(calibration_path);
                    
%% Debug with stereo gui
f = figure(1);
debug.gui_stereo(cb_imgs, ...
                 board_points_ps, ...
                 four_points_ps, ...
                 A, ...
                 distortion, ...
                 rotations, ...
                 translations, ...
                 R_s, ...
                 t_s, ...
                 homographies_refine, ...
                 cal_config, ...
                 f);