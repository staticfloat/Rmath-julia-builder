using BinaryBuilder
using SHA

# Define what we're downloading, where we're putting it
src_name = "Rmath-julia"
src_vers = "0.2.0"
src_url = "https://github.com/JuliaLang/Rmath-julia/archive/v$(src_vers).tar.gz"
src_hash = "087ada2913c5401c5772cde1606f9924dcb159f1c9d755630dcce350ef8036ac"

# First, download the source, store it in ./downloads/
src_path = joinpath(pwd(), "downloads", basename(src_url))
try mkpath(dirname(src_path)) end
download_verify(src_url, src_hash, src_path; verbose=true)

# Our build products will go into ./products
out_path = joinpath(pwd(), "products")
rm(out_path; force=true, recursive=true)
mkpath(out_path)

# Build Rmath-julia for all our platforms
products = Dict()
for platform in supported_platforms()
    target = platform_triplet(platform)

    # We build in a platform-specific directory
    build_path = joinpath(pwd(), "build", target)
    try mkpath(build_path) end

    cd(build_path) do
        # For each build, create a temporary prefix we'll install into
        temp_prefix() do prefix
            # Unpack the source into our build directory
            unpack(src_path, build_path; verbose=true)

            cd("./Rmath-julia-$(src_vers)") do
                # We expect this output from our build steps
                libRmath = LibraryProduct("./src", "libRmath")

                # The libRmath makefile is kind of dumb
                makevars = `fPIC=-fPIC`
                if startswith(String(platform), "win")
                    makevars = `$makevars OS=Windows_NT`
                end

                steps = [
                    `make clean`,
                    `make $(makevars) -j$(min(Sys.CPU_CORES + 1,8))`,
                ]

                dep = Dependency(src_name, [libRmath], steps, platform, prefix)
                build(dep; verbose=true)

                # Create the folders we're going to install into
                mkdir(libdir(prefix))

                # Once it's been built, manually copy `libRmath` to `prefix`
                # We have to do this because the Makefile doesn't install it.
                libRmath_path = locate(libRmath, platform=platform, verbose=true)
                cp(libRmath_path, joinpath(libdir(prefix), basename(libRmath_path)))
                # Also copy in the headers, because why not.
                cp("./include", includedir(prefix))
            end

            # Once we're built up, go ahead and package this prefix out
            tarball_path, tarball_hash = package(prefix, joinpath(out_path, src_name); platform=platform, verbose=true)
            products[target] = (basename(tarball_path), tarball_hash)
        end
    end
    
    # Finally, destroy the build_path
    rm(build_path; recursive=true)
end

# In the end, dump an informative message telling the user how to download/install these
info("Hash/filename pairings:")
for target in keys(products)
    filename, hash = products[target]
    println("    :$(platform_key(target)) => (\"\$bin_prefix/$(filename)\", \"$(hash)\"),")
end
