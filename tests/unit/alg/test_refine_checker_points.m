function test_refine_checker_points
    % Get tests path
    tests_path = fileparts(fileparts(fileparts(mfilename('fullpath'))));

    % Get circle points
    array_cb = rgb2gray(im2double(imread(fullfile(tests_path, 'data', 'checker1.jpg'))));

    opts.height_fp = 550;
    opts.width_fp = 550;
    opts.num_targets_height = 24;
    opts.num_targets_width = 24;
    opts.target_spacing = 50;
    opts.refine_checker_min_hw = 4;
    opts.refine_checker_max_hw = 15;
    opts.refine_checker_opencv_it_cutoff = 20;
    opts.refine_checker_opencv_norm_cutoff = 1.000000000000000e-03;
    opts.refine_checker_edges_it_cutoff = 20;
    opts.refine_checker_edges_norm_cutoff = 1.000000000000000e-03;
    opts.refine_checker_edges_h2_init = 0.750000000000000;
    opts.refine_checker_opencv_edges_diff_norm_cutoff = 2;
    target_mat = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 0 0 0 0 0 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1; ...
                  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
    [p_cb_ps_test, cov_cb_ps_test, idx_valid_test] = alg.refine_checker_points(array_cb, ...
                                                                               @(p)(alg.apply_homography_p2p(p, 1.0e+02 * [ 0.001256459398407   0.005934300321008   0.698997741053384
                                                                                                                          -0.004150564736654   0.000555600998692   4.686353109023896
                                                                                                                           0.000004070859589   0.000001141362501   0.010000000000000])), ...
                                                                               opts, ...
                                                                               target_mat(:));

    %{
    % Plot example
    f = figure;
    imshow(array_cb, []);
    hold on;
    plot(p_cb_ps_test(idx_valid_test, 1), p_cb_ps_test(idx_valid_test, 2), 'gs');
    sf = 1e3;
    for i = 1:numel(cov_cb_ps_test)
        if idx_valid_test(i)
            e = alg.cov2ellipse(cov_cb_ps_test{i}, p_cb_ps_test(i, :));
            external.ellipse(e(3)*sf, e(4)*sf, e(5), e(1), e(2), 'r');
        end
    end
    pause(1);
    close(f);
    %}

    % Assert
    load(fullfile(tests_path, 'data', 'checker1_points.mat'));

    assert(all(all(abs(p_cb_ps - p_cb_ps_test) < 1e-4)));
    for i = 1:numel(cov_cb_ps_test)
        assert(all(all(abs(cov_cb_ps{i} - cov_cb_ps_test{i}) < 1e-4))); %#ok<IDISVAR, USENS>
    end
    assert(all(idx_valid  == idx_valid_test));
end
