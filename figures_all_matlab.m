% figures_all_matlab_jsac_style.m
% ================================================
% Revised plotting/styling version inspired by the
% visual language of the uploaded journal article.
%
% FIGURE-TO-PAPER MAPPING
% -----------------------
%   fig1_val_w0       -> Paper Figure 1(a): P_total vs w0
%   fig2_val_alpha    -> Paper Figure 1(b): P_total vs alpha (bar chart)
%   fig3_val_vs_n     -> Paper Figure 1(c): P_total vs n
%   fig4_val_vs_m     -> Paper Figure 2(a): P_total vs m
%   fig5_val_condpdf  -> Paper Figure 2(b): Conditional score density
%   fig6_val_benchmark-> Paper Figure 2(c): Benchmark distribution vs q
%   fig7_app_policy   -> Paper Figure 3(a): Policy comparison (3 contexts)
%   fig8_app_w0       -> Paper Figure 3(b): P_total vs w0 (4 contexts)
%   fig9_app_alpha    -> Paper Figure 3(c): P_total vs alpha (4 contexts)
%   fig10_robust_w0   -> Paper Table  6:    Heavy-tail robustness
%   (Paper Figure 4 is produced by backtest_kpi_full.py, not this script)
%
% Core analytical / Monte Carlo computations are unchanged.
% Main changes:
%   - IEEE / journal-like single-panel styling
%   - compact boxed legends
%   - article-inspired color palette
%   - red-star Monte Carlo grammar where appropriate
%   - no in-axes titles (caption carries meaning)
%   - direct on-plot annotations where cleaner than large legends
%   - Figure 2 rendered as a chart (bars) instead of curves, as requested
%
% HOW TO RUN:
%   >> figures_all_matlab_jsac_style
%
% Produces:
%   fig2_val_alpha.pdf
%   fig3_val_vs_n.pdf
%   fig4_val_vs_m.pdf
%   fig5_val_condpdf.pdf
%   fig6_val_benchmark.pdf
%   fig7_app_policy.pdf
%   fig8_app_w0.pdf
%   fig9_app_alpha.pdf
%
% NOTE:
%   The mathematics/data generation are from the user's original script.
%   Only plotting logic and visual parameters have been reworked.

clear; clc; close all;
rng(42);

%% =========================================================================
%% USER SETTINGS
%% =========================================================================
SAVE_FMT   = 'eps';   % currently written but reserved for future use
OUTPUT_DIR = '.';
N_MC       = 20000;
DPI        = 600;

%% =========================================================================
%% BASE PARAMETERS
%% =========================================================================
BP.mu_R  = 0.008;   BP.sig_R = 0.055;
BP.mu_M  = 0.000;   BP.sig_M = 0.650;
BP.Ta    = 0.020;   BP.Tb    = 0.300;
BP.n     = 120;     BP.m     = 10;
BP.q     = 5;       BP.w0    = 5;
BP.s1    = 1;       BP.s2    = 0;
BP.wmin  = 1;       BP.wmax  = 20;
BP.alpha = 0.5;

%% =========================================================================
%% THREE APPLICATION PARAMETER SETS
%% =========================================================================
APP(1).name  = 'Large-Cap Equity';
APP(1).mu_R  = 0.008;  APP(1).sig_R = 0.055;
APP(1).mu_M  = 0.000;  APP(1).sig_M = 0.650;
APP(1).Ta    = 0.020;  APP(1).Tb    = 0.300;
APP(1).n     = 120;    APP(1).m     = 10;

APP(2).name  = 'Small-Cap Equity';
APP(2).mu_R  = 0.010;  APP(2).sig_R = 0.075;
APP(2).mu_M  = 0.400;  APP(2).sig_M = 0.800;
APP(2).Ta    = 0.030;  APP(2).Tb    = 0.600;
APP(2).n     = 150;    APP(2).m     = 12;

APP(3).name  = 'High-Yield Credit';
APP(3).mu_R  = 0.004;  APP(3).sig_R = 0.025;
APP(3).mu_M  = -0.300; APP(3).sig_M = 0.500;
APP(3).Ta    = 0.008;  APP(3).Tb    = -0.100;
APP(3).n     = 150;    APP(3).m     = 10;

APP(4).name  = 'Liq-Stressed';
APP(4).mu_R  = 0.002;  APP(4).sig_R = 0.080;
APP(4).mu_M  = 0.000;  APP(4).sig_M = 0.500;
APP(4).Ta    = 0.010;  APP(4).Tb    = 0.400;
APP(4).n     = 120;    APP(4).m     = 10;

%% =========================================================================
%% ARTICLE-INSPIRED COLOR PALETTE
%% =========================================================================
C.redSim   = [1.00 0.23 0.19];
C.blue     = [0.18 0.33 1.00];
C.darkGray = [0.30 0.30 0.30];
C.gray     = [0.48 0.48 0.48];
C.black    = [0.12 0.12 0.12];
C.orange   = [0.77 0.42 0.18];
C.green    = [0.18 0.55 0.34];
C.purple   = [0.72 0.48 0.79];
C.magenta  = [0.90 0.00 0.90];
C.cyan     = [0.00 0.84 1.00];
C.lightBlueFill = [0.85 0.91 1.00];
C.lightGray = [0.88 0.88 0.88];

APP(1).color = C.black;
APP(2).color = C.orange;
APP(3).color = C.green;
APP(4).color = [0.76 0.14 0.14];   % dark red for Liq-Stressed

%% =========================================================================
%% GLOBAL STYLE (journal-like)
%% =========================================================================
set(groot,'defaultFigureColor','w');
set(groot,'defaultAxesColor','w');
set(groot,'defaultAxesBox','on');
set(groot,'defaultAxesFontName','Times New Roman');
set(groot,'defaultTextFontName','Times New Roman');
set(groot,'defaultAxesFontSize',10);
set(groot,'defaultTextFontSize',10);
set(groot,'defaultAxesLineWidth',0.8);
set(groot,'defaultLineLineWidth',1.0);
set(groot,'defaultAxesTickDir','in');
set(groot,'defaultAxesTickLabelInterpreter','latex');
set(groot,'defaultLegendInterpreter','latex');
set(groot,'defaultTextInterpreter','latex');
set(groot,'defaultAxesXGrid','on');
set(groot,'defaultAxesYGrid','on');
set(groot,'defaultAxesGridColor',[0.82 0.82 0.82]);
set(groot,'defaultAxesGridAlpha',1.0);
set(groot,'defaultAxesGridLineStyle','-');

%% =========================================================================
%% RUN FIGURES
%% =========================================================================
fprintf('%s\nGenerating restyled Figures 1--10 ...\n%s\n', ...
    repmat('=',1,66), repmat('=',1,66));
fig1_val_w0(BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI);
fig2_val_alpha(BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig3_val_vs_n(BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig4_val_vs_m(BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig5_val_condpdf(BP, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig6_val_benchmark(BP, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig7_app_policy(APP(1:3), BP, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig8_app_w0(APP(1:4), BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig9_app_alpha(APP(1:4), BP, SAVE_FMT, OUTPUT_DIR, DPI, C);
fig10_robust_w0(BP, N_MC, SAVE_FMT, OUTPUT_DIR, DPI, C);   % FIX: was missing
fprintf('\n%s\nDone. Figures saved to: %s\n%s\n', ...
    repmat('=',1,66), OUTPUT_DIR, repmat('=',1,66));

%% =========================================================================
%% ALL FUNCTIONS BELOW
%% =========================================================================

function [p_func, pe, mu_c, sig_c, s_min] = ...
        build_model(mu_R, sig_R, mu_M, sig_M, Ta, Tb, alpha)

    a   = alpha;
    dR  = (Ta - mu_R) / sig_R;
    dM  = (Tb - mu_M) / sig_M;
    pe  = (1 - normcdf(dR)) * (1 - normcdf(dM));
    vs  = sqrt(a^2 + (1 - a)^2);
    % FIX: guard against division by zero when threshold is in the far tail
    lR  = normpdf(dR) / max(1 - normcdf(dR), 1e-14);
    lM  = normpdf(dM) / max(1 - normcdf(dM), 1e-14);
    mu_c   = a*lR + (1-a)*lM;
    sig_c2 = a^2*(1+dR*lR-lR^2) + (1-a)^2*(1+dM*lM-lM^2);
    sig_c  = sqrt(max(sig_c2, 1e-10));
    s_min  = a*dR + (1-a)*dM;

    fSD_anon = @(s) fSD_eval(s, s_min, a, dR, dM, vs, pe);

    s_grid  = linspace(s_min, 5.0, 120);
    ps_vals = zeros(1, 120);
    for i = 1:120
        if s_grid(i) >= 4.5
            ps_vals(i) = 0;
        else
            ps_vals(i) = pe * min( ...
                integral(fSD_anon, s_grid(i), 8.0, ...
                    'RelTol',1e-7,'AbsTol',1e-10), 1.0);
        end
    end
    p_func = @(s) p_interp(s, s_min, pe, s_grid, ps_vals);
end

function v = fSD_eval(s, s_min, a, dR, dM, vs, pe)
    cu = ((s - (1-a)*dM) ./ a  -  a.*s ./ vs.^2) .* vs ./ (1-a);
    cl = (dR - a.*s ./ vs.^2) .* vs ./ (1-a);
    v  = max((1/(pe*vs)) .* normpdf(s./vs) .* ...
             (normcdf(cu) - normcdf(cl)), 0);
    v(s  <= s_min) = 0;
    v(cu <= cl)    = 0;
end

function v = p_interp(s, s_min, pe, s_grid, ps_vals)
    if s <= s_min;  v = pe;  return; end
    if s >= 5.0;    v = 0;   return; end
    v = max(interp1(s_grid, ps_vals, s, 'linear'), 0);
end

function v = P_rec(p, mp, r, w, s1, s2, wmin, wmax, C)
    if mp == 0;           v = 1; return; end
    if r <= 0 || r < mp;  v = 0; return; end
    key = sprintf('%d|%d|%d', mp, r, w);
    if isKey(C, key);  v = C(key); return; end
    wh = min(w,r); wp = min(w+s2,wmax); wm = max(w-s1,wmin);
    ph0 = (1-p)^wh; ph1 = wh*p*(1-p)^(wh-1); phg = 1-ph0-ph1;
    v = ph0*P_rec(p,mp,r-wh,wp,s1,s2,wmin,wmax,C);
    if mp==1; v=v+ph1; else; v=v+ph1*P_rec(p,mp-1,r-wh,w,s1,s2,wmin,wmax,C); end
    if phg > 1e-8  % FIX: aligned with Python threshold (was 1e-10)
        if mp==1; v=v+phg; else; v=v+phg*P_rec(p,mp-1,r-wh,wm,s1,s2,wmin,wmax,C); end
    end
    C(key) = v;
end

function tot = P_total(p_func, pe, mu_c, sig_c, n, m, q, w0, s1, s2, wmin, wmax)
    K=8; [xg,wg]=gh_nodes(K); sc_q=sig_c/sqrt(q); tot=0;
    for q0=q:(n-m)
        r=n-q0; if r<m; break; end
        pQ=nbinpdf(q0-q,q,pe); if pQ<1e-8; continue; end  % consistent with Python
        gh=0;
        for k=1:K
            C=containers.Map('KeyType','char','ValueType','double');
            gh=gh+wg(k)*P_rec(p_func(mu_c+sqrt(2)*sc_q*xg(k)), ...
                               m,r,w0,s1,s2,wmin,wmax,C);
        end
        tot=tot+pQ*gh/sqrt(pi);
    end
end

function out = run_mc(mu_R,sig_R,mu_M,sig_M,Ta,Tb,alpha, ...
                      n,m,q,w0,s1,s2,wmin,wmax,N)
    suc=0;
    for trial_=1:N
        R=mu_R+sig_R*randn(n,1); M=mu_M+sig_M*randn(n,1);
        D=(R>=Ta)&(M>=Tb);
        S=alpha*(R-mu_R)/sig_R+(1-alpha)*(M-mu_M)/sig_M;
        ec=0; bs=[]; i=1;
        while i<=n&&ec<q
            if D(i); ec=ec+1; bs(ec)=S(i); end %#ok<AGROW>
            i=i+1;
        end
        if ec<q; continue; end
        Ss=mean(bs); quota=m; w=w0; j=i;
        while j<=n&&quota>0
            we=min(w,n-j+1); if we==0; break; end
            H=0; fi=-1;
            for k=j:j+we-1
                if D(k)&&S(k)>Ss; H=H+1; if fi<0; fi=k; end; end
            end
            if fi>0; quota=quota-1; end
            if H==0; w=min(w+s2,wmax); elseif H>=2; w=max(w-s1,wmin); end
            j=j+we;
        end
        suc=suc+(quota==0);
    end
    out=suc/N;
end

function [x,w] = gh_nodes(n)
    i=(1:n-1)'; b=sqrt(i/2); J=diag(b,1)+diag(b,-1);
    [V,D]=eig(J); d=diag(D); [x,ix]=sort(d);
    V=V(:,ix); w=sqrt(pi)*(V(1,:).^2)';
end

function sfig(fig, name, fmt, out_dir, dpi) %#ok<INUSL>
    if nargin < 5; dpi = 600; end
    if nargin < 4 || isempty(out_dir); out_dir = '.'; end

    fig_path = fullfile(out_dir, [name '.fig']);
    eps_path = fullfile(out_dir, [name '.eps']);
    png_path = fullfile(out_dir, [name '_preview.png']);

    savefig(fig, fig_path);
    print(fig, eps_path, '-depsc', '-painters', '-r600');
    print(fig, png_path, '-dpng', sprintf('-r%d', 150));

    fprintf('  -> %s  (.fig + .eps)\n', name);
end

function fig = make_ieee_figure(w_in, h_in)
    % w_in, h_in in inches; single-col=3.46 x 2.60, double-col=6.89 x 2.90
    fig = figure('Color','w','Units','inches', ...
        'Position',[1 1 w_in h_in], ...
        'PaperUnits','inches', ...
        'PaperSize',[w_in h_in], ...
        'PaperPosition',[0 0 w_in h_in], ...
        'PaperPositionMode','manual', ...
        'InvertHardcopy','off');
end

function ax = make_axes(fig)
    ax = axes('Parent',fig, 'Units','normalized', ...
        'Position',[0.15 0.16 0.80 0.77], ...
        'Box','on', 'LineWidth',0.8, 'Layer','top', ...
        'FontName','Times New Roman', 'FontSize',10, ...
        'TickDir','in', 'TickLength',[0.015 0.015], ...
        'XMinorTick','off', 'YMinorTick','off', ...
        'XGrid','on', 'YGrid','on', ...
        'GridColor',[0.82 0.82 0.82], 'GridAlpha',1.0, ...
        'GridLineStyle','-');
    hold(ax,'on');
end

function format_legend(lg)
    lg.Box = 'on';
    lg.FontSize = 9;
    lg.FontName = 'Times New Roman';
    lg.Interpreter = 'latex';
    lg.EdgeColor = [0 0 0];
    lg.LineWidth = 0.5;
    lg.Color = [1 1 1];
    try
        lg.ItemTokenSize = [16 9];
    catch
    end
end

function add_direct_label(ax, x, y, str, color, rot, halign)
    if nargin < 7; halign = 'left'; end
    if nargin < 6; rot = 0; end
    text(ax, x, y, str, 'Color', color, 'FontSize', 10, ...  % FIX: was 9
        'Interpreter','latex', 'Rotation', rot, ...
        'HorizontalAlignment', halign, 'VerticalAlignment','middle');
end
% =========================================================================
%  FIG 1 -- Validation: P_total vs w0
%  JSAC-style revision: compact journal styling, no title,
%  red-star simulation markers, thin boxed axes, direct annotations.
% =========================================================================
function fig1_val_w0(BP, N_MC, fmt, dir, dpi)

    fprintf('\n[Fig 1] P_total vs w0 ...\n');

    % -----------------------------
    % Compute data
    % -----------------------------
    w0r = 1:12;
    nw  = numel(w0r);

    Ps = zeros(1,nw);   % Shrink-only analytical
    Pc = zeros(1,nw);   % Constant analytical
    Pm = zeros(1,nw);   % Shrink-only MC
    Qm = zeros(1,nw);   % Constant MC

    [pf,pe,mc,sc] = build_model(BP.mu_R, BP.sig_R, BP.mu_M, BP.sig_M, ...
                                BP.Ta, BP.Tb, BP.alpha);

    for i = 1:nw
        w = w0r(i);

        Ps(i) = P_total(pf,pe,mc,sc, BP.n,BP.m,BP.q, w,1,0, BP.wmin,BP.wmax);
        Pc(i) = P_total(pf,pe,mc,sc, BP.n,BP.m,BP.q, w,0,0, BP.wmin,BP.wmax);

        Pm(i) = run_mc(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb, ...
                       BP.alpha,BP.n,BP.m,BP.q,w,1,0,BP.wmin,BP.wmax,N_MC);

        Qm(i) = run_mc(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb, ...
                       BP.alpha,BP.n,BP.m,BP.q,w,0,0,BP.wmin,BP.wmax,N_MC);

        fprintf('  w0=%2d  shrink %.4f(MC=%.4f)  const %.4f(MC=%.4f)\n', ...
                w, Ps(i), Pm(i), Pc(i), Qm(i));
    end

    % -----------------------------
    % JSAC-like palette
    % -----------------------------
    C.blue    = [0.18 0.33 1.00];   % analytical family 1
    C.dgray   = [0.30 0.30 0.30];   % analytical family 2
    C.redSim  = [1.00 0.23 0.19];   % simulation stars
    C.textblu = [0.18 0.33 1.00];
    C.textgry = [0.35 0.35 0.35];

    % -----------------------------
    % Figure / axes
    % -----------------------------
    fig = figure('Color','w', ...
                 'Units','inches', ...
                 'Position',[1 1 3.45 2.60]);

    ax = axes('Parent',fig);
    hold(ax,'on');
    box(ax,'on');

    set(ax, ...
        'FontName','Times New Roman', ...
        'FontSize',8.5, ...
        'LineWidth',0.6, ...
        'TickDir','in', ...       % FIX: was 'out'; all other figs use 'in'
        'TickLength',[0.018 0.018], ...
        'XMinorTick','off', ...
        'YMinorTick','off', ...
        'Layer','top', ...
        'Color','w', ...
        'XGrid','on', ...         % FIX: was 'off'; aligns with global default
        'YGrid','on');            % FIX: was 'off'

    % -----------------------------
    % Plot analytical curves
    % -----------------------------
    h1 = plot(ax, w0r, Ps, '-', ...
        'Color', C.blue, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Shrink-only, Analytical');

    h2 = plot(ax, w0r, Pc, '--', ...
        'Color', C.blue, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Constant, Analytical');

    % Sparse indices for simulation markers
    idx = unique(round(linspace(1, nw, min(nw,10))));

    h3 = plot(ax, w0r(idx), Pm(idx), '*', ...
        'Color', C.redSim, ...
        'LineStyle','none', ...
        'MarkerSize', 5, ...
        'LineWidth', 0.8, ...
        'DisplayName', 'Simulation');

    plot(ax, w0r(idx), Qm(idx), '*', ...
        'Color', C.redSim, ...
        'LineStyle','none', ...
        'MarkerSize', 5, ...
        'LineWidth', 0.8, ...
        'HandleVisibility','off');

    % -----------------------------
    % Labels
    % -----------------------------
    xlabel(ax, '$w_0$', 'Interpreter','latex', 'FontSize',10);
    ylabel(ax, '$P_{\rm total}$', 'Interpreter','latex', 'FontSize',10);

    % -----------------------------
    % Limits / ticks
    % -----------------------------
    xmin = min(w0r);
    xmax = max(w0r);

    yall = [Ps(:); Pc(:); Pm(:); Qm(:)];
    ymin = min(yall);
    ymax = max(yall);
    yrng = ymax - ymin;
    if yrng <= 0
        yrng = max(1e-3, abs(ymax));
    end

    xlim(ax, [xmin xmax]);
    ylim(ax, [max(0, ymin - 0.06*yrng), ymax + 0.10*yrng]);

    ax.XTick = 1:1:12;

    % A light, paper-like y tick density
    try
        yticks(ax, linspace(ax.YLim(1), ax.YLim(2), 6));
    catch
        % fallback for older MATLAB
    end

    % -----------------------------
    % Compact legend (boxed, like article)
    % -----------------------------
    lg = legend(ax, [h1 h2 h3], ...
        'Location','northeast', ...
        'Interpreter','latex', ...
        'FontSize',7.8, ...
        'Box','on');

    lg.LineWidth = 0.5;
    lg.Color     = 'white';

    % No direct annotations — legend carries the meaning

    % -----------------------------
    % Tighten layout
    % -----------------------------
    set(ax, 'Units','normalized');
    ax.Position = [0.15 0.17 0.80 0.76];

    % -----------------------------
    % Save
    % -----------------------------
    sfig(fig, 'fig1_val_w0', fmt, dir, dpi);
end
%% =========================================================================
%% FIG 2 -- Validation: P_total vs alpha (CHART / bars instead of curves)
%% =========================================================================
function fig2_val_alpha(BP, N_MC, fmt, dir, dpi, C)
    fprintf('\n[Fig 2] P_total vs alpha (chart style) ...\n');
    ag = linspace(0.05,0.95,15);
    na = numel(ag);
    Pr = zeros(1,na); Pm = zeros(1,na);
    for i = 1:na
        a = ag(i);
        [pf,pe,mc,sc] = build_model(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M, ...
                                    BP.Ta,BP.Tb,a);
        Pr(i) = P_total(pf,pe,mc,sc,BP.n,BP.m,BP.q,BP.w0,1,0,BP.wmin,BP.wmax);
        Pm(i) = run_mc(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb, ...
                       a,BP.n,BP.m,BP.q,BP.w0,1,0,BP.wmin,BP.wmax,N_MC);
        fprintf('  alpha=%.2f  rec=%.4f  mc=%.4f\n', a, Pr(i), Pm(i));
    end

    [~,ia] = max(Pr); as = ag(ia);
    fig = make_ieee_figure(3.46, 2.60);
    ax  = make_axes(fig);
    ax.Position = [0.12 0.22 0.84 0.70];

    x = 1:na;
    Y = [Pr(:), Pm(:)];
    hb = bar(ax, x, Y, 0.82, 'grouped', 'LineWidth',0.55);
    hb(1).FaceColor = C.blue;
    hb(1).EdgeColor = C.black;
    hb(2).FaceColor = 'w';
    hb(2).EdgeColor = C.redSim;
    hb(2).LineStyle = '-';

    % star overlays to keep the article's MC visual grammar
    for i = 1:na
        x_mc = hb(2).XEndPoints(i);
        plot(ax, x_mc, Pm(i), '*', 'Color', C.redSim, ...
            'MarkerSize', 4.8, 'LineWidth',0.8, 'HandleVisibility','off');
    end

    xline(ax, ia, '--', 'Color', C.gray, 'LineWidth',0.9, 'HandleVisibility','off');
    add_direct_label(ax, ia+0.18, min([Pr Pm])+0.02*(max([Pr Pm])-min([Pr Pm])), ...
        sprintf('$\\alpha^{\\star}=%.2f$', as), C.gray, 90, 'left');

    ax.XLim = [0.3 na+0.7];
    ax.XTick = x;
    ax.XTickLabel = arrayfun(@(z) sprintf('%.2f',z), ag, 'UniformOutput', false);
    ax.XTickLabelRotation = 45;
    ax.FontSize = 7.5;
    xlabel(ax, '$\alpha$');
    ylabel(ax, '$P_{\rm total}$');

    lg = legend(ax, [hb(1), hb(2)], {'Analytical', 'Monte Carlo'}, ...
        'Location','northwest');
    format_legend(lg);

    sfig(fig,'fig2_val_alpha',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 3 -- Validation: P_total vs n
%% =========================================================================
function fig3_val_vs_n(BP, N_MC, fmt, dir, dpi, C)
    fprintf('\n[Fig 3] P_total vs n ...\n');
    [pf,pe,mc,sc]=build_model(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M, ...
                               BP.Ta,BP.Tb,BP.alpha);
    nr = [50 60 80 100 120 150 180];
    Pr = zeros(1,numel(nr)); Pm = zeros(1,numel(nr));
    for i = 1:numel(nr)
        nv = nr(i);
        Pr(i) = P_total(pf,pe,mc,sc,nv,BP.m,BP.q,BP.w0,1,0,BP.wmin,BP.wmax);
        Pm(i) = run_mc(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb, ...
                     BP.alpha,nv,BP.m,BP.q,BP.w0,1,0,BP.wmin,BP.wmax,N_MC);
        fprintf('  n=%d  rec=%.4f  mc=%.4f\n',nv,Pr(i),Pm(i));
    end

    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    h1 = plot(ax, nr, Pr, '-', 'Color', C.blue, 'LineWidth',1.0, ...
        'DisplayName','Analytical');
    h2 = plot(ax, nr, Pm, '*', 'Color', C.redSim, 'MarkerSize',4.8, ...
        'LineWidth',0.8, 'DisplayName','Simulation');

    xlabel(ax, '$n$');
    ylabel(ax, '$P_{\rm total}$');
    xlim(ax,[min(nr)-5 max(nr)+5]);
    xticks(ax,nr);

    lg = legend(ax,[h2 h1],{'Simulation','Analytical'},'Location','southeast');
    format_legend(lg);

    sfig(fig,'fig3_val_vs_n',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 4 -- Validation: P_total vs m
%% =========================================================================
function fig4_val_vs_m(BP, N_MC, fmt, dir, dpi, C)
    fprintf('\n[Fig 4] P_total vs m ...\n');
    [pf,pe,mc,sc] = build_model(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M, ...
                                BP.Ta,BP.Tb,BP.alpha);
    mr = [3 5 7 10 12 15 18];
    Pr = zeros(1,numel(mr)); Pm = zeros(1,numel(mr));
    for i = 1:numel(mr)
        mv = mr(i);
        Pr(i) = P_total(pf,pe,mc,sc,BP.n,mv,BP.q,BP.w0,1,0,BP.wmin,BP.wmax);
        Pm(i) = run_mc(BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb, ...
                     BP.alpha,BP.n,mv,BP.q,BP.w0,1,0,BP.wmin,BP.wmax,N_MC);
        fprintf('  m=%d  rec=%.4f  mc=%.4f\n',mv,Pr(i),Pm(i));
    end

    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    h1 = plot(ax, mr, Pr, '-', 'Color', C.blue, 'LineWidth',1.0, ...
        'DisplayName','Analytical');
    h2 = plot(ax, mr, Pm, '*', 'Color', C.redSim, 'MarkerSize',4.8, ...
        'LineWidth',0.8, 'DisplayName','Simulation');

    xlabel(ax, '$m$');
    ylabel(ax, '$P_{\rm total}$');
    xlim(ax,[min(mr)-0.5 max(mr)+0.5]);
    xticks(ax,mr);

    lg = legend(ax,[h2 h1],{'Simulation','Analytical'},'Location','southwest');
    format_legend(lg);

    sfig(fig,'fig4_val_vs_m',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 5 -- Validation: conditional PDF vs MC (article-like line/marker form)
%% =========================================================================
function fig5_val_condpdf(BP, fmt, dir, dpi, C)
    fprintf('\n[Fig 5] Conditional PDF ...\n');
    a = BP.alpha;
    dR = (BP.Ta-BP.mu_R)/BP.sig_R; dM = (BP.Tb-BP.mu_M)/BP.sig_M;
    pe = (1-normcdf(dR))*(1-normcdf(dM));
    vs = sqrt(a^2+(1-a)^2);
    s_min = a*dR+(1-a)*dM;
    fSD_w = @(s) fSD_eval(s,s_min,a,dR,dM,vs,pe);

    N2 = 400000;
    ZR = randn(N2,1); ZM = randn(N2,1);
    el = (ZR>=dR)&(ZM>=dM);
    Sc = (a*ZR+(1-a)*ZM); Sc = Sc(el);

    s_c = linspace(-0.3,3.5,500);
    fc  = fSD_w(s_c);

    % empirical density converted to sparse star markers
    [f_mc, x_mc] = ksdensity(Sc, s_c);
    idx = unique(round(linspace(1, numel(x_mc), 28)));

    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    h1 = plot(ax, s_c, fc, '-', 'Color', C.blue, 'LineWidth',1.0, ...
        'DisplayName','Analytical');
    h2 = plot(ax, x_mc(idx), f_mc(idx), '*', 'Color', C.redSim, ...
        'MarkerSize',4.6, 'LineWidth',0.8, 'DisplayName','Simulation');

    xline(ax, s_min, '--', 'Color', C.gray, 'LineWidth',0.9, ...
        'HandleVisibility','off');
    add_direct_label(ax, s_min+0.05, 0.84*max(fc), ...
        sprintf('$s_{\min}=%.3f$', s_min), C.gray, 0, 'left');

    xlabel(ax, '$s$');
    ylabel(ax, '$f_{S\mid D}$');
    xlim(ax,[-0.3 3.5]);

    lg = legend(ax,[h2 h1],{'Simulation','Analytical'},'Location','northeast');
    format_legend(lg);

    sfig(fig,'fig5_val_condpdf',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 6 -- Validation: benchmark distribution vs q
%% =========================================================================
function fig6_val_benchmark(BP, fmt, dir, dpi, C)
    fprintf('\n[Fig 6] Benchmark distribution ...\n');
    a  = BP.alpha;
    dR = (BP.Ta-BP.mu_R)/BP.sig_R; dM = (BP.Tb-BP.mu_M)/BP.sig_M;
    lR = normpdf(dR)/(1-normcdf(dR)); lM = normpdf(dM)/(1-normcdf(dM));
    mu_c = a*lR+(1-a)*lM;
    sc   = sqrt(a^2*(1+dR*lR-lR^2)+(1-a)^2*(1+dM*lM-lM^2));

    N3 = 400000;
    ZR = randn(N3,1); ZM = randn(N3,1);
    el = (ZR>=dR)&(ZM>=dM);
    Se = (a*ZR+(1-a)*ZM); Se = Se(el);

    qv = [1 5 10];
    cols = {C.black, C.orange, C.green};
    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    h_mc = gobjects(1,3);
    h_th = gobjects(1,3);
    ypeaks = zeros(1,3);
    xpeaks = zeros(1,3);
    for ii = 1:3
        q_v  = qv(ii);
        sc_q = sc/sqrt(q_v);
        sr   = linspace(0,2.8,300);
        th   = normpdf(sr,mu_c,sc_q);
        h_th(ii) = plot(ax, sr, th, '-', 'Color', cols{ii}, 'LineWidth',1.0, ...
            'HandleVisibility','off');

        nt = min(floor(numel(Se)/q_v),50000);
        Ss = mean(reshape(Se(1:nt*q_v),q_v,[]).',2);
        [f_mc, x_mc] = ksdensity(Ss, sr);
        idx = unique(round(linspace(1, numel(x_mc), 20)));
        h_mc(ii) = plot(ax, x_mc(idx), f_mc(idx), '*', 'Color', C.redSim, ...
            'MarkerSize',4.1, 'LineWidth',0.75, 'HandleVisibility','off'); %#ok<NASGU>

        [ypeaks(ii), ip] = max(th);
        xpeaks(ii) = sr(ip);
    end

    % proxy handles for compact legend like the article
    proxySim = plot(ax, nan, nan, '*', 'Color', C.redSim, 'MarkerSize',4.6, ...
        'LineWidth',0.8, 'DisplayName','Simulation');
    proxyTh  = plot(ax, nan, nan, '-', 'Color', C.blue, 'LineWidth',1.0, ...
        'DisplayName','Analytical');

    add_direct_label(ax, xpeaks(1)+0.10, ypeaks(1)*0.96, '$q=1$',  C.black,  0, 'left');
    add_direct_label(ax, xpeaks(2)+0.08, ypeaks(2)*1.02, '$q=5$',  C.orange, 0, 'left');
    add_direct_label(ax, xpeaks(3)+0.05, ypeaks(3)*1.02, '$q=10$', C.green,  0, 'left');

    xlabel(ax, '$S^{\star}$');
    ylabel(ax, '$f_{S^{\star}}$');
    xlim(ax,[0 2.8]);

    lg = legend(ax,[proxySim proxyTh],{'Simulation','Analytical'},'Location','northeast');
    format_legend(lg);

    sfig(fig,'fig6_val_benchmark',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 7 -- Applications: policy comparison grouped bar
%% =========================================================================
function fig7_app_policy(APP, BP, fmt, dir, dpi, C)
    fprintf('\n[Fig 7] Policy comparison ...\n');
    pol_av = [0.95 0.05 0.50 0.50 0.50];
    pol_s1 = [1    1    0    1    1   ];
    pol_s2 = [0    0    0    1    0   ];
    pol_lb = {'Return-only','Liquidity-only','Constant','Full adapt.','Shrink-only'};
    bcols  = [C.redSim; C.purple; C.orange; C.green; C.blue];

    nA = numel(APP); nP = 5; vals = zeros(nA,nP);
    for j = 1:nA
        ap = APP(j);
        for k = 1:nP
            [pf,pe,mc,sc] = build_model(ap.mu_R,ap.sig_R,ap.mu_M,ap.sig_M, ...
                                        ap.Ta,ap.Tb,pol_av(k));
            vals(j,k)=P_total(pf,pe,mc,sc,ap.n,ap.m,5,5, ...
                              pol_s1(k),pol_s2(k),BP.wmin,BP.wmax);
        end
        fprintf('  %s: Shrink=%.4f Const=%.4f Gain=%+.4f (+%.1f%%)\n', ...
            ap.name,vals(j,5),vals(j,3),vals(j,5)-vals(j,3), ...
            (vals(j,5)/vals(j,3)-1)*100);
    end

    fig = make_ieee_figure(3.46, 2.60);
    ax  = make_axes(fig);
    ax.Position = [0.13 0.18 0.83 0.72];

    gw   = 0.82; bw = gw/nP; offs = linspace(-gw/2+bw/2, gw/2-bw/2, nP);
    proxies = gobjects(1,nP);
    for k = 1:nP
        for j = 1:nA
            x  = j + offs(k);
            hb = bar(ax, x, vals(j,k), bw, 'FaceColor', bcols(k,:), ...
                     'EdgeColor', C.black, 'LineWidth',0.5, 'HandleVisibility','off'); %#ok<NASGU>
            text(ax, x, vals(j,k)+0.005, sprintf('%.3f',vals(j,k)), ...
                'HorizontalAlignment','center', 'VerticalAlignment','bottom', ...
                'FontSize',7.2, 'Color', C.black, 'Interpreter','latex');
        end
        proxies(k) = bar(ax, nan, nan, bw, 'FaceColor', bcols(k,:), ...
                         'EdgeColor', C.black, 'LineWidth',0.5, ...
                         'DisplayName', pol_lb{k});
    end

    ax.XTick = 1:nA;
    ax.XTickLabel = {'Large-Cap','Small-Cap','HY Credit'};
    ylabel(ax, '$P_{\rm total}$');
    ylim(ax,[0 max(vals(:))*1.18]);

    lg = legend(ax, proxies, pol_lb, 'Location','northwest', ...
        'Orientation','vertical', 'NumColumns',1);
    format_legend(lg);

    sfig(fig,'fig7_app_policy',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 8 -- Applications: P_total vs w0, 3 apps overlay
%% =========================================================================
function fig8_app_w0(APP, BP, N_MC, fmt, dir, dpi, C)
    fprintf('\n[Fig 8] P_total vs w0, 3 apps ...\n');
    w0r = 1:11;
    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    proxyShrink = plot(ax, nan, nan, '-',  'Color', C.black,  'LineWidth',1.0, 'DisplayName','Shrink-only');
    proxyConst  = plot(ax, nan, nan, '--', 'Color', C.black,  'LineWidth',1.0, 'DisplayName','Constant');
    proxyMC     = plot(ax, nan, nan, '*',  'Color', C.redSim, 'MarkerSize',4.6, 'LineWidth',0.8, 'DisplayName','Simulation');

    end_x = zeros(1,numel(APP));
    end_y = zeros(1,numel(APP));
    end_yc = zeros(1,numel(APP));
    for j = 1:numel(APP)
        ap = APP(j);
        [pf,pe,mc,sc] = build_model(ap.mu_R,ap.sig_R,ap.mu_M,ap.sig_M, ...
                                    ap.Ta,ap.Tb,0.5);
        Ps = zeros(1,numel(w0r)); Pc = zeros(1,numel(w0r)); Pm = zeros(1,numel(w0r));
        for i = 1:numel(w0r)
            w = w0r(i);
            Ps(i) = P_total(pf,pe,mc,sc,ap.n,ap.m,5,w,1,0,BP.wmin,BP.wmax);
            Pc(i) = P_total(pf,pe,mc,sc,ap.n,ap.m,5,w,0,0,BP.wmin,BP.wmax);
            Pm(i) = run_mc(ap.mu_R,ap.sig_R,ap.mu_M,ap.sig_M,ap.Ta,ap.Tb, ...
                           0.5,ap.n,ap.m,5,w,1,0,BP.wmin,BP.wmax,N_MC);
        end

        plot(ax, w0r, Ps, '-',  'Color', ap.color, 'LineWidth',1.0, 'HandleVisibility','off');
        plot(ax, w0r, Pc, '--', 'Color', ap.color, 'LineWidth',1.0, 'HandleVisibility','off');
        idx = 1:2:numel(w0r);
        plot(ax, w0r(idx), Pm(idx), '*', 'Color', C.redSim, 'MarkerSize',4.4, ...
             'LineWidth',0.75, 'HandleVisibility','off');

        end_x(j)  = w0r(end);
        end_y(j)  = Ps(end);
        end_yc(j) = Pc(end);
        fprintf('  %s done\n',ap.name);
    end

    % Context labels directly on curves
    lbl_names = {'Large-Cap','Small-Cap','HY Credit','Liq-Stressed'};
    offsets_y = [0.010, 0.006, -0.008, 0.008];
    offsets_x = [0.3, 0.3, 0.3, 0.3];
    for j2 = 1:numel(APP)
        xi = round(0.4*numel(w0r));
        add_direct_label(ax, w0r(xi)+offsets_x(j2), end_y(j2)+offsets_y(j2)*3, ...
            lbl_names{j2}, APP(j2).color, 0, 'left');
    end

    xlabel(ax, '$w_0$');
    ylabel(ax, '$P_{\rm total}$');
    xlim(ax,[1 11]);
    xticks(ax,1:11);

    lg = legend(ax, [proxyMC proxyShrink proxyConst], ...
        {'Simulation','Shrink-only','Constant'}, 'Location','southeast');
    format_legend(lg);

    sfig(fig,'fig8_app_w0',fmt,dir,dpi);
end

%% =========================================================================
%% FIG 9 -- Applications: P_total vs alpha, 3 apps overlay
%% =========================================================================
function fig9_app_alpha(APP, BP, fmt, dir, dpi, C)
    fprintf('\n[Fig 9] P_total vs alpha, 3 apps ...\n');
    ag  = linspace(0.05,0.95,15);
    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    proxyShrink = plot(ax, nan, nan, '-',  'Color', C.black, 'LineWidth',1.0, 'DisplayName','Shrink-only');
    proxyConst  = plot(ax, nan, nan, '--', 'Color', C.black, 'LineWidth',1.0, 'DisplayName','Constant');
    proxyStar   = plot(ax, nan, nan, ':',  'Color', C.gray,  'LineWidth',0.9, 'DisplayName','$\alpha^{\star}$');

    peakx = zeros(1,numel(APP));
    peaky = zeros(1,numel(APP));
    for j = 1:numel(APP)
        ap = APP(j);
        Ps = zeros(1,numel(ag)); Pc = zeros(1,numel(ag));
        for i = 1:numel(ag)
            a = ag(i);
            [pf,pe,mc,sc] = build_model(ap.mu_R,ap.sig_R,ap.mu_M,ap.sig_M, ...
                                        ap.Ta,ap.Tb,a);
            Ps(i) = P_total(pf,pe,mc,sc,ap.n,ap.m,5,5,1,0,BP.wmin,BP.wmax);
            Pc(i) = P_total(pf,pe,mc,sc,ap.n,ap.m,5,5,0,0,BP.wmin,BP.wmax);
        end
        [Pm,ia] = max(Ps); ast = ag(ia);
        plot(ax, ag, Ps, '-',  'Color', ap.color, 'LineWidth',1.0, 'HandleVisibility','off');
        plot(ax, ag, Pc, '--', 'Color', ap.color, 'LineWidth',1.0, 'HandleVisibility','off');
        xline(ax, ast, ':', 'Color', ap.color, 'LineWidth',0.9, 'HandleVisibility','off');

        peakx(j) = ast;
        peaky(j) = Pm;
        fprintf('  %s: alpha*=%.2f  Pmax=%.4f\n',ap.name,ast,Pm);
    end

    lbl_names9 = {'Large-Cap','Small-Cap','HY Credit','Liq-Stressed'};
    lbl_dy9    = [0.008, 0.006, -0.010, 0.008];
    lbl_dx9    = [-0.16, -0.14, -0.10, -0.12];
    for j9 = 1:numel(APP)
        add_direct_label(ax, peakx(j9)+lbl_dx9(j9), peaky(j9)+lbl_dy9(j9), ...
            lbl_names9{j9}, APP(j9).color, 0, 'left');
    end

    xlabel(ax, '$\alpha$');
    ylabel(ax, '$P_{\rm total}$');
    xlim(ax,[0.05 0.95]);
    xticks(ax,0.1:0.1:0.9);

    lg = legend(ax, [proxyShrink proxyConst proxyStar], ...
        {'Shrink-only','Constant','$\alpha^{\star}$'}, 'Location','southeast');
    format_legend(lg);

    sfig(fig,'fig9_app_alpha',fmt,dir,dpi);
end
%% =========================================================================
%% FIG 10 -- Heavy-tail robustness: P_total vs w0
%% Gaussian analytical curves vs Student-t Monte Carlo
%% Purpose:
%%   - keep analytical model unchanged (Gaussian recursion)
%%   - generate Monte Carlo returns from standardized Student-t
%%   - test whether shrink-only still ranks above constant across w0
%% =========================================================================
function fig10_robust_w0(BP, N_MC, fmt, dir, dpi, C)

    fprintf('\n[Fig 10] Heavy-tail robustness vs w0 ...\n');

    % -------------------------------------------------
    % Settings
    % -------------------------------------------------
    nu  = 5;        % heavy-tail strength
    w0r = 1:12;
    nw  = numel(w0r);

    % Arrays
    Pana_ad = zeros(1,nw);   % Gaussian analytical, shrink-only
    Pana_ct = zeros(1,nw);   % Gaussian analytical, constant
    Pmc_ad  = zeros(1,nw);   % Student-t MC, shrink-only
    Pmc_ct  = zeros(1,nw);   % Student-t MC, constant

    % -------------------------------------------------
    % Analytical model remains Gaussian
    % -------------------------------------------------
    [pf,pe,mc,sc] = build_model(BP.mu_R, BP.sig_R, BP.mu_M, BP.sig_M, ...
                                BP.Ta, BP.Tb, BP.alpha);

    % -------------------------------------------------
    % Compute curves
    % -------------------------------------------------
    for i = 1:nw
        w = w0r(i);

        Pana_ad(i) = P_total(pf,pe,mc,sc, ...
                             BP.n,BP.m,BP.q,w,1,0,BP.wmin,BP.wmax);

        Pana_ct(i) = P_total(pf,pe,mc,sc, ...
                             BP.n,BP.m,BP.q,w,0,0,BP.wmin,BP.wmax);

        % Heavy-tailed MC: Student-t returns, same rest of logic
        Pmc_ad(i) = run_mc_student_t( ...
            BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb,BP.alpha, ...
            BP.n,BP.m,BP.q,w,1,0,BP.wmin,BP.wmax,N_MC,nu);

        Pmc_ct(i) = run_mc_student_t( ...
            BP.mu_R,BP.sig_R,BP.mu_M,BP.sig_M,BP.Ta,BP.Tb,BP.alpha, ...
            BP.n,BP.m,BP.q,w,0,0,BP.wmin,BP.wmax,N_MC,nu);

        fprintf(['  w0=%2d  AnaShrink=%.4f  tMC-Shrink=%.4f  ' ...
                 'AnaConst=%.4f  tMC-Const=%.4f\n'], ...
                 w, Pana_ad(i), Pmc_ad(i), Pana_ct(i), Pmc_ct(i));
    end

    % -------------------------------------------------
    % FIX: Compute Table 6 aggregate statistics
    % These were previously missing; computed here from per-w0 results.
    % -------------------------------------------------
    gains = Pmc_ad - Pmc_ct;
    fprintf('\n=== Table 6: Heavy-tail robustness summary (Student-t MC, nu=%d) ===\n', nu);
    fprintf('Mean gain Delta_t-MC(w0)          : %.4f\n', mean(gains));
    fprintf('Minimum gain                       : %.4f\n', min(gains));
    fprintf('Positive-gain frequency (all w0)   : %.1f%%\n', 100*mean(gains > 0));
    gains_ge2 = gains(w0r >= 2);
    fprintf('Positive-gain frequency (w0 >= 2)  : %.1f%%\n', 100*mean(gains_ge2 > 0));
    fprintf('=================================================================\n');

    % -------------------------------------------------
    % Figure / axes
    % -------------------------------------------------
    fig = make_ieee_figure(3.45, 2.60);
    ax  = make_axes(fig);

    % -------------------------------------------------
    % Plot analytical curves
    % -------------------------------------------------
    h1 = plot(ax, w0r, Pana_ad, '-', ...
        'Color', C.blue, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Analytical, shrink-only');

    h2 = plot(ax, w0r, Pana_ct, '--', ...
        'Color', C.darkGray, ...
        'LineWidth', 1.0, ...
        'DisplayName', 'Analytical, constant');

    % -------------------------------------------------
    % Plot Student-t Monte Carlo markers
    % -------------------------------------------------
    idx = unique(round(linspace(1, nw, min(nw,10))));

    h3 = plot(ax, w0r(idx), Pmc_ad(idx), '*', ...
        'Color', C.redSim, ...
        'LineStyle', 'none', ...
        'MarkerSize', 4.8, ...
        'LineWidth', 0.8, ...
        'DisplayName', sprintf('Student-$t$ MC, shrink-only ($\\nu=%d$)',nu));

    h4 = plot(ax, w0r(idx), Pmc_ct(idx), 'o', ...
        'Color', C.redSim, ...
        'MarkerFaceColor', 'w', ...
        'LineStyle', 'none', ...
        'MarkerSize', 4.2, ...
        'LineWidth', 0.8, ...
        'DisplayName', sprintf('Student-$t$ MC, constant ($\\nu=%d$)',nu));

    % -------------------------------------------------
    % Labels / limits
    % -------------------------------------------------
    xlabel(ax, '$w_0$');
    ylabel(ax, '$P_{\rm total}$');

    xlim(ax, [min(w0r) max(w0r)]);
    xticks(ax, 1:12);

    yall = [Pana_ad(:); Pana_ct(:); Pmc_ad(:); Pmc_ct(:)];
    ymin = min(yall);
    ymax = max(yall);
    yrng = ymax - ymin;
    if yrng <= 0
        yrng = max(1e-3, abs(ymax));
    end
    ylim(ax, [max(0, ymin - 0.06*yrng), min(1, ymax + 0.10*yrng)]);

    % -------------------------------------------------
    % Compact legend
    % -------------------------------------------------
    lg = legend(ax, [h1 h2 h3 h4], 'Location','northeast');
    format_legend(lg);

    % -------------------------------------------------
    % Direct labels in same style as other figures
    % -------------------------------------------------
    j1 = max(3, round(0.68*nw));
    j2 = max(3, round(0.42*nw));

    text(ax, w0r(j1), Pana_ad(j1) + 0.040*yrng, 'Shrink-only', ...
        'Interpreter','latex', ...
        'FontName','Times New Roman', ...
        'FontSize',8, ...
        'Color', C.blue, ...
        'HorizontalAlignment','left');

    text(ax, w0r(j2), Pana_ct(j2) - 0.050*yrng, 'Constant', ...
        'Interpreter','latex', ...
        'FontName','Times New Roman', ...
        'FontSize',8, ...
        'Color', C.darkGray, ...
        'HorizontalAlignment','left');

    text(ax, min(w0r)+0.2, ax.YLim(2)-0.06*yrng, ...
        sprintf('$t$-MC with $\\nu=%d$', nu), ...
        'Interpreter','latex', ...
        'FontSize',8, ...
        'Color', C.gray, ...
        'HorizontalAlignment','left');

    % -------------------------------------------------
    % Save
    % -------------------------------------------------
    sfig(fig, 'fig10_robust_w0', fmt, dir, dpi);
end

%% =========================================================================
%% Heavy-tail Monte Carlo:
%% identical screening logic, but returns are generated from a
%% standardized Student-t law matched in mean/variance to Gaussian baseline
%% =========================================================================
function out = run_mc_student_t(mu_R,sig_R,mu_M,sig_M,Ta,Tb,alpha, ...
                                n,m,q,w0,s1,s2,wmin,wmax,N,nu)
    suc = 0;

    for trial_ = 1:N

        % Standardized Student-t: mean 0, variance 1
        Tstd = trnd(nu, n, 1) * sqrt((nu-2)/nu);

        % Heavy-tailed returns, Gaussian log-tradability
        R = mu_R + sig_R * Tstd;
        M = mu_M + sig_M * randn(n,1);

        D = (R >= Ta) & (M >= Tb);
        S = alpha*(R-mu_R)/sig_R + (1-alpha)*(M-mu_M)/sig_M;

        % Learning phase
        ec = 0;
        bs = [];
        i  = 1;

        while i <= n && ec < q
            if D(i)
                ec = ec + 1;
                bs(ec) = S(i); %#ok<AGROW>
            end
            i = i + 1;
        end

        if ec < q
            continue;
        end

        Ss    = mean(bs);
        quota = m;
        w     = w0;
        j     = i;

        % Selection phase
        while j <= n && quota > 0
            we = min(w, n-j+1);
            if we == 0
                break;
            end

            H  = 0;
            fi = -1;

            for k = j:j+we-1
                if D(k) && S(k) > Ss
                    H = H + 1;
                    if fi < 0
                        fi = k;
                    end
                end
            end

            if fi > 0
                quota = quota - 1;
            end

            if H == 0
                w = min(w + s2, wmax);
            elseif H >= 2
                w = max(w - s1, wmin);
            end

            j = j + we;
        end

        suc = suc + (quota == 0);
    end

    out = suc / N;
end