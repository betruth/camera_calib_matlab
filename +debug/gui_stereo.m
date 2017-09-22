function gui_stereo(four_points_ps,cb_imgs,A,distortion,rotations,translations,R_s,t_s,board_points_ps,homographies_refine,cal_config,f)
    % GUI for stereo calibration
        
    if ~exist('f','var')
        f = figure(); 
    end
    clf(f);
    
    % Plot parameters
    num_boards = length(rotations.L);                                            
    colors = util.distinguishable_colors(num_boards,{'w','r','k'});
    idx_board = 2;
    alphas = 0.1*ones(1,num_boards);
    alphas(idx_board) = 1;
    
    % Set axes parameters
    padding_height = 0.1;
    padding_width = 0.05;
    extrinsics_height = 0.25;
    extrinsics_width = 0.2;
    res_height = extrinsics_height;
        
    % Set axes  
    pos_extrinsics = [padding_width 1-padding_height-extrinsics_height extrinsics_width extrinsics_height];
    axes_extrinsics = axes('Position',pos_extrinsics,'Parent',f);
    
    pos_cal_board = [padding_width padding_height pos_extrinsics(3) pos_extrinsics(2)-2*padding_height];
    axes_cal_board = axes('Position',pos_cal_board,'Parent',f);        
    
    pos_res_L = [pos_cal_board(1)+pos_cal_board(3)+padding_width 1-padding_height-res_height (1-(pos_cal_board(1)+pos_cal_board(3))-3*padding_width)/2 res_height];
    axes_res_L = axes('Position',pos_res_L,'Parent',f);
    
    pos_res_R = [pos_res_L(1)+pos_res_L(3)+padding_width pos_res_L(2) pos_res_L(3) pos_res_L(4)];
    axes_res_R = axes('Position',pos_res_R,'Parent',f);
    
    pos_board_L = [pos_res_L(1) pos_cal_board(2) pos_res_L(3) pos_res_L(2)-2*padding_height];
    axes_board_L = axes('Position',pos_board_L,'Parent',f);
    
    pos_board_R = [pos_res_R(1) pos_cal_board(2) pos_res_R(3) pos_res_R(2)-2*padding_height];
    axes_board_R = axes('Position',pos_board_R,'Parent',f);
    
    % Compute model points and residuals for plots
    
    board_points_ms.L = {};
    board_points_ms.R = {};
    res.L = {};
    res.R = {};
    for i = 1:num_boards
        % Left
        board_points_ms.L{i} = alg.p_m(A.L, ...
                                       distortion.L, ...
                                       rotations.L{i}, ...
                                       translations.L{i}, ...
                                       alg.cb_points(cal_config));
        res.L{i} = board_points_ms.L{i}-board_points_ps.L{i};   

        % Right
        board_points_ms.R{i} = alg.p_m(A.R, ...
                                       distortion.R, ...
                                       R_s*rotations.L{i}, ...
                                       R_s*translations.L{i}+t_s, ...
                                       alg.cb_points(cal_config));
        res.R{i} = board_points_ms.R{i}-board_points_ps.R{i};  
    end 
    
    % Plot
    debug.plot_stereo_extrinsic(rotations, ...
                                translations, ...
                                R_s, ...
                                t_s, ...
                                colors, ...
                                alphas, ...
                                cal_config, ...
                                axes_extrinsics);  
    title(axes_extrinsics,'Extrinsics','FontSize',10); 
    rotate3d(axes_extrinsics,'on');
    
    debug.plot_cb_board_info_2D(cal_config,axes_cal_board);
    title(axes_cal_board,'Calibration board','FontSize',10);
                                
    debug.plot_res(res.L,colors,alphas,axes_res_L); 
    title(axes_res_L,'Residuals (left)','FontSize',10); 
    xlabel(axes_res_L,{['mean: [' num2str(mean(res.L{idx_board})) ']'],[' stddev: [' num2str(std(res.L{idx_board})) ']']}, ...
           'FontSize',8);
    
    debug.plot_res(res.R,colors,alphas,axes_res_R);
    title(axes_res_R,'Residuals (right)','FontSize',10); 
    xlabel(axes_res_R,{['mean: [' num2str(mean(res.R{idx_board})) ']'],[' stddev: [' num2str(std(res.R{idx_board})) ']']}, ...
           'FontSize',8);    
           
    debug.plot_cb_img_info_2D(four_points_ps.L{idx_board}, ...
                              board_points_ps.L{idx_board}, ...
                              board_points_ms.L{idx_board}, ...   
                              A.L, ...     
                              distortion.L, ...      
                              rotations.L{idx_board}, ...
                              translations.L{idx_board}, ...
                              cb_imgs.L(idx_board), ...
                              homographies_refine.L{idx_board}, ...
                              cal_config, ...
                              axes_board_L);
    title(axes_board_L,'Left board', ...
          'FontSize',10,'Interpreter','none'); 
    xlabel(axes_board_L,cb_imgs.L(idx_board).get_path(), ...
           'FontSize',8,'Interpreter','none');    
    
    debug.plot_cb_img_info_2D(four_points_ps.R{idx_board}, ...
                              board_points_ps.R{idx_board}, ...
                              board_points_ms.R{idx_board}, ...   
                              A.R, ...   
                              distortion.R, ...
                              rotations.R{idx_board}, ...
                              translations.R{idx_board}, ...
                              cb_imgs.R(idx_board), ...
                              homographies_refine.R{idx_board}, ...
                              cal_config, ...
                              axes_board_R);
    title(axes_board_R,'Right board', ...
          'FontSize',10,'Interpreter','none'); 
    xlabel(axes_board_R,cb_imgs.R(idx_board).get_path(), ...
           'FontSize',8,'Interpreter','none');    
end