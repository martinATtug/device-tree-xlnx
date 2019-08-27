#
# (C) Copyright 2018 Xilinx, Inc.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

proc generate {drv_handle} {
	foreach i [get_sw_cores device_tree] {
		set common_tcl_file "[get_property "REPOSITORY" $i]/data/common_proc.tcl"
		if {[file exists $common_tcl_file]} {
			source $common_tcl_file
			break
		}
	}
	set node [gen_peripheral_nodes $drv_handle]
	if {$node == 0} {
		return
	}
	set compatible [get_comp_str $drv_handle]
	set compatible [append compatible " " "xlnx,dsi"]
	set_drv_prop $drv_handle compatible "$compatible" stringlist
	set dsi_num_lanes [get_property CONFIG.DSI_LANES [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dsi-num-lanes" $dsi_num_lanes int
	set dsi_pixels_perbeat [get_property CONFIG.DSI_PIXELS [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dsi-pixels-perbeat" $dsi_pixels_perbeat int
	set dsi_datatype [get_property CONFIG.DSI_DATATYPE [get_cells -hier $drv_handle]]
	hsi::utils::add_new_dts_param "$node" "xlnx,dsi-datatype" $dsi_datatype string
	set connected_ip [hsi::utils::get_connected_stream_ip [get_cells -hier $drv_handle] "S_AXIS"]
	set connected_ip_type [get_property IP_NAME $connected_ip]
	if {[string match -nocase $connected_ip_type "v_frmbuf_rd"]} {
		set dsi_port_node [add_or_get_dt_node -n "port" -l encoder_dsi_port -u 0 -p $node]
		hsi::utils::add_new_dts_param "$dsi_port_node" "reg" 0 int
		set dsi_encoder_node [add_or_get_dt_node -n "endpoint" -l dsi_encoder -p $dsi_port_node]
		hsi::utils::add_new_dts_param "$dsi_encoder_node" "remote-endpoint" pl_disp_crtc reference
		set dts_file [current_dt_tree]
		set bus_node "amba_pl"
		set pl_display [add_or_get_dt_node -n "drm-pl-disp-drv" -l "v_drm_pl_disp_drv" -d $dts_file -p $bus_node]
		hsi::utils::add_new_dts_param $pl_display "compatible" "xlnx,pl-disp" string
		hsi::utils::add_new_dts_param $pl_display "dmas" "$connected_ip 0" reference
		hsi::utils::add_new_dts_param $pl_display "dma-names" "dma0" string
		hsi::utils::add_new_dts_param "${pl_display}" "/* User needs to fill the xlnx,vformat=BG24 based on their requirement */" "" comment
		hsi::utils::add_new_dts_param $pl_display "xlnx,vformat" "BG24" string
		set pl_display_port_node [add_or_get_dt_node -n "port" -l pl_display_port -u 0 -p $pl_display]
		hsi::utils::add_new_dts_param "$pl_display_port_node" "reg" 0 int
		set pl_disp_crtc_node [add_or_get_dt_node -n "endpoint" -l pl_disp_crtc -p $pl_display_port_node]
		hsi::utils::add_new_dts_param "$pl_disp_crtc_node" "remote-endpoint" dsi_encoder reference
	}
	if {[string match -nocase $connected_ip_type "v_mix"]} {
		set dsi_port_node [add_or_get_dt_node -n "port" -l encoder_dsi_port -u 0 -p $node]
		hsi::utils::add_new_dts_param "$dsi_port_node" "reg" 0 int
		set dsi_encoder_node [add_or_get_dt_node -n "endpoint" -l dsi_encoder -p $dsi_port_node]
		hsi::utils::add_new_dts_param "$dsi_encoder_node" "remote-endpoint" mixer_crtc reference
	}
	set panel_node [add_or_get_dt_node -n "simple_panel" -l simple_panel -u 0 -p $node]
	hsi::utils::add_new_dts_param "${panel_node}" "/* User needs to add the panel node based on their requirement */" "" comment
	hsi::utils::add_new_dts_param "$panel_node" "reg" 0 int
	hsi::utils::add_new_dts_param "$panel_node" "compatible" "auo,b101uan01" string
}
