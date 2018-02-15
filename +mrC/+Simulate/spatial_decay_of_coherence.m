% estimate and write out functional model and  parameters for
% distance-dependence of coherence (according to Fig. 4 from 'Multi-scale
% analysis of neural activity in humans: Implications for 
% micro-scale electrocorticography'
clear all

model_fun.gauss = @(p,x)(p(4)+p(1)*exp(-((x-p(3))/2*p(2)^2)));
model_fun.expo   =  @(p,x)(p(4)+p(1)*exp(-p(2)*(x-p(3))));
model_fun.lorentzian   =  @(p,x)(p(4)+p(1)* ((p(2)^2)./(p(2)^2+(x-p(3)).^2)));
model_fun.power_law =  @(p,x)(p(4)+p(1)* (x+p(3)).^(-p(2)));

% data taken from Fig. 4
x = [0,0.38,0.5,0.54,1:0.5:3] % in mm
y.delta = [7., 6.3, 6.1, 6.05, 5.5,  5.3,  5,    4.9,  4.8]/7; % strange number where read from print in cm
y.theta = [7., 6.1, 5.8, 5.7,  5.1,  4.8,  4.5,  4.4,  4.3]/7;
y.beta =  [7., 6.3, 6.1, 6.05, 5.75, 5.5,  5.25, 5.1,  5]/7;
y.alpha = [7., 5.1, 4.9, 4.8,  4.45, 4.2,  3.9,  3.8,  3.6]/7;
y.gamma = [7., 3.2, 2.9, 2.75, 2.3,  2.05, 1.9,  1.75, 1.6]/7;

band_freqs{1} = [0,4];
band_freqs{2} = [4,8];
band_freqs{3} = [8,12];
band_freqs{4} = [12,30];
band_freqs{5} = [30,80];

fig=figure ;
freq_band_names = fieldnames(y) ;
model_names = fieldnames(model_fun) ;

x_temp = [0:0.5:4];

colors = {'r','g','b','k','c','m','y'};
linestyles = {'-','--',':','-.'};

handles = [];
for i = 1:length(freq_band_names)
    this_bands_mse = 100000;
    
    for this_model_idx = 1:length(model_names)
        subplot(1,length(model_names),this_model_idx );
        this_model_name = model_names{this_model_idx} ;
        scatter(x,y.(freq_band_names{i}),colors{i})
        hold on 
        if strcmp(this_model_name,'power_law')
             if strfind(version,'R2011')
             [this_p,R,J,CovB,MSE] =nlinfit(x(1:end),y.(freq_band_names{i})(1:end),model_fun.(this_model_name),[1.,1.,1.   ,0.]);
             else
             [this_p,R,J,CovB,MSE,ErrorModelInfo] =nlinfit(x(1:end),y.(freq_band_names{i})(1:end),model_fun.(this_model_name),[1.,1.,1.   ,0.]);
             end
        else
            if strfind(version,'R2011')
            [this_p,R,J,CovB,MSE] =nlinfit(x(1:end),y.(freq_band_names{i})(1:end),model_fun.(this_model_name),[1.,1.,0  ,0.]);
            else
            [this_p,R,J,CovB,MSE,ErrorModelInfo] =nlinfit(x(1:end),y.(freq_band_names{i})(1:end),model_fun.(this_model_name),[1.,1.,0  ,0.]);
            end
        end
        
        model_params.(freq_band_names{i}).(this_model_name) = this_p;
        h=plot(x_temp,model_fun.(this_model_name)( model_params.(freq_band_names{i}).(this_model_name) ,x_temp),colors{i});
        if this_model_idx==1
            handles = [handles,h];
        end
        
        if MSE<this_bands_mse
            this_bands_mse = MSE ;
            best_model.(freq_band_names{i}).model_params = this_p;
            best_model.(freq_band_names{i}).fun = model_fun.(this_model_name);
        end
        
        
        title(this_model_name)
    end

end
legend(handles,freq_band_names)
save('spatial_decay_models_coherence','model_fun','model_params','best_model','band_freqs')
