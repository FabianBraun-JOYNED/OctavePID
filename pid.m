###########################################
# Simulation of a PI Controller           #
# fabianb,  09/2017                       #
###########################################

clear;
# Number of samples taken for the simulation
length = 1000; # 1 kHz ticks

# t_ptp is the common time base of two systems
t_ptp = 0:1:length; # startpoint : increment value for common time base : endpoint

# t_media_soll is the media time of system 1 refered to the common time base t_ptp
t_media_soll = t_ptp * 0.99995 + sin(t_ptp); # run 50 ppm slower than the time reference, sin to have some error in there

# t_media_step is the increment value of the media time of system 2 when it is uncontrolled/freewheeling
t_media_step = 1.00005; # run 50 ppm faster than time reference

# t_media_ist is the current time of system 2 refered to the common timebase. 
# It is incremented and controlled in the for loop below.
t_media_ist = t_ptp;

# t_media_error is added as error signal to t_media_ist
t_media_error = rand(length+1)*5-2.5; 
#t_media_error = sin(t_ptp*0.5);

ierror = zeros(length+1);
perror = zeros(length+1);
derror = zeros(length+1);
  
# Update interval of the PID controller  
update_interval = 125; # 1 kHz ticks

# calculate error based on samples in the past
offset = update_interval;



t_media_step_init = 1.1;
t_media_step = t_media_step_init;
t_media_step_1 = t_media_step_init;
next_update = update_interval;

# Control loop  
for i=2+offset:1:length
  # increment t_media_ist
  t_media_ist(i) = t_media_ist(i) + t_media_step + t_media_error(i) + t_media_step_init; # Add calculated step, add some error signal, add a constant = timer running to fast
  
  # just for nicer plots
  ierror(i) = ierror(i-1);
  perror(i) = perror(i-1);
  derror(i) = derror(i-1);
  
  # Update the t_media_step when update_interval is over
  if i > next_update
    perror(i) = t_media_ist(i-offset) - t_media_soll(i-offset);
    derror(i) = perror(i) - perror(i-offset);
    ierror(i) = perror(i) + perror(i-offset);
    t_media_step = t_media_step - perror(i) * 0.1 - perror(i) * 0.6 - derror(i) * 0.3;
    next_update = i + update_interval;
  endif
  
  # lowpass the t_media_step signal (behaviour of a PLL)
  t_media_step = (t_media_step + t_media_step_1) * 0.5;
  t_media_step_1 = t_media_step;
endfor
ierror(length+1) = 0;
perror(length+1) = 0;
t_media_ist(length+1) = t_media_soll(length+1);
   
# Claculate absolute error
error = t_media_ist - t_media_soll;

# Plots
figure(1);

# Plot the timing values 
subplot(2,1,1);
plot (t_ptp, t_ptp, '-', t_ptp, t_media_soll, '--', t_ptp, t_media_ist, '--');
legend('t_p_t_p', 't_m_e_d_i_a_s_o_l_l', 't_m_e_d_i_a_i_s_t');
#axis ([0 length+1 -10 length+10]); #[x_lo x_hi y_lo y_hi]

# Plot the error signals
subplot(2,1,2);
plot ( t_ptp, error, '-', t_ptp, ierror, '--', t_ptp, perror, '-', t_ptp, derror, '-');
legend('error', 'ierror', 'perror', 'derror');
#axis ([0 length+1 -20 20]); #[x_lo x_hi y_lo y_hi]