function [p, cov_p] = refine_checker_edges(array_dx, array_dy, l1, l2, opts, W)
    % Performs "edges" refinement of a checker center.
    %
    % Inputs:
    %   array_dx - array; MxN array gradient in x direction
    %   array_dy - array; MxN array gradient in y direction
    %   l1 - array; 3x1 array of a line in the form:
    %       [a; b; c] where ax + by + c = 0
    %   l2 - array; 3x1 array of a line in the form:
    %       [a; b; c] where ax + by + c = 0
    %   opts - struct;
    %       .refine_checker_edges_h2_init - scalar; initial value of h2
    %           parameter in "edges" checker refinement
    %       .refine_checker_edges_it_cutoff - int; max number of
    %           iterations performed for "edges" checker refinement
    %       .refine_checker_edges_norm_cutoff - scalar; cutoff for the
    %           difference in norm of the parameter vector for "edges"
    %           checker refinement
    %   W - array; optional MxN weight array
    %
    % Outputs:
    %   p - array; 1x2 refined checker center
    %   cov_p - array; 2x2 covariance array

    if ~exist('W', 'var')
        W = ones(size(array_dx));
    end

    % Get coordinates of pixels
    bb_array = alg.bb_array(array_dx);
    [ys, xs] = alg.ndgrid_bb(bb_array);
    xs = xs(:);
    ys = ys(:);

    % Initial guess for center point
    p_init = alg.line_line_intersect(l1, l2);

    % Get gradient magnitude - I found that using squared magnitude is
    % better because it tends to supress smaller gradients due to noise
    array_grad_mag = array_dx.^2 + array_dy.^2;

    % Normalize gradient magnitude between 0 and 1
    array_grad_mag = alg.normalize_array(array_grad_mag, 'min-max');

    % Create initial parameter vector
    params = [1;
              opts.refine_checker_edges_h2_init;
              atan(-l1(1)/l1(2));
              atan(-l2(1)/l2(2));
              p_init(1);
              p_init(2)];

    % Perform iterations until convergence
    for it = 1:opts.refine_checker_edges_it_cutoff
        % Get residual and jacobian
        [res, jacob] = calc_res_and_jacob(params, ...
                                          array_grad_mag, ...
                                          xs, ...
                                          ys);

        % Get and store update
        delta_params = -alg.safe_lscov(jacob, res, W(:));
        params = params + delta_params;

        % Exit if change in distance is small
        if norm(delta_params) < opts.refine_checker_edges_norm_cutoff
            break
        end
    end

    % Get center point
    p = params(5:6)';

    % Get covariance of center point
    [res, jacob] = calc_res_and_jacob(params, ...
                                      array_grad_mag, ...
                                      xs, ...
                                      ys);

    % Get covariance
    [~, ~, ~, cov_params] = alg.safe_lscov(jacob, res, W(:));
    cov_p = cov_params(5:6, 5:6);
end

function [res, jacob] = calc_res_and_jacob(params, array_grad_mag, xs, ys)
    % Sample edge function
    f = params(1)*exp(-params(2)^2*((xs-params(5))*sin(params(3))-(ys-params(6))*cos(params(3))).^2) + ...
        params(1)*exp(-params(2)^2*((xs-params(5))*sin(params(4))-(ys-params(6))*cos(params(4))).^2) - ...
        2*params(1)*exp(-params(2)^2*((xs-params(5)).^2+(ys-params(6)).^2));

    % Get residuals
    res = f-array_grad_mag(:);

    % Get jacobian of edge function
    jacob = [exp(-params(2)^2*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2) - 2*exp(-params(2)^2*((params(5) - xs).^2 + (params(6) - ys).^2)) + exp(-params(2)^2*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2), ...
             4*params(1)*params(2)*exp(-params(2)^2*((params(5) - xs).^2 + (params(6) - ys).^2)).*((params(5) - xs).^2 + (params(6) - ys).^2) - 2*params(1)*params(2)*exp(-params(2)^2*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2).*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2 - 2*params(1)*params(2)*exp(-params(2)^2*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2).*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2, ...
             2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2).*(cos(params(3))*(params(5) - xs) + sin(params(3))*(params(6) - ys)).*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)), ...
             2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2).*(cos(params(4))*(params(5) - xs) + sin(params(4))*(params(6) - ys)).*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)), ...
             2*params(1)*params(2)^2*exp(-params(2)^2*((params(5) - xs).^2 + (params(6) - ys).^2)).*(2*params(5) - 2*xs) + 2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2).*(sin(params(3))*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs))) + 2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2).*(sin(params(4))*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs))), ...
             2*params(1)*params(2)^2*exp(-params(2)^2*((params(5) - xs).^2 + (params(6) - ys).^2)).*(2*params(6) - 2*ys) - 2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs)).^2).*(cos(params(3))*(cos(params(3))*(params(6) - ys) - sin(params(3))*(params(5) - xs))) - 2*params(1)*params(2)^2*exp(-params(2)^2*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)).^2).*(cos(params(4))*(cos(params(4))*(params(6) - ys) - sin(params(4))*(params(5) - xs)))];
end
