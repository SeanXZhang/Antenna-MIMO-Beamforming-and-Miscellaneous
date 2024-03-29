%************************************************************************
%	[S_SOI, s, m] = planar_sig_gen(p,d,nn,NN,type,sig,noise,E_pattern)
%************************************************************************
%	SIG_GEN is a MATLAB function that generates the SOI and SNOIs
%   signals (with and without Gaussian noise)
%
%	Input Parameters Description
%	----------------------------
%	- p          number of elements in x axis and y axis
%	- d          inter-element spacing (in wavelength)
%                default value is (0.5,0.5) (Nyquist rate)
%   - nn         number of samples
%   - NN         number of samples per cycle or symbol
%   - type       option: 'sinusoid' or 'bpsk'
%   - sig        signals amplitudes and directions of SOI and SNOI
%   - noise      amplitude and variance values
%	- E_pattern  samples of element pattern (column vector)
%                if interested in array factor only, enter 1
%                default value is 1
%
%	Output Parameters Description
%	-----------------------------
%	- S_SOI      SOI reference signal (column vector)
%   - s          matrix containing all signals including noise
%   - m          frequency multiplier for sinusoidal signals
%************************************************************************

function [S_SOI, s, m] = planar_sig_gen(p,d,nn,NN,type,sig,noise,E_pattern)

%%%%%%%%%%%%%%% Parameters initialization %%%%%%%%%%%%%%%
k0 = 2*pi;                                                 % k in free space
n_sig = size(sig,1);                                       % Total number of signals
m = [];

x = linspace(0,p(1)-1,p(1));
y = linspace(0,p(2)-1,p(2));

sigr = [sig(:,1) pi/180*sig(:,2:3)];                    % degrees to radians conversion

[X,Y] = meshgrid(x,y);

err_1 = sprintf('\nSignal type not supported...');
%-------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%% Generating SOI %%%%%%%%%%%%%%%%%%%%
PSI_SOI = -k0*d(1,1)*sin(sigr(1,2))*cos(sigr(1,3))*X - k0*d(1,2)*sin(sigr(1,2))*sin(sigr(1,3))*Y;

PSI_SOI = reshape(PSI_SOI,1,p(1)*p(2));

switch type
   case 'bpsk'
      STATE1 = sum(100*clock);
      rand('state',STATE1);
      s_rand = round(rand(nn,1));
      s_rand_index = find(s_rand == 0);
      s_rand(s_rand_index) = -1;
      s_NN = ones(1,NN);
      s_rand = (s_rand*s_NN)';
      s_rand = reshape(s_rand,size(s_rand,1)*size(s_rand,2),1);
      [s_rand,PSI_SOI] = meshgrid(s_rand,PSI_SOI);
      s = sigr(1,1)*(s_rand.*exp(i*PSI_SOI));
      S_SOI  = s(1,:);
   otherwise
      error(err_1);
end;

%-------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%% Generating SNOI %%%%%%%%%%%%%%%%%%%
for k = 2 : n_sig,
   PSI_SNOI = -k0*d(1,1)*sin(sigr(k,2))*cos(sigr(k,3))*X - k0*d(1,2)*sin(sigr(k,2))*sin(sigr(k,3))*Y;

   PSI_SNOI = reshape(PSI_SNOI,1,p(1)*p(2));

   switch type
      case 'bpsk'
         STATE2 = sum(k*100*clock);
         rand('state',STATE2);
         s_rand = round(rand(nn,1));
         s_rand_index = find(s_rand == 0);
         s_rand(s_rand_index) = -1;
         s_NN = ones(1,NN);
         s_rand = (s_rand*s_NN)';
         s_rand = reshape(s_rand,size(s_rand,1)*size(s_rand,2),1);
         [s_rand,PSI_SNOI] = meshgrid(s_rand,PSI_SNOI);
         SNOI = sigr(k,1)*(s_rand.*exp(i*PSI_SNOI));
         s = s + SNOI;
      otherwise
         error(err_1);
   end;
end;
%-------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%% Noise %%%%%%%%%%%%%%%%%%%%
if ~isempty(noise)
    n_ant = p(1) * p(2);

    for k = 1 : n_ant
        STATE3 = sum(rand(1)*100*clock);
        randn('state',STATE3);
        noise_data_real = noise(1,1) + sqrt(noise(1,2)/2)*randn(1,size(s,2));
        STATE4 = sum(rand(1)*100*clock);
        randn('state',STATE4);
        noise_data_imag = noise(1,1) + sqrt(noise(1,2)/2)*randn(1,size(s,2));
        noise_data = complex(noise_data_real,noise_data_imag);
        s(k,:) = s(k,:) + noise_data;
    end;
end;
%-------------------------------------------------------%
