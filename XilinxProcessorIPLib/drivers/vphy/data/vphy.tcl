##******************************************************************************
##
## Copyright (C) 2015 Xilinx, Inc.  All rights reserved.
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## Use of the Software is limited solely to applications:
## (a) running on a Xilinx device, or
## (b) that interact with a Xilinx device through a bus or interconnect.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
## WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
## OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
##
## Except as contained in this notice, the name of the Xilinx shall not be used
## in advertising or otherwise to promote the sale, use or other dealings in
## this Software without prior written authorization from Xilinx.
##
##*****************************************************************************/

proc generate {drv_handle} {
    xdefine_include_file $drv_handle "xparameters.h" "XVPHY" "NUM_INSTANCES" "DEVICE_ID" "C_BASEADDR" "Transceiver" "C_Tx_No_Of_Channels" "C_Rx_No_Of_Channels" "C_Tx_Protocol" "C_Rx_Protocol" "C_TX_REFCLK_SEL" "C_RX_REFCLK_SEL" "C_TX_PLL_SELECTION" "C_RX_PLL_SELECTION" "C_NIDRU" "C_NIDRU_REFCLK_SEL"
    ::hsi::utils::define_config_file $drv_handle "xvphy_g.c" "XVphy" "DEVICE_ID" "C_BASEADDR" "TRANSCEIVER" "C_Tx_No_Of_Channels" "C_Rx_No_Of_Channels" "C_Tx_Protocol" "C_Rx_Protocol" "C_TX_REFCLK_SEL" "C_RX_REFCLK_SEL" "C_TX_PLL_SELECTION" "C_RX_PLL_SELECTION" "C_NIDRU" "C_NIDRU_REFCLK_SEL"
    xdefine_canonical_xpars $drv_handle "xparameters.h" "VPHY" "DEVICE_ID" "C_BASEADDR" "Transceiver" "C_Tx_No_Of_Channels" "C_Rx_No_Of_Channels" "C_Tx_Protocol" "C_Rx_Protocol" "C_TX_REFCLK_SEL" "C_RX_REFCLK_SEL" "C_TX_PLL_SELECTION" "C_RX_PLL_SELECTION" "C_NIDRU" "C_NIDRU_REFCLK_SEL"
}

#
# Given a list of arguments, define them all in an include file.
# Handles IP model/user parameters, as well as the special parameters NUM_INSTANCES,
# DEVICE_ID
# Will not work for a processor.
#
proc xdefine_include_file {drv_handle file_name drv_string args} {
    set args [::hsi::utils::get_exact_arg_list $args]
    # Open include file
    set file_handle [::hsi::utils::open_include_file $file_name]

    # Get all peripherals connected to this driver
    set periphs [::hsi::utils::get_common_driver_ips $drv_handle]

    # Handle special cases
    set arg "NUM_INSTANCES"
    set posn [lsearch -exact $args $arg]
    if {$posn > -1} {
        puts $file_handle "/* Definitions for driver [string toupper [common::get_property name $drv_handle]] */"
        # Define NUM_INSTANCES
        puts $file_handle "#define [::hsi::utils::get_driver_param_name $drv_string $arg] [llength $periphs]"
        set args [lreplace $args $posn $posn]
    }

    # Check if it is a driver parameter
    lappend newargs
    foreach arg $args {
        set value [common::get_property CONFIG.$arg $drv_handle]
        if {[llength $value] == 0} {
            lappend newargs $arg
        } else {
            puts $file_handle "#define [::hsi::utils::get_driver_param_name $drv_string $arg] [common::get_property $arg $drv_handle]"
        }
    }
    set args $newargs

    # Print all parameters for all peripherals
    set device_id 0
    foreach periph $periphs {
        puts $file_handle ""
        puts $file_handle "/* Definitions for peripheral [string toupper [common::get_property NAME $periph]] */"
        foreach arg $args {
            if {[string compare -nocase "DEVICE_ID" $arg] == 0} {
                set value $device_id
                incr device_id
            } else {
                set value [common::get_property CONFIG.$arg $periph]
            }
            if {[llength $value] == 0} {
                set value 0
            }
            set value [::hsi::utils::format_addr_string $value $arg]
            if {[string compare -nocase "HW_VER" $arg] == 0} {
                puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $arg] \"$value\""
	    } elseif {[string compare -nocase "TRANSCEIVER" $arg] == 0} {
                puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $arg]_STR \"$value\""
                if {[string compare -nocase "GTXE2" "$value"] == 0} {
                    puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $arg] 1"
		} elseif {[string compare -nocase "GTHE3" "$value"] == 0} {
                    puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $arg] 4"
		} else {
		    puts $file_handle "#error \"Video PHY currently supports only GTHE3 and GTXE2; $value not supported\""
		}
            } else {
                puts $file_handle "#define [::hsi::utils::get_ip_param_name $periph $arg] $value"
            }
        }
        puts $file_handle ""
    }
    puts $file_handle "\n/******************************************************************/\n"
    close $file_handle
}

#
# define_canonical_xpars - Used to print out canonical defines for a driver.
# Given a list of arguments, define each as a canonical constant name, using
# the driver name, in an include file.
#
proc xdefine_canonical_xpars {drv_handle file_name drv_string args} {
    set args [::hsi::utils::get_exact_arg_list $args]
   # Open include file
   set file_handle [::hsi::utils::open_include_file $file_name]

   # Get all the peripherals connected to this driver
   set periphs [::hsi::utils::get_common_driver_ips $drv_handle]

   # Get the names of all the peripherals connected to this driver
   foreach periph $periphs {
       set peripheral_name [string toupper [common::get_property NAME $periph]]
       lappend peripherals $peripheral_name
   }

   # Get possible canonical names for all the peripherals connected to this
   # driver
   set device_id 0
   foreach periph $periphs {
       set canonical_name [string toupper [format "%s_%s" $drv_string $device_id]]
       lappend canonicals $canonical_name

       # Create a list of IDs of the peripherals whose hardware instance name
       # doesn't match the canonical name. These IDs can be used later to
       # generate canonical definitions
       if { [lsearch $peripherals $canonical_name] < 0 } {
           lappend indices $device_id
       }
       incr device_id
   }

   set i 0
   foreach periph $periphs {
       set periph_name [string toupper [common::get_property NAME $periph]]

       # Generate canonical definitions only for the peripherals whose
       # canonical name is not the same as hardware instance name
       if { [lsearch $canonicals $periph_name] < 0 } {
           puts $file_handle "/* Canonical definitions for peripheral $periph_name */"
           set canonical_name [format "%s_%s" $drv_string [lindex $indices $i]]

           foreach arg $args {
               set lvalue [::hsi::utils::get_driver_param_name $canonical_name $arg]

               # The commented out rvalue is the name of the instance-specific constant
               # set rvalue [::hsi::utils::get_ip_param_name $periph $arg]
               # The rvalue set below is the actual value of the parameter
               set rvalue [::hsi::utils::get_param_value $periph $arg]
               if {[llength $rvalue] == 0} {
                   set rvalue 0
               }
               set rvalue [::hsi::utils::format_addr_string $rvalue $arg]

	       if {[string compare -nocase "TRANSCEIVER" $arg] == 0} {
                   puts $file_handle "#define [string toupper $lvalue]_STR \"$rvalue\""
                   if {[string compare -nocase "GTXE2" "$rvalue"] == 0} {
                       puts $file_handle "#define [string toupper $lvalue] 1"
		   } elseif {[string compare -nocase "GTHE3" "$rvalue"] == 0} {
                       puts $file_handle "#define [string toupper $lvalue] 4"
		   } else {
		       puts $file_handle "#error \"Video PHY currently supports only GTHE3 and GTXE2; $rvalue not supported\""
		   }
               } else {
                   puts $file_handle "#define [string toupper $lvalue] $rvalue"
               }

           }
           puts $file_handle ""
           incr i
       }
   }

   puts $file_handle "\n/******************************************************************/\n"
   close $file_handle
}
