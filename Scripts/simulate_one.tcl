#  Set path for current stimuli file 
set CURRENT_STIMULI_PATH ./../Current_Stimuli.txt 

set STIMULI_DIR_PATH ./../Stimuli 
#  Set path for Current report file 
set BASE_DIR_PATH ./../../TESTBENCH

#      [file exists ./../TESTBENCH/Current_Stimuli.txt]         ./../TESTBENCH/Current_Stimuli.txt

set CURRENT_REPORT_PATH ./../Current_Report.txt

#info exists

if {[info exists sim_num] == 1} {
   puts "sim is $sim_num"
} else {
   puts "sim is not set"
}

#set test_n [llength [glob -type d $STIMULI_DIR_PATH]]


set isSim [current_sim]
#set stimuli_file [glob $STIMULI_DIR_PATH -type f *{Test_$sim_num}*]
set stimuli_file Test_$sim_num.txt

if { [file exists $CURRENT_STIMULI_PATH] == 1} {    
      puts "Deleting old Stimuli file" 
      file delete -force $CURRENT_STIMULI_PATH 
    
}
file copy $STIMULI_DIR_PATH/$stimuli_file $CURRENT_STIMULI_PATH  
puts "loading stimuli file with  $stimuli_file"


if {$isSim == ""} {

   puts "Sim is not running , starting sim."
   reset_simulation -simset sim_1 -mode behavioral
   launch_simulation
   
   
} else {
   restart
}

run all

puts "copyng the report file in the directory Reportst naming it Report_$sim_num.txt"
file copy -force $CURRENT_REPORT_PATH ./../Reports/Report_$sim_num.txt

cd $BASE_DIR_PATH

set slaves_data_files [glob $BASE_DIR_PATH -type f *{Current_slv}*]
set slaves_files [regexp -all -inline -- {[0-9]+} $slaves_data_files ]



foreach x $slaves_files {
    file copy -force ./Current_slv_$x.txt ./Reports/Report_$sim_num.data_received_from_slave_$x.txt
}

cd ./Scripts