module InputFiles 

# External Packages

# Internal Packages
include("IOModule.jl")
using .IOModule

include("SetupModule.jl")
using .SetupModule

# Exports
export load_raw_input
export preprocess_input 
export setup_global!

end # module
