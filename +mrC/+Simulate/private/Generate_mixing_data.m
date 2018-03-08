function noise_mixing_data = Generate_mixing_data(spat_dists)
%% preparing mixing matrices
    load('spatial_decay_models_coherence')% this is located in simulate/private folder, it can be obtained by run the code 'spatial_decay_of_coherence.m'

    % calcualting the distances and the coherence takes some time, better to
    % precalculate, write and read
    % mixing_matrices remain constant over all trials!
    band_names = fieldnames(best_model) ;
    noise_mixing_data.band_freqs = band_freqs ;
    noise_mixing_data.mixing_type = 'coh' ;

    for freq_band_idx = 1:length(band_freqs)
        this_spatial_decay_model = best_model.(band_names{freq_band_idx}) ;
        this_coh = this_spatial_decay_model.fun(this_spatial_decay_model.model_params,spat_dists);
        this_coh = min(max(this_coh,0),1) ;
        noise_mixing_data.matrices{freq_band_idx} =  chol(this_coh) ; 
        display ([num2str(freq_band_idx/length(band_freqs)*100) '%']);
    end       

end