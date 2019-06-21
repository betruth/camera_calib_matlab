function [p, cov_p] = refine_ring_opencv(array_dx, array_dy, W)
    % Performs "opencv" refinement of a ring center on input array
    % gradients; it is assumed the ring is circular (i.e. flat, without
    % perspective transform).
    %
    % This is the same technique as the "opencv" method for checkers,
    % except it's done on the orthogonal gradient. This will also
    % technically work on a circle, but I'll consider an circle a subset
    % of a ring.
    %
    % Inputs:
    %   array_dx - array; MxN array gradient in x direction
    %   array_dy - array; MxN array gradient in y direction
    %   W - array; optional MxN weight array
    %
    % Outputs:
    %   p - array; 1x2 refined ring center
    %   cov_p - array; 2x2 covariance of ring center

    if ~exist('W', 'var')
        W = ones(size(array_dx));
    end

    % Get coordinates of pixels
    bb_array = alg.bb_array(array_dx);
    [ys, xs] = alg.ndgrid_bb(bb_array);
    ps = [xs(:) ys(:)];

    % Perform normalization
    T = norm_mat(ps);
    p_augs = [ps ones(size(ps, 1), 1)]';
    p_norms = T*p_augs;

    % Form linear system
    A = [array_dy(:) -array_dx(:)];
    b = array_dy(:).*p_norms(1, :)' - array_dx(:).*p_norms(2, :)';

    % Solve
    [p, ~, ~, cov_p] = alg.safe_lscov(A, b, W(:));

    % "Undo" normalization
    T_inv = alg.safe_inv(T);
    p = T_inv*[p; 1];
    p = p(1:2)';
    cov_p = T_inv(1:2, 1:2)*cov_p*T_inv(1:2, 1:2)';
end

function T_norm = norm_mat(ps)
    xs = ps(:, 1);
    ys = ps(:, 2);
    mean_x = mean(xs);
    mean_y = mean(ys);
    s_m = sqrt(2)*size(ps, 1)./sum(sqrt((xs-mean_x).^2+(ys-mean_y).^2));
    T_norm = [s_m 0   -mean_x*s_m;
              0   s_m -mean_y*s_m;
              0   0    1];
end
