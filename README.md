# NettleBuilder

[![Build Status](https://travis-ci.org/staticfloat/NettleBuilder.svg?branch=master)](https://travis-ci.org/staticfloat/NettleBuilder)

This is an example repository showing how to construct a "builder" repository for a binary dependency.  Using a combination of [`BinDeps2.jl`](https://github.com/staticfloat/BinDeps2.jl), [Travis](https://travis-ci.org), and [GitHub releases](https://docs.travis-ci.com/user/deployment/releases/), we are able to create a fully-automated, github-hosted binary building and serving infrastructure.