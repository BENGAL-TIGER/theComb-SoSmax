# ψᵟ
#
FROM mdabioinfo/sos-notebook

LABEL maintainer="mdAshford"

USER root


# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
# install julia-0.6.4
# ENV JULIA_DEPOT_PATH=/opt/julia

ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION_1=0.6.4

RUN \
    mkdir /opt/julia-${JULIA_VERSION_1} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION_1} | cut -d. -f 1,2`/julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz && \
    # echo "d20e6984bcf8c3692d853a9922e2cf1de19b91201cb9e396d9264c32cebedc46 *julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION_1} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION_1}-linux-x86_64.tar.gz

RUN ln -fs /opt/julia-${JULIA_VERSION_1}/bin/julia /usr/local/bin/julia-${JULIA_VERSION_1}

    # Show Julia where conda libraries are \
# RUN mkdir /etc/julia && \
RUN    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    # Create JULIA_PKGDIR \
    # mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_UID

# Add Julia packages. Only add HDF5 if this is not a test-only build since
# it takes roughly half the entire build time of all of the images on Travis
# to add this one package and often causes Travis to timeout.
#
# Install IJulia as jovyan and then move the kernelspec out
# to the system share location. Avoids problems with runtime UID change not
# taking effect properly on the .local folder in the jovyan home dir.
RUN julia-${JULIA_VERSION_1} -e 'Pkg.init(); Pkg.update()' && \
    julia-${JULIA_VERSION_1} -e 'Pkg.clone("https://github.com/vimalaad/CoolProp.jl.git"); Pkg.build("CoolProp")'  && \
    # (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    # julia -e 'import Pkg; Pkg.add("Gadfly")' && \
    # julia -e 'import Pkg; Pkg.add("RDatasets")' && \
    # julia -e 'import Pkg; Pkg.add("IJulia")' && \
     # Precompile Julia packages \
    julia-${JULIA_VERSION_1} -e 'using IJulia; IJulia.installkernel("Julia quiet", "--depwarn=no")' && \
     # move kernelspec out of home \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter


RUN     cd ~/work
