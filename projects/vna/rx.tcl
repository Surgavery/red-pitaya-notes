# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 96 DIN_FROM 0 DIN_TO 0 DOUT_WIDTH 1
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_1 {
  DIN_WIDTH 96 DIN_FROM 1 DIN_TO 1 DOUT_WIDTH 1
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 slice_2 {
  DIN_WIDTH 96 DIN_FROM 63 DIN_TO 32 DOUT_WIDTH 32
}

# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 8
} {
  m_axis_aclk /ps_0/FCLK_CLK0
  m_axis_aresetn slice_0/Dout
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 8
  M_TDATA_NUM_BYTES 2
  NUM_MI 4
  M00_TDATA_REMAP {tdata[15:0]}
  M01_TDATA_REMAP {tdata[31:16]}
  M02_TDATA_REMAP {tdata[47:32]}
  M03_TDATA_REMAP {tdata[47:32]}
} {
  S_AXIS fifo_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create axi_axis_writer
cell pavel-demin:user:axi_axis_writer:1.0 writer_0 {
  AXI_DATA_WIDTH 32
} {
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_data_fifo
cell xilinx.com:ip:axis_data_fifo:1.1 fifo_1 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
  FIFO_DEPTH 1024
} {
  S_AXIS writer_0/M_AXIS
  s_axis_aclk /ps_0/FCLK_CLK0
  s_axis_aresetn /rst_0/peripheral_aresetn
}

# Create axis_interpolator
cell pavel-demin:user:axis_interpolator:1.0 inter_0 {
  AXIS_TDATA_WIDTH 32
  CNTR_WIDTH 32
} {
  S_AXIS fifo_1/M_AXIS
  cfg_data slice_2/Dout
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

# Create axis_broadcaster
cell xilinx.com:ip:axis_broadcaster:1.1 bcast_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 4
  NUM_MI 4
  M00_TDATA_REMAP {tdata[31:0]}
  M01_TDATA_REMAP {tdata[31:0]}
  M02_TDATA_REMAP {tdata[31:0]}
  M03_TDATA_REMAP {tdata[31:0]}
} {
  S_AXIS inter_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn /rst_0/peripheral_aresetn
}

for {set i 0} {$i <= 3} {incr i} {

  # Create dds_compiler
  cell xilinx.com:ip:dds_compiler:6.0 dds_$i {
    DDS_CLOCK_RATE 125
    SPURIOUS_FREE_DYNAMIC_RANGE 138
    FREQUENCY_RESOLUTION 0.2
    PHASE_INCREMENT Streaming
    HAS_TREADY true
    HAS_ARESETN true
    HAS_PHASE_OUT false
    PHASE_WIDTH 30
    OUTPUT_WIDTH 24
    DSP48_USE Minimal
    NEGATIVE_SINE true
  } {
    S_AXIS_PHASE bcast_1/M0${i}_AXIS
    aclk /ps_0/FCLK_CLK0
    aresetn slice_0/Dout
  }

  # Create axis_lfsr
  cell pavel-demin:user:axis_lfsr:1.0 lfsr_$i {} {
    aclk /ps_0/FCLK_CLK0
    aresetn /rst_0/peripheral_aresetn
  }

  # Create cmpy
  cell xilinx.com:ip:cmpy:6.0 mult_$i {
    FLOWCONTROL Blocking
    APORTWIDTH.VALUE_SRC USER
    BPORTWIDTH.VALUE_SRC USER
    APORTWIDTH 14
    BPORTWIDTH 24
    ROUNDMODE Random_Rounding
    OUTPUTWIDTH 25
  } {
    S_AXIS_A bcast_0/M0${i}_AXIS
    S_AXIS_B dds_$i/M_AXIS_DATA
    S_AXIS_CTRL lfsr_$i/M_AXIS
    aclk /ps_0/FCLK_CLK0
  }

  # Create axis_broadcaster
  cell xilinx.com:ip:axis_broadcaster:1.1 bcast_[expr $i + 2] {
    S_TDATA_NUM_BYTES.VALUE_SRC USER
    M_TDATA_NUM_BYTES.VALUE_SRC USER
    S_TDATA_NUM_BYTES 8
    M_TDATA_NUM_BYTES 3
    M00_TDATA_REMAP {tdata[23:0]}
    M01_TDATA_REMAP {tdata[55:32]}
  } {
    S_AXIS mult_$i/M_AXIS_DOUT
    aclk /ps_0/FCLK_CLK0
    aresetn slice_0/Dout
  }

}

for {set i 0} {$i <= 7} {incr i} {

  # Create cic_compiler
  cell xilinx.com:ip:cic_compiler:4.0 cic_$i {
    INPUT_DATA_WIDTH.VALUE_SRC USER
    FILTER_TYPE Decimation
    NUMBER_OF_STAGES 6
    SAMPLE_RATE_CHANGES Fixed
    FIXED_OR_INITIAL_RATE 625
    INPUT_SAMPLE_FREQUENCY 125
    CLOCK_FREQUENCY 125
    INPUT_DATA_WIDTH 24
    QUANTIZATION Truncation
    OUTPUT_DATA_WIDTH 24
    USE_XTREME_DSP_SLICE false
    HAS_DOUT_TREADY true
    HAS_ARESETN true
  } {
    S_AXIS_DATA bcast_[expr $i / 2 + 2]/M0[expr $i % 2]_AXIS
    aclk /ps_0/FCLK_CLK0
    aresetn slice_0/Dout
  }

}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 3
  NUM_SI 8
} {
  S00_AXIS cic_7/M_AXIS_DATA
  S01_AXIS cic_6/M_AXIS_DATA
  S02_AXIS cic_5/M_AXIS_DATA
  S03_AXIS cic_4/M_AXIS_DATA
  S04_AXIS cic_3/M_AXIS_DATA
  S05_AXIS cic_2/M_AXIS_DATA
  S06_AXIS cic_1/M_AXIS_DATA
  S07_AXIS cic_0/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 24
  M_TDATA_NUM_BYTES 3
} {
  S_AXIS comb_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.6477796835e-08, -4.7324109616e-08, -7.9386377448e-10, 3.0935253686e-08, 1.8628637484e-08, 3.2749802165e-08, -6.3009636018e-09, -1.5228550143e-07, -8.3046642497e-08, 3.1454718625e-07, 3.0563420390e-07, -4.7419061103e-07, -7.1351570805e-07, 5.4734546459e-07, 1.3346629657e-06, -4.1415915453e-07, -2.1505783817e-06, -6.7737176788e-08, 3.0755642207e-06, 1.0370494593e-06, -3.9444926704e-06, -2.5919902032e-06, 4.5155234807e-06, 4.7479729541e-06, -4.4929905432e-06, -7.3984795163e-06, 3.5722809653e-06, 1.0289858883e-05, -1.5038695261e-06, -1.3021282261e-05, -1.8321390166e-06, 1.5078637447e-05, 6.3548590679e-06, -1.5906194686e-05, -1.1732869327e-05, 1.5011478906e-05, 1.7372551944e-05, -1.2094710859e-05, -2.2467615177e-05, 7.1699281430e-06, 2.6104110256e-05, -6.6353451848e-07, -2.7430148478e-05, -6.5509129865e-06, 2.5865149265e-05, 1.3204830901e-05, -2.1317652580e-05, -1.7790681867e-05, 1.4366752253e-05, 1.8820340233e-05, -6.3577439114e-06, -1.5163017119e-05, -6.3476831165e-07, 6.4159733040e-06, 4.0081563515e-06, 6.7578563684e-06, -1.0056736048e-06, -2.2403849634e-05, -1.0762711914e-05, 3.7234763249e-05, 3.2701623153e-05, -4.6862281429e-05, -6.4654537376e-05, 4.6261796579e-05, 1.0440508544e-04, -3.0541740195e-05, -1.4746189251e-04, -4.1198925704e-06, 1.8719196036e-04, 5.9473838751e-05, -2.1538194574e-04, -1.3430607984e-04, 2.2323147849e-04, 2.2384225060e-04, -2.0270731736e-04, -3.1963381725e-04, 1.4810108212e-04, 4.1006342621e-04, -5.7561661693e-05, -4.8153035535e-04, -6.5678519410e-05, 5.2026753908e-04, 2.1267122551e-04, -5.1463492734e-04, -3.6901803540e-04, 4.5748151510e-04, 5.1599061014e-04, -3.4848823142e-04, -6.3290191507e-04, 1.9565478815e-04, 7.0021131607e-04, -1.5798090247e-05, -7.0322764116e-04, -1.6638407119e-04, 6.3586339930e-04, 3.2084480271e-04, -5.0382554335e-04, -4.1627091895e-04, 3.2657785900e-04, 4.2540748023e-04, -1.3746781164e-04, -3.3105729483e-04, -1.8437257488e-05, 1.3195748309e-04, 8.8999327215e-05, 1.5241222601e-04, -2.2012112968e-05, -4.7912707032e-04, -2.2616082478e-04, 7.8162512263e-04, 6.8035330307e-04, -9.7387823183e-04, -1.3374700150e-03, 9.5754276070e-04, 2.1583048994e-03, -6.3308615644e-04, -3.0624934922e-03, -8.6272668936e-05, 3.9276195054e-03, 1.2589342877e-03, -4.5933512886e-03, -2.8991517793e-03, 4.8709685222e-03, 4.9628713849e-03, -4.5580306679e-03, -7.3369048529e-03, 3.4572763357e-03, 9.8328495813e-03, -1.3982372821e-03, -1.2186552269e-02, -1.7404036929e-03, 1.4062728571e-02, 6.0087383700e-03, -1.5066047123e-02, -1.1370519108e-02, 1.4748808548e-02, 1.7687809181e-02, -1.2618891723e-02, -2.4713969057e-02, 8.1311013959e-03, 3.2087497371e-02, -6.4507671935e-04, -3.9318275074e-02, -1.0692886942e-02, 4.5738007985e-02, 2.7251228023e-02, -5.0322844004e-02, -5.1717719162e-02, 5.1020674679e-02, 9.0573967266e-02, -4.1608640360e-02, -1.6375265144e-01, -1.0802871265e-02, 3.5639480389e-01, 5.5482837305e-01, 3.5639480389e-01, -1.0802871265e-02, -1.6375265144e-01, -4.1608640360e-02, 9.0573967266e-02, 5.1020674679e-02, -5.1717719162e-02, -5.0322844004e-02, 2.7251228023e-02, 4.5738007985e-02, -1.0692886942e-02, -3.9318275074e-02, -6.4507671935e-04, 3.2087497371e-02, 8.1311013959e-03, -2.4713969057e-02, -1.2618891723e-02, 1.7687809181e-02, 1.4748808548e-02, -1.1370519108e-02, -1.5066047123e-02, 6.0087383700e-03, 1.4062728571e-02, -1.7404036929e-03, -1.2186552269e-02, -1.3982372821e-03, 9.8328495813e-03, 3.4572763357e-03, -7.3369048529e-03, -4.5580306679e-03, 4.9628713849e-03, 4.8709685222e-03, -2.8991517793e-03, -4.5933512886e-03, 1.2589342877e-03, 3.9276195054e-03, -8.6272668936e-05, -3.0624934922e-03, -6.3308615644e-04, 2.1583048994e-03, 9.5754276070e-04, -1.3374700150e-03, -9.7387823183e-04, 6.8035330307e-04, 7.8162512263e-04, -2.2616082478e-04, -4.7912707032e-04, -2.2012112968e-05, 1.5241222601e-04, 8.8999327215e-05, 1.3195748309e-04, -1.8437257488e-05, -3.3105729483e-04, -1.3746781164e-04, 4.2540748023e-04, 3.2657785900e-04, -4.1627091895e-04, -5.0382554335e-04, 3.2084480271e-04, 6.3586339930e-04, -1.6638407119e-04, -7.0322764116e-04, -1.5798090247e-05, 7.0021131607e-04, 1.9565478815e-04, -6.3290191507e-04, -3.4848823142e-04, 5.1599061014e-04, 4.5748151510e-04, -3.6901803540e-04, -5.1463492734e-04, 2.1267122551e-04, 5.2026753908e-04, -6.5678519410e-05, -4.8153035535e-04, -5.7561661693e-05, 4.1006342621e-04, 1.4810108212e-04, -3.1963381725e-04, -2.0270731736e-04, 2.2384225060e-04, 2.2323147849e-04, -1.3430607984e-04, -2.1538194574e-04, 5.9473838751e-05, 1.8719196036e-04, -4.1198925704e-06, -1.4746189251e-04, -3.0541740195e-05, 1.0440508544e-04, 4.6261796579e-05, -6.4654537376e-05, -4.6862281429e-05, 3.2701623153e-05, 3.7234763249e-05, -1.0762711914e-05, -2.2403849634e-05, -1.0056736048e-06, 6.7578563684e-06, 4.0081563515e-06, 6.4159733040e-06, -6.3476831165e-07, -1.5163017119e-05, -6.3577439114e-06, 1.8820340233e-05, 1.4366752253e-05, -1.7790681867e-05, -2.1317652580e-05, 1.3204830901e-05, 2.5865149265e-05, -6.5509129865e-06, -2.7430148478e-05, -6.6353451848e-07, 2.6104110256e-05, 7.1699281430e-06, -2.2467615177e-05, -1.2094710859e-05, 1.7372551944e-05, 1.5011478906e-05, -1.1732869327e-05, -1.5906194686e-05, 6.3548590679e-06, 1.5078637447e-05, -1.8321390166e-06, -1.3021282261e-05, -1.5038695261e-06, 1.0289858883e-05, 3.5722809653e-06, -7.3984795163e-06, -4.4929905432e-06, 4.7479729541e-06, 4.5155234807e-06, -2.5919902032e-06, -3.9444926704e-06, 1.0370494593e-06, 3.0755642207e-06, -6.7737176788e-08, -2.1505783817e-06, -4.1415915453e-07, 1.3346629657e-06, 5.4734546459e-07, -7.1351570805e-07, -4.7419061103e-07, 3.0563420390e-07, 3.1454718625e-07, -8.3046642497e-08, -1.5228550143e-07, -6.3009636018e-09, 3.2749802165e-08, 1.8628637484e-08, 3.0935253686e-08, -7.9386377448e-10, -4.7324109616e-08, -1.6477796835e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Maximize_Dynamic_Range
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_CHANNELS 8
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 0.2
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 25
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA conv_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_0/M_AXIS_DATA
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create floating_point
cell xilinx.com:ip:floating_point:7.1 fp_0 {
  OPERATION_TYPE Fixed_to_float
  A_PRECISION_TYPE.VALUE_SRC USER
  C_A_EXPONENT_WIDTH.VALUE_SRC USER
  C_A_FRACTION_WIDTH.VALUE_SRC USER
  A_PRECISION_TYPE Custom
  C_A_EXPONENT_WIDTH 2
  C_A_FRACTION_WIDTH 22
  RESULT_PRECISION_TYPE Single
  HAS_ARESETN true
} {
  S_AXIS_A subset_0/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 32
} {
  S_AXIS fp_0/M_AXIS_RESULT
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}

# Create fifo_generator
cell xilinx.com:ip:fifo_generator:13.0 fifo_generator_0 {
  PERFORMANCE_OPTIONS First_Word_Fall_Through
  INPUT_DATA_WIDTH 256
  INPUT_DEPTH 1024
  OUTPUT_DATA_WIDTH 32
  OUTPUT_DEPTH 8192
  READ_DATA_COUNT true
  READ_DATA_COUNT_WIDTH 14
} {
  clk /ps_0/FCLK_CLK0
  srst slice_1/Dout
}

# Create axis_fifo
cell pavel-demin:user:axis_fifo:1.0 fifo_2 {
  S_AXIS_TDATA_WIDTH 256
  M_AXIS_TDATA_WIDTH 32
} {
  S_AXIS conv_1/M_AXIS
  FIFO_READ fifo_generator_0/FIFO_READ
  FIFO_WRITE fifo_generator_0/FIFO_WRITE
  aclk /ps_0/FCLK_CLK0
}

# Create axi_axis_reader
cell pavel-demin:user:axi_axis_reader:1.0 reader_0 {
  AXI_DATA_WIDTH 32
} {
  S_AXIS fifo_2/M_AXIS
  aclk /ps_0/FCLK_CLK0
  aresetn slice_0/Dout
}
