cmake_minimum_required(VERSION 3.1)

### GENERATE INCLUDABLE STRINGS FROM OPENCL CODE

# Make the OpenCL kernels includable at build time
function(make_includable input_file output_file)
    file(READ "${input_file}" content)
    set(delim "for_c++_include")
    set(content "R\"${delim}(\n${content})${delim}\"")
    file(WRITE "${output_file}" "${content}")
endfunction(make_includable)

### ADD SUBDIRECTORIES

add_subdirectory("common")
# add_subdirectory("data_structures")
