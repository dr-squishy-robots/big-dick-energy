function R = FORMAT()
    R.c1 = [0.0000, 0.4470, 0.7410]; %blue
    R.c2 = [0.8500, 0.3250, 0.0980]; %orange
    R.c3 = [0.9290, 0.6940, 0.1250]; %yellow
    R.c4 = [0.4941, 0.1843, 0.5569]; %purple
    
%figure properties
    R.fig.Units = 'pixels';
    R.fig.Position = [50 100 1280 720];

    R.fig.Renderer = 'painters';
    R.fig.Color = 'white';
    
    
%axes properties
    R.ax.FontSize = 12;
    %R.font.FontName = 'CMU Sans Serif';
    R.ax.FontName = 'CMU Bright';
    R.ax.FontWeight = 'normal';
    R.ax.TitleFontWeight = 'normal';
    R.ax.TitleFontSizeMultiplier = 14/12;
    
    R.ax.Position = [0 -0.1 1.05 1.2];
  
end

