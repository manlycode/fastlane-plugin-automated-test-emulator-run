require 'tempfile'

module Fastlane
  module Factory

    class AVD_Controller
        attr_accessor :command_create_avd, :command_start_avd, :command_delete_avd, :command_apply_config_avd, :command_get_property, :command_kill_device,
                      :output_file

        def self.create_output_file(params)
          output_file = Tempfile.new('emulator_output', '#{params[:AVD_path]}')
        end
    end

    class AvdControllerFactory
  
        def self.get_avd_controller(params, avd_scheme)
          UI.message(["Preparing parameters and commands for emulator:", avd_scheme.avd_name].join(" ").yellow)

          # Get paths
          path_sdk = "#{params[:SDK_path]}"
          path_android_binary = path_sdk + "/tools/android"
          path_adb = path_sdk + "/platform-tools/adb"
          path_avd = "#{params[:AVD_path]}"

          # Create AVD shell command parts
          sh_create_answer_no = "echo \"no\" |"
          sh_create_avd = "create avd"
          sh_create_avd_name = ["--name \"", avd_scheme.avd_name, "\""].join("")
          sh_create_avd_additional_options = avd_scheme.create_avd_additional_options
          sh_create_config_loc = "#{path_avd}/#{avd_scheme.avd_name}.avd/config.ini"

          if avd_scheme.create_avd_target.eql? "" 
            sh_create_avd_target = ""
          else
            sh_create_avd_target = ["--target \"", avd_scheme.create_avd_target, "\""].join("")
          end

          if avd_scheme.create_avd_abi.eql? "" 
            sh_create_avd_abi = ""
          else
            sh_create_avd_abi = ["--abi ", avd_scheme.create_avd_abi].join("")
          end
          
          # Launch AVD shell command parts
          sh_launch_emulator_binray = [path_sdk, "/tools/", avd_scheme.launch_avd_launch_binary_name].join("")
          sh_launch_avd_name = ["-avd ", avd_scheme.avd_name].join("")
          sh_launch_avd_additional_options = avd_scheme.launch_avd_additional_options
          sh_launch_avd_port = ["-port", avd_scheme.launch_avd_port].join(" ") 
          
          if avd_scheme.launch_avd_snapshot_filepath.eql? ""
             sh_launch_avd_snapshot = ""
          else
             sh_launch_avd_snapshot = ["-wipe-data -initdata ", avd_scheme.launch_avd_snapshot_filepath].join("")
          end   

          # Re-create AVD shell command parts
          sh_delete_avd = ["delete avd -n ", avd_scheme.avd_name].join("")

          # ADB related shell command parts
          sh_specific_device = "-s"
          sh_device_name_adb = ["emulator-", avd_scheme.launch_avd_port].join("")
          sh_get_property = "shell getprop"
          sh_kill_device = "emu kill"

          # Assemble AVD controller
          avd_controller = AVD_Controller.new
          avd_controller.command_create_avd = [
           sh_create_answer_no, 
           path_android_binary, 
           sh_create_avd, 
           sh_create_avd_name, 
           sh_create_avd_target, 
           sh_create_avd_abi, 
           sh_create_avd_additional_options].join(" ")

          avd_controller.output_file = Tempfile.new('emulator_output')
          avd_output = File.exists?(avd_controller.output_file) ? ["&>", avd_controller.output_file.path, "&"].join("") : "&>/dev/null &"
          
          avd_controller.command_start_avd = [
           sh_launch_emulator_binray, 
           sh_launch_avd_port, 
           sh_launch_avd_name, 
           sh_launch_avd_snapshot, 
           sh_launch_avd_additional_options, 
           avd_output].join(" ")

          avd_controller.command_delete_avd = [
           path_android_binary,
           sh_delete_avd].join(" ")

          if path_avd.nil? || (avd_scheme.create_avd_hardware_config_filepath.eql? "")
            avd_controller.command_apply_config_avd = ""
          else
            avd_controller.command_apply_config_avd = [
              "cat",
              avd_scheme.create_avd_hardware_config_filepath,
              ">",
              sh_create_config_loc].join(" ")
          end
          
          avd_controller.command_get_property = [
           path_adb,
           sh_specific_device,
           sh_device_name_adb,
           sh_get_property].join(" ")

          avd_controller.command_kill_device = [
           path_adb,
           sh_specific_device,
           sh_device_name_adb,
           sh_kill_device,
           "&>/dev/null"].join(" ")

          return avd_controller
        end 
    end
  end
end