`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2024 23:24:09
// Design Name: 
// Module Name: main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module main(
    input clk,
    input [15:0] sw,
    input btnC, btnU, btnL, btnR, btnD,
    inout PS2Clk,  // oled
    inout PS2Data, // oled
    input JB2,   // Connect from this signal to Audio_Capture.v JB MIC PIN 3
    output JB0,   // Connect to this signal from Audio_Capture.v JB MIC PIN 1
    output JB3,   // Connect to this signal from Audio_Capture.v JB MIC PIN 4
    output [15:0] led, 
    output [7:0] JC, // oled
    output [6:0] seg, // 7 segment display
    output [3:0] an, // 7 segment display
    output dp // 7 segmenet display
    );
    
    // OLED display
    slow_clock slow_clock_6p25MHz(.clk(clk), .max_counts(8), .new_clk(clock_6p25M));
    wire frame_beg, send_pix, sample_pix;
    wire [15:0] pix_data;
    wire [12:0] pix_index;
    
    // beat variables
    wire beat_detected = 0;
        
    // clocks
    wire clk_1hz, clk_20khz, clk_480;
    slow_clock clock_1hz(.clk(clk), .max_counts(50_000_000), .new_clk(clk_1hz));
    slow_clock clock_20khz(.clk(clk), .max_counts(2500), .new_clk(clk_20khz));
    slow_clock clock_480Hz(.clk(clk), .max_counts(104167), .new_clk(clk_480));
    //clock_divider twentykhz (clk, 32'd20000, clk_20k);
    
    clock_divider six25mhz (clk, 32'd6250000, clk_6p25M);
    wire clk_20k;
    // slow_clock slow_clk_20k (.clk(clk), .max_counts(2500), .new_clk(clk_20k));
    clock_divider twentykhz (clk, 32'd20000, clk_20k);
    
    // 7 segment display
    reg [1:0] an_count = 0;
    reg [6:0] digit0 = 7'b100_0000; 
    reg [6:0] digit1 = 7'b111_1001; 
    reg [6:0] digit2 = 7'b010_0100; 
    reg [6:0] digit3 = 7'b011_0000; 
    reg [6:0] digit4 = 7'b001_1001; 
    reg [6:0] digit5 = 7'b001_0010; 
    reg [6:0] digit6 = 7'b000_0010; 
    reg [6:0] digit7 = 7'b111_1000; 
    reg [6:0] digit8 = 7'b000_0000;
    reg [6:0] digit9 = 7'b001_0000; 
    
        // audio capture
        reg clk20kFORAUDIO = 0;
        reg [31:0] clk20kaudiodiv = (100000000 / (20000 * 2)) - 1;
        reg [31:0] clk20kaudioCOUNT = 0;
        always @ (posedge clk) begin
            clk20kaudioCOUNT <= ((clk20kaudioCOUNT >= clk20kaudiodiv) ? 32'd0 : clk20kaudioCOUNT + 1);
            clk20kFORAUDIO <= clk20kaudioCOUNT >= clk20kaudiodiv ? ~clk20kFORAUDIO : clk20kFORAUDIO;
        end
        wire [11:0] mic_in;
        audio_capture mic(clk, clk20kFORAUDIO, JB2, JB0, JB3, mic_in);


     ui user_interface(.clk(clk), .sw(sw), .pixel_index(pix_index), .random_x_pos(random_x), .btnC(btnC), .btnU(btnU), .btnL(btnL), .btnR(btnR), .btnD(btnD), .difficulty(speed), .seg(seg), .an(an),.oled_data(pix_data));
//     ui user_interface(.clk(clk), .sw(sw), .pixel_index(pix_index), .random_x_pos(random_x), .btnC(btnC), .btnU(btnU), .btnL(btnL), .btnR(btnR), .btnD(btnD), .difficulty(speed), .seg(seg), .an(an), .led(led) ,.oled_data(pix_data));
     
   
     //fft
     wire signed [11:0] sample_imag = 12'b0; //imaginary part is 0
     wire signed [5:0] output_real, output_imag; //bits for output real and imaginary
     reg [13:0] abs; //to calculate the absolute magnitude of output real and imaginary
     // reg [(512 * 6) - 1:0] bins; //vector for all the 1024 bins(not necessary)
     reg [9:0] maxbins = 512;
     wire sync; //high when fft is ready
     reg [9:0] bin = 0; //current bin editting
     wire fft_ce; 
     assign fft_ce = 1; //always high when fft is transforming
 
     //spectrogram stuff after fft
     reg [(6 * 20) - 1:0] spectrogram = 0;
     reg [5:0] current_highest_spectrogram = 0;
     wire [4:0] spectrobinsize = 25;
     integer j;
     
     //tuner stuff after fft
     reg [5:0] current_highest_note = 0;
     reg [9:0] previous_highest_note_index = 0;
     reg [9:0] current_highest_note_index = 0;
     reg [15:0] stable_note_count = 0;
     wire stable_note_held;
     wire [5:0] holdcount = 20000/1024 * 2;
     assign stable_note_held = stable_note_count >= holdcount;
 
     
     wire clk_5k;
     wire custom_fft_clk = clk_20k;
     wire spectropause = 0;
     wire reset_stablenoteheld = 0;
     wire lock = 0;
     
     always @(posedge clk) begin
             if (reset_stablenoteheld) begin
                 stable_note_count = 0;
             end
             if (custom_fft_clk) begin
                 if(fft_ce) begin
                     abs <= (output_real * output_real) + (output_imag * output_imag);
                     if(sync) begin
                         bin <= 0;
                         j <= 0;
                         current_highest_spectrogram <= 0;
     
                         if (current_highest_note_index == previous_highest_note_index) begin
                             stable_note_count <= stable_note_count <= holdcount ? stable_note_count + 1 : stable_note_count;
                         end else begin
                             stable_note_count <= 0;
                             previous_highest_note_index <= current_highest_note_index;
                         end
                         current_highest_note_index <= 0;
                         current_highest_note <= 0;
                     end else begin
                         bin <= bin + 1;
                     end   
                     if (bin < maxbins) begin
                         // This is for finding highest of each bin of spectrogram, 0Hz is not included as it always skews results
                         if (!lock && !spectropause) begin
                             if (bin != 0) begin
                                 if (bin % spectrobinsize == 0) begin
                                     if (j < 20) begin
                                         spectrogram[j*6 +: 6] <= 63 - current_highest_spectrogram;
                                         current_highest_spectrogram = 0;
                                         j <= j + 1;
                                     end
                                 end     
                                 if (current_highest_spectrogram < ((abs >> 4) < 63 ? (abs >> 4) : 63)) begin
                                     current_highest_spectrogram <= ((abs >> 4) < 63 ? (abs >> 4) : 63);
                                 end   
                             end
                         end
                         else begin
                             if (bin != 0) begin
                                 // bins[bin * 6+: 6] <= (abs >> 4) < 63 ? (abs >> 4): 63; // scale & limit to 63 (not necessary to store whole thing)
                                 // This is for finding current note being played and how to reset it
                                 if (current_highest_note < ((abs >> 4) < 63 ? (abs >> 4) : 63) && ((abs >> 4) < 63 ? (abs >> 4) : 63) > 15) begin
                                     current_highest_note_index <= bin;
                                     current_highest_note <= ((abs >> 4) < 63 ? (abs >> 4) : 63);
                                 end
                             end
                         end
                     end
                 end
             end
         end
         fftmain fft_0(.i_clk(custom_fft_clk), .i_reset(0), .i_ce(fft_ce), .i_sample({mic_in, sample_imag}), .o_result({output_real, output_imag}), .o_sync(sync));

     wire [1:0] speed;
     beatdetection(
         .clk(clk),
         .custom_fft_clk(custom_fft_clk),  // Clock signal for FFT module
         .spectrogram(spectrogram),
         .led(led),  // Spectrogram data (20 bars, 6 bits per bar)
         .speed(speed)
         );
  
     
    
    // OLED Display code below
    Oled_Display oled(
        .clk(clock_6p25M), 
        .reset(0), 
        .frame_begin(frame_beg), 
        .sending_pixels(send_pix),
        .sample_pixel(sample_pix), 
        .pixel_index(pix_index), 
        .pixel_data(pix_data), 
        .cs(JC[0]), 
        .sdin(JC[1]), 
        .sclk(JC[3]), 
        .d_cn(JC[4]), 
        .resn(JC[5]), 
        .vccen(JC[6]),
        .pmoden(JC[7])
    );
endmodule
