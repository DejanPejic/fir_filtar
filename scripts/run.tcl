# Stvaranje direktorijuma u kojem ce biti smesten projekat
cd ..
file mkdir project
cd project

# Stvaranje projekta
create_project fir_filter fir_filter -part xc7z010clg400-1
set_property board_part digilentinc.com:zybo:part0:2.0 [current_project]
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]

# Ucitavanje dizajn fajlova i podesavanje vrha hijerarhije
add_files -norecurse ../design/util_pkg.vhd
add_files -norecurse ../design/txt_util.vhd
add_files -norecurse ../design/mac.vhd
add_files -norecurse ../design/fir.vhd
add_files -norecurse ../design/switch.vhd
add_files -norecurse ../design/voter.vhd
add_files -norecurse ../design/self_purging_fir.vhd
add_files -norecurse ../design/fir_axi_top.vhd
set_property top fir_axi_top [current_fileset]
update_compile_order -fileset sources_1

# Ucitavanje contraint fajla
add_files -fileset constrs_1 -norecurse ../constraint/constraint.xdc
update_compile_order -fileset sources_1

# Ucitavanje simulacionih fajlova
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../sim/fir_tb.vhd
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../sim/switch_tb.vhd
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../sim/voter_tb.vhd
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../sim/self_purging_fir_tb.vhd
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../sim/fir_axi_top_tb.vhd
set_property top fir_axi_top_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

# Pokretanje sinteze i implementacije
#launch_runs synth_1 -jobs 6
#wait_on_run synth_1
#launch_runs impl_1 -jobs 6
#wait_on_run impl_1

set_property -name {xsim.simulate.runtime} -value {0 ns} -objects [get_filesets sim_1]
launch_simulation
# source ../scripts/force_faults.tcl