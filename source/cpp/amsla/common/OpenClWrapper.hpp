/** @file OpenClWrapper.hpp
 *  @brief Wrapper for the OpenCl library
 *
 *  This contains the definition for DataStructure object. Any data structure has
 *  abide by this interface.
 *
 *  @author Andrea Picciau <andrea@picciau.net>
 *
 *  @copyright Copyright 2019-2020 Andrea Picciau
 *
 *  @license Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *  
 *     http://www.apache.org/licenses/LICENSE-2.0
 *  
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#ifndef _AMSLA_COMMON_OPENCLWRAPPER_HPP
#define _AMSLA_COMMON_OPENCLWRAPPER_HPP

// System includes
#define __CL_ENABLE_EXCEPTIONS
#include <CL/cl.hpp>
#include <string>
#include <vector>
#include <algorithm>

// Project includes
#include "Assertions.hpp"

namespace amsla::common
{

/** @function defaultContext 
 * @brief Get the default OpenCL context
 */
cl::Context defaultContext(void)
{
    // Query platforms
    std::vector<cl::Platform> platforms;
    cl::Platform::get(&platforms);
    amsla::common::check_that(platforms.size() != 0, "No OpenCL platforms found.");

    // Get list of devices on default platform and create context
    cl_context_properties properties[] =
        {CL_CONTEXT_PLATFORM, (cl_context_properties)(platforms[0])(), 0};
    cl::Context context(CL_DEVICE_TYPE_ALL, properties);
}

/** @brief Compile a kernel
 *  
 *  Given the source of the kernel as a string and the kernel's name, compile it
  *
 *  @params kernel_source The source for the kernel.
 *  @params kernel_name The name of the kernel in the source.
 */
cl::Kernel compileKernel(std::string const &kernel_source, std::string const &kernel_name)
{
    amsla::common::check_that(kernel_source.length() != 0 && kernel_name.length() != 0,
                              "Empty kernel provided.")
        cl::Context context = defaultContext();

    //Build kernel from source string
    cl::Program::Sources source(1,
                                std::make_pair(kernel_source.c_str(), kernel_source.length()));
    cl::Program program = cl::Program(context, source);
    try
    {
        program.build(devices);
    }
    catch (cl::Error err)
    {
        std::cerr
            << err << std::endl;
        if (err.what() == "clBuildProgram")
        {
            auto build_log = program.getBuildInfo<CL_PROGRAM_BUILD_LOG>(devices[0]);
            std::cerr << build_log << std::endl;
        }
    }

    // Create kernel object
    return cl::Kernel kernel(program, kernel_name.c_str(), &err);
}

} // namespace amsla::common

#endif