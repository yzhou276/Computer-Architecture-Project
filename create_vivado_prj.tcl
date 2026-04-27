# Vivado script

# project directory
set prjDir      "prj"
# project name
set project     "prj"
# device part number
set devicePart  "xc7a100tcsg324-1"
# top module rtl
set topModule   "ceil_log2"

# create the project
create_project $projectName $prjDir -part $device -force
# Project properties
set obj [current_project]
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
update_ip_catalog
# set source management mode
set_property source_mgmt_mode All [current_project]


add_files -norecurse {C:/Users/zhouy2/Documents/JHU/Computer-Architecture-Project/firmware/rtl/leading_one_detector_32.sv C:/Users/zhouy2/Documents/JHU/Computer-Architecture-Project/firmware/rtl/ceil_log2.sv}
update_compile_order -fileset sources_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse C:/Users/zhouy2/Documents/JHU/Computer-Architecture-Project/firmware/sim/ceil_log2_test_values.txt
add_files -fileset sim_1 -norecurse C:/Users/zhouy2/Documents/JHU/Computer-Architecture-Project/firmware/sim/tb_ceil_log2_32_fileio.sv
update_compile_order -fileset sim_1


