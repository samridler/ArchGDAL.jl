mutable struct Source <: Data.Source
    schema::Data.Schema
    featurelayer::FeatureLayer
    feature::ArchGDAL.Feature
    ngeom::Int
end

function Source(layer::FeatureLayer)
    layerdefn = getlayerdefn(layer)
    ngeom = ngeomfield(layerdefn)
    nfld = nfield(layerdefn)
    header = [
        ["geometry$(i-1)" for i in 1:ngeom];
        [getname(getfielddefn(layerdefn,i-1)) for i in 1:nfld]
    ]
    types = [
        [IGeometry for i in 1:ngeom];
        [_FIELDTYPE[gettype(getfielddefn(layerdefn,i-1))] for i in 1:nfld]
    ]
    ArchGDAL.Source(
        Data.Schema(types, header, nfeature(layer)),
        layer,
        unsafe_nextfeature(layer),
        ngeom
    )
end
Data.schema(source::ArchGDAL.Source) = source.schema
Data.isdone(s::ArchGDAL.Source, row, col) = s.feature.ptr == C_NULL
Data.streamtype(::Type{ArchGDAL.Source}, ::Type{Data.Field}) = true
Data.accesspattern(source::ArchGDAL.Source) = Data.Sequential
Data.reset!(source::ArchGDAL.Source) = resetreading!(source.featurelayer)

function Data.streamfrom{T}(
        source::ArchGDAL.Source,
        ::Type{Data.Field},
        ::Type{T},
        row,
        col
    )
    val = if col <= source.ngeom
        T(getgeomfield(source.feature, col-1).ptr)
    else
        T(getfield(source.feature, col-source.ngeom-1))
    end
    if col == source.schema.cols
        destroy(source.feature)
        source.feature.ptr = GDAL.getnextfeature(source.featurelayer.ptr)
        if row == source.schema.rows
            @assert source.feature.ptr == C_NULL
            resetreading!(source.featurelayer)
        end
    end
    val
end
