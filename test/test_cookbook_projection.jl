using Base.Test
import ArchGDAL; const AG = ArchGDAL

@testset "Reproject a Geometry" begin
    @testset "Method 1" begin
        source = AG.unsafe_importEPSG(2927); target = AG.unsafe_importEPSG(4326)
            transform = AG.unsafe_createcoordtrans(source, target)
                point = AG.unsafe_fromWKT("POINT (1120351.57 741921.42)")
                    @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                    AG.transform!(point, transform)
                    @test GeoInterface.coordinates(point) ≈ [-122.598135, 47.348801]
                AG.destroy(point)
            AG.destroy(transform)
        AG.destroy(target); AG.destroy(source)
    end

    @testset "Method 2" begin
        AG.importEPSG(2927) do source; AG.importEPSG(4326) do target
            AG.createcoordtrans(source, target) do transform
                AG.fromWKT("POINT (1120351.57 741921.42)") do point
                    @test AG.toWKT(point) == "POINT (1120351.57 741921.42)"
                    AG.transform!(point, transform)
                    @test GeoInterface.coordinates(point) ≈ [-122.598135, 47.348801]
        end end end end
    end
end

@testset "Get Projection" begin
    AG.registerdrivers() do
        AG.read("ospy/data1/sites.shp") do dataset
            layer = AG.getlayer(dataset, 0)
            spatialref = AG.getspatialref(layer)
            @test AG.toWKT(spatialref)[1:6] == "PROJCS"
            @test AG.toWKT(spatialref, false)[1:6] == "PROJCS"
            @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs "
            @test AG.toXML(spatialref)[1:17] == "<gml:ProjectedCRS"
            @test AG.toMICoordSys(spatialref) == "Earth Projection 8, 104, \"m\", -111, 0, 0.9996, 500000, 0"
            AG.nextfeature(layer) do feature
                @test AG.toPROJ4(AG.getspatialref(AG.getgeom(feature))) == "+proj=utm +zone=12 +datum=WGS84 +units=m +no_defs "
            end
        end
    end

    AG.importEPSG(26912) do spatialref
        @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs "
        @test AG.toWKT(spatialref)[1:6] == "PROJCS"
        AG.morphtoESRI!(spatialref)
        @test AG.toPROJ4(spatialref) == "+proj=utm +zone=12 +ellps=GRS80 +units=m +no_defs "
    end
end
