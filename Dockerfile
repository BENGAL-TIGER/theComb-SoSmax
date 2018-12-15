# ψᵟ
#
FROM    mdabioinfo/sos-notebook

LABEL   maintainer="mdAshford"

USER    root

ENV     JULIA_VERSION_0=$JULIA_VERSION

       # Build CoolProp
RUN     /opt/julia-0.6.2/bin/julia -e 'Pkg.init(); Pkg.clone("https://github.com/vimalaad/CoolProp.jl.git"); Pkg.build("CoolProp"); Pkg.update()'

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
# install julia-1.0.2
# ENV JULIA_DEPOT_PATH=/opt/julia

# ENV JULIA_PKGDIR=/opt/julia

ENV     JULIA_VERSION_1=1.0.2

RUN     mkdir -p /opt/julia-${JULIA_VERSION_1} && \
        cd /tmp && \
        curl -O https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION_1} | cut -d. -f 1,2`/julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz && \
        echo "e0e93949753cc4ac46d5f27d7ae213488b3fef5f8e766794df0058e1b3d2f142 *julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz" | sha256sum -c - && \
        tar xzf julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION_1} --strip-components=1 && \
        rm /tmp/julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz

RUN     ln -fs /opt/julia-${JULIA_VERSION_1}/bin/julia /usr/local/bin/julia-${JULIA_VERSION_1}

       # Show Julia where conda libraries are \
RUN     mkdir -p /etc/julia

RUN     echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
       # Create JULIA_PKGDIR \
        mkdir -p $JULIA_PKGDIR && \
        chown $NB_USER $JULIA_PKGDIR && \
        fix-permissions $JULIA_PKGDIR

USER    $NB_UID




# Add Julia packages. Only add HDF5 if this is not a test-only build since
# it takes roughly half the entire build time of all of the images on Travis
# to add this one package and often causes Travis to timeout.
#
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN       julia-${JULIA_VERSION_1} -e 'using Pkg; Pkg.add("Feather"); Pkg.add("DataFrames")' && \
          julia-${JULIA_VERSION_1} -e 'Pkg.add("NamedArrays"); Pkg.add("RDatasets")' && \
          julia-${JULIA_VERSION_1} -e 'Pkg.add("Unitful"); Pkg.update()'

    # (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    # julia -e 'import Pkg; Pkg.add("Gadfly")' && \
    # julia -e 'import Pkg; Pkg.add("RDatasets")' && \
    # julia -e 'import Pkg; Pkg.add("IJulia")' && \

         # Precompile Julia packages \
RUN       julia-${JULIA_VERSION_1} -e 'Pkg.add("IJulia"); using IJulia'
# RUN       julia-${JULIA_VERSION_1} -e 'using IJulia; IJulia.installkernel("Julia quiet", "--depwarn=no")'

         # move kernelspec out of home \
RUN       mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
          chmod -R go+rx $CONDA_DIR/share/jupyter && \
          rm -rf $HOME/.local && \
          fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter


RUN     cd ~/work
